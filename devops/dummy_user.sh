#!/bin/bash

# Define color variables
RED='\033[0;31m'
RESET='\033[0m' # Reset color to default

# Create udev rules
detect_devices='SUBSYSTEMS=="usb", IMPORT{builtin}="usb_id"'
sudo -u root echo $detect_devices >> /etc/udev/rules.d/96-wattrex.rules
sudo -u root echo "" >> /etc/udev/rules.d/96-wattrex.rules
sudo -u root echo "# Detect BK" >> /etc/udev/rules.d/96-wattrex.rules
detect_devices='KERNEL=="ttyUSB*", ENV{ID_MODEL}=="2831E_Multimeter", SYMLINK+="wattrex/bk/BK_$env{ID_SERIAL_SHORT}", GROUP="wattrex", MODE="0660", GOTO="label_end"'
sudo -u root echo $detect_devices >> /etc/udev/rules.d/96-wattrex.rules
sudo -u root echo "" >> /etc/udev/rules.d/96-wattrex.rules
sudo -u root echo "# Detect Source" >> /etc/udev/rules.d/96-wattrex.rules
detect_devices='KERNEL=="ttyACM*", ATTRS{manufacturer}=="EA*", ATTRS{product}=="PS*", SYMLINK+="wattrex/source/EA_$env{ID_SERIAL_SHORT}", GROUP="wattrex", MODE="0660", GOTO="label_end"'
sudo -u root echo $detect_devices >> /etc/udev/rules.d/96-wattrex.rules
sudo -u root echo "" >> /etc/udev/rules.d/96-wattrex.rules
sudo -u root echo "# Detect BiSource" >> /etc/udev/rules.d/96-wattrex.rules
detect_devices='KERNEL=="ttyACM*", ATTRS{manufacturer}=="EPS*", ATTRS{product}=="PSB*", SYMLINK+="wattrex/bisource/EPS_$env{ID_SERIAL_SHORT}", GROUP="wattrex", MODE="0660", GOTO="label_end"'
sudo -u root echo $detect_devices >> /etc/udev/rules.d/96-wattrex.rules
sudo -u root echo "" >> /etc/udev/rules.d/96-wattrex.rules
sudo -u root echo "# Detect Loads" >> /etc/udev/rules.d/96-wattrex.rules
detect_devices='KERNEL=="ttyACM*", ATTRS{manufacturer}=="nuvoton", ATTRS{product}=="KORAD USB Mode", SYMLINK+="wattrex/loads/RS_$env{ID_SERIAL_SHORT}", GROUP="wattrex", MODE="0660", GOTO="label_end"'
sudo -u root echo $detect_devices >> /etc/udev/rules.d/96-wattrex.rules
sudo -u root echo "" >> /etc/udev/rules.d/96-wattrex.rules
sudo -u root echo "# Detect Flowmeter in arduino" >> /etc/udev/rules.d/96-wattrex.rules
detect_devices='KERNEL=="ttyACM*", ATTRS{manufacturer}=="Arduino*", SYMLINK+="wattrex/arduino_$env{ID_SERIAL_SHORT}", GOTO="label_end"'
sudo -u root echo $detect_devices >> /etc/udev/rules.d/96-wattrex.rules
sudo -u root echo "" >> /etc/udev/rules.d/96-wattrex.rules
sudo -u root echo 'LABEL="label_end"' >> /etc/udev/rules.d/96-wattrex.rules

# Reload udev rules
sudo -u root udevadm control --reload && sudo -u root udevadm trigger

echo -e "${RED}UDEV RULES DONE${RESET}"
# Set static ip
ip_conf="interface wlan0"
sudo -u root echo $ip_conf >> /etc/dhcpcd.conf
ip_conf="static ip_address=10.15.2.${1}/24"
sudo -u root echo $ip_conf >> /etc/dhcpcd.conf
ip_conf="static routers=10.15.2.65"
sudo -u root echo $ip_conf >> /etc/dhcpcd.conf
ip_conf="static domain_name_servers=192.168.1.254 8.8.8.8"
sudo -u root echo $ip_conf >> /etc/dhcpcd.conf

echo -e "${RED}STATIC IP DONE${RESET}"
# Install python and pip
sudo -u root apt-get update
sudo -u root apt-get upgrade -y
sudo -u root apt-get install -y python3 python3-pip
echo -e "${RED}PYTHON AND PIP INSTALLED${RESET}"
# Install screen
sudo -u root apt-get install -y screen
echo -e "${RED}SCREEN INSTALLED${RESET}"
# Install docker
sudo -u root curl -fsSL https://get.docker.com -o get-docker.sh
sudo -u root sh get-docker.sh

echo -e "${RED}DOCKER INSTALLED${RESET}"
# Create user, group and change password
sudo -u root groupadd -g 69976 wattrex
sudo -u root useradd -u 69976 -g wattrex wattrex
sudo -u root mkhomedir_helper wattrex
echo -e "${RED}NEW PASSWORD FOR WATTREX USER${RESET}"
sudo -u root passwd wattrex

# Add new user to docker group
sudo -u root usermod -aG docker wattrex

echo -e "${RED}DEVICE WILL REBOOT NOW${RESET}"
sudo -u root reboot now