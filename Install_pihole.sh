#!/bin/bash

#You will need to run the following to make the script executable
#sudo chmod +x Install_pihole.sh
#sudo ./Install_pihole.sh

#Settings
INSTALL_PIHOLE=true							#Install Pihole - set to false to skip
INSTALL_ZEROTIER_ROUTER=true				#Install Zerotier - set to false to skip
INSTALL_HASS=true							#Install Home Assistant - set to false to skip
INSTALL_LIBRE_SPEEDTEST=true                #Install Libre Speedtest - set to false to skip
INSTALL_SHARES=false                         #Install MergerFS and SAMBA - set to false to skip

source "secrets.sh"

#Variables
ZT_TOKEN=$ZT_TOKEN 	                        #Your Zerotier API Token - Get this from https://my.zerotier.com/account -> "new token"
NWID=$NWID  				                #Your Zerotier Network ID - Get this from https://my.zerotier.com/
REMOTE_USER=$SAMBA_USER                     #User to use for the SAMBA share. You will connect with this user.
REMOTE_PASS=$SAMBA_PASS                     #The above user's password.
HDD_IDS=()                                  #The IDs of the HDD's you wan to add to the pool - Get from: ls -l /dev/disk/by-id
MERGERFS_DIR="default"                      #The directory name where the merged forlder should be mounted
READ_ONLY_SHARES=no                         #Should the shared folder be read-only
PHY_IFACE=default 							#The Network Interface to use - Default auto detects the interface
DNS_1=8.8.8.8 								#DNS Server used by your ISP - Get this from ifconfig/connection properties on any PC or from your router. Leave as is to use Google's DNS server
DNS_2=8.8.4.4 								#DNS Server used by your ISP - Get this from ifconfig/connection properties on any PC or from your router. Leave as is to use Google's DNS server
DNS_3=2001:4860:4860::8888  				#DNS Server used by your ISP - Leave as is if the ISP has not IPV6 DNS
DNS_4=2001:4860:4860::8844  				#DNS Server used by your ISP - Leave as is if the ISP has not IPV6 DNS

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

add-apt-repository multiverse -y
apt update
apt upgrade -y

apt install curl nano build-essential openssh-server git python3-pip pipx python3-dev htop net-tools cifs-utils bzip2 ntfs-3g ufw -y

#Zerotier Router Setup
if [ "$INSTALL_ZEROTIER_ROUTER" == "true" ]
then
	if [ "$PHY_IFACE" == "default" ]
	then
		PHY_IFACE=$(ifconfig | grep -E 'eth|enp|end' | cut -d ":" -f 1 | cut -d " " -f 1 | xargs)
		echo "Detected Ethernet Connection: $PHY_IFACE"
	fi
	
	curl -s https://install.zerotier.com | bash
	zerotier-cli join $NWID

	MEMBER_ID=$(zerotier-cli info | cut -d " " -f 3)
	echo "Joined network: $NWID with member_id: $MEMBER_ID"

	curl -s -H "Authorization: token $ZT_TOKEN" -X POST "https://api.zerotier.com/api/v1/network/$NWID/member/$MEMBER_ID" --data '{"config": {"authorized": true}, "name": "'"${HOSTNAME}"'"}'
	
	sleep 3
	VIA_IP=$(curl -s -H "Authorization: token $ZT_TOKEN" -X GET "https://api.zerotier.com/api/v1/network/$NWID/member/$MEMBER_ID" | jq '.config.ipAssignments[0]' | cut -d '"' -f2)
	ZT_IFACE=$(ifconfig | grep zt* | cut -d ":" -f 1 | head --lines 1)
	
	echo "Authorized Zerotier Interface: $ZT_IFACE with IP: $VIA_IP"
	
	echo net.ipv4.ip_forward = 1 >> /etc/sysctl.conf
	sysctl -p

	iptables -t nat -A POSTROUTING -o $PHY_IFACE -j MASQUERADE
	iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
	iptables -A FORWARD -i $PHY_IFACE -o $ZT_IFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
	iptables -A FORWARD -i $ZT_IFACE -o $PHY_IFACE -j ACCEPT

	LOCAL_IP="$(ifconfig $PHY_IFACE | grep "inet " | xargs | cut -d " " -f 2)"
	NET_MASK="$(ifconfig $PHY_IFACE | grep "inet " | xargs | cut -d " " -f 4)"
	TARGET_RANGE="$(ifconfig $PHY_IFACE | grep "inet " | xargs | cut -d " " -f 2 | cut -d "." -f 1,2,3).0"
	
	echo "Detected Local IP: $LOCAL_IP with Netmask: $NET_MASK"

	NEW_ROUTES="$(curl -s -H "Authorization: token $ZT_TOKEN" -X GET "https://api.zerotier.com/api/v1/network/$NWID" | jq '.config.routes' | cut -d ']' -f1), {\"target\":\"${TARGET_RANGE}/23\", \"via\":\"${VIA_IP}\"}, {\"target\":\"0.0.0.0/0\", \"via\":\"${VIA_IP}\"}]"
	
	echo "Configuring new routes:"
	echo $NEW_ROUTES | jq '.'

	if [ "$INSTALL_PIHOLE" == "true" ]
	then
		NEW_DNS="$(curl -s -H "Authorization: token $ZT_TOKEN" -X GET "https://api.zerotier.com/api/v1/network/$NWID" | jq '.config.dns.servers' | cut -d ']' -f1), \"${VIA_IP}\"]"
		echo "Configuring new DNS servers:"
		echo $NEW_DNS | jq '.'
		
		curl -H "Authorization: token $ZT_TOKEN" -X POST "https://api.zerotier.com/api/v1/network/$NWID" --data '{"config": {"routes": '"$NEW_ROUTES"', "dns":{"domain": "'"$HOSTNAME"'.local", "servers" :'"$NEW_DNS"'}}}'
	else
		curl -H "Authorization: token $ZT_TOKEN" -X POST "https://api.zerotier.com/api/v1/network/$NWID" --data '{"config": {"routes": '"$NEW_ROUTES"'}}'
	fi
	
	echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
	echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections

	apt-get -y install iptables-persistent
	bash -c iptables-save > /etc/iptables/rules.v4
