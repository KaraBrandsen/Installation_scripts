#!/bin/bash
source "secrets.sh"

#Variables
	#Zerotier
		ZT_TOKEN=$ZT_TOKEN	 	                                #Your Zerotier API Token - Get this from https://my.zerotier.com/account -> "new token"
        NWID=$NWID              								#Your Zerotier Network ID - Get this from https://my.zerotier.com/
        PHY_IFACE=default
    
    #MergerFS
        HDD_IDS=()                                              #The IDs of the HDD's you wan to add to the pool - Get from: ls -l /dev/disk/by-id
        MERGERFS_DIR="default"                                  #The directory name where the merged forlder should be mounted
        READ_ONLY_SHARES=no                                     #Should the shared folder be read-only
        REMOTE_USER=$SAMBA_USER                                 #User to use for the SAMBA share. You will connect with this user.
        REMOTE_PASS=$SAMBA_PASS                                 #The above user's password.
	
	#SABNZBd
		SABNZBD_PORT=8001										#Port SABNZBD should be served on
        SERVER_HOST=$SERVER_HOST    		                    #News server host name
		SERVER_PORT=$SERVER_PORT								#News server port
		SERVER_USERNAME=$SERVER_USERNAME	        			#News server username
		SERVER_PASSWORD=$SERVER_PASSWORD           				#News server password
		SERVER_CONNECTIONS=$SERVER_CONNECTIONS					#News server number of active connections
		SERVER_SSL=$SERVER_SSL									#Should the news server use SSL
		
	#Sonarr
		SONARR_PORT=8989										#Port Sonarr should be served on
		SONARR_ROOT_FOLDER=("/mnt/nas/series")		            #Folders to where you want to store series (Can already conatin a few)
		INDEXER_NAME=$INDEXER_NAME			           			#Indexer name
		INDEXER_URL=$INDEXER_URL		                    	#Indexer host name
		INDEXER_API_PATH=$INDEXER_API_PATH						#Indexer path to the api
		INDEXER_APIKEY=$INDEXER_APIKEY	                        #Indexer api key
		
	#Radarr
		RADARR_PORT=7878										#Port Radarr should be served on
        RADARR_ROOT_FOLDER=("/mnt/nas/movies")		        	#Folders to where you want to store movies (Can already conatin a few)

    #Shares
        WIN_HOST=$WIN_HOST
        WIN_SHARES=$WIN_SHARES

    #Pihole
        DNS_1=8.8.8.8 								#DNS Server used by your ISP - Get this from ifconfig/connection properties on any PC or from your router. Leave as is to use Google's DNS server
        DNS_2=8.8.4.4 								#DNS Server used by your ISP - Get this from ifconfig/connection properties on any PC or from your router. Leave as is to use Google's DNS server
        DNS_3=2001:4860:4860::8888  				#DNS Server used by your ISP - Leave as is if the ISP has not IPV6 DNS
        DNS_4=2001:4860:4860::8844  				#DNS Server used by your ISP - Leave as is if the ISP has not IPV6 DNS

    #Shell Extensions
        EXTENSION_SETTINGS='H4sIAAAAAAAAA+VWS2/jOAy++1cUuXgXqOIk7XSaAgb6mkOx7TToFgssiqBQJNrWRJYMic5jiv73pRwnTV+LorO3vSQ2yY8SyY+k7yT4KdoqqcCpqgDHtU9KW3sYR4ZjTe/MC2e1TjNSQRTdvYVAW4ui4vIdEM4ty5TJwbVyemZg+ESDTNHVz9w6NeNiOY4cVNYhQxCFUYJcVs4SoPQvEQ5Ki8A2r7IaRyvnK0vUnglwmMZJYUtIptzxpKst+Ux8wR0kuSE5e+2HEbQrHMaNjyksP+mCkPH7F54ZMY54jQUrAQsr07ji3s+tk/GzOJ4cePBeWTOOlNTBj+bLtFYG9wY7w16PDD0gUo49k5zOMkml61wZn1R2Dm4NU2VbHq8BKqYMF6hmwLhgqEqwNaZ7B+TuDfWygjQ2Fgs6JETmC9B6HEnlw3UZ0ccxWCCYcE3fHtNq5bbmLq4ntcGaSSumx6vnrrBlvC7hC2vuRAmmPm7/G9PdnVhyXzC0rOIG9PEPCc56GHZzhUU9WRvlXlhjQOAxN3JZWF2CX5soGyx+1B4Z8TojIzpwXaHjF/Jg+pdCCur4zDo4s5LS0N464zPrFFWXV1W4MEm7ubW5hu5Z4Ygj3dZpcGJd3m2I0/1O9Ve69m9rb8GVlH+9rcVZt9Kw6I7o53wl3qjH0Ry0CISUimubM80pAF/YuWEzcCGZabx/0O1tapc8ZTlpc0vlhIzXGll4YzMF8zQ+0fp+5GzueOnjqFFMakTKFcUL1BVGEDMuKNFxVDnIPOG8CpyoeA5pj7pagEG9JD55ymAocJspb3jFPFJC71tOeJvhnJprKy5PZ4iCZge6JZtQixDRHJeq9ulvoUl2dwZffo9CpA1vHCWNqjhTAjZj41W8z8hDnWhUyVcFVBQHKyyljK2kgRQNEtOH+OZiNLr8Fh/t7FM5Rpcn3/9on/+8uFop+o/R2kvJHXVgur8R0LQMtAmSGVe66RtqVUUJoGz0KPuWOGe9wqZap9e3t9dXcVRYpGniWbgUtT2jKk9sGt9+uxpd35zcXFz+HUcaMpzYxeYI1o+a2CgIUQT38UOn1znqXF2cn19+6zzGrRpoulJom1PXhncPnVZFoJDbE6rYaVP2zm6nLXDnqOny3c4aHWyRiynI28vO4+62j2aSkBH8kpcQ5qldbIMbCnwEi9xPJ9x9ChsIDO6DJ5/evEA7lRcfvfYrsF96hPKK2u5TcEm8/jx41YSvK/ZvHsYbcmkwORZrSvV7vY3Gq5+wlu8NgthRr1F/t+1AU4M8Yu3Zs8YhVqOjDth6nysjqfNp8IRpRVsMw+DZ9NDt9ejNgRfg40gUIKZs0e/P+VLThnh3XrzYBoSkD4HpakpuDuu9JWU2y2g1k/J/uQszRRvBLu7b//9kE45bErVbqCVDwylK86+swVkTFflfF0+ZVU5pZDcLZsKR5sByxZNGknGz/qQKrzOrMWy9lkjY3j3RkNMXLn3p2kxp8EfJ0aQvhRhKyb4MDgZsXx7SVjw82GPicPgVDuTw63AyfNrHITga/LouiQf9Qe+5wtm5pw+36B8kf6MK2wsAAA=='
        EXTENSION_LIST=( https://extensions.gnome.org/extension/1160/dash-to-panel/
 https://extensions.gnome.org/extension/1460/vitals/
 https://extensions.gnome.org/extension/3628/arcmenu/
 https://extensions.gnome.org/extension/1319/gsconnect/
 https://extensions.gnome.org/extension/3843/just-perfection/)


if [ "$EUID" -ne 0 ]
  then 
  echo "Please run as root"
  exit
fi

ARG=${1:-"desktop"}   

sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1

if [ "$ARG" == "desktop" ]; then
    echo "Running desktop setup"
    echo "----------------------------------------------------------------------------------"

    INSTALL_ZEROTIER=true					#Install Zerotier - set to false to skip
    INSTALL_ZEROTIER_ROUTER=false			#Install Zerotier - set to false to skip
    INSTALL_PIHOLE=false					#Install Pihole - set to false to skip
    INSTALL_HASS=false						#Install Home Assistant - set to false to skip
    INSTALL_LIBRE_SPEEDTEST=false           #Install Libre Speedtest Server - set to false to skip
    INSTALL_FILE_SERVER=false               #Install MergerFS and SAMBA - set to false to skip
    INSTALL_SABNZBD=false					#Install SABNZBD - set to false to skip
    INSTALL_SONARR=false					#Install Sonarr - set to false to skip
    INSTALL_RADARR=false					#Install Radarr - set to false to skip
    INSTALL_PLEX=false						#Install Plex Server - set to false to skip
    INSTALL_SHARES=false                    #Install Windows Shares - set to false to skip
    INSTALL_SHELL_EXTENSIONS=true           #Install Shell Extensions - set to false to skip

    add-apt-repository multiverse -y
    apt update
    apt upgrade -y

    apt install flatpak gnome-software-plugin-flatpak gnome-shell-extension-manager piper gir1.2-gtop-2.0 lm-sensors gnome-tweaks gparted -y

    VERSION=$(lsb_release -a | grep "Release" | cut -d ':' -f 2 | xargs | cut -d '.' -f 1)

    if [ "$VERSION" -gt 22 ]; then
            dpkg --add-architecture i386
            apt update
            apt install steam-installer -y
    else
            apt install steam -y
    fi

    snap refresh
    snap install --classic code

    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 
    flatpak install flathub com.google.Chrome com.discordapp.Discord org.videolan.VLC com.spotify.Client org.gimp.GIMP org.libreoffice.LibreOffice io.github.mimbrero.WhatsAppDesktop org.signal.Signal org.inkscape.Inkscape com.slack.Slack com.adobe.Reader com.skype.Client tv.plex.PlexDesktop cc.arduino.IDE2 org.raspberrypi.rpi-imager com.ultimaker.cura io.github.prateekmedia.appimagepool org.kicad.KiCad org.gnome.meld org.qbittorrent.qBittorrent com.notepadqq.Notepadqq org.wireshark.Wireshark us.zoom.Zoom -y
fi

if [ "$ARG" == "nas" ]; then
    echo "Running NAS setup"
    echo "----------------------------------------------------------------------------------"

    INSTALL_ZEROTIER=true					#Install Zerotier - set to false to skip
    INSTALL_ZEROTIER_ROUTER=false			#Install Zerotier - set to false to skip
    INSTALL_PIHOLE=false					#Install Pihole - set to false to skip
    INSTALL_HASS=false						#Install Home Assistant - set to false to skip
    INSTALL_LIBRE_SPEEDTEST=false           #Install Libre Speedtest Server - set to false to skip
    INSTALL_FILE_SERVER=false               #Install MergerFS and SAMBA - set to false to skip
    INSTALL_SABNZBD=true					#Install SABNZBD - set to false to skip
    INSTALL_SONARR=true 					#Install Sonarr - set to false to skip
    INSTALL_RADARR=true 					#Install Radarr - set to false to skip
    INSTALL_PLEX=true  						#Install Plex Server- set to false to skip
    INSTALL_SHARES=false                    #Install Windows Shares - set to false to skip
    INSTALL_SHELL_EXTENSIONS=true           #Install Shell Extensions - set to false to skip

    apt update
    apt install sqlite3 -y
fi

if [ "$ARG" == "pihole" ]; then
    echo "Running pihole setup"
    echo "----------------------------------------------------------------------------------"

    INSTALL_ZEROTIER=false					#Install Zerotier - set to false to skip
    INSTALL_ZEROTIER_ROUTER=true			#Install Zerotier - set to false to skip
    INSTALL_PIHOLE=true 					#Install Pihole - set to false to skip
    INSTALL_HASS=true						#Install Home Assistant - set to false to skip
    INSTALL_LIBRE_SPEEDTEST=true            #Install Libre Speedtest Server - set to false to skip
    INSTALL_FILE_SERVER=true                #Install MergerFS and SAMBA - set to false to skip
    INSTALL_SABNZBD=false					#Install SABNZBD - set to false to skip
    INSTALL_SONARR=false 					#Install Sonarr - set to false to skip
    INSTALL_RADARR=false 					#Install Radarr - set to false to skip
    INSTALL_PLEX=false  					#Install Plex Server- set to false to skip
    INSTALL_SHARES=false                    #Install Windows Shares - set to false to skip
    INSTALL_SHELL_EXTENSIONS=false          #Install Shell Extensions - set to false to skip

    add-apt-repository multiverse -y
fi

apt update
apt upgrade -y
apt install curl nano jq build-essential openssh-server git python3-pip pipx python3-dev htop bmon net-tools bzip2 ntfs-3g ufw bmon -y

#Constants
APP_UID=$SUDO_USER
APP_GUID=users
HOST=$(hostname -I)
IP_LOCAL=$(grep -oP '^\S*' <<<"$HOST")

#Zerotier Setup
if [ "$INSTALL_ZEROTIER" == "true" ]
then
    echo "-----------------------------Installing Zerotier-----------------------------"

	curl -s https://install.zerotier.com | bash
	zerotier-cli join $NWID

	MEMBER_ID=$(zerotier-cli info | cut -d " " -f 3)
    echo "Joined network: $NWID with member_id: $MEMBER_ID"
    
	curl -H "Authorization: token $ZT_TOKEN" -X POST "https://api.zerotier.com/api/v1/network/$NWID/member/$MEMBER_ID" --data '{"config": {"authorized": true}, "name": "'"${HOSTNAME}"'"}'

    sleep 5
    VIA_IP=$(curl -s -H "Authorization: token $ZT_TOKEN" -X GET "https://api.zerotier.com/api/v1/network/$NWID/member/$MEMBER_ID" | jq '.config.ipAssignments[0]' | cut -d '"' -f2)
    ZT_IFACE=$(ifconfig | grep zt* | cut -d ":" -f 1 | head --lines 1)

    echo "Authorized Zerotier Interface: $ZT_IFACE with IP: $VIA_IP"
    echo "Installled Zerotier"
fi

#Zerotier Router Setup
if [ "$INSTALL_ZEROTIER_ROUTER" == "true" ]
then
    echo "-----------------------------Installing Zerotier Router-----------------------------"

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
	
	sleep 5
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

    echo "Installled Zerotier Router"
fi

#PiHole
if [ "$INSTALL_PIHOLE" == "true" ]
then
    echo "-----------------------------Installing PiHole-----------------------------"

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

    echo "Installled PiHole"
fi

#Home Assistant
if [ "$INSTALL_HASS" == "true" ]
then
    echo "-----------------------------Installing Home Assistant-----------------------------"

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

    echo "Installled Home Assistant"
fi

if [ "$INSTALL_LIBRE_SPEEDTEST" == "true" ]
then
    echo "-----------------------------Installing Libre Speed Test-----------------------------"

    echo "Installing Nginx"
    apt install nginx mysql-server php-fpm php-mysql php-image-text php-gd php-sqlite3 -y

    rm -rf /etc/nginx/sites-available/speedtest

    echo "Configuring Nginx"
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

    FPM_VERSION=$(ls /var/run/php | grep "php8.*fpm.sock") 
    INI_LOCATION="/etc/php/${FPM_VERSION:3:3}/fpm/php.ini"

    echo "Configuring PHP"
    sed -i 's/post_max_size = 8M/post_max_size = 100M/' $INI_LOCATION
    sed -i 's/;extension=gd/extension=gd/' $INI_LOCATION
    sed -i 's/;extension=pdo_sqlite/extension=pdo_sqlite/' $INI_LOCATION

    systemctl restart nginx    

    echo "Installing Libre Speed Test"

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
    echo "Installled Libre Speed Test"
fi

#MergerFS Setup
if [ "$INSTALL_FILE_SERVER" == "true" ]
then
    echo "-----------------------------Installing MergerFS-----------------------------"

    echo "Setting up Shared Folders"
    apt install samba mergerfs -y

    if [ ${#HDD_IDS[@]} -eq 0 ]; then
        echo "No HDD configured using default options"
        echo "Seaching for suitable drives..."

        ls /dev/disk/by-id | grep -v "part\|DVD\|CD" | grep "ata\|usb\|nvme" | while read -r DRIVE ; do
            echo "Found Drive: $DRIVE"

            PARTITIONS=$(ls /dev/disk/by-id | grep "$DRIVE-part1")
            
            ls /dev/disk/by-id | grep "$DRIVE-part" | while read -r PARTITION ; do
                MOUNT_POINT=$(lsblk -r /dev/disk/by-id/$PARTITION | grep "sd" | cut -d " " -f 7)
                FSTYPE=$(lsblk -n -o FSTYPE /dev/disk/by-id/$PARTITION)
                
                if [ -z ${MOUNT_POINT} ]; then
                    echo "  Found Partition: $PARTITION which is not mounted"

                    if [ -z ${FSTYPE} ]; then
                        echo "      Partition $PARTITION is not formatted. Formatting now..."
                        mkfs.ntfs -f /dev/disk/by-id/$PARTITION
                    fi

                    echo "      Adding partition to MergerFS Pool"
                    echo $PARTITION >> hdd_ids.temp
                else
                    echo "  Found Partition: $PARTITION mounted at $MOUNT_POINT"

                    if [ "$MOUNT_POINT" = "/" ] || [[ "$MOUNT_POINT" = *"/boot/"* ]] || [[ "$MOUNT_POINT" = *"/root/"* ]] || [[ "$MOUNT_POINT" = *"/snap/"* ]]; then
                        echo "      Partition mounted on root: skipping"
                    else

                        echo "      Adding partition to MergerFS Pool"
                        echo $PARTITION >> hdd_ids.temp
                    fi
                fi
            done
            
            if [ -z ${PARTITIONS} ]; then
                echo "  Drive has no paritions: "
                echo "  Attempting to create them now..."

                sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/disk/by-id/$DRIVE
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
                PARTITION=$(ls /dev/disk/by-id | grep "$DRIVE-part1")

                echo "  Formatting with NTFS:"
                mkfs.ntfs -f /dev/disk/by-id/$PARTITION

                echo "Adding to MergerFS pool"
                echo $PARTITION >> hdd_ids.temp
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
            MERGERFS_DIR="nas"
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
        SMB_URL="smb://$IP_LOCAL/$MERGERFS_DIR"
        echo "Samba share can now be accessed at: $SMB_URL"
    fi

    echo "Installled MergerFS"
fi

#SabNZBd
if [ "$INSTALL_SABNZBD" == "true" ]
then
    echo "-----------------------------Installing SABNZBd-----------------------------"

	apt install software-properties-common -y
	add-apt-repository multiverse -y
	add-apt-repository universe -y
	add-apt-repository ppa:jcfp/nobetas -y
	apt-get update -y && apt-get dist-upgrade -y
	apt-get install sabnzbdplus -y
       
	echo "Creating new service file..."
	cat <<EOF | tee /etc/default/sabnzbdplus >/dev/null
	# This file is sourced by /etc/init.d/sabnzbdplus
	#
	# When SABnzbd+ is started using the init script, the
	# --daemon option is always used, and the program is
	# started under the account of $USER, as set below.
	#
	# Each setting is marked either "required" or "optional";
	# leaving any required setting unconfigured will cause
	# the service to not start.

	# [required] user or uid of account to run the program as:
	USER=$APP_UID

	# [optional] full path to the configuration file of your choice;
	#            otherwise, the default location (in $USER's home
	#            directory) is used:
	CONFIG=

	# [optional] hostname/ip and port number to listen on:
	HOST=0.0.0.0
	PORT=$SABNZBD_PORT
	
	# [optional] extra command line options, if any:
	EXTRAOPTS=
EOF

	echo "Waiting for background processes"
	service sabnzbdplus stop
	systemctl daemon-reload
	service sabnzbdplus restart
	sleep 9
	service sabnzbdplus stop
	sleep 1
	
	if grep -F "[servers]" /home/$APP_UID/.sabnzbd/sabnzbd.ini
	then
		echo "Existing Servers Found!"
	else
		echo "Creating new config in /home/$APP_UID/.sabnzbd/sabnzbd.ini"
		echo [servers] >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo [[$SERVER_HOST]] >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo name = $SERVER_HOST >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo displayname = $SERVER_HOST >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo host = $SERVER_HOST >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo port = $SERVER_PORT >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo timeout = 30 >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo username = $SERVER_USERNAME >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo "password = \"$SERVER_PASSWORD\"" >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo connections = $SERVER_CONNECTIONS >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo ssl = $SERVER_SSL >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo ssl_verify = 2 >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo ssl_ciphers = "" >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo enable = 1 >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo required = 0 >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo optional = 0 >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo retention = 0 >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo expire_date = "" >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo quota = "" >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo usage_at_start = 0 >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo priority = 0 >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo notes = "" >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo [categories] >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo [[*]] >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo "name = *" >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo order = 0 >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo pp = 3 >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo script = None >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo dir = "" >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo newzbin = "" >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo priority = 0 >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo [[movies]] >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo name = movies >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo order = 0 >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo pp = "" >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo script = Default >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo dir = "" >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo newzbin = "" >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo priority = -100 >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo [[tv]] >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo name = tv >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo order = 0 >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo pp = "" >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo script = Default >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo dir = "" >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo newzbin = "" >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo priority = -100 >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo [[audio]] >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo name = audio >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo order = 0 >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo pp = "" >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo script = Default >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo dir = "" >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo newzbin = "" >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo priority = -100 >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo [[software]] >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo name = software >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo order = 0 >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo pp = "" >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo script = Default >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo dir = "" >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo newzbin = "" >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo priority = -100 >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo [[sonarr]] >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo name = sonarr >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo order = 0 >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo pp = "" >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo script = Default >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo dir = sonarr >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo newzbin = "" >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo priority = -100 >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo [[radarr]] >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo name = radarr >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo order = 0 >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo pp = "" >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo script = Default >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo dir = radarr >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo newzbin = "" >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
		echo priority = -100 >> /home/$APP_UID/.sabnzbd/sabnzbd.ini
	fi
	
	sed -i 's/permissions = ""/permissions = 775/' /home/$APP_UID/.sabnzbd/sabnzbd.ini

	systemctl daemon-reload
	service sabnzbdplus restart
	
	echo "SABNZBd Is running: Browse to http://$IP_LOCAL:$SABNZBD_PORT for the SABNZBd GUI"
	SABNZBD_URL="http://$IP_LOCAL:$SABNZBD_PORT"
    echo "Installled SABNZBd"
fi

#Sonarr
if [ "$INSTALL_SONARR" == "true" ]
then
    echo "-----------------------------Installing Sonarr-----------------------------"
	set -euo pipefail

	app="sonarr"
	app_port=$SONARR_PORT
	app_umask="0002"
	branch="main"
	installdir="/opt"              # {Update me if needed} Install Location
	bindir="${installdir}/${app^}" # Full Path to Install Location
	datadir="/var/lib/$app/"       # {Update me if needed} AppData directory to use
	app_bin=${app^}                # Binary Name of the app
	APP_UID=$(echo "$APP_UID" | tr -d ' ')
	APP_UID=${APP_UID:-$app}
	APP_GUID=$(echo "$APP_GUID" | tr -d ' ')
	APP_GUID=${APP_GUID:-media}

	echo "This will install [${app^}] to [$bindir] and use [$datadir] for the AppData Directory"

	echo "Stoppin the App if running"
	if service --status-all | grep -Fq "$app"; then
	    systemctl stop "$app"
	    systemctl disable "$app".service
	    echo "Stopped existing $app"
	fi

	mkdir -p "$datadir"
	chown -R "$APP_UID":"$APP_GUID" "$datadir"
	chmod 775 "$datadir"
	echo "Directories created"

	echo "Downloading and installing the App"
	ARCH=$(dpkg --print-architecture)
	dlbase="https://services.sonarr.tv/v1/download/$branch/latest?version=4&os=linux"
	case "$ARCH" in
	"amd64") DLURL="${dlbase}&arch=x64" ;;
	"armhf") DLURL="${dlbase}&arch=arm" ;;
	"arm64") DLURL="${dlbase}&arch=arm64" ;;
	*)
	    echo "Arch not supported"
	    exit 1
	    ;;
	esac

	rm -f "${app^}".*.tar.gz
	wget --inet4-only --content-disposition "$DLURL"
	tar -xvzf "${app^}".*.tar.gz
	echo "Installation files downloaded and extracted"

	echo "Removing existing installation"
	rm -rf "$bindir"

	echo "Installing..."
	mv "${app^}" $installdir
	chown "$APP_UID":"$APP_GUID" -R "$bindir"
	chmod 775 "$bindir"
	rm -rf "${app^}.*.tar.gz"
	touch "$datadir"/update_required
	chown "$APP_UID":"$APP_GUID" "$datadir"/update_required
	echo "App Installed"

	echo "Removing old service file"
	rm -rf /etc/systemd/system/"$app".service

	echo "Creating service file"
	cat <<EOF | tee /etc/systemd/system/"$app".service >/dev/null
	[Unit]
	Description=${app^} Daemon
	After=syslog.target network.target
	[Service]
	User=$APP_UID
	Group=$APP_GUID
	UMask=$app_umask
	Type=simple
	ExecStart=$bindir/$app_bin -nobrowser -data=$datadir
	TimeoutStopSec=20
	KillMode=process
	Restart=on-failure
	[Install]
	WantedBy=multi-user.target
