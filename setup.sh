#!/bin/bash

# Check if the script is run by the root user (EUID 0)
if [ "$EUID" -ne 0 ]; then
    echo "Error: This setup script must be run as the root user."
    exit 1
fi

# Step 1: Update apt repository
echo -n " Updating apt repository ..."
apt update &> /dev/null  # Run apt update and suppress output
if [ $? -eq 0 ]; then
    echo "ok"
else
    echo " ... Failed"
    echo -n "Error: Unable to update apt repository. Please check your internet connection and try again."
    exit 1
fi

# Step 2: Install required packages
echo -n " Installing required packages ..."
apt install -y figlet dsniff netdiscover &> /dev/null  # Install packages and suppress output
if [ $? -eq 0 ]; then
    echo "ok"
else
    echo " ... Failed"
    echo -n "Error: Unable to install required packages. Please check your internet connection and try again."
    exit 1
fi

# Step 3: Make fastmitm.sh executable
echo -n " Making fastmitm.sh executable ..."
chmod +x fastmitm.sh
if [ $? -eq 0 ]; then
    echo "ok"
else
    echo " ... Failed"
    echo -n "Error: Unable to make fastmitm.sh executable. Please check file permissions."
    exit 1
fi

# Step 4: Setup completed
echo -e -n  "Setup is completed.\nYou can now use 'sudo ./fastmitm.sh' to start the tool.\n"
