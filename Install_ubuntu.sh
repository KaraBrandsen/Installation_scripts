#!/bin/bash
source "secrets.sh"

#Variables
ZT_TOKEN=$ZT_TOKEN
NWID=$NWID
WIN_USER=$WIN_USER
WIN_PASS=$WIN_PASS

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

add-apt-repository multiverse -y
apt update
apt upgrade -y

apt install curl nano build-essential openssh-server git python3-pip pipx python3-dev htop flatpak net-tools gnome-software-plugin-flatpak gnome-shell-extension-manager steam piper gir1.2-gtop-2.0 lm-sensors gnome-tweaks cifs-utils gparted -y

snap install --classic code


#Zerotier Setup
curl -s https://install.zerotier.com | bash
zerotier-cli join $NWID

MEMBER_ID=$(zerotier-cli info | cut -d " " -f 3)

curl -H "Authorization: token $ZT_TOKEN" -X POST "https://api.zerotier.com/api/v1/network/$NWID/member/$MEMBER_ID" --data '{"config": {"authorized": true}, "name": "'"${HOSTNAME}"'"}'


#Flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 

flatpak install flathub com.google.Chrome com.discordapp.Discord org.videolan.VLC com.spotify.Client org.gimp.GIMP org.libreoffice.LibreOffice io.github.mimbrero.WhatsAppDesktop org.signal.Signal org.inkscape.Inkscape com.slack.Slack com.adobe.Reader com.skype.Client tv.plex.PlexDesktop cc.arduino.IDE2 org.raspberrypi.rpi-imager com.ultimaker.cura io.github.prateekmedia.appimagepool org.kicad.KiCad org.gnome.meld org.qbittorrent.qBittorrent com.notepadqq.Notepadqq org.wireshark.Wireshark us.zoom.Zoom -y

#Windows Shares
mkdir /media/D
mkdir /media/E
mkdir /media/F
mkdir /media/G

#echo -e "//192.168.194.1/D  /media/D  cifs username=$WIN_USER,password=$WIN_PASS,iocharset=utf8  0  0" >> /etc/fstab

#echo -e "//192.168.194.1/E  /media/E  cifs username=$WIN_USER,password=$WIN_PASS,iocharset=utf8  0  0" >> /etc/fstab

#echo -e "//192.168.194.1/F  /media/F  cifs username=$WIN_USER,password=$WIN_PASS,iocharset=utf8  0  0" >> /etc/fstab

#echo -e "//192.168.194.1/G  /media/G  cifs username=$WIN_USER,password=$WIN_PASS,iocharset=utf8  0  0" >> /etc/fstab

#mount -a

#Shell Extensions
#array=( https://extensions.gnome.org/extension/1160/dash-to-panel/
#https://extensions.gnome.org/extension/1460/vitals/
#https://extensions.gnome.org/extension/3628/arcmenu/
#https://extensions.gnome.org/extension/1319/gsconnect/
#https://extensions.gnome.org/extension/3843/just-perfection/)
#
#for i in "${array[@]}"
#do
#    EXTENSION_ID=$(curl -s $i | grep -oP 'data-uuid="\K[^"]+')
#   VERSION_TAG=$(curl -Lfs "https://extensions.gnome.org/extension-query/?search=$EXTENSION_ID" | jq '.extensions[0] | .shell_version_map | map(.pk) | max')
#   wget -O ${EXTENSION_ID}.zip "https://extensions.gnome.org/download-extension/${EXTENSION_ID}.shell-extension.zip?version_tag=$VERSION_TAG"
#    gnome-extensions install --force ${EXTENSION_ID}.zip
#    if ! gnome-extensions list | grep --quiet ${EXTENSION_ID}; then
#        busctl --user call org.gnome.Shell.Extensions /org/gnome/Shell/Extensions org.gnome.Shell.Extensions InstallRemoteExtension s ${EXTENSION_ID}
#    fi
#    gnome-extensions enable ${EXTENSION_ID}
#    rm ${EXTENSION_ID}.zip
#done
