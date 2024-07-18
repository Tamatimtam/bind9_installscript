#!/bin/bash

# Initialize variables
data=""
counter=1

# Parse BIND9 configuration to get zone names
zones=$(grep '^zone "' /etc/bind/named.conf.local | sed 's/.*zone "\(.*\)".*/\1/')

# Iterate over each zone
for zone in $zones; do
    # Read DNS settings from zone file
    if [ -f "/etc/bind/db.$zone" ]; then
        # Extract IP address from the zone file
        ip=$(awk '/^\s*@?\s*IN\s*A\s+/{print $NF}' "/etc/bind/db.$zone" | head -n 1)
        
        # Format data for displays
        data+=" $counter $zone $ip"
        ((counter++))
    fi
done

# Display data in a formatted table using zenity
choice=$(zenity --list --width=600 --height=400 --title="DNS Settings" --column="No" --column="Domain" --column="IP" \
        $data  --ok-label="Edit" --cancel-label="Back")

# Check user choice and execute corresponding script
case $? in
    0) # Edit was chosen
        # Execute add_dns_setting.sh
        ./add_dns_setting.sh ;;
    1) # Back was chosen
        # Execute main_menu.sh
        ./main_menu.sh ;;
    -1) # Dialog was closed
        echo "Dialog closed." ;;
esac