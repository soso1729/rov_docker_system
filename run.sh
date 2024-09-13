#!/bin/sh

sudo apt update
if ! dpkg -l | grep -q "^ii.*bluetooth"; then
    echo "Bluetooth is not installed. Installing..."
    sudo apt update
    sudo apt install -y bluetooth bluez
else 
    echo "Bluetooth is already installed."
fi 

echo "bash end"