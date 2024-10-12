#!/bin/bash

#You will need to run the following to make the script executable
#sudo chmod +x Install_pihole.sh
#sudo ./Install_pihole.sh

#Settings
INSTALL_PIHOLE=true							#Install Pihole - set to false to skip
INSTALL_ZEROTIER=true						#Install Zerotier - set to false to skip
INSTALL_HASS=true							#Install Home Assistant - set to false to skip

#Variables
ZT_TOKEN= 	                                #Your Zerotier API Token - Get this from https://my.zerotier.com/account -> "new token"
NWID= 						                #Your Zerotier Network ID - Get this from https://my.zerotier.com/
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

apt install curl nano build-essential openssh-server git python3-pip pipx python3-dev htop net-tools cifs-utils -y

#Zerotier Router Setup
if [ "$INSTALL_ZEROTIER" == "true" ]
then
	if [ "$PHY_IFACE" == "default" ]
	then
		PHY_IFACE=$(ifconfig | grep -E 'eth|enp' | cut -d ":" -f 1 | cut -d " " -f 1 | xargs)
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

if [ "$INSTALL_ZEROTIER" == "true" ]
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
