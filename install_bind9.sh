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
    sudo apt install -y bind9
}

# Function to configure default forwarders
configure_forwarders() {
   sudo tee /etc/bind/named.conf.options > /dev/null <<EOF
options {
    directory "/var/cache/bind";

    // If there is a firewall between you and nameservers you want
    // to talk to, you may need to fix the firewall to allow multiple
    // ports to talk.  See http://www.kb.cert.org/vuls/id/800113

    // If your ISP provided one or more IP addresses for stable 
    // nameservers, you probably want to use them as forwarders.  
    // Uncomment the following block, and insert the addresses replacing 
    // the all-0's placeholder.

    forwarders {
        1.1.1.1;
    };

    //========================================================================
    // If BIND logs error messages about the root key being expired,
    // you will need to update your keys.  See https://www.isc.org/bind-keys
    //========================================================================
    dnssec-validation auto;

    listen-on-v6 { any; };
};
EOF
}

# Function to set local nameserver to 127.0.0.1
configure_resolv_conf() {
    {
        echo "nameserver 127.0.0.1"
        echo "nameserver 8.8.8.8"
        echo "nameserver 1.1.1.1"
    } | sudo tee /etc/resolv.conf > /dev/null
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

# Configure default forwarders
configure_forwarders

# Set local nameserver to 127.0.0.1
configure_resolv_conf

sudo systemctl daemon-reload
sudo systemctl enable named
sleep 3
# Restart BIND9
sudo systemctl start bind9.service
sudo systemctl status bind9.service

zenity --info --text="BIND9 installation complete."
