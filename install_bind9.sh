#!/bin/bash

# Function to check if BIND9 is installed
check_bind9_installed() {
    dpkg -l | grep bind9 > /dev/null 2>&1
    return $?
}

# Function to uninstall BIND9 and remove configuration files
uninstall_bind9() {
    sudo systemctl stop bind9
    sudo apt-get purge -y bind9 bind9utils bind9-doc
    sudo apt-get autoremove -y
    sudo rm -rf /etc/bind
}

# Function to install BIND9
install_bind9() {
    sudo apt install bind9
}

# Function to configure forwarders and other settings
configure_forwarders() {
    # Backup existing configurations
    sudo cp /etc/bind/named.conf.options /etc/bind/named.conf.options.bak
    sudo cp /etc/bind/named.conf /etc/bind/named.conf.bak

    # Configure named.conf.options
    sudo tee /etc/bind/named.conf.options > /dev/null <<EOF
options {
    directory "/var/cache/bind";

    forwarders {
        1.1.1.1; # cloudflare DNS
	8.8.8.8; # google public DNS
    };

    dnssec-validation auto;
    listen-on-v6 { any; };

    rate-limit { 
        responses-per-second 5; 
        window 5; 
    };
};
EOF

    # Configure named.conf
    sudo tee /etc/bind/named.conf > /dev/null <<EOF
include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
include "/etc/bind/named.conf.default-zones";

// Logging configuration
logging {
    channel default_log {
        file "/var/log/named/named.log" versions 3 size 5M;
        severity info;
        print-time yes;
        print-severity yes;
        print-category yes;
    };
    category default { default_log; };
    category security { default_log; };
};
EOF
}

# Function to set local nameserver to 127.0.0.1
configure_resolv_conf() {
    echo -e "nameserver 127.0.0.1\nnameserver 1.1.1.1" | sudo tee /etc/resolv.conf > /dev/null
}

# Check if BIND9 is installed and notify user
if check_bind9_installed; then
    zenity --question --text="BIND9 is already installed. Do you want to reinstall it? This will remove all previous configurations." --title="Reinstall BIND9" --ok-label="Yes, reinstall" --cancel-label="No, cancel"
    response=$?
    if [ $response -eq 0 ]; then
        zenity --info --text="Uninstalling BIND9..."
        uninstall_bind9 | zenity --progress --title="Uninstalling BIND9" --pulsate --auto-close --no-cancel
    else
        zenity --info --text="No action taken."
        exit 0
    fi
else
    zenity --info --text="BIND9 is not installed."
fi

# Install BIND9
zenity --info --text="Installing BIND9..."
install_bind9 | zenity --progress --title="Installing BIND9" --pulsate --auto-close --no-cancel

# Ensure the log directory exists and has correct permissions
sudo mkdir -p /var/log/named
sudo chown bind:bind /var/log/named
sudo chmod 750 /var/log/named

# Ensure the log file exists and has correct permissions
sudo touch /var/log/named/named.log
sudo chown bind:bind /var/log/named/named.log
sudo chmod 640 /var/log/named/named.log

# Configure default forwarders
configure_forwarders

# Set local nameserver to 127.0.0.1
configure_resolv_conf

# Restart BIND9
sudo systemctl daemon-reload
sudo systemctl enable named
sleep 3
sudo systemctl start bind9.service
sudo systemctl status bind9.service

zenity --info --text="BIND9 installation complete."
