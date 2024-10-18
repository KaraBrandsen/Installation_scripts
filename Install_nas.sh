#!/bin/bash

#You will need to run the following to make the script executable
#sudo chmod +x Install_nas.sh
#sudo ./Install_nas.sh

INSTALL_ZEROTIER=true					#Install Zerotier - set to false to skip
INSTALL_SHARES=true                     #Install MergerFS and SAMBA - set to false to skip
INSTALL_SABNZBD=true					#Install SABNZBD - set to false to skip
INSTALL_SONARR=true						#Install Sonarr - set to false to skip
INSTALL_RADARR=true						#Install Radarr - set to false to skip
INSTALL_PLEX=true						#Install Plex - set to false to skip

source "secrets.sh"

#Variables
	#Zerotier
		ZT_TOKEN=$ZT_TOKEN	 	                                #Your Zerotier API Token - Get this from https://my.zerotier.com/account -> "new token"
        NWID=$NWID              								#Your Zerotier Network ID - Get this from https://my.zerotier.com/
    
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
		SONARR_ROOT_FOLDER=("/opt/series1" "/opt/series2")		#Folders to where you want to store series (Can already conatin a few)
		INDEXER_NAME=$INDEXER_NAME			           			#Indexer name
		INDEXER_URL=$INDEXER_URL		                    	#Indexer host name
		INDEXER_API_PATH=$INDEXER_API_PATH						#Indexer path to the api
		INDEXER_APIKEY=$INDEXER_APIKEY	                        #Indexer api key
		
	#Radarr
		RADARR_PORT=7878										#Port Radarr should be served on
		RADARR_ROOT_FOLDER=("/opt/movies1")						#Folders to where you want to store movies (Can already conatin a few)
	
#Constants
app_uid=$SUDO_USER
app_guid=users
host=$(hostname -I)
ip_local=$(grep -oP '^\S*' <<<"$host")

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

apt update
apt install curl sqlite3 nano openssh-server net-tools bzip2 build-essential ntfs-3g -y

#Zerotier Setup
if [ "$INSTALL_ZEROTIER" == "true" ]
then
    echo "Installing Zerotier"

	curl -s https://install.zerotier.com | bash
	zerotier-cli join $NWID

	MEMBER_ID=$(zerotier-cli info | cut -d " " -f 3)

	curl -H "Authorization: token $ZT_TOKEN" -X POST "https://api.zerotier.com/api/v1/network/$NWID/member/$MEMBER_ID" --data '{"config": {"authorized": true}, "name": "'"${HOSTNAME}"'"}'
fi

