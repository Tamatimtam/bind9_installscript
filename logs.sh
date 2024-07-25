#!/bin/bash

# Read the log file
log_file="/var/log/named/named.log"

# Function to format log entries
format_log() {
  while IFS= read -r line; do
    # Extract the date, time, and log level
    date_time=$(echo "$line" | cut -d' ' -f1-2)
    log_level=$(echo "$line" | cut -d' ' -f3 | cut -d':' -f1)
    message=$(echo "$line" | cut -d':' -f4- | sed 's/^[ \t]*//')

    # Format the log entry
    echo "DATE/TIME:\t$date_time\nLEVEL:\t\t$log_level\nMESSAGE:\t$message\n\n"
  done < "$log_file"
}

# Format the log entries and save to a temporary file
formatted_log=$(format_log)
formatted_log_file=$(mktemp)
echo -e "$formatted_log" > "$formatted_log_file"

# Display the formatted log using Zenity
zenity --text-info --filename="$formatted_log_file" --width=800 --height=600 --title="BIND9 Log"

# Clean up temporary file
rm "$formatted_log_file"

./main_menu.sh