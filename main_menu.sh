#!/bin/bash

# Check if user is root
if [[ $EUID -ne 0 ]]; then
    zenity --error --text="This script must be run as root." 2>/dev/null
    exit 1
fi

# Function to display the main menu
main_menu() {
    choice=$(zenity --list --title="BIND9 DNS Server Management" --column="Action" \
        "Install / Uninstall BIND9"\
        "Show Current DNS Settings" \
        "Add DNS Setting" \
        "Remove DNS Setting"\
        "See BIND9 Logs" 2>/dev/null)

    case $choice in
        "Install / Uninstall BIND9")
            ./install_bind9.sh 
            ;;
        "Show Current DNS Settings")
            ./show_dns_settings.sh
            ;;
        "Add DNS Setting")
            ./add_dns_setting.sh
            ;;
        "Remove DNS Setting")
            ./remove_dns_setting.sh
            ;;
        "See BIND9 Logs")
            ./logs.sh
            ;;
        *)
            zenity --error --text="Action Canceled, Exiting dashboard." 2>/dev/null
            ;;
    esac
}

# Run the main menu
main_menu
