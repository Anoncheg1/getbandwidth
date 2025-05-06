#!/bin/bash

# Allow two parameters: interface name and interval (in seconds).
# Defaults: interface "wlan0", interval 20 seconds.
intf="${1:-wlan0}"
interval="${2:-20}"
data_file="/tmp/bw_data_${intf}"

# Get the current timestamp and RX/TX values for the interface.
current_ts=$(date +%s)
current_rx=$(grep "$intf" /proc/net/dev | tr -s ' ' | cut -d ' ' -f3)
current_tx=$(grep "$intf" /proc/net/dev | tr -s ' ' | cut -d ' ' -f11)

# Append the current measurement (timestamp, RX, TX) to the persistent file.
echo "$current_ts $current_rx $current_tx" >> "$data_file"

# Prune any entries older than 20 seconds to keep the data file small.
awk -v ts="$current_ts" '$1 >= ts - 20' "$data_file" > "${data_file}.tmp" && mv -f "${data_file}.tmp" "$data_file"

# Determine the target timestamp from [interval] seconds ago.
target_ts=$(( current_ts - interval ))

# Find the most recent record whose timestamp is <= target_ts.
prev_line=$(awk -v target="$target_ts" '($1 <= target){line=$0} END{if(line) print line}' "$data_file")

# If a record with an appropriate timestamp isn't found…
if [ -z "$prev_line" ]; then
    if [ -s "$data_file" ]; then
        # Data exists in the file, so fall back to the oldest available record.
        prev_line=$(head -n 1 "$data_file")
        echo "Not enough historical data for a full $interval seconds interval. Using oldest available record." >&2
    else
        # No record exists at all; use current values so that bandwidth reads 0.
        prev_line="$current_ts $current_rx $current_tx"
        echo "No historical data available. Assuming 0 bandwidth." >&2
    fi
fi

# Extract previous timestamp, RX, and TX values from the selected record.
prev_ts=$(echo "$prev_line" | awk '{print $1}')
prev_rx=$(echo "$prev_line" | awk '{print $2}')
prev_tx=$(echo "$prev_line" | awk '{print $3}')

# Calculate the elapsed time.
delta_t=$(( current_ts - prev_ts ))
if [ $delta_t -eq 0 ]; then
    # If no time has elapsed, assume 0 bandwidth.
    avg_rx=0
    avg_tx=0
else
    # Calculate differences in RX and TX.
    delta_rx=$(( current_rx - prev_rx ))
    delta_tx=$(( current_tx - prev_tx ))
    # Compute average bandwidth values (bytes per second).
    avg_rx=$(( delta_rx / delta_t ))
    avg_tx=$(( delta_tx / delta_t ))
fi

function to_dashes() {
    local num=$1
    local UPPER_LIMIT=${2:-2500}  # Default to 50000 if second parameter not provided
    local dashes=""
    local count=0

    # Ensure input is within valid range
    if [[ ! $num =~ ^[0-9]+$ ]] || [ "$num" -lt 0 ] || [ "$num" -gt "$UPPER_LIMIT" ]; then
        echo "Error: Input must be a number between 0 and $UPPER_LIMIT" >&2
        return 1
    fi

    # Calculate number of dashes (each dash represents ~UPPER_LIMIT/9)
    count=$(( (num * 9 + UPPER_LIMIT/2) / UPPER_LIMIT ))
    # Count of 9-slashes
    acount=$(( 9 - count ))

    # Create string of dashes
    while [ $count -gt 0 ]; do
        dashes="${dashes}#"
        count=$((count - 1))
    done

    while [ $acount -gt 0 ]; do
        dashes="${dashes}_"
        acount=$((acount - 1))
    done

    echo "$dashes"
}

# Function to format the bandwidth into higher units when applicable.
format_bandwidth() {
    python3 -c "import sys
value = float(sys.argv[1])
if value < 1024:
    print(f'{value:.2f} bytes/s')
elif value < 1024*1024:
    print(f'{value/1024:.2f} KB/s')
elif value < 1024*1024*1024:
    print(f'{value/(1024*1024):.2f} MB/s')
else:
    print(f'{value/(1024*1024*1024):.2f} GB/s')
" "$1"
}

formatted_rx=$(format_bandwidth "$avg_rx")
formatted_tx=$(format_bandwidth "$avg_tx")

# - Output the current RX and TX.
# echo -e "$(($current_rx / 1024 / 1024))MB RX: $formatted_rx\tTX: $formatted_tx"

# - Output the "dashed" current RX and TX.
dashed_rx="$(to_dashes $avg_rx)"
dashed_tx="$(to_dashes $avg_tx)"
echo -e "$(($current_rx / 1024 / 1024))MB" RX:"$dashed_rx" TX:"$dashed_tx"
