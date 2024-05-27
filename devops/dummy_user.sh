#!/bin/bash
CS_VERSION=$(cat /proc/cpuinfo | grep -q "Raspberry Pi Zero W Rev 1.1")
# Define color variables
RED='\033[0;31m'
RESET='\033[0m' # Reset color to default
archivo="/etc/udev/rules.d/96-wattrex.rules"
if [ -f "$archivo" ]; then
    echo -e "${RED}CONFIGURATION ALREADY DONE${RESET}"
    echo -e "${RED}PLEASE LOG IN WITH WATTREX USER${RESET}"
    exit 1
else
        # Create udev rules
    detect_devices="SUBSYSTEMS==\"usb\", IMPORT{builtin}=\"usb_id\"

# Detect BK
KERNEL==\"ttyUSB*\", ENV{ID_MODEL}==\"2831E_Multimeter\", SYMLINK+=\"wattrex/bk/BK_\$env{ID_SERIAL_SHORT}\", GROUP=\"wattrex\", MODE=\"0660\", GOTO=\"label_end\"

# Detect Source
KERNEL==\"ttyACM*\", ATTRS{manufacturer}==\"EA*\", ATTRS{product}==\"PS*\", SYMLINK+=\"wattrex/source/EA_\$env{ID_SERIAL_SHORT}\", GROUP=\"wattrex\", MODE=\"0660\", GOTO=\"label_end\"

# Detect BiSource
KERNEL==\"ttyACM*\", ATTRS{manufacturer}==\"EPS*\", ATTRS{product}==\"PSB*\", SYMLINK+=\"wattrex/bisource/EPS_\$env{ID_SERIAL_SHORT}\", GROUP=\"wattrex\", MODE=\"0660\", GOTO=\"label_end\"

# Detect Loads
KERNEL==\"ttyACM*\", ATTRS{manufacturer}==\"nuvoton\", ATTRS{product}==\"KORAD USB Mode\", SYMLINK+=\"wattrex/loads/RS_\$env{ID_SERIAL_SHORT}\", GROUP=\"wattrex\", MODE=\"0660\", GOTO=\"label_end\"

# Detect Arduino
KERNEL==\"ttyACM*\", ATTRS{manufacturer}==\"Arduino*\", SYMLINK+=\"wattrex/arduino_\$env{ID_SERIAL_SHORT}\", GOTO=\"label_end\"

LABEL=\"label_end\"
"
    sudo -u root echo "$detect_devices" >> /etc/udev/rules.d/96-wattrex.rules

    # Reload udev rules
    sudo -u root udevadm control --reload && sudo -u root udevadm trigger

    echo -e "${RED}UDEV RULES DONE${RESET}"
    # Configure wifi
    sudo -u root head -n 2 /etc/wpa_supplicant/wpa_supplicant.conf > temp.conf
    sudo -u root mv temp.conf /etc/wpa_supplicant/wpa_supplicant.conf
    wpa="network={
	ssid=\"LIFTEC-BFR50-E\"
	psk=\"Iuchaeph9d\"
	priority=5
}

network={
	ssid=\"dlink-CE4E\"
	psk=\"kpjja63799\"
	priority=2
}"
    sudo -u root echo "$wpa" >> /etc/wpa_supplicant/wpa_supplicant.conf
    # Set static ip
    ip_conf="ssid LIFTEC-BFR50-E"
    sudo -u root echo $ip_conf >> /etc/dhcpcd.conf
    ip_conf="static ip_address=10.15.2.${1}/24"
    sudo -u root echo $ip_conf >> /etc/dhcpcd.conf
    ip_conf="static routers=10.15.2.65"
    sudo -u root echo $ip_conf >> /etc/dhcpcd.conf
    ip_conf="static domain_name_servers=192.168.1.254 8.8.8.8"
    sudo -u root echo $ip_conf >> /etc/dhcpcd.conf
    
    # Set static ip
    ip_conf="ssid dlink-CE4E"
    sudo -u root echo $ip_conf >> /etc/dhcpcd.conf
    ip_conf="static ip_address=172.16.0.${1}/24"
    sudo -u root echo $ip_conf >> /etc/dhcpcd.conf
    ip_conf="static routers=172.16.0.1"
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
    export PATH=/home/wattrex/.local/bin:$PATH

    # Add crontab
    sudo -u root sed -i '$d' /etc/rc.local
    sudo -u root echo "sudo sh -c 'echo 400 > /proc/sys/fs/mqueue/msg_max'" >> /etc/rc.local
    sudo -u root echo "sudo sh -c 'echo 900 > /proc/sys/fs/mqueue/msgsize_max'" >> /etc/rc.local
    sudo -u root echo "exit 0" >> /etc/rc.local
    sudo -u root loginctl enable-linger wattrex
    sudo -u root echo "KillUserProcesses=no" >> /etc/systemd/logind.conf
    # Add scpi and can0 configuration
    if ! $CS_VERSION; then 
        interface_conf="dtparam=spi=on
dtoverlay=w5500,cs=1,int_pin=6
dtparam=i2c_arm=on
dtoverlay=i2c-rtc,ds3231
dtoverlay=mcp2515-can0,interrupt=5,oscillator=20000000
dtoverlay=sc16is752-spi1,int_pin=22,xtal=14745600
enable_uart=1
dtoverlay=mcp23017,noints,mcp23008,addr=0x20
dtoverlay=mcp23017,noints,mcp23008,addr=0x21
dtoverlay=i2c-pwm-pca9685a,addr=0x40
dtoverlay=i2c-pwm-pca9685a,addr=0x41
dtoverlay=ads1015,addr=0x48
dtparam=cha_enable=true,cha_gain=1
dtparam=chb_enable=true,chb_gain=1
dtparam=chc_enable=true,chc_gain=1
dtparam=chd_enable=true,chd_gain=1
dtoverlay=ads1015,addr=0x49
dtparam=cha_enable=true,cha_gain=1
dtparam=chb_enable=true,chb_gain=1
dtparam=chc_enable=true,chc_gain=1
dtparam=chd_enable=true,chd_gain=1
dtoverlay=ads1015,addr=0x4a
dtparam=cha_enable=true,cha_gain=1
dtparam=chb_enable=true,chb_gain=1
dtparam=chc_enable=true,chc_gain=1
dtparam=chd_enable=true,chd_gain=1
dtoverlay=ads1015,addr=0x4b
dtparam=cha_enable=true,cha_gain=1
dtparam=chb_enable=true,chb_gain=1
dtparam=chc_enable=true,chc_gain=1
dtparam=chd_enable=true,chd_gain=1"
        sudo -u root echo $interface_conf >> /boot/config.txt
    fi
    echo -e "${RED}DEVICE WILL REBOOT NOW${RESET}"
    sudo -u root reboot now
fi