fi

#MergerFS Setup
if [ "$INSTALL_SHARES" == "true" ]
then
    echo "Setting up Shared Folders"
    apt install samba mergerfs -y

    if [ ${#HDD_IDS[@]} -eq 0 ]; then
        echo "No HDD configured using default options"
        echo "Seaching for suitable drives..."

        ls /dev/disk/by-id | grep -v "part\|DVD\|CD" | grep "ata\|usb\|nvme" | while read -r drive ; do
            echo "Found Drive: $drive"

            partitions=$(ls /dev/disk/by-id | grep "$drive-part1")
            
            ls /dev/disk/by-id | grep "$drive-part" | while read -r partition ; do
                mount_point=$(lsblk -r /dev/disk/by-id/$partition | grep "sd" | cut -d " " -f 7)
                FSTYPE=$(lsblk -n -o FSTYPE /dev/disk/by-id/$partition)
                
                if [ -z ${mount_point} ]; then
                    echo "  Found Partition: $partition which is not mounted"

                    if [ -z ${FSTYPE} ]; then
                        echo "      Partition $partition is not formatted. Formatting now..."
                        mkfs.ntfs -f /dev/disk/by-id/$partition
                    fi

                    echo "      Adding partition to MergerFS Pool"
                    echo $partition >> hdd_ids.temp
                else
                    echo "  Found Partition: $partition mounted at $mount_point"

                    if [ "$mount_point" = "/" ] || [[ "$mount_point" = *"/boot/"* ]] || [[ "$mount_point" = *"/root/"* ]] || [[ "$mount_point" = *"/snap/"* ]]; then
                        echo "      Partition mounted on root: skipping"
                    else

                        echo "      Adding partition to MergerFS Pool"
                        echo $partition >> hdd_ids.temp
                    fi
                fi
            done
            
            if [ -z ${partitions} ]; then
                echo "  Drive has no paritions: "
                echo "  Attempting to create them now..."

                sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/disk/by-id/$drive
                    o # clear the in memory partition table
                    n # new partition
                    p # primary partition
                    1 # partition number 1
                        # default, start immediately after preceding partition
                        # default, extend partition to end of disk
                    p # print the in-memory partition table
                    w # write the partition table
                    q # and we're done
EOF
                sleep 5
                partition=$(ls /dev/disk/by-id | grep "$drive-part1")

                echo "  Formatting with NTFS:"
                mkfs.ntfs -f /dev/disk/by-id/$partition

                echo "Adding to MergerFS pool"
                echo $partition >> hdd_ids.temp
            fi
        done
    fi

    if [ ${#HDD_IDS[@]} -eq 0 ]; then
        mapfile -t HDD_IDS < hdd_ids.temp
        rm -f hdd_ids.temp
    fi

    if [ ${#HDD_IDS[@]} -eq 0 ]; then
        echo "No suitable drives found for MergerFS. Skipping setup"
    else
        echo "Configuring MergerFS:"

        COUNTER=1
        for HDD_ID in ${HDD_IDS[@]}; do
            HDD=$(ls /dev/disk/by-id | grep "$HDD_ID")

            if [ -z ${HDD} ]; then
                echo "Invalid disk ID: $HDD_ID, skipping"
                continue
            fi

            FSNAME=$(lsblk -n -o NAME /dev/disk/by-id/$HDD_ID)
            FSTYPE=$(lsblk -n -o FSTYPE /dev/disk/by-id/$HDD_ID)

            if grep -F "/dev/disk/by-id/$HDD_ID /mnt/disk$COUNTER" /etc/fstab
            then
                echo "Found existing disk: $FSNAME, with partition type: $FSTYPE, mounted on: /mnt/disk$COUNTER"
                COUNTER=$[ $COUNTER + 1 ]
                continue
            fi

            echo "Detected new disk: $FSNAME with partition type: $FSTYPE"

            mkdir -p /mnt/disk$COUNTER
            echo "/dev/disk/by-id/$HDD_ID /mnt/disk$COUNTER   $FSTYPE defaults 0 0" >> /etc/fstab
            mount /dev/disk/by-id/$HDD_ID /mnt/disk$COUNTER
            COUNTER=$[ $COUNTER + 1 ]
        done

        if [ "$MERGERFS_DIR" == "default" ]; then
            MERGERFS_DIR="NAS"
        fi

        if grep -F "/mnt/disk* /mnt/$MERGERFS_DIR fuse.mergerfs" /etc/fstab 
        then
            echo "MergerFS already found"
        else
            mkdir -p /mnt/$MERGERFS_DIR

            echo "/mnt/disk*/ /mnt/$MERGERFS_DIR fuse.mergerfs defaults,nonempty,allow_other,use_ino,cache.files=off,moveonenospc=true,dropcacheonclose=true,minfreespace=20G,fsname=mergerfs 0 0" >> /etc/fstab
            mergerfs -o defaults,nonempty,allow_other,use_ino,cache.files=off,moveonenospc=true,dropcacheonclose=true,minfreespace=20G,fsname=mergerfs /mnt/disk\* /mnt/$MERGERFS_DIR
        fi

        if grep -F "comment = MergerFS Share" /etc/samba/smb.conf
        then
            echo "Share Already Exists"
        else
            echo "[$MERGERFS_DIR]" >> /etc/samba/smb.conf
            echo "    comment = MergerFS Share" >> /etc/samba/smb.conf
            echo "    path = /mnt/$MERGERFS_DIR" >> /etc/samba/smb.conf
            echo "    read only = $READ_ONLY_SHARES" >> /etc/samba/smb.conf
            echo "    browsable = yes" >> /etc/samba/smb.conf

            service smbd restart
            ufw allow samba

            if [ "$REMOTE_USER" == "default" ]; then
                REMOTE_USER=$SUDO_USER
            fi

            useradd $REMOTE_USER
            sleep 1
            echo -ne "$REMOTE_PASS\n$REMOTE_PASS\n" | passwd -q $REMOTE_USER
            echo -ne "$REMOTE_PASS\n$REMOTE_PASS\n" | smbpasswd -a -s $REMOTE_USER
        fi
        SMB_URL="smb://$ip_local/$MERGERFS_DIR"
        echo "Samba share can now be accessed at: $SMB_URL"
    fi
fi

#PiHole
if [ "$INSTALL_PIHOLE" == "true" ]
then
	mkdir /etc/pihole

	echo PIHOLE_INTERFACE=$PHY_IFACE > /etc/pihole/setupVars.conf
	echo PIHOLE_DNS_1=$DNS_1 >> /etc/pihole/setupVars.conf
	echo PIHOLE_DNS_2=$DNS_2 >> /etc/pihole/setupVars.conf
	echo PIHOLE_DNS_3=$DNS_3 >> /etc/pihole/setupVars.conf
	echo PIHOLE_DNS_4=$DNS_4 >> /etc/pihole/setupVars.conf
	echo QUERY_LOGGING=true >> /etc/pihole/setupVars.conf
	echo INSTALL_WEB_SERVER=true >> /etc/pihole/setupVars.conf
	echo INSTALL_WEB_INTERFACE=true >> /etc/pihole/setupVars.conf
	echo LIGHTTPD_ENABLED=true >> /etc/pihole/setupVars.conf
	echo CACHE_SIZE=10000 >> /etc/pihole/setupVars.conf
	echo DNS_FQDN_REQUIRED=true >> /etc/pihole/setupVars.conf
	echo DNS_BOGUS_PRIV=true >> /etc/pihole/setupVars.conf
	echo DNSMASQ_LISTENING=local >> /etc/pihole/setupVars.conf
	echo WEBPASSWORD=dfc3c40f4febab4fca7f76a6936def7c3b6e82397e231ba65e55531c92f7dbff >> /etc/pihole/setupVars.conf
	echo BLOCKING_ENABLED=true >> /etc/pihole/setupVars.conf
	echo WEBUIBOXEDLAYOUT=boxed >> /etc/pihole/setupVars.conf
	echo WEBTHEME=default-dark >> /etc/pihole/setupVars.conf

	curl -L https://install.pi-hole.net | bash /dev/stdin --unattended
fi

#Home Assistant
if [ "$INSTALL_HASS" == "true" ]
then
	apt-get install -y python3 python3-dev python3-venv python3-pip bluez libffi-dev libssl-dev libjpeg-dev zlib1g-dev autoconf build-essential libopenjp2-7 libtiff6 libturbojpeg0-dev tzdata ffmpeg liblapack3 liblapack-dev libatlas-base-dev

	useradd -rm homeassistant

	mkdir /srv/homeassistant
	chmod 777 -R /srv/homeassistant

	echo '#!/bin/bash' > /srv/homeassistant/Install_HAS.sh
	echo cd /srv/homeassistant >> /srv/homeassistant/Install_HAS.sh
	echo python3 -m venv . >> /srv/homeassistant/Install_HAS.sh
	echo source bin/activate >> /srv/homeassistant/Install_HAS.sh
	echo python3 -m pip install wheel >> /srv/homeassistant/Install_HAS.sh
	echo pip3 install homeassistant >> /srv/homeassistant/Install_HAS.sh
	echo mkdir /home/homeassistant/.homeassistant >> /srv/homeassistant/Install_HAS.sh

	chown -R homeassistant:homeassistant /srv/homeassistant 
	chmod +x /srv/homeassistant/Install_HAS.sh

	sudo -u homeassistant -H -s /srv/homeassistant/Install_HAS.sh 
	
	echo [Unit] > /etc/systemd/system/home-assistant@homeassistant.service
	echo Description=Home Assistant >> /etc/systemd/system/home-assistant@homeassistant.service
	echo After=network-online.target >> /etc/systemd/system/home-assistant@homeassistant.service
	echo " " >> /etc/systemd/system/home-assistant@homeassistant.service
	echo [Service] >> /etc/systemd/system/home-assistant@homeassistant.service
	echo Type=simple >> /etc/systemd/system/home-assistant@homeassistant.service
	echo User=%i >> /etc/systemd/system/home-assistant@homeassistant.service
	echo WorkingDirectory=/home/%i/.homeassistant >> /etc/systemd/system/home-assistant@homeassistant.service
	echo ExecStart=/srv/homeassistant/bin/hass -c "/home/%i/.homeassistant" >> /etc/systemd/system/home-assistant@homeassistant.service
	echo Environment="PATH=/srv/homeassistant/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/homeassistant/.local/bin" >>  /etc/systemd/system/home-assistant@homeassistant.service
	echo RestartForceExitStatus=100 >> /etc/systemd/system/home-assistant@homeassistant.service
	echo " " >> /etc/systemd/system/home-assistant@homeassistant.service
	echo [Install] >> /etc/systemd/system/home-assistant@homeassistant.service
	echo WantedBy=multi-user.target >> /etc/systemd/system/home-assistant@homeassistant.service
	
	systemctl --system daemon-reload
	systemctl enable home-assistant@homeassistant
	systemctl start home-assistant@homeassistant
fi

if [ "$INSTALL_LIBRE_SPEEDTEST" == "true" ]
then
    apt install nginx mysql-server php-fpm php-mysql php-image-text php-gd php-sqlite3 -y

    rm -rf /etc/nginx/sites-available/speedtest

    echo "server {" > /etc/nginx/sites-available/speedtest
    echo "    listen 11000;" >> /etc/nginx/sites-available/speedtest
    echo "    server_name speedtest www.speedtest;" >> /etc/nginx/sites-available/speedtest
    echo "    root /var/www/html/speedtest;" >> /etc/nginx/sites-available/speedtest
    echo "" >> /etc/nginx/sites-available/speedtest
    echo "    index index.html index.htm index.php;" >> /etc/nginx/sites-available/speedtest
    echo "" >> /etc/nginx/sites-available/speedtest
    echo "    location / {" >> /etc/nginx/sites-available/speedtest
    echo '        try_files $uri $uri/ =404;' >> /etc/nginx/sites-available/speedtest
    echo "    }" >> /etc/nginx/sites-available/speedtest
    echo "" >> /etc/nginx/sites-available/speedtest
    echo "    location ~ \.php$ {" >> /etc/nginx/sites-available/speedtest
    echo "        include snippets/fastcgi-php.conf;" >> /etc/nginx/sites-available/speedtest
    echo "        fastcgi_pass unix:/var/run/php/php-fpm.sock;" >> /etc/nginx/sites-available/speedtest
    echo "    }" >> /etc/nginx/sites-available/speedtest
    echo "" >> /etc/nginx/sites-available/speedtest
    echo "    location ~ /\.ht {" >> /etc/nginx/sites-available/speedtest
    echo "        deny all;" >> /etc/nginx/sites-available/speedtest
    echo "    }" >> /etc/nginx/sites-available/speedtest
    echo "" >> /etc/nginx/sites-available/speedtest
    echo "}" >> /etc/nginx/sites-available/speedtest

    ln -s /etc/nginx/sites-available/speedtest /etc/nginx/sites-enabled/
    unlink /etc/nginx/sites-enabled/default

    systemctl reload nginx

    fpm_version=$(ls /var/run/php | grep "php8.*fpm.sock") 
    ini_location="/etc/php/${fpm_version:3:3}/fpm/php.ini"

    sed -i 's/post_max_size = 8M/post_max_size = 100M/' $ini_location
    sed -i 's/;extension=gd/extension=gd/' $ini_location
    sed -i 's/;extension=pdo_sqlite/extension=pdo_sqlite/' $ini_location

    systemctl restart nginx    

    
    rm -rf /var/www/html/speedtest/
    mkdir -p /var/www/html/speedtest
    chown -R $SUDO_USER:$SUDO_USER /var/www/html/speedtest
    
    git clone https://github.com/librespeed/speedtest.git

    sleep 3

    cp -f ./speedtest/index.html /var/www/html/speedtest/
    cp -f ./speedtest/speedtest.js /var/www/html/speedtest/
    cp -f ./speedtest/speedtest_worker.js /var/www/html/speedtest/
    cp -f ./speedtest/favicon.ico /var/www/html/speedtest/
    cp -rf ./speedtest/backend/  /var/www/html/speedtest/
    cp -rf ./speedtest/results/  /var/www/html/results/

    rm -rf ./speedtest
fi

echo "---------------------------------------------------------------------"
echo " "
echo "Installations Complete!"

if [ "$INSTALL_PIHOLE" == "true" ]
then
	echo " "
	echo "Finish Setting Up Pihole:"
	echo "Change default password (Password):"
	echo "	sudo pihole -a -p"
	echo "NB: You will now need to log into your router and configure the DHCP settings to use $LOCAL_IP as the primary DNS server"
	echo " "
	echo "PiHole can be accessed via: http://$LOCAL_IP/admin"
fi

if [ "$INSTALL_HASS" == "true" ]
then
	echo " "
	echo "Finish Setting Up Home Assistant:"
	echo "Home Assistant can be accessed via: http://$LOCAL_IP:8123"
fi

if [ "$INSTALL_LIBRE_SPEEDTEST" == "true" ]
then
	echo " "
	echo "Finish Setting Up Libre Speed Test:"
	echo "Libre Speed Test can be accessed via: http://$LOCAL_IP:11000"
fi

if [ "$INSTALL_SHARES" == "true" ]
then
    echo " "
	echo "Finish Setting Up MergerFS with Samba:"
    echo "Samba can now be accessed at: $SMB_URL"
    echo "User: $REMOTE_USER"
    echo "Password": $REMOTE_PASS
fi

if [ "$INSTALL_ZEROTIER_ROUTER" == "true" ]
then
	echo " "
	echo "Optional Zerotier Config:"
	echo "Joining Two Physical Networks (This allows devices without Zerotier to communicate with each other across networks):"
	echo "You will need a Zerotier router setup on both ends of the network (IE. You will need to run this script on devices on either end)"
	echo "If you would like local devices to be able to access a remote Zerotier device's network you will need to add a static route to your router with the following settings:"
	echo "	Network Destination: The destination network IP Range (Ex 192.168.0.0 for devices in range 192.168.0.1 to 192.168.0.254)"
	echo "	Default Gateway: $LOCAL_IP"
	echo "	Network Mask: $NET_MASK"
	echo "	Interface: LAN"
	echo "	Description: Zerotier Route"
fi
