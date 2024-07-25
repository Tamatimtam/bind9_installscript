#!/bin/bash

# Function to add new DNS setting
add_dns_setting() {
    local domain_name=$1
    local ip_address=$2

    # Add zone entry to named.conf.local
    sudo bash -c "echo 'zone \"$domain_name\" {
        type master;
        file \"/etc/bind/db.$domain_name\";
    };' >> /etc/bind/named.conf.local"

    # Add DNS records to domain zone file
    sudo bash -c "echo '\$ORIGIN $domain_name.
\$TTL    604800
@       IN      SOA     ns.$domain_name. root.$domain_name. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns.$domain_name.
ns      IN      A       $ip_address
@       IN      A       $ip_address
' >> /etc/bind/db.$domain_name"
}

# Function to validate IP address format
validate_ip_address() {
    local ip=$1
    # Regular expression to match IP address format
    local ip_regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"

    if [[ $ip =~ $ip_regex ]]; then
        # Check if each octet is in the range of 0-255
        local IFS='.'
        local octets=($ip)
        for octet in "${octets[@]}"; do
            if (( octet < 0 || octet > 255 )); then
                return 1  # Invalid IP address
            fi
        done
        return 0  # Valid IP address
    else
        return 1  # Invalid IP address format
    fi
}

# Prompt user for domain name and IP address
domain_name=$(zenity --entry --title="Add DNS Setting" --text="Enter the domain name:")
if [ -z "$domain_name" ]; then
    zenity --error --text="Domain name cannot be empty."
    exit 1
fi

ip_address=$(zenity --entry --title="Add DNS Setting" --text="Enter the IP address:")
if [ -z "$ip_address" ]; then
    zenity --error --text="aw."
    exit 1
fi

# Validate IP address format
if ! validate_ip_address "$ip_address"; then
    zenity --error --text="Invalid IP address format or range."
    exit 1
fi

# Add the new DNS setting
add_dns_setting "$domain_name" "$ip_address"

# Restart BIND9 to apply changes
sudo systemctl restart bind9
zenity --info --text="New DNS setting added and BIND9 restarted."

exit 0
