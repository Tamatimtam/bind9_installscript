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

# Function to display the list of DNS settings
display_dns_list() {
    grep -oP '(?<=zone ")[^"]*' /etc/bind/named.conf.local
}

# Function to display the remove DNS menu and return to main menu if cancelled
remove_dns_menu() {
    # Display list of DNS settings
    dns_list=$(display_dns_list)
    domain_name=$(zenity --list --title="Remove DNS" --column="Available DNS Domains" $dns_list --height=300 --width=400)

    # Check if a domain was selected
    if [ -n "$domain_name" ]; then
        # Prompt user to confirm removal
        zenity --question --text="Domain '$domain_name' found in named.conf.local. Remove?" --title="Confirm Removal" --ok-label="Yes, remove" --cancel-label="No, cancel" 2>/dev/null
        response=$?
        if [ $response -eq 0 ]; then
            # Remove the DNS setting
            remove_dns_setting "$domain_name"

            # Restart BIND9 to apply changes
            sudo systemctl restart bind9
            zenity --info --text="DNS setting for '$domain_name' removed and BIND9 restarted." 2>/dev/null
        else
            zenity --info --text="No action taken. Returning to main menu." 2>/dev/null
        fi
    else
        # Domain not selected, return to main menu
        zenity --error --text="No domain selected. Returning to main menu." 2>/dev/null
    fi
    # Call the main menu after finishing
    ./main_menu.sh
}

# Call the remove DNS menu function
remove_dns_menu
