#!/bin/bash
source "secrets.sh"

#Variables
ZT_TOKEN=$ZT_TOKEN
NWID=$NWID

WIN_HOST=192.168.194.1
WIN_SHARES=( D E F G )
WIN_USER=$WIN_USER
WIN_PASS=$WIN_PASS

EXTENSION_LIST=( https://extensions.gnome.org/extension/1160/dash-to-panel/
 https://extensions.gnome.org/extension/1460/vitals/
 https://extensions.gnome.org/extension/3628/arcmenu/
 https://extensions.gnome.org/extension/1319/gsconnect/
 https://extensions.gnome.org/extension/3843/just-perfection/)

EXTENSION_SETTINGS='H4sIAAAAAAAAA+1VS2/bRhC+81cYvDABtIrkOglqlIXsxAehUiw4QoHCEIIlOSQ3Wu4Iu0M9avi/d5akFMsxikDpsaclZ+e1M983c/9mEWTKyURDJmBLYJxC4+L7qE5qQ7XIMF2O2u9+ilW0CMC8oC1tWoGpR93ZqPbOoky6UhCKlTSgR18zsOjg136hqKyTvVLhUjQGUhpJk+1K1BW4vYpCr/G1diRWYHNW4oAiA7ckXI2eyb3qn4qkdqMPaOEDZsoUXda5XKNVBEKuVj7hXFnIcfulO/udS+8CbdEvDFbQ/yRrUrp2L9/OwVbKSH24XQQb0BwORKakxkJoyfm5EjdGrMH6WsXRxbv+IAqC+2/le+PTXARpCelSbIfDjdxprkRMtoZjRU6GVYV0TjmShhaB5IevQWyUyXAjSmVIpKjRxpEtklfnw2Hv/aB3PnwdBU0uXRZCGbbX3MX44l2ALLUqy8AIB0QcwcUPT95Z1URg+5AVINoMosuz30ZVcmaQOGTx+1FZOvUl7BLOynvrExaFbowZNxpy+ikHVhXldx4ejyvV4ZDBDbmsNQn/J9YKNnF0pfWXmcXCyspFQXORcEguC2MDpJUmhTgaMyijYMXocGznFGOeYVxAPAgcK6WlAEN2JxK0DGthZaZqF7/yTeudnb99Hfi+NySxjBGG7Fql4F5o6hFHuKNGVbLFqeIUROnbI1qpb11jSdygu/FsNrnhOlxw9WaTq09/dN+fx9P2YvgY7L1U0hbKxBcHwUpmvrRespZKe0qLCo0itEyPARcOmVroFDWovb6dz2+nUVAicV+c8ElpuWOwVQnG0fxmOru9u7obT/5ipHGDE9weQohh0LyNH5GW3n30EA7Cy3A6/vhxchM+Rt01aOBmfIu6V7x/CLsrNvJVvWIKXzcdC3th15vwMmfeQy/cW3tdkukSsvkkfOw99dGQhpXgp7z4Z17j9qlx0/wfsSXplom0J9mmfID9wcjXd8+sG/Kcaux2jqCaMmNOMs8Y16cbt0P2+479m4fFAVwaTEHlHlLDweBw49TfsJf/cu7FlrnGzO7o4AlPkmonjojDqCbLDHjy301hnhl+0PC0Ij8zDhya386eDf5n+4t3gOZ1286qg93gJanAPOdhzZf/b+//bHu3eOh2QdfXBh5c5tM2+7p5z6LdBYn0e23XroBGkksTNwOn/V2jJr9hGoV/AHAM7teaCQAA'

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1

add-apt-repository multiverse -y
apt update
apt upgrade -y

apt install curl nano build-essential openssh-server git python3-pip pipx python3-dev htop bmon flatpak net-tools dbus-x11 gnome-software-plugin-flatpak gnome-shell-extension-manager piper gir1.2-gtop-2.0 lm-sensors gnome-tweaks cifs-utils ntfs-3g gparted -y

VERSION=$(lsb_release -a | grep "Release" | cut -d ':' -f 2 | xargs | cut -d '.' -f 1)

if [ "$VERSION" -gt 22 ]; then
        dpkg --add-architecture i386
        apt update
        apt install steam-installer -y
else
        apt install steam -y
fi

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

#Shell Extensions
apt install gnome-menus

for i in "${EXTENSION_LIST[@]}"
do
    EXTENSION_ID=$(curl -s $i | grep -oP 'data-uuid="\K[^"]+')
    VERSION_TAG=$(curl -Lfs "https://extensions.gnome.org/extension-query/?search=$EXTENSION_ID" | jq '.extensions | map(select(.uuid=="'$EXTENSION_ID'")) | .[0].shell_version_map | map(.pk) | max')

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
	   cat /home/$SUDO_USER/extension_settings.conf | dconf load /org/gnome/shell/
EOF

    rm /home/$SUDO_USER/extension_settings.conf
fi

echo "Script done. You will have to restart to apply the changes"