EOF

	echo "Service file created. Attempting to start the app"
	systemctl -q daemon-reload
	systemctl enable --now -q "$app"

	echo ""
	echo "Install complete: waiting for Sonarr to start"
	sleep 15
	STATUS="$(systemctl is-active "$app")"
	if [ "${STATUS}" = "active" ]; then
	
		if grep "api_key" "/home/$APP_UID/.sabnzbd/sabnzbd.ini"
		then
			SONARR_APIKEY=$(grep "ApiKey" "$datadir/config.xml" | cut -d '>' -f 2 | cut -d '<' -f 1)
			SABNZBD_APIKEY=$(grep "api_key" "/home/$APP_UID/.sabnzbd/sabnzbd.ini" | cut -d "=" -f 2 | xargs)
			
			echo "Adding Download Client:"
			curl -H "Content-Type: application/json" -H "X-Api-Key: $SONARR_APIKEY" -H "accept: application/json" -X POST "http://$IP_LOCAL:$SONARR_PORT/api/v3/downloadclient" --data '{"enable":true,"protocol":"usenet","priority":1,"removeCompletedDownloads":true,"removeFailedDownloads":true,"name":"SABnzbd","fields":[{"order":0,"name":"host","label":"Host","value":"localhost","type":"textbox","advanced":false,"privacy":"normal","isFloat":false},{"order":1,"name":"port","label":"Port","value":'"$SABNZBD_PORT"',"type":"textbox","advanced":false,"privacy":"normal","isFloat":false},{"order":2,"name":"useSsl","label":"Use SSL","helpText":"Use secure connection when connection to Sabnzbd","value":false,"type":"checkbox","advanced":false,"privacy":"normal","isFloat":false},{"order":3,"name":"urlBase","label":"URL Base","helpText":"Adds a prefix to the Sabnzbd url, such as http://[host]:[port]/[urlBase]/api","type":"textbox","advanced":true,"privacy":"normal","isFloat":false},{"order":4,"name":"apiKey","label":"API Key","value":"'"$SABNZBD_APIKEY"'","type":"textbox","advanced":false,"privacy":"apiKey","isFloat":false},{"order":5,"name":"username","label":"Username","value":"admin","type":"textbox","advanced":false,"privacy":"userName","isFloat":false},{"order":6,"name":"password","label":"Password","value":"password","type":"password","advanced":false,"privacy":"password","isFloat":false},{"order":7,"name":"tvCategory","label":"Category","helpText":"Adding a category specific to Sonarr avoids conflicts with unrelated non-Sonarr downloads. Using a category is optional, but strongly recommended.","value":"sonarr","type":"textbox","advanced":false,"privacy":"normal","isFloat":false},{"order":8,"name":"recentTvPriority","label":"Recent Priority","helpText":"Priority to use when grabbing episodes that aired within the last 14 days","value":-100,"type":"select","advanced":false,"selectOptions":[{"value":-100,"name":"Default","order":-100},{"value":-2,"name":"Paused","order":-2},{"value":-1,"name":"Low","order":-1},{"value":0,"name":"Normal","order":0},{"value":1,"name":"High","order":1},{"value":2,"name":"Force","order":2}],"privacy":"normal","isFloat":false},{"order":9,"name":"olderTvPriority","label":"Older Priority","helpText":"Priority to use when grabbing episodes that aired over 14 days ago","value":-100,"type":"select","advanced":false,"selectOptions":[{"value":-100,"name":"Default","order":-100},{"value":-2,"name":"Paused","order":-2},{"value":-1,"name":"Low","order":-1},{"value":0,"name":"Normal","order":0},{"value":1,"name":"High","order":1},{"value":2,"name":"Force","order":2}],"privacy":"normal","isFloat":false}],"implementationName":"SABnzbd","implementation":"Sabnzbd","configContract":"SabnzbdSettings","infoLink":"https://wiki.servarr.com/sonarr/supported#sabnzbd","tags":[]}'
			
			echo "Adding Indexer:"
			curl -H "Content-Type: application/json" -H "X-Api-Key: $SONARR_APIKEY" -H "accept: application/json" -X POST "http://$IP_LOCAL:$SONARR_PORT/api/v3/indexer" --data '{"enableRss":true,"enableAutomaticSearch":true,"enableInteractiveSearch":true,"supportsRss":true,"supportsSearch":true,"protocol":"usenet","priority":25,"seasonSearchMaximumSingleEpisodeAge":0,"downloadClientId":0,"name":"'"$INDEXER_NAME"'","fields":[{"order":0,"name":"baseUrl","label":"URL","value":"'"$INDEXER_URL"'","type":"textbox","advanced":false,"privacy":"normal","isFloat":false},{"order":1,"name":"apiPath","label":"API Path","helpText":"Path to the api, usually /api","value":"'"$INDEXER_API_PATH"'","type":"textbox","advanced":true,"privacy":"normal","isFloat":false},{"order":2,"name":"apiKey","label":"API Key","value":"'"$INDEXER_APIKEY"'","type":"textbox","advanced":false,"privacy":"apiKey","isFloat":false},{"order":3,"name":"categories","label":"Categories","helpText":"Drop down list, leave blank to disable standard/daily shows","value":[5030,5040,5050,5070],"type":"select","advanced":false,"selectOptionsProviderAction":"newznabCategories","privacy":"normal","isFloat":false},{"order":4,"name":"animeCategories","label":"Anime Categories","helpText":"Drop down list, leave blank to disable anime","value":[5030,5040,5070],"type":"select","advanced":false,"selectOptionsProviderAction":"newznabCategories","privacy":"normal","isFloat":false},{"order":5,"name":"animeStandardFormatSearch","label":"Anime Standard Format Search","helpText":"Also search for anime using the standard numbering","value":false,"type":"checkbox","advanced":false,"privacy":"normal","isFloat":false},{"order":6,"name":"additionalParameters","label":"Additional Parameters","helpText":"Please note if you change the category you will have to add required/restricted rules about the subgroups to avoid foreign language releases.","type":"textbox","advanced":true,"privacy":"normal","isFloat":false},{"order":7,"name":"multiLanguages","label":"Multi Languages","helpText":"What languages are normally in a multi release on this indexer?","value":[],"type":"select","advanced":true,"selectOptions":[{"value":-2,"name":"Original","order":0},{"value":26,"name":"Arabic","order":0},{"value":41,"name":"Bosnian","order":0},{"value":28,"name":"Bulgarian","order":0},{"value":38,"name":"Catalan","order":0},{"value":10,"name":"Chinese","order":0},{"value":39,"name":"Croatian","order":0},{"value":25,"name":"Czech","order":0},{"value":6,"name":"Danish","order":0},{"value":7,"name":"Dutch","order":0},{"value":1,"name":"English","order":0},{"value":42,"name":"Estonian","order":0},{"value":16,"name":"Finnish","order":0},{"value":19,"name":"Flemish","order":0},{"value":2,"name":"French","order":0},{"value":4,"name":"German","order":0},{"value":20,"name":"Greek","order":0},{"value":23,"name":"Hebrew","order":0},{"value":27,"name":"Hindi","order":0},{"value":22,"name":"Hungarian","order":0},{"value":9,"name":"Icelandic","order":0},{"value":44,"name":"Indonesian","order":0},{"value":5,"name":"Italian","order":0},{"value":8,"name":"Japanese","order":0},{"value":21,"name":"Korean","order":0},{"value":36,"name":"Latvian","order":0},{"value":24,"name":"Lithuanian","order":0},{"value":45,"name":"Macedonian","order":0},{"value":29,"name":"Malayalam","order":0},{"value":15,"name":"Norwegian","order":0},{"value":37,"name":"Persian","order":0},{"value":12,"name":"Polish","order":0},{"value":18,"name":"Portuguese","order":0},{"value":33,"name":"Portuguese (Brazil)","order":0},{"value":35,"name":"Romanian","order":0},{"value":11,"name":"Russian","order":0},{"value":40,"name":"Serbian","order":0},{"value":31,"name":"Slovak","order":0},{"value":46,"name":"Slovenian","order":0},{"value":3,"name":"Spanish","order":0},{"value":34,"name":"Spanish (Latino)","order":0},{"value":14,"name":"Swedish","order":0},{"value":43,"name":"Tamil","order":0},{"value":32,"name":"Thai","order":0},{"value":17,"name":"Turkish","order":0},{"value":30,"name":"Ukrainian","order":0},{"value":13,"name":"Vietnamese","order":0}],"privacy":"normal","isFloat":false}],"implementationName":"Newznab","implementation":"Newznab","configContract":"NewznabSettings","infoLink":"https://wiki.servarr.com/sonarr/supported#newznab","tags":[]}'
		
			echo "Adding Root Folders:"
			for FOLDER in ${SONARR_ROOT_FOLDER[@]}; do
				mkdir -p $FOLDER
				chown -R "$APP_UID":"$APP_GUID" $FOLDER
				chmod 775 "$FOLDER"
				
		  		curl -H "Content-Type: application/json" -H "X-Api-Key: $SONARR_APIKEY" -H "accept: application/json" -X POST "http://$IP_LOCAL:$SONARR_PORT/api/v3/rootfolder" --data '{"path":"'"$FOLDER"'","accessible":true,"freeSpace":0,"unmappedFolders":[]}'
			done
			
			echo "Setting more sensible quality values"
			QUALITIES=('{"quality":{"id":0,"name":"Unknown","source":"unknown","resolution":0},"title":"Unknown","weight":1,"minSize":1,"maxSize":50,"preferredSize":20,"id":1 }' '{"quality":{"id":1,"name":"SDTV","source":"television","resolution":480},"title":"SDTV","weight":2,"minSize":2,"maxSize":50,"preferredSize":20,"id":2 }' '{"quality":{"id":12,"name":"WEBRip-480p","source":"webRip","resolution":480},"title":"WEBRip-480p","weight":3,"minSize":2,"maxSize":50,"preferredSize":20,"id":3 }' '{"quality":{"id":8,"name":"WEBDL-480p","source":"web","resolution":480},"title":"WEBDL-480p","weight":3,"minSize":2,"maxSize":50,"preferredSize":20,"id":4 }' '{"quality":{"id":2,"name":"DVD","source":"dvd","resolution":480},"title":"DVD","weight":4,"minSize":2,"maxSize":50,"preferredSize":20,"id":5 }' '{"quality":{"id":13,"name":"Bluray-480p","source":"bluray","resolution":480},"title":"Bluray-480p","weight":5,"minSize":2,"maxSize":50,"preferredSize":20,"id":6 }' '{"quality":{"id":4,"name":"HDTV-720p","source":"television","resolution":720},"title":"HDTV-720p","weight":6,"minSize":3,"maxSize":50,"preferredSize":20,"id":7 }' '{"quality":{"id":9,"name":"HDTV-1080p","source":"television","resolution":1080},"title":"HDTV-1080p","weight":7,"minSize":4,"maxSize":50,"preferredSize":20,"id":8 }' '{"quality":{"id":10,"name":"Raw-HD","source":"televisionRaw","resolution":1080},"title":"Raw-HD","weight":8,"minSize":4,"maxSize":50,"preferredSize":20,"id":9 }' '{"quality":{"id":14,"name":"WEBRip-720p","source":"webRip","resolution":720},"title":"WEBRip-720p","weight":9,"minSize":3,"maxSize":50,"preferredSize":20,"id":10 }' '{"quality":{"id":5,"name":"WEBDL-720p","source":"web","resolution":720},"title":"WEBDL-720p","weight":9,"minSize":3,"maxSize":50,"preferredSize":20,"id":11 }' '{"quality":{"id":6,"name":"Bluray-720p","source":"bluray","resolution":720},"title":"Bluray-720p","weight":10,"minSize":4,"maxSize":50,"preferredSize":20,"id":12 }' '{"quality":{"id":15,"name":"WEBRip-1080p","source":"webRip","resolution":1080},"title":"WEBRip-1080p","weight":11,"minSize":4,"maxSize":50,"preferredSize":20,"id":13 }' '{"quality":{"id":3,"name":"WEBDL-1080p","source":"web","resolution":1080},"title":"WEBDL-1080p","weight":11,"minSize":4,"maxSize":50,"preferredSize":20,"id":14 }' '{"quality":{"id":7,"name":"Bluray-1080p","source":"bluray","resolution":1080},"title":"Bluray-1080p","weight":12,"minSize":4,"maxSize":50,"preferredSize":20,"id":15 }' '{"quality":{"id":20,"name":"Bluray-1080p Remux","source":"blurayRaw","resolution":1080},"title":"Bluray-1080p Remux","weight":13,"minSize":0,"maxSize":50,"preferredSize":20,"id":16 }' '{"quality":{"id":16,"name":"HDTV-2160p","source":"television","resolution":2160},"title":"HDTV-2160p","weight":14,"minSize":35,"maxSize":50,"preferredSize":20,"id":17 }' '{"quality":{"id":17,"name":"WEBRip-2160p","source":"webRip","resolution":2160},"title":"WEBRip-2160p","weight":15,"minSize":35,"maxSize":50,"preferredSize":20,"id":18 }' '{"quality":{"id":18,"name":"WEBDL-2160p","source":"web","resolution":2160},"title":"WEBDL-2160p","weight":15,"minSize":35,"maxSize":50,"preferredSize":20,"id":19 }' '{"quality":{"id":19,"name":"Bluray-2160p","source":"bluray","resolution":2160},"title":"Bluray-2160p","weight":16,"minSize":35,"maxSize":50,"preferredSize":20,"id":20 }' '{"quality":{"id":21,"name":"Bluray-2160p Remux","source":"blurayRaw","resolution":2160},"title":"Bluray-2160p Remux","weight":17,"minSize":35,"maxSize":50,"preferredSize":20,"id":21}')

			for ((i = 0; i < ${#QUALITIES[@]}; i++))
			do
			    	curl -H "Content-Type: application/json" -H "X-Api-Key: $SONARR_APIKEY" -H "accept: application/json" -X PUT "http://$IP_LOCAL:$SONARR_PORT/api/v3/qualitydefinition" --data "${QUALITIES[$i]}"
			done
		fi
		
		echo "Setting Permissions"
		curl -H "Content-Type: application/json" -H "X-Api-Key: e2a8d11872a6488c885dce8ee23f9fe2" -H "accept: application/json" -X PUT "http://localhost:8989/api/v3/config/mediamanagement"  --data '{"autoUnmonitorPreviouslyDownloadedEpisodes":false,"recycleBin":"","recycleBinCleanupDays":7,"downloadPropersAndRepacks":"preferAndUpgrade","createEmptySeriesFolders":false,"deleteEmptyFolders":true,"fileDate":"none","rescanAfterRefresh":"always","setPermissionsLinux":true,"chmodFolder":"755","chownGroup":"'"$APP_GUID"'","episodeTitleRequired":"always","skipFreeSpaceCheckWhenImporting":false,"minimumFreeSpaceWhenImporting":100,"copyUsingHardlinks":true,"useScriptImport":false,"scriptImportPath":"","importExtraFiles":true,"extraFileExtensions":"srt","enableMediaInfo":true,"id":1}'
	   	
	   	echo "Browse to http://$IP_LOCAL:$app_port for the ${app^} GUI"
	   	SONARR_URL="http://$IP_LOCAL:$app_port"
	else
	    echo "${app^} failed to start"
	fi

    echo "Installled Sonarr"
fi

#Radarr
if [ "$INSTALL_RADARR" == "true" ]
then
    echo "-----------------------------Installing Radarr-----------------------------"
	set -euo pipefail

	app="radarr"
	app_port=$RADARR_PORT          # Default App Port; Modify config.xml after install if needed
	app_umask="0002"
	branch="master"           # {Update me if needed} branch to install
	installdir="/opt"              # {Update me if needed} Install Location
	bindir="${installdir}/${app^}" # Full Path to Install Location
	datadir="/var/lib/$app/"       # {Update me if needed} AppData directory to use
	app_bin=${app^}                # Binary Name of the app

	echo "This will install [${app^}] to [$bindir] and use [$datadir] for the AppData Directory"

	echo "Stoping the App if running"
	if service --status-all | grep -Fq "$app"; then
	    systemctl stop "$app"
	    systemctl disable "$app".service
	    echo "Stopped existing $app."
	fi

	echo "Create Appdata Directories"
	mkdir -p "$datadir"
	chown -R "$APP_UID":"$APP_GUID" "$datadir"
	chmod 775 "$datadir"
	echo -e "Directories $bindir and $datadir created!"

	echo "Download and install the App"
	ARCH=$(dpkg --print-architecture)
	dlbase="https://$app.servarr.com/v1/update/$branch/updatefile?os=linux&runtime=netcore"
	case "$ARCH" in
	"amd64") DLURL="${dlbase}&arch=x64" ;;
	"armhf") DLURL="${dlbase}&arch=arm" ;;
	"arm64") DLURL="${dlbase}&arch=arm64" ;;
	*)
	    echo -e "Your arch is not supported!"
	    echo -e "Exiting installer script!"
	    exit 1
	    ;;
	esac

	echo -e "Removing tarballs..."
	sleep 3
	rm -f "${app^}".*.tar.gz
	echo -e "Downloading required files..."
	wget --inet4-only --content-disposition "$DLURL"
	tar -xvzf "${app^}".*.tar.gz >/dev/null 2>&1
	echo -e "Installation files downloaded and extracted!"

	echo -e "Removing existing installation files from $bindir]"
	rm -rf "$bindir"
	sleep 2
	echo -e "Attempting to install ${app^}..."
	sleep 2
	mv "${app^}" $installdir
	chown "$APP_UID":"$APP_GUID" -R "$bindir"
	chmod 775 "$bindir"
	touch "$datadir"/update_required
	chown "$APP_UID":"$APP_GUID" "$datadir"/update_required
	echo -e "Successfully installed ${app^}!!"
	rm -rf "${app^}.*.tar.gz"
	sleep 2

	echo "Removing old service file..."
	rm -rf /etc/systemd/system/"$app".service
	sleep 2

	echo "Creating new service file..."
	cat <<EOF | tee /etc/systemd/system/"$app".service >/dev/null
	[Unit]
	Description=${app^} Daemon
	After=syslog.target network.target
	[Service]
	User=$APP_UID
	Group=$APP_GUID
	UMask=$app_umask
	Type=simple
	ExecStart=$bindir/$app_bin -nobrowser -data=$datadir
	TimeoutStopSec=20
	KillMode=process
	Restart=on-failure
	[Install]
	WantedBy=multi-user.target
