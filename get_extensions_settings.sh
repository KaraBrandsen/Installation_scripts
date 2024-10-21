#!/bin/bash

if [ "$EUID" -lt 0 ]
  then echo "Please DO NOT run as root"
  exit
fi

echo "Getting current settings"

EXTENSION_SETTINGS=$(dconf dump /org/gnome/ | gzip | base64 -w0)

echo "Paste this line in the installation script"
echo ""
echo "$EXTENSION_SETTINGS"