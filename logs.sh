##!/bin/bash
#
## Read the log file
#log_file="/var/log/named/named.log"
#
## Function to format log entries
#format_log() {
#  while IFS= read -r line; do
#    # Extract the date, time, and log level
#    date_time=$(echo "$line" | cut -d' ' -f1-2)
#    log_level=$(echo "$line" | cut -d' ' -f3 | cut -d':' -f1)
#    message=$(echo "$line" | cut -d':' -f4- | sed 's/^[ \t]*//')
#
#    # Format the log entry
#    echo "DATE/TIME:\t$date_time\nLEVEL:\t\t$log_level\nMESSAGE:\t$message\n\n"
#  done < "$log_file"
#}
#
## Format the log entries and save to a temporary file
#formatted_log=$(format_log)
#formatted_log_file=$(mktemp)
#echo -e "$formatted_log" > "$formatted_log_file"
#
## Display the formatted log using Zenity
#zenity --text-info --filename="$formatted_log_file" --width=800 --height=600 --title="BIND9 Log"
#
## Clean up temporary file
#rm "$formatted_log_file"
#
#./main_menu.sh

# DISPLAY LOGS FOR THE LAST 24 HOURS ONLY

# Define the log file and temporary formatted log file
log_file="/var/log/named/named.log"
formatted_log_file=$(mktemp)

# Get the current date and time minus 24 hours
end_time=$(date +"%Y-%m-%d %H:%M:%S")
start_time=$(date --date='24 hours ago' +"%Y-%m-%d %H:%M:%S")

# Print debugging information
echo "End time: $end_time"
echo "Start time: $start_time"

# Function to format log entries
format_log() {
  while IFS= read -r line; do
    # Extract the date and time from the log entry
    date_time=$(echo "$line" | cut -d' ' -f1-2)
    
    # Debugging output
    echo "Processing line: $line"
    echo "Extracted date_time: $date_time"

    # Check if the log entry is within the last 24 hours
    if [[ "$date_time" > "$start_time" && "$date_time" < "$end_time" ]]; then
      # Extract the log level and message
      log_level=$(echo "$line" | cut -d' ' -f3 | cut -d':' -f1)
      message=$(echo "$line" | cut -d':' -f4- | sed 's/^[ \t]*//')

      # Format the log entry
      echo "DATE/TIME:\t$date_time\nLEVEL:\t\t$log_level\nMESSAGE:\t$message\n\n"
    fi
  done < "$log_file"
}

# Format the log entries from the last 24 hours and save to a temporary file
formatted_log=$(format_log)
echo -e "$formatted_log" > "$formatted_log_file"

# Check if the temporary file contains data
if [[ -s "$formatted_log_file" ]]; then
  # Display the formatted log using Zenity
  zenity --text-info --filename="$formatted_log_file" --width=800 --height=600 --title="BIND9 Log"
else
  zenity --info --text="No log entries found for the last 24 hours."
fi

# Clean up temporary file
rm "$formatted_log_file"

# Run the main menu script
./main_menu.sh