#MergerFS Setup
if [ "$INSTALL_SHARES" == "true" ]
then
    echo "Setting up Shared Folders"
    apt install samba mergerfs -y

    if [ ${#HDD_IDS[@]} -eq 0 ]; then
        echo "No HDD configured using default options"
        echo "Seaching for suitable drives..."

        ls /dev/disk/by-id | grep -v "part\|DVD\|CD" | grep "ata" | while read -r drive ; do
            echo "Found Drive: $drive"

            partitions=$(ls /dev/disk/by-id | grep "$drive-part1")
            
            ls /dev/disk/by-id | grep "$drive-part" | while read -r partition ; do
                mount_point=$(lsblk -r /dev/disk/by-id/$partition | grep "sd" | cut -d " " -f 7)
                FSNAME=$(lsblk --fs /dev/disk/by-id/$drive | grep "sd" | cut -d " " -f 1)

                if [[ "$FSNAME" = *"sda"* ]]; then
                    echo "  Skipping primary drive: /dev/sda"
                    continue
                fi
                
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
                        FSTYPE=$(lsblk --fs /dev/disk/by-id/$partition | grep "sd" | cut -d " " -f 2)
                        
                
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

            #Check if HDD exists
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

#SabNZBd
if [ "$INSTALL_SABNZBD" == "true" ]
then
    echo "Installing SABNZBd"

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
	USER=$app_uid

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
	
	if grep -F "[servers]" /home/$app_uid/.sabnzbd/sabnzbd.ini
	then
		echo "Existing Servers Found!"
	else
		echo "Creating new config in /home/$app_uid/.sabnzbd/sabnzbd.ini"
		echo [servers] >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo [[$SERVER_HOST]] >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo name = $SERVER_HOST >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo displayname = $SERVER_HOST >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo host = $SERVER_HOST >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo port = $SERVER_PORT >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo timeout = 30 >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo username = $SERVER_USERNAME >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo "password = \"$SERVER_PASSWORD\"" >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo connections = $SERVER_CONNECTIONS >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo ssl = $SERVER_SSL >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo ssl_verify = 2 >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo ssl_ciphers = "" >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo enable = 1 >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo required = 0 >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo optional = 0 >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo retention = 0 >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo expire_date = "" >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo quota = "" >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo usage_at_start = 0 >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo priority = 0 >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo notes = "" >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo [categories] >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo [[*]] >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo "name = *" >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo order = 0 >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo pp = 3 >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo script = None >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo dir = "" >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo newzbin = "" >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo priority = 0 >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo [[movies]] >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo name = movies >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo order = 0 >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo pp = "" >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo script = Default >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo dir = "" >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo newzbin = "" >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo priority = -100 >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo [[tv]] >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo name = tv >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo order = 0 >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo pp = "" >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo script = Default >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo dir = "" >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo newzbin = "" >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo priority = -100 >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo [[audio]] >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo name = audio >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo order = 0 >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo pp = "" >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo script = Default >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo dir = "" >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo newzbin = "" >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo priority = -100 >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo [[software]] >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo name = software >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo order = 0 >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo pp = "" >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo script = Default >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo dir = "" >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo newzbin = "" >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo priority = -100 >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo [[sonarr]] >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo name = sonarr >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo order = 0 >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo pp = "" >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo script = Default >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo dir = sonarr >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo newzbin = "" >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo priority = -100 >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo [[radarr]] >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo name = radarr >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo order = 0 >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo pp = "" >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo script = Default >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo dir = radarr >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo newzbin = "" >> /home/$app_uid/.sabnzbd/sabnzbd.ini
		echo priority = -100 >> /home/$app_uid/.sabnzbd/sabnzbd.ini
	fi
	
	sed -i 's/permissions = ""/permissions = 775/' /home/$app_uid/.sabnzbd/sabnzbd.ini

	systemctl daemon-reload
	service sabnzbdplus restart
	
	echo "SABNZBd Is running: Browse to http://$ip_local:$SABNZBD_PORT for the SABNZBd GUI"
	SABNZBD_URL="http://$ip_local:$SABNZBD_PORT"
fi

#Sonarr
if [ "$INSTALL_SONARR" == "true" ]
then
    echo "Installing Sonarr"
	set -euo pipefail

	app="sonarr"
	app_port=$SONARR_PORT
	app_umask="0002"
	branch="main"
	installdir="/opt"              # {Update me if needed} Install Location
	bindir="${installdir}/${app^}" # Full Path to Install Location
	datadir="/var/lib/$app/"       # {Update me if needed} AppData directory to use
	app_bin=${app^}                # Binary Name of the app
	app_uid=$(echo "$app_uid" | tr -d ' ')
	app_uid=${app_uid:-$app}
	app_guid=$(echo "$app_guid" | tr -d ' ')
	app_guid=${app_guid:-media}

	echo "This will install [${app^}] to [$bindir] and use [$datadir] for the AppData Directory"

	echo "Stoppin the App if running"
	if service --status-all | grep -Fq "$app"; then
	    systemctl stop "$app"
	    systemctl disable "$app".service
	    echo "Stopped existing $app"
	fi

	mkdir -p "$datadir"
	chown -R "$app_uid":"$app_guid" "$datadir"
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
	wget --content-disposition "$DLURL"
	tar -xvzf "${app^}".*.tar.gz
	echo "Installation files downloaded and extracted"

	echo "Removing existing installation"
	rm -rf "$bindir"

	echo "Installing..."
	mv "${app^}" $installdir
	chown "$app_uid":"$app_guid" -R "$bindir"
	chmod 775 "$bindir"
	rm -rf "${app^}.*.tar.gz"
	touch "$datadir"/update_required
	chown "$app_uid":"$app_guid" "$datadir"/update_required
	echo "App Installed"

	echo "Removing old service file"
	rm -rf /etc/systemd/system/"$app".service

	echo "Creating service file"
	cat <<EOF | tee /etc/systemd/system/"$app".service >/dev/null
	[Unit]
	Description=${app^} Daemon
	After=syslog.target network.target
	[Service]
	User=$app_uid
	Group=$app_guid
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
	echo "Install complete: wiating for Sonarr to start"
	sleep 15
	STATUS="$(systemctl is-active "$app")"
	if [ "${STATUS}" = "active" ]; then
	
		if grep "api_key" "/home/$app_uid/.sabnzbd/sabnzbd.ini"
		then
			SONARR_APIKEY=$(grep "ApiKey" "$datadir/config.xml" | cut -d '>' -f 2 | cut -d '<' -f 1)
			SABNZBD_APIKEY=$(grep "api_key" "/home/$app_uid/.sabnzbd/sabnzbd.ini" | cut -d "=" -f 2 | xargs)
			
			echo "Adding Download Client:"
			curl -H "Content-Type: application/json" -H "X-Api-Key: $SONARR_APIKEY" -H "accept: application/json" -X POST "http://$ip_local:$SONARR_PORT/api/v3/downloadclient" --data '{"enable":true,"protocol":"usenet","priority":1,"removeCompletedDownloads":true,"removeFailedDownloads":true,"name":"SABnzbd","fields":[{"order":0,"name":"host","label":"Host","value":"localhost","type":"textbox","advanced":false,"privacy":"normal","isFloat":false},{"order":1,"name":"port","label":"Port","value":'"$SABNZBD_PORT"',"type":"textbox","advanced":false,"privacy":"normal","isFloat":false},{"order":2,"name":"useSsl","label":"Use SSL","helpText":"Use secure connection when connection to Sabnzbd","value":false,"type":"checkbox","advanced":false,"privacy":"normal","isFloat":false},{"order":3,"name":"urlBase","label":"URL Base","helpText":"Adds a prefix to the Sabnzbd url, such as http://[host]:[port]/[urlBase]/api","type":"textbox","advanced":true,"privacy":"normal","isFloat":false},{"order":4,"name":"apiKey","label":"API Key","value":"'"$SABNZBD_APIKEY"'","type":"textbox","advanced":false,"privacy":"apiKey","isFloat":false},{"order":5,"name":"username","label":"Username","value":"admin","type":"textbox","advanced":false,"privacy":"userName","isFloat":false},{"order":6,"name":"password","label":"Password","value":"password","type":"password","advanced":false,"privacy":"password","isFloat":false},{"order":7,"name":"tvCategory","label":"Category","helpText":"Adding a category specific to Sonarr avoids conflicts with unrelated non-Sonarr downloads. Using a category is optional, but strongly recommended.","value":"sonarr","type":"textbox","advanced":false,"privacy":"normal","isFloat":false},{"order":8,"name":"recentTvPriority","label":"Recent Priority","helpText":"Priority to use when grabbing episodes that aired within the last 14 days","value":-100,"type":"select","advanced":false,"selectOptions":[{"value":-100,"name":"Default","order":-100},{"value":-2,"name":"Paused","order":-2},{"value":-1,"name":"Low","order":-1},{"value":0,"name":"Normal","order":0},{"value":1,"name":"High","order":1},{"value":2,"name":"Force","order":2}],"privacy":"normal","isFloat":false},{"order":9,"name":"olderTvPriority","label":"Older Priority","helpText":"Priority to use when grabbing episodes that aired over 14 days ago","value":-100,"type":"select","advanced":false,"selectOptions":[{"value":-100,"name":"Default","order":-100},{"value":-2,"name":"Paused","order":-2},{"value":-1,"name":"Low","order":-1},{"value":0,"name":"Normal","order":0},{"value":1,"name":"High","order":1},{"value":2,"name":"Force","order":2}],"privacy":"normal","isFloat":false}],"implementationName":"SABnzbd","implementation":"Sabnzbd","configContract":"SabnzbdSettings","infoLink":"https://wiki.servarr.com/sonarr/supported#sabnzbd","tags":[]}'
			
			echo "Adding Indexer:"
			curl -H "Content-Type: application/json" -H "X-Api-Key: $SONARR_APIKEY" -H "accept: application/json" -X POST "http://$ip_local:$SONARR_PORT/api/v3/indexer" --data '{"enableRss":true,"enableAutomaticSearch":true,"enableInteractiveSearch":true,"supportsRss":true,"supportsSearch":true,"protocol":"usenet","priority":25,"seasonSearchMaximumSingleEpisodeAge":0,"downloadClientId":0,"name":"'"$INDEXER_NAME"'","fields":[{"order":0,"name":"baseUrl","label":"URL","value":"'"$INDEXER_URL"'","type":"textbox","advanced":false,"privacy":"normal","isFloat":false},{"order":1,"name":"apiPath","label":"API Path","helpText":"Path to the api, usually /api","value":"'"$INDEXER_API_PATH"'","type":"textbox","advanced":true,"privacy":"normal","isFloat":false},{"order":2,"name":"apiKey","label":"API Key","value":"'"$INDEXER_APIKEY"'","type":"textbox","advanced":false,"privacy":"apiKey","isFloat":false},{"order":3,"name":"categories","label":"Categories","helpText":"Drop down list, leave blank to disable standard/daily shows","value":[5030,5040,5050,5070],"type":"select","advanced":false,"selectOptionsProviderAction":"newznabCategories","privacy":"normal","isFloat":false},{"order":4,"name":"animeCategories","label":"Anime Categories","helpText":"Drop down list, leave blank to disable anime","value":[5030,5040,5070],"type":"select","advanced":false,"selectOptionsProviderAction":"newznabCategories","privacy":"normal","isFloat":false},{"order":5,"name":"animeStandardFormatSearch","label":"Anime Standard Format Search","helpText":"Also search for anime using the standard numbering","value":false,"type":"checkbox","advanced":false,"privacy":"normal","isFloat":false},{"order":6,"name":"additionalParameters","label":"Additional Parameters","helpText":"Please note if you change the category you will have to add required/restricted rules about the subgroups to avoid foreign language releases.","type":"textbox","advanced":true,"privacy":"normal","isFloat":false},{"order":7,"name":"multiLanguages","label":"Multi Languages","helpText":"What languages are normally in a multi release on this indexer?","value":[],"type":"select","advanced":true,"selectOptions":[{"value":-2,"name":"Original","order":0},{"value":26,"name":"Arabic","order":0},{"value":41,"name":"Bosnian","order":0},{"value":28,"name":"Bulgarian","order":0},{"value":38,"name":"Catalan","order":0},{"value":10,"name":"Chinese","order":0},{"value":39,"name":"Croatian","order":0},{"value":25,"name":"Czech","order":0},{"value":6,"name":"Danish","order":0},{"value":7,"name":"Dutch","order":0},{"value":1,"name":"English","order":0},{"value":42,"name":"Estonian","order":0},{"value":16,"name":"Finnish","order":0},{"value":19,"name":"Flemish","order":0},{"value":2,"name":"French","order":0},{"value":4,"name":"German","order":0},{"value":20,"name":"Greek","order":0},{"value":23,"name":"Hebrew","order":0},{"value":27,"name":"Hindi","order":0},{"value":22,"name":"Hungarian","order":0},{"value":9,"name":"Icelandic","order":0},{"value":44,"name":"Indonesian","order":0},{"value":5,"name":"Italian","order":0},{"value":8,"name":"Japanese","order":0},{"value":21,"name":"Korean","order":0},{"value":36,"name":"Latvian","order":0},{"value":24,"name":"Lithuanian","order":0},{"value":45,"name":"Macedonian","order":0},{"value":29,"name":"Malayalam","order":0},{"value":15,"name":"Norwegian","order":0},{"value":37,"name":"Persian","order":0},{"value":12,"name":"Polish","order":0},{"value":18,"name":"Portuguese","order":0},{"value":33,"name":"Portuguese (Brazil)","order":0},{"value":35,"name":"Romanian","order":0},{"value":11,"name":"Russian","order":0},{"value":40,"name":"Serbian","order":0},{"value":31,"name":"Slovak","order":0},{"value":46,"name":"Slovenian","order":0},{"value":3,"name":"Spanish","order":0},{"value":34,"name":"Spanish (Latino)","order":0},{"value":14,"name":"Swedish","order":0},{"value":43,"name":"Tamil","order":0},{"value":32,"name":"Thai","order":0},{"value":17,"name":"Turkish","order":0},{"value":30,"name":"Ukrainian","order":0},{"value":13,"name":"Vietnamese","order":0}],"privacy":"normal","isFloat":false}],"implementationName":"Newznab","implementation":"Newznab","configContract":"NewznabSettings","infoLink":"https://wiki.servarr.com/sonarr/supported#newznab","tags":[]}'
		
			echo "Adding Root Folders:"
			for folder in ${SONARR_ROOT_FOLDER[@]}; do
				mkdir -p $folder
				chown -R "$app_uid":"$app_guid" $folder
				chmod 775 "$folder"
				
		  		curl -H "Content-Type: application/json" -H "X-Api-Key: $SONARR_APIKEY" -H "accept: application/json" -X POST "http://$ip_local:$SONARR_PORT/api/v3/rootfolder" --data '{"path":"'"$folder"'","accessible":true,"freeSpace":0,"unmappedFolders":[]}'
			done
			
			echo "Setting more sensible quality values"
			qualities=('{"quality":{"id":0,"name":"Unknown","source":"unknown","resolution":0},"title":"Unknown","weight":1,"minSize":1,"maxSize":50,"preferredSize":20,"id":1 }' '{"quality":{"id":1,"name":"SDTV","source":"television","resolution":480},"title":"SDTV","weight":2,"minSize":2,"maxSize":50,"preferredSize":20,"id":2 }' '{"quality":{"id":12,"name":"WEBRip-480p","source":"webRip","resolution":480},"title":"WEBRip-480p","weight":3,"minSize":2,"maxSize":50,"preferredSize":20,"id":3 }' '{"quality":{"id":8,"name":"WEBDL-480p","source":"web","resolution":480},"title":"WEBDL-480p","weight":3,"minSize":2,"maxSize":50,"preferredSize":20,"id":4 }' '{"quality":{"id":2,"name":"DVD","source":"dvd","resolution":480},"title":"DVD","weight":4,"minSize":2,"maxSize":50,"preferredSize":20,"id":5 }' '{"quality":{"id":13,"name":"Bluray-480p","source":"bluray","resolution":480},"title":"Bluray-480p","weight":5,"minSize":2,"maxSize":50,"preferredSize":20,"id":6 }' '{"quality":{"id":4,"name":"HDTV-720p","source":"television","resolution":720},"title":"HDTV-720p","weight":6,"minSize":3,"maxSize":50,"preferredSize":20,"id":7 }' '{"quality":{"id":9,"name":"HDTV-1080p","source":"television","resolution":1080},"title":"HDTV-1080p","weight":7,"minSize":4,"maxSize":50,"preferredSize":20,"id":8 }' '{"quality":{"id":10,"name":"Raw-HD","source":"televisionRaw","resolution":1080},"title":"Raw-HD","weight":8,"minSize":4,"maxSize":50,"preferredSize":20,"id":9 }' '{"quality":{"id":14,"name":"WEBRip-720p","source":"webRip","resolution":720},"title":"WEBRip-720p","weight":9,"minSize":3,"maxSize":50,"preferredSize":20,"id":10 }' '{"quality":{"id":5,"name":"WEBDL-720p","source":"web","resolution":720},"title":"WEBDL-720p","weight":9,"minSize":3,"maxSize":50,"preferredSize":20,"id":11 }' '{"quality":{"id":6,"name":"Bluray-720p","source":"bluray","resolution":720},"title":"Bluray-720p","weight":10,"minSize":4,"maxSize":50,"preferredSize":20,"id":12 }' '{"quality":{"id":15,"name":"WEBRip-1080p","source":"webRip","resolution":1080},"title":"WEBRip-1080p","weight":11,"minSize":4,"maxSize":50,"preferredSize":20,"id":13 }' '{"quality":{"id":3,"name":"WEBDL-1080p","source":"web","resolution":1080},"title":"WEBDL-1080p","weight":11,"minSize":4,"maxSize":50,"preferredSize":20,"id":14 }' '{"quality":{"id":7,"name":"Bluray-1080p","source":"bluray","resolution":1080},"title":"Bluray-1080p","weight":12,"minSize":4,"maxSize":50,"preferredSize":20,"id":15 }' '{"quality":{"id":20,"name":"Bluray-1080p Remux","source":"blurayRaw","resolution":1080},"title":"Bluray-1080p Remux","weight":13,"minSize":0,"maxSize":50,"preferredSize":20,"id":16 }' '{"quality":{"id":16,"name":"HDTV-2160p","source":"television","resolution":2160},"title":"HDTV-2160p","weight":14,"minSize":35,"maxSize":50,"preferredSize":20,"id":17 }' '{"quality":{"id":17,"name":"WEBRip-2160p","source":"webRip","resolution":2160},"title":"WEBRip-2160p","weight":15,"minSize":35,"maxSize":50,"preferredSize":20,"id":18 }' '{"quality":{"id":18,"name":"WEBDL-2160p","source":"web","resolution":2160},"title":"WEBDL-2160p","weight":15,"minSize":35,"maxSize":50,"preferredSize":20,"id":19 }' '{"quality":{"id":19,"name":"Bluray-2160p","source":"bluray","resolution":2160},"title":"Bluray-2160p","weight":16,"minSize":35,"maxSize":50,"preferredSize":20,"id":20 }' '{"quality":{"id":21,"name":"Bluray-2160p Remux","source":"blurayRaw","resolution":2160},"title":"Bluray-2160p Remux","weight":17,"minSize":35,"maxSize":50,"preferredSize":20,"id":21}')

			for ((i = 0; i < ${#qualities[@]}; i++))
			do
			    	curl -H "Content-Type: application/json" -H "X-Api-Key: $SONARR_APIKEY" -H "accept: application/json" -X PUT "http://$ip_local:$SONARR_PORT/api/v3/qualitydefinition" --data "${qualities[$i]}"
			done
		fi
		
		echo "Setting Permissions"
		curl -H "Content-Type: application/json" -H "X-Api-Key: e2a8d11872a6488c885dce8ee23f9fe2" -H "accept: application/json" -X PUT "http://localhost:8989/api/v3/config/mediamanagement"  --data '{"autoUnmonitorPreviouslyDownloadedEpisodes":false,"recycleBin":"","recycleBinCleanupDays":7,"downloadPropersAndRepacks":"preferAndUpgrade","createEmptySeriesFolders":false,"deleteEmptyFolders":true,"fileDate":"none","rescanAfterRefresh":"always","setPermissionsLinux":true,"chmodFolder":"755","chownGroup":"'"$app_guid"'","episodeTitleRequired":"always","skipFreeSpaceCheckWhenImporting":false,"minimumFreeSpaceWhenImporting":100,"copyUsingHardlinks":true,"useScriptImport":false,"scriptImportPath":"","importExtraFiles":true,"extraFileExtensions":"srt","enableMediaInfo":true,"id":1}'
	   	
	   	echo "Browse to http://$ip_local:$app_port for the ${app^} GUI"
	   	SONARR_URL="http://$ip_local:$app_port"
	else
	    echo "${app^} failed to start"
	fi
fi

#Radarr
if [ "$INSTALL_RADARR" == "true" ]
then
    echo "Installing Radarr"
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
	chown -R "$app_uid":"$app_guid" "$datadir"
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
	wget --content-disposition "$DLURL"
	tar -xvzf "${app^}".*.tar.gz >/dev/null 2>&1
	echo -e "Installation files downloaded and extracted!"

	echo -e "Removing existing installation files from $bindir]"
	rm -rf "$bindir"
	sleep 2
	echo -e "Attempting to install ${app^}..."
	sleep 2
	mv "${app^}" $installdir
	chown "$app_uid":"$app_guid" -R "$bindir"
	chmod 775 "$bindir"
	touch "$datadir"/update_required
	chown "$app_uid":"$app_guid" "$datadir"/update_required
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
	User=$app_uid
	Group=$app_guid
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

	echo -e "Attempting to check for a connection at http://$ip_local:$app_port..."
	sleep 15
	STATUS="$(systemctl is-active "$app")"
	if [ "${STATUS}" = "active" ]; then
		if grep "api_key" "/home/$app_uid/.sabnzbd/sabnzbd.ini"
		then
			RADARR_APIKEY=$(grep "ApiKey" "$datadir/config.xml" | cut -d '>' -f 2 | cut -d '<' -f 1)
			SABNZBD_APIKEY=$(grep "api_key" "/home/$app_uid/.sabnzbd/sabnzbd.ini" | cut -d "=" -f 2 | xargs)
			
			echo "Adding Download Client:"
			curl -H "Content-Type: application/json" -H "X-Api-Key: $RADARR_APIKEY" -H "accept: application/json" -X POST "http://$ip_local:$RADARR_PORT/api/v3/downloadclient" --data '{"enable":true,"protocol":"usenet","priority":1,"removeCompletedDownloads":true,"removeFailedDownloads":true,"name":"SABnzbd","fields":[{"order":0,"name":"host","label":"Host","value":"localhost","type":"textbox","advanced":false,"privacy":"normal","isFloat":false},{"order":1,"name":"port","label":"Port","value":'"$SABNZBD_PORT"',"type":"textbox","advanced":false,"privacy":"normal","isFloat":false},{"order":2,"name":"useSsl","label":"Use SSL","helpText":"Use secure connection when connection to Sabnzbd","value":false,"type":"checkbox","advanced":false,"privacy":"normal","isFloat":false},{"order":3,"name":"urlBase","label":"URL Base","helpText":"Adds a prefix to the Sabnzbd url, such as http://[host]:[port]/[urlBase]/api","type":"textbox","advanced":true,"privacy":"normal","isFloat":false},{"order":4,"name":"apiKey","label":"API Key","value":"'"$SABNZBD_APIKEY"'","type":"textbox","advanced":false,"privacy":"apiKey","isFloat":false},{"order":5,"name":"username","label":"Username","value":"admin","type":"textbox","advanced":false,"privacy":"userName","isFloat":false},{"order":6,"name":"password","label":"Password","value":"password","type":"password","advanced":false,"privacy":"password","isFloat":false},{"order":7,"name":"tvCategory","label":"Category","helpText":"Adding a category specific to Sonarr avoids conflicts with unrelated non-Sonarr downloads. Using a category is optional, but strongly recommended.","value":"sonarr","type":"textbox","advanced":false,"privacy":"normal","isFloat":false},{"order":8,"name":"recentTvPriority","label":"Recent Priority","helpText":"Priority to use when grabbing episodes that aired within the last 14 days","value":-100,"type":"select","advanced":false,"selectOptions":[{"value":-100,"name":"Default","order":-100},{"value":-2,"name":"Paused","order":-2},{"value":-1,"name":"Low","order":-1},{"value":0,"name":"Normal","order":0},{"value":1,"name":"High","order":1},{"value":2,"name":"Force","order":2}],"privacy":"normal","isFloat":false},{"order":9,"name":"olderTvPriority","label":"Older Priority","helpText":"Priority to use when grabbing episodes that aired over 14 days ago","value":-100,"type":"select","advanced":false,"selectOptions":[{"value":-100,"name":"Default","order":-100},{"value":-2,"name":"Paused","order":-2},{"value":-1,"name":"Low","order":-1},{"value":0,"name":"Normal","order":0},{"value":1,"name":"High","order":1},{"value":2,"name":"Force","order":2}],"privacy":"normal","isFloat":false}],"implementationName":"SABnzbd","implementation":"Sabnzbd","configContract":"SabnzbdSettings","infoLink":"https://wiki.servarr.com/sonarr/supported#sabnzbd","tags":[]}'
			
			echo "Adding Indexer:"
			curl -H "Content-Type: application/json" -H "X-Api-Key: $RADARR_APIKEY" -H "accept: application/json" -X POST "http://$ip_local:$RADARR_PORT/api/v3/indexer" --data '{"enableRss":true,"enableAutomaticSearch":true,"enableInteractiveSearch":true,"supportsRss":true,"supportsSearch":true,"protocol":"usenet","priority":25,"seasonSearchMaximumSingleEpisodeAge":0,"downloadClientId":0,"name":"'"$INDEXER_NAME"'","fields":[{"order":0,"name":"baseUrl","label":"URL","value":"'"$INDEXER_URL"'","type":"textbox","advanced":false,"privacy":"normal","isFloat":false},{"order":1,"name":"apiPath","label":"API Path","helpText":"Path to the api, usually /api","value":"'"$INDEXER_API_PATH"'","type":"textbox","advanced":true,"privacy":"normal","isFloat":false},{"order":2,"name":"apiKey","label":"API Key","value":"'"$INDEXER_APIKEY"'","type":"textbox","advanced":false,"privacy":"apiKey","isFloat":false},{"order":3,"name":"categories","label":"Categories","helpText":"Drop down list, leave blank to disable standard/daily shows","value":[2030,2040,2045,2050],"type":"select","advanced":false,"selectOptionsProviderAction":"newznabCategories","privacy":"normal","isFloat":false},{"order":4,"name":"animeCategories","label":"Anime Categories","helpText":"Drop down list, leave blank to disable anime","value":[5030,5040,5070],"type":"select","advanced":false,"selectOptionsProviderAction":"newznabCategories","privacy":"normal","isFloat":false},{"order":5,"name":"animeStandardFormatSearch","label":"Anime Standard Format Search","helpText":"Also search for anime using the standard numbering","value":false,"type":"checkbox","advanced":false,"privacy":"normal","isFloat":false},{"order":6,"name":"additionalParameters","label":"Additional Parameters","helpText":"Please note if you change the category you will have to add required/restricted rules about the subgroups to avoid foreign language releases.","type":"textbox","advanced":true,"privacy":"normal","isFloat":false},{"order":7,"name":"multiLanguages","label":"Multi Languages","helpText":"What languages are normally in a multi release on this indexer?","value":[],"type":"select","advanced":true,"selectOptions":[{"value":-2,"name":"Original","order":0},{"value":26,"name":"Arabic","order":0},{"value":41,"name":"Bosnian","order":0},{"value":28,"name":"Bulgarian","order":0},{"value":38,"name":"Catalan","order":0},{"value":10,"name":"Chinese","order":0},{"value":39,"name":"Croatian","order":0},{"value":25,"name":"Czech","order":0},{"value":6,"name":"Danish","order":0},{"value":7,"name":"Dutch","order":0},{"value":1,"name":"English","order":0},{"value":42,"name":"Estonian","order":0},{"value":16,"name":"Finnish","order":0},{"value":19,"name":"Flemish","order":0},{"value":2,"name":"French","order":0},{"value":4,"name":"German","order":0},{"value":20,"name":"Greek","order":0},{"value":23,"name":"Hebrew","order":0},{"value":27,"name":"Hindi","order":0},{"value":22,"name":"Hungarian","order":0},{"value":9,"name":"Icelandic","order":0},{"value":44,"name":"Indonesian","order":0},{"value":5,"name":"Italian","order":0},{"value":8,"name":"Japanese","order":0},{"value":21,"name":"Korean","order":0},{"value":36,"name":"Latvian","order":0},{"value":24,"name":"Lithuanian","order":0},{"value":45,"name":"Macedonian","order":0},{"value":29,"name":"Malayalam","order":0},{"value":15,"name":"Norwegian","order":0},{"value":37,"name":"Persian","order":0},{"value":12,"name":"Polish","order":0},{"value":18,"name":"Portuguese","order":0},{"value":33,"name":"Portuguese (Brazil)","order":0},{"value":35,"name":"Romanian","order":0},{"value":11,"name":"Russian","order":0},{"value":40,"name":"Serbian","order":0},{"value":31,"name":"Slovak","order":0},{"value":46,"name":"Slovenian","order":0},{"value":3,"name":"Spanish","order":0},{"value":34,"name":"Spanish (Latino)","order":0},{"value":14,"name":"Swedish","order":0},{"value":43,"name":"Tamil","order":0},{"value":32,"name":"Thai","order":0},{"value":17,"name":"Turkish","order":0},{"value":30,"name":"Ukrainian","order":0},{"value":13,"name":"Vietnamese","order":0}],"privacy":"normal","isFloat":false}],"implementationName":"Newznab","implementation":"Newznab","configContract":"NewznabSettings","infoLink":"https://wiki.servarr.com/sonarr/supported#newznab","tags":[]}'
		
			echo "Adding Root Folders:"RADARR_PORT
			for folder in ${RADARR_ROOT_FOLDER[@]}; do
				mkdir -p $folder
				chown -R "$app_uid":"$app_guid" $folder
				chmod 775 "$folder"
				
		  		curl -H "Content-Type: application/json" -H "X-Api-Key: $RADARR_APIKEY" -H "accept: application/json" -X POST "http://$ip_local:$RADARR_PORT/api/v3/rootfolder" --data '{"path":"'"$folder"'","accessible":true,"freeSpace":0,"unmappedFolders":[]}'
			done
			
			echo "Setting more sensible quality values"
			qualities=('{"quality":{"id":0,"name":"Unknown","source":"unknown","resolution":0,"modifier":"none"},"title":"Unknown","weight":1,"minSize":0,"maxSize":50,"preferredSize":20,"id":1}' '{"quality":{"id":24,"name":"WORKPRINT","source":"workprint","resolution":0,"modifier":"none"},"title":"WORKPRINT","weight":2,"minSize":0,"maxSize":50,"preferredSize":20,"id":2}' '{"quality":{"id":25,"name":"CAM","source":"cam","resolution":0,"modifier":"none"},"title":"CAM","weight":3,"minSize":0,"maxSize":50,"preferredSize":20,"id":3}' '{"quality":{"id":26,"name":"TELESYNC","source":"telesync","resolution":0,"modifier":"none"},"title":"TELESYNC","weight":4,"minSize":0,"maxSize":50,"preferredSize":20,"id":4}' '{"quality":{"id":27,"name":"TELECINE","source":"telecine","resolution":0,"modifier":"none"},"title":"TELECINE","weight":5,"minSize":0,"maxSize":50,"preferredSize":20,"id":5}' '{"quality":{"id":29,"name":"REGIONAL","source":"dvd","resolution":480,"modifier":"regional"},"title":"REGIONAL","weight":6,"minSize":0,"maxSize":50,"preferredSize":20,"id":6}' '{"quality":{"id":28,"name":"DVDSCR","source":"dvd","resolution":480,"modifier":"screener"},"title":"DVDSCR","weight":7,"minSize":0,"maxSize":50,"preferredSize":20,"id":7}' '{"quality":{"id":1,"name":"SDTV","source":"tv","resolution":480,"modifier":"none"},"title":"SDTV","weight":8,"minSize":0,"maxSize":50,"preferredSize":20,"id":8}' '{"quality":{"id":2,"name":"DVD","source":"dvd","resolution":0,"modifier":"none"},"title":"DVD","weight":9,"minSize":0,"maxSize":50,"preferredSize":20,"id":9}' '{"quality":{"id":23,"name":"DVD-R","source":"dvd","resolution":480,"modifier":"remux"},"title":"DVD-R","weight":10,"minSize":0,"maxSize":50,"preferredSize":20,"id":10}' '{"quality":{"id":8,"name":"WEBDL-480p","source":"webdl","resolution":480,"modifier":"none"},"title":"WEBDL-480p","weight":11,"minSize":0,"maxSize":50,"preferredSize":20,"id":11}' '{"quality":{"id":12,"name":"WEBRip-480p","source":"webrip","resolution":480,"modifier":"none"},"title":"WEBRip-480p","weight":11,"minSize":0,"maxSize":50,"preferredSize":20,"id":12}' '{"quality":{"id":20,"name":"Bluray-480p","source":"bluray","resolution":480,"modifier":"none"},"title":"Bluray-480p","weight":12,"minSize":0,"maxSize":50,"preferredSize":20,"id":13}' '{"quality":{"id":21,"name":"Bluray-576p","source":"bluray","resolution":576,"modifier":"none"},"title":"Bluray-576p","weight":13,"minSize":0,"maxSize":50,"preferredSize":20,"id":14}' '{"quality":{"id":4,"name":"HDTV-720p","source":"tv","resolution":720,"modifier":"none"},"title":"HDTV-720p","weight":14,"minSize":0,"maxSize":50,"preferredSize":20,"id":15}' '{"quality":{"id":5,"name":"WEBDL-720p","source":"webdl","resolution":720,"modifier":"none"},"title":"WEBDL-720p","weight":15,"minSize":0,"maxSize":50,"preferredSize":20,"id":16}' '{"quality":{"id":14,"name":"WEBRip-720p","source":"webrip","resolution":720,"modifier":"none"},"title":"WEBRip-720p","weight":15,"minSize":0,"maxSize":50,"preferredSize":20,"id":17}' '{"quality":{"id":6,"name":"Bluray-720p","source":"bluray","resolution":720,"modifier":"none"},"title":"Bluray-720p","weight":16,"minSize":0,"maxSize":50,"preferredSize":20,"id":18}' '{"quality":{"id":9,"name":"HDTV-1080p","source":"tv","resolution":1080,"modifier":"none"},"title":"HDTV-1080p","weight":17,"minSize":0,"maxSize":50,"preferredSize":20,"id":19}' '{"quality":{"id":3,"name":"WEBDL-1080p","source":"webdl","resolution":1080,"modifier":"none"},"title":"WEBDL-1080p","weight":18,"minSize":0,"maxSize":50,"preferredSize":20,"id":20}' '{"quality":{"id":15,"name":"WEBRip-1080p","source":"webrip","resolution":1080,"modifier":"none"},"title":"WEBRip-1080p","weight":18,"minSize":0,"maxSize":50,"preferredSize":20,"id":21}' '{"quality":{"id":7,"name":"Bluray-1080p","source":"bluray","resolution":1080,"modifier":"none"},"title":"Bluray-1080p","weight":19,"minSize":0,"maxSize":50,"preferredSize":20,"id":22}' '{"quality":{"id":30,"name":"Remux-1080p","source":"bluray","resolution":1080,"modifier":"remux"},"title":"Remux-1080p","weight":20,"minSize":0,"maxSize":50,"preferredSize":20,"id":23}' '{"quality":{"id":16,"name":"HDTV-2160p","source":"tv","resolution":2160,"modifier":"none"},"title":"HDTV-2160p","weight":21,"minSize":0,"maxSize":80,"preferredSize":20,"id":24}' '{"quality":{"id":18,"name":"WEBDL-2160p","source":"webdl","resolution":2160,"modifier":"none"},"title":"WEBDL-2160p","weight":22,"minSize":0,"maxSize":80,"preferredSize":20,"id":25}' '{"quality":{"id":17,"name":"WEBRip-2160p","source":"webrip","resolution":2160,"modifier":"none"},"title":"WEBRip-2160p","weight":22,"minSize":0,"maxSize":80,"preferredSize":20,"id":26}' '{"quality":{"id":19,"name":"Bluray-2160p","source":"bluray","resolution":2160,"modifier":"none"},"title":"Bluray-2160p","weight":23,"minSize":0,"maxSize":80,"preferredSize":20,"id":27}' '{"quality":{"id":31,"name":"Remux-2160p","source":"bluray","resolution":2160,"modifier":"remux"},"title":"Remux-2160p","weight":24,"minSize":0,"maxSize":80,"preferredSize":20,"id":28}' '{"quality":{"id":22,"name":"BR-DISK","source":"bluray","resolution":1080,"modifier":"brdisk"},"title":"BR-DISK","weight":25,"minSize":0,"maxSize":80,"preferredSize":20,"id":29}' '{"quality":{"id":10,"name":"Raw-HD","source":"tv","resolution":1080,"modifier":"rawhd"},"title":"Raw-HD","weight":26,"minSize":0,"maxSize":80,"preferredSize":20,"id":30}')

			for ((i = 0; i < ${#qualities[@]}; i++))
			do
			    	curl -H "Content-Type: application/json" -H "X-Api-Key: $RADARR_APIKEY" -H "accept: application/json" -X PUT "http://$ip_local:$RADARR_PORT/api/v3/qualitydefinition" --data "${qualities[$i]}"
			done
			
			echo "Setting permissions settings"
			curl -H "Content-Type: application/json" -H "X-Api-Key: $RADARR_APIKEY" -H "accept: application/json" -X PUT "http://$ip_local:$RADARR_PORT/api/v3/config/mediamanagement"  --data '{"autoUnmonitorPreviouslyDownloadedMovies":false,"recycleBin":"","recycleBinCleanupDays":7,"downloadPropersAndRepacks":"preferAndUpgrade","createEmptyMovieFolders":false,"deleteEmptyFolders":true,"fileDate":"none","rescanAfterRefresh":"always","autoRenameFolders":true,"pathsDefaultStatic":false,"setPermissionsLinux":true,"chmodFolder":"755","chownGroup":"'"$app_guid"'","skipFreeSpaceCheckWhenImporting":false,"minimumFreeSpaceWhenImporting":100,"copyUsingHardlinks":true,"useScriptImport":false,"scriptImportPath":"","importExtraFiles":true,"extraFileExtensions":"srt","enableMediaInfo":true,"id":1}'
		fi
	    	echo "Browse to http://$ip_local:$app_port for the ${app^} GUI"
	    	RADARR_URL="http://$ip_local:$app_port"
	else
	   	echo "${app^} failed to start"
	fi
fi

#Plex Media Server
if [ "$INSTALL_PLEX" == "true" ]
then
    echo "Plex"

	curl https://downloads.plex.tv/plex-keys/PlexSign.key | apt-key add -
	echo deb https://downloads.plex.tv/repo/deb public main | tee /etc/apt/sources.list.d/plexmediaserver.list
	apt update
	apt install plexmediaserver -y
	echo "Waiting for Plex to start:"
	
	sleep 10
	echo "Setting Plex permissions:"
	usermod -a -G $app_guid plex
	systemctl restart plexmediaserver
	
	PLEX_URL="http://$ip_local:32400"
fi

echo "----------------------------------------------------------------------------------"
echo " "
echo "Completed Installing Items"
echo " "
echo "Access Details:"
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
echo "	1. You will need to log into Radarr/Sonarr (if installed) and set a user, password, and auth req to 'not required for local'"
echo "	2. You will need to import existing media into Radarr/Sonarr"
echo "	3. Start Plex from the apps menu and setup the server (You will need to manually add the libraries)"
echo "  4. Mount the Shared folder on your windows/linux machine.