EOF
	sleep 2

	echo -e "${app^} is attempting to start, this may take a few seconds..."
	systemctl -q daemon-reload
	systemctl enable --now -q "$app"
	sleep 3

	echo "Checking if the service is up and running..."
	while ! systemctl is-active --quiet "$app"; do
	    sleep 1
	done
	echo -e "${app^} installation and service start up is complete!"

	echo -e "Attempting to check for a connection at http://$IP_LOCAL:$app_port..."
	sleep 15
	STATUS="$(systemctl is-active "$app")"
	if [ "${STATUS}" = "active" ]; then
		if grep "api_key" "/home/$APP_UID/.sabnzbd/sabnzbd.ini"
		then
			RADARR_APIKEY=$(grep "ApiKey" "$datadir/config.xml" | cut -d '>' -f 2 | cut -d '<' -f 1)
			SABNZBD_APIKEY=$(grep "api_key" "/home/$APP_UID/.sabnzbd/sabnzbd.ini" | cut -d "=" -f 2 | xargs)
			
			echo "Adding Download Client:"
			curl -H "Content-Type: application/json" -H "X-Api-Key: $RADARR_APIKEY" -H "accept: application/json" -X POST "http://$IP_LOCAL:$RADARR_PORT/api/v3/downloadclient" --data '{"enable":true,"protocol":"usenet","priority":1,"removeCompletedDownloads":true,"removeFailedDownloads":true,"name":"SABnzbd","fields":[{"order":0,"name":"host","label":"Host","value":"localhost","type":"textbox","advanced":false,"privacy":"normal","isFloat":false},{"order":1,"name":"port","label":"Port","value":'"$SABNZBD_PORT"',"type":"textbox","advanced":false,"privacy":"normal","isFloat":false},{"order":2,"name":"useSsl","label":"Use SSL","helpText":"Use secure connection when connection to Sabnzbd","value":false,"type":"checkbox","advanced":false,"privacy":"normal","isFloat":false},{"order":3,"name":"urlBase","label":"URL Base","helpText":"Adds a prefix to the Sabnzbd url, such as http://[host]:[port]/[urlBase]/api","type":"textbox","advanced":true,"privacy":"normal","isFloat":false},{"order":4,"name":"apiKey","label":"API Key","value":"'"$SABNZBD_APIKEY"'","type":"textbox","advanced":false,"privacy":"apiKey","isFloat":false},{"order":5,"name":"username","label":"Username","value":"admin","type":"textbox","advanced":false,"privacy":"userName","isFloat":false},{"order":6,"name":"password","label":"Password","value":"password","type":"password","advanced":false,"privacy":"password","isFloat":false},{"order":7,"name":"tvCategory","label":"Category","helpText":"Adding a category specific to Sonarr avoids conflicts with unrelated non-Sonarr downloads. Using a category is optional, but strongly recommended.","value":"sonarr","type":"textbox","advanced":false,"privacy":"normal","isFloat":false},{"order":8,"name":"recentTvPriority","label":"Recent Priority","helpText":"Priority to use when grabbing episodes that aired within the last 14 days","value":-100,"type":"select","advanced":false,"selectOptions":[{"value":-100,"name":"Default","order":-100},{"value":-2,"name":"Paused","order":-2},{"value":-1,"name":"Low","order":-1},{"value":0,"name":"Normal","order":0},{"value":1,"name":"High","order":1},{"value":2,"name":"Force","order":2}],"privacy":"normal","isFloat":false},{"order":9,"name":"olderTvPriority","label":"Older Priority","helpText":"Priority to use when grabbing episodes that aired over 14 days ago","value":-100,"type":"select","advanced":false,"selectOptions":[{"value":-100,"name":"Default","order":-100},{"value":-2,"name":"Paused","order":-2},{"value":-1,"name":"Low","order":-1},{"value":0,"name":"Normal","order":0},{"value":1,"name":"High","order":1},{"value":2,"name":"Force","order":2}],"privacy":"normal","isFloat":false}],"implementationName":"SABnzbd","implementation":"Sabnzbd","configContract":"SabnzbdSettings","infoLink":"https://wiki.servarr.com/sonarr/supported#sabnzbd","tags":[]}'
			
			echo "Adding Indexer:"
			curl -H "Content-Type: application/json" -H "X-Api-Key: $RADARR_APIKEY" -H "accept: application/json" -X POST "http://$IP_LOCAL:$RADARR_PORT/api/v3/indexer" --data '{"enableRss":true,"enableAutomaticSearch":true,"enableInteractiveSearch":true,"supportsRss":true,"supportsSearch":true,"protocol":"usenet","priority":25,"seasonSearchMaximumSingleEpisodeAge":0,"downloadClientId":0,"name":"'"$INDEXER_NAME"'","fields":[{"order":0,"name":"baseUrl","label":"URL","value":"'"$INDEXER_URL"'","type":"textbox","advanced":false,"privacy":"normal","isFloat":false},{"order":1,"name":"apiPath","label":"API Path","helpText":"Path to the api, usually /api","value":"'"$INDEXER_API_PATH"'","type":"textbox","advanced":true,"privacy":"normal","isFloat":false},{"order":2,"name":"apiKey","label":"API Key","value":"'"$INDEXER_APIKEY"'","type":"textbox","advanced":false,"privacy":"apiKey","isFloat":false},{"order":3,"name":"categories","label":"Categories","helpText":"Drop down list, leave blank to disable standard/daily shows","value":[2030,2040,2045,2050],"type":"select","advanced":false,"selectOptionsProviderAction":"newznabCategories","privacy":"normal","isFloat":false},{"order":4,"name":"animeCategories","label":"Anime Categories","helpText":"Drop down list, leave blank to disable anime","value":[5030,5040,5070],"type":"select","advanced":false,"selectOptionsProviderAction":"newznabCategories","privacy":"normal","isFloat":false},{"order":5,"name":"animeStandardFormatSearch","label":"Anime Standard Format Search","helpText":"Also search for anime using the standard numbering","value":false,"type":"checkbox","advanced":false,"privacy":"normal","isFloat":false},{"order":6,"name":"additionalParameters","label":"Additional Parameters","helpText":"Please note if you change the category you will have to add required/restricted rules about the subgroups to avoid foreign language releases.","type":"textbox","advanced":true,"privacy":"normal","isFloat":false},{"order":7,"name":"multiLanguages","label":"Multi Languages","helpText":"What languages are normally in a multi release on this indexer?","value":[],"type":"select","advanced":true,"selectOptions":[{"value":-2,"name":"Original","order":0},{"value":26,"name":"Arabic","order":0},{"value":41,"name":"Bosnian","order":0},{"value":28,"name":"Bulgarian","order":0},{"value":38,"name":"Catalan","order":0},{"value":10,"name":"Chinese","order":0},{"value":39,"name":"Croatian","order":0},{"value":25,"name":"Czech","order":0},{"value":6,"name":"Danish","order":0},{"value":7,"name":"Dutch","order":0},{"value":1,"name":"English","order":0},{"value":42,"name":"Estonian","order":0},{"value":16,"name":"Finnish","order":0},{"value":19,"name":"Flemish","order":0},{"value":2,"name":"French","order":0},{"value":4,"name":"German","order":0},{"value":20,"name":"Greek","order":0},{"value":23,"name":"Hebrew","order":0},{"value":27,"name":"Hindi","order":0},{"value":22,"name":"Hungarian","order":0},{"value":9,"name":"Icelandic","order":0},{"value":44,"name":"Indonesian","order":0},{"value":5,"name":"Italian","order":0},{"value":8,"name":"Japanese","order":0},{"value":21,"name":"Korean","order":0},{"value":36,"name":"Latvian","order":0},{"value":24,"name":"Lithuanian","order":0},{"value":45,"name":"Macedonian","order":0},{"value":29,"name":"Malayalam","order":0},{"value":15,"name":"Norwegian","order":0},{"value":37,"name":"Persian","order":0},{"value":12,"name":"Polish","order":0},{"value":18,"name":"Portuguese","order":0},{"value":33,"name":"Portuguese (Brazil)","order":0},{"value":35,"name":"Romanian","order":0},{"value":11,"name":"Russian","order":0},{"value":40,"name":"Serbian","order":0},{"value":31,"name":"Slovak","order":0},{"value":46,"name":"Slovenian","order":0},{"value":3,"name":"Spanish","order":0},{"value":34,"name":"Spanish (Latino)","order":0},{"value":14,"name":"Swedish","order":0},{"value":43,"name":"Tamil","order":0},{"value":32,"name":"Thai","order":0},{"value":17,"name":"Turkish","order":0},{"value":30,"name":"Ukrainian","order":0},{"value":13,"name":"Vietnamese","order":0}],"privacy":"normal","isFloat":false}],"implementationName":"Newznab","implementation":"Newznab","configContract":"NewznabSettings","infoLink":"https://wiki.servarr.com/sonarr/supported#newznab","tags":[]}'
		
			echo "Adding Root Folders:"RADARR_PORT
			for FOLDER in ${RADARR_ROOT_FOLDER[@]}; do
				mkdir -p $FOLDER
				chown -R "$APP_UID":"$APP_GUID" $FOLDER
				chmod 775 "$FOLDER"
				
		  		curl -H "Content-Type: application/json" -H "X-Api-Key: $RADARR_APIKEY" -H "accept: application/json" -X POST "http://$IP_LOCAL:$RADARR_PORT/api/v3/rootfolder" --data '{"path":"'"$FOLDER"'","accessible":true,"freeSpace":0,"unmappedFolders":[]}'
			done
			
			echo "Setting more sensible quality values"
			QUALITIES=('{"quality":{"id":0,"name":"Unknown","source":"unknown","resolution":0,"modifier":"none"},"title":"Unknown","weight":1,"minSize":0,"maxSize":50,"preferredSize":20,"id":1}' '{"quality":{"id":24,"name":"WORKPRINT","source":"workprint","resolution":0,"modifier":"none"},"title":"WORKPRINT","weight":2,"minSize":0,"maxSize":50,"preferredSize":20,"id":2}' '{"quality":{"id":25,"name":"CAM","source":"cam","resolution":0,"modifier":"none"},"title":"CAM","weight":3,"minSize":0,"maxSize":50,"preferredSize":20,"id":3}' '{"quality":{"id":26,"name":"TELESYNC","source":"telesync","resolution":0,"modifier":"none"},"title":"TELESYNC","weight":4,"minSize":0,"maxSize":50,"preferredSize":20,"id":4}' '{"quality":{"id":27,"name":"TELECINE","source":"telecine","resolution":0,"modifier":"none"},"title":"TELECINE","weight":5,"minSize":0,"maxSize":50,"preferredSize":20,"id":5}' '{"quality":{"id":29,"name":"REGIONAL","source":"dvd","resolution":480,"modifier":"regional"},"title":"REGIONAL","weight":6,"minSize":0,"maxSize":50,"preferredSize":20,"id":6}' '{"quality":{"id":28,"name":"DVDSCR","source":"dvd","resolution":480,"modifier":"screener"},"title":"DVDSCR","weight":7,"minSize":0,"maxSize":50,"preferredSize":20,"id":7}' '{"quality":{"id":1,"name":"SDTV","source":"tv","resolution":480,"modifier":"none"},"title":"SDTV","weight":8,"minSize":0,"maxSize":50,"preferredSize":20,"id":8}' '{"quality":{"id":2,"name":"DVD","source":"dvd","resolution":0,"modifier":"none"},"title":"DVD","weight":9,"minSize":0,"maxSize":50,"preferredSize":20,"id":9}' '{"quality":{"id":23,"name":"DVD-R","source":"dvd","resolution":480,"modifier":"remux"},"title":"DVD-R","weight":10,"minSize":0,"maxSize":50,"preferredSize":20,"id":10}' '{"quality":{"id":8,"name":"WEBDL-480p","source":"webdl","resolution":480,"modifier":"none"},"title":"WEBDL-480p","weight":11,"minSize":0,"maxSize":50,"preferredSize":20,"id":11}' '{"quality":{"id":12,"name":"WEBRip-480p","source":"webrip","resolution":480,"modifier":"none"},"title":"WEBRip-480p","weight":11,"minSize":0,"maxSize":50,"preferredSize":20,"id":12}' '{"quality":{"id":20,"name":"Bluray-480p","source":"bluray","resolution":480,"modifier":"none"},"title":"Bluray-480p","weight":12,"minSize":0,"maxSize":50,"preferredSize":20,"id":13}' '{"quality":{"id":21,"name":"Bluray-576p","source":"bluray","resolution":576,"modifier":"none"},"title":"Bluray-576p","weight":13,"minSize":0,"maxSize":50,"preferredSize":20,"id":14}' '{"quality":{"id":4,"name":"HDTV-720p","source":"tv","resolution":720,"modifier":"none"},"title":"HDTV-720p","weight":14,"minSize":0,"maxSize":50,"preferredSize":20,"id":15}' '{"quality":{"id":5,"name":"WEBDL-720p","source":"webdl","resolution":720,"modifier":"none"},"title":"WEBDL-720p","weight":15,"minSize":0,"maxSize":50,"preferredSize":20,"id":16}' '{"quality":{"id":14,"name":"WEBRip-720p","source":"webrip","resolution":720,"modifier":"none"},"title":"WEBRip-720p","weight":15,"minSize":0,"maxSize":50,"preferredSize":20,"id":17}' '{"quality":{"id":6,"name":"Bluray-720p","source":"bluray","resolution":720,"modifier":"none"},"title":"Bluray-720p","weight":16,"minSize":0,"maxSize":50,"preferredSize":20,"id":18}' '{"quality":{"id":9,"name":"HDTV-1080p","source":"tv","resolution":1080,"modifier":"none"},"title":"HDTV-1080p","weight":17,"minSize":0,"maxSize":50,"preferredSize":20,"id":19}' '{"quality":{"id":3,"name":"WEBDL-1080p","source":"webdl","resolution":1080,"modifier":"none"},"title":"WEBDL-1080p","weight":18,"minSize":0,"maxSize":50,"preferredSize":20,"id":20}' '{"quality":{"id":15,"name":"WEBRip-1080p","source":"webrip","resolution":1080,"modifier":"none"},"title":"WEBRip-1080p","weight":18,"minSize":0,"maxSize":50,"preferredSize":20,"id":21}' '{"quality":{"id":7,"name":"Bluray-1080p","source":"bluray","resolution":1080,"modifier":"none"},"title":"Bluray-1080p","weight":19,"minSize":0,"maxSize":50,"preferredSize":20,"id":22}' '{"quality":{"id":30,"name":"Remux-1080p","source":"bluray","resolution":1080,"modifier":"remux"},"title":"Remux-1080p","weight":20,"minSize":0,"maxSize":50,"preferredSize":20,"id":23}' '{"quality":{"id":16,"name":"HDTV-2160p","source":"tv","resolution":2160,"modifier":"none"},"title":"HDTV-2160p","weight":21,"minSize":0,"maxSize":80,"preferredSize":20,"id":24}' '{"quality":{"id":18,"name":"WEBDL-2160p","source":"webdl","resolution":2160,"modifier":"none"},"title":"WEBDL-2160p","weight":22,"minSize":0,"maxSize":80,"preferredSize":20,"id":25}' '{"quality":{"id":17,"name":"WEBRip-2160p","source":"webrip","resolution":2160,"modifier":"none"},"title":"WEBRip-2160p","weight":22,"minSize":0,"maxSize":80,"preferredSize":20,"id":26}' '{"quality":{"id":19,"name":"Bluray-2160p","source":"bluray","resolution":2160,"modifier":"none"},"title":"Bluray-2160p","weight":23,"minSize":0,"maxSize":80,"preferredSize":20,"id":27}' '{"quality":{"id":31,"name":"Remux-2160p","source":"bluray","resolution":2160,"modifier":"remux"},"title":"Remux-2160p","weight":24,"minSize":0,"maxSize":80,"preferredSize":20,"id":28}' '{"quality":{"id":22,"name":"BR-DISK","source":"bluray","resolution":1080,"modifier":"brdisk"},"title":"BR-DISK","weight":25,"minSize":0,"maxSize":80,"preferredSize":20,"id":29}' '{"quality":{"id":10,"name":"Raw-HD","source":"tv","resolution":1080,"modifier":"rawhd"},"title":"Raw-HD","weight":26,"minSize":0,"maxSize":80,"preferredSize":20,"id":30}')

			for ((i = 0; i < ${#QUALITIES[@]}; i++))
			do
			    	curl -H "Content-Type: application/json" -H "X-Api-Key: $RADARR_APIKEY" -H "accept: application/json" -X PUT "http://$IP_LOCAL:$RADARR_PORT/api/v3/qualitydefinition" --data "${QUALITIES[$i]}"
			done
			
			echo "Setting permissions settings"
			curl -H "Content-Type: application/json" -H "X-Api-Key: $RADARR_APIKEY" -H "accept: application/json" -X PUT "http://$IP_LOCAL:$RADARR_PORT/api/v3/config/mediamanagement"  --data '{"autoUnmonitorPreviouslyDownloadedMovies":false,"recycleBin":"","recycleBinCleanupDays":7,"downloadPropersAndRepacks":"preferAndUpgrade","createEmptyMovieFolders":false,"deleteEmptyFolders":true,"fileDate":"none","rescanAfterRefresh":"always","autoRenameFolders":true,"pathsDefaultStatic":false,"setPermissionsLinux":true,"chmodFolder":"755","chownGroup":"'"$APP_GUID"'","skipFreeSpaceCheckWhenImporting":false,"minimumFreeSpaceWhenImporting":100,"copyUsingHardlinks":true,"useScriptImport":false,"scriptImportPath":"","importExtraFiles":true,"extraFileExtensions":"srt","enableMediaInfo":true,"id":1}'
		fi
	    	echo "Browse to http://$IP_LOCAL:$app_port for the ${app^} GUI"
	    	RADARR_URL="http://$IP_LOCAL:$app_port"
	else
	   	echo "${app^} failed to start"
	fi
    echo "Installled Radarr"
fi

#Plex Media Server
if [ "$INSTALL_PLEX" == "true" ]
then
    echo "-----------------------------Installing Plex-----------------------------"

	curl https://downloads.plex.tv/plex-keys/PlexSign.key | apt-key add -
	echo deb https://downloads.plex.tv/repo/deb public main | tee /etc/apt/sources.list.d/plexmediaserver.list
	apt update
	apt install plexmediaserver -y
	echo "Waiting for Plex to start:"
	
	sleep 10
	echo "Setting Plex permissions:"
	usermod -a -G $APP_GUID plex
	systemctl restart plexmediaserver
	
	PLEX_URL="http://$IP_LOCAL:32400"
    echo "Installled Plex"
fi

#Windows Shares
if [ "$INSTALL_SHARES" == "true" ]
then
    echo "-----------------------------Installing Windows Shares-----------------------------"

    apt install cifs-utils -y

    for SHARE in ${WIN_SHARES[@]}; do
        mkdir -p /media/$SHARE

        if grep -F "/media/$SHARE" /etc/fstab
        then
            echo "Found existing share: $SHARE"
            continue
        fi

        echo -e "//$WIN_HOST/$SHARE  /media/$SHARE  cifs username=$WIN_USER,password=$WIN_PASS,iocharset=utf8  0  0" >> /etc/fstab
    done

    mount -a
    echo "Installled Windows Shares"
fi

#Shell Extensions
if [ "$INSTALL_SHELL_EXTENSIONS" == "true" ]
then
    echo "-----------------------------Installing Shell Extensions-----------------------------"
    apt install gnome-menus dbus-x11 -y

    for i in "${EXTENSION_LIST[@]}"
    do
        EXTENSION_ID=$(curl -s $i | grep -oP 'data-uuid="\K[^"]+')
        VERSION_TAG=$(curl -Lfs "https://extensions.gnome.org/extension-query/?search=$EXTENSION_ID" | jq '.extensions | map(select(.uuid=="'$EXTENSION_ID'")) | .[0].shell_version_map | map(.pk) | max')

        echo "Installing: $EXTENSION_ID"

        wget --inet4-only -O ${EXTENSION_ID}.zip "https://extensions.gnome.org/download-extension/${EXTENSION_ID}.shell-extension.zip?version_tag=$VERSION_TAG"
        sudo -u $SUDO_USER -H -s gnome-extensions install --force ${EXTENSION_ID}.zip
        sudo -u $SUDO_USER -H -s gnome-extensions enable ${EXTENSION_ID}
        rm ${EXTENSION_ID}.zip
    done

    if [ "$EXTENSION_SETTINGS" == "default" ]
    then
        echo "No extension settings configured"
    else
        echo "Loading extension settings"
        echo $EXTENSION_SETTINGS | base64 -d | gunzip >> /home/$SUDO_USER/extension_settings.conf

        sudo  -i -u $SUDO_USER bash <<-EOF
        cat /home/$SUDO_USER/extension_settings.conf | dconf load /org/gnome/
EOF

        rm /home/$SUDO_USER/extension_settings.conf
    fi

    echo "Installled Shell Extensions"
fi

echo "----------------------------------------------------------------------------------"
echo " "
echo "Completed Installing Items"
echo " "
echo "Access Details:"
if [ "$INSTALL_HASS" == "true" ]
then
echo "Home Assistant: http://$LOCAL_IP:8123"
fi
if [ "$INSTALL_LIBRE_SPEEDTEST" == "true" ]
then
echo "Libre Speed Test: http://$LOCAL_IP:11000"
fi
if [ "$INSTALL_PIHOLE" == "true" ]
then
echo "PiHole: http://$LOCAL_IP/admin"
fi
if [ "$INSTALL_SABNZBD" == "true" ]
then
echo "SABNZBd: $SABNZBD_URL"
fi
if [ "$INSTALL_SONARR" == "true" ]
then
echo "Sonarr: $SONARR_URL"
fi
if [ "$INSTALL_RADARR" == "true" ]
then
echo "Radarr: $RADARR_URL"
fi
if [ "$INSTALL_PLEX" == "true" ]
then
echo "Plex: $PLEX_URL"
fi
echo ""
if [ "$INSTALL_SHARES" == "true" ]
then
    echo "SMB: $SMB_URL"
    echo "User: $REMOTE_USER"
    echo "Password": $REMOTE_PASS
fi

echo " "
echo "Next Steps"

if [ "$INSTALL_RADARR" == "true" ] || [ "$INSTALL_SONARR" == "true" ]
then
    echo "Sonarr/Radarr:"
    echo "	1. You will need to log into Radarr/Sonarr (if installed) and set a user, password, and auth req to 'not required for local'"
    echo "	2. You will need to import existing media into Radarr/Sonarr"
    echo "	3. Start Plex from the apps menu and setup the server (You will need to manually add the libraries)"
    echo "  4. Mount the Shared folder on your windows/linux machine."
    echo " "
fi

if [ "$INSTALL_PIHOLE" == "true" ]
then
	echo "Pihole:"
	echo "  1. Change default password (Password): sudo pihole -a -p"
	echo "  2. You will now need to log into your router and configure the DHCP settings to use $LOCAL_IP as the primary DNS server"
    echo " "
fi

if [ "$INSTALL_ZEROTIER_ROUTER" == "true" ]
then
	echo "Zerotier Route - Optional Zerotier Config:"
	echo "  Joining Two Physical Networks (This allows devices without Zerotier to communicate with each other across networks):"
	echo "  You will need a Zerotier router setup on both ends of the network (IE. You will need to run this script on devices on either end)"
	echo "  If you would like local devices to be able to access a remote Zerotier device's network you will need to add a static route to your router with the following settings:"
	echo "	    Network Destination: The destination network IP Range (Ex 192.168.0.0 for devices in range 192.168.0.1 to 192.168.0.254)"
	echo "	    Default Gateway: $LOCAL_IP"
	echo "	    Network Mask: $NET_MASK"
	echo "	    Interface: LAN"
	echo "	    Description: Zerotier Route"
    echo " "
fi

if [ "$INSTALL_SHELL_EXTENSIONS" == "true" ]
then
	echo "Shell Extensions: "
    echo "  You will need to reboot for changes to take effect"
fi