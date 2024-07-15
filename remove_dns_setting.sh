#!/bin/bash

# Function to check if domain exists in named.conf.local
check_domain_exists() {
    local domain_name=$1

    grep -q "zone \"$domain_name\"" /etc/bind/named.conf.local
    return $?
}

# Function to remove DNS setting
remove_dns_setting() {
    local domain_name=$1

    sudo sed -i "/zone \"$domain_name\"/,/};/d" /etc/bind/named.conf.local
    sudo rm -f /etc/bind/db.$domain_name
}

# Loop to prompt user until a valid domain name is entered
while true; do
    # Prompt user for domain name
    domain_name=$(zenity --entry --title="Remove DNS Setting" --text="Enter the domain name to remove:")

    # Check if domain exists in named.conf.local
    if check_domain_exists "$domain_name"; then
        # Prompt user to confirm removal
        zenity --question --text="Domain '$domain_name' found in named.conf.local. Remove?" --title="Confirm Removal" --ok-label="Yes, remove" --cancel-label="No, cancel"
        response=$?
        if [ $response -eq 0 ]; then
            # Remove the DNS setting
            remove_dns_setting "$domain_name"

            # Restart BIND9 to apply changes
            sudo systemctl restart bind9
            zenity --info --text="DNS setting for '$domain_name' removed and BIND9 restarted."
            break
        else
            zenity --info --text="No action taken."
            exit 0
        fi
    else
        # Domain not found, prompt user to input again
        zenity --error --text="Domain '$domain_name' not found in named.conf.local. Please enter a valid domain name."
    fi
done
