#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 
fi
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
CYAN=$(tput setaf 6)
RED=$(tput setaf 1)
RESET=$(tput sgr0)

mkdir /root/wui-dds

cd /root/wui-dds


ln -s "$(pwd)/wui.sh" /usr/local/bin/wui-dds
echo "${GREEN}Installation completed. You can now use ${RESET}${RED} wui-dds ${RESET} command.${RESET}"

chmod +x wui.sh
sudo bash wui.sh

