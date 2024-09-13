#!/bin/sh

sudo apt update
if ! dpkg -l | grep -q "^ii.*bluetooth"; then
    echo -e "\e[31mBluetooth is not installed. Installing...\e[0m"
    sudo apt update
    sudo apt install -y bluetooth bluez
else 
    echo -e "\e[31mBluetooth is already installed.\e[0m"
fi 

echo "\e[37;44mbash end\e[0m"