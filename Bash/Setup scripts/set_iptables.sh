#!/usr/bin/env bash

# This standalone iptables script is to
# update the firewall in the future.

## Pre-set variables
green=$( tput setaf 2 )
reset=$( tput sgr0 )

## Start functions
# Configure iptables
set_filter(){
    cat <<EOF
    *basic
    # Set default policy
    :INPUT    DROP
    :OUTPUT   ACCEPT
    :FORWARD  DROP
    # Allow on localhost
    -A INPUT  -i lo -j ACCEPT
    -A OUTPUT -o lo -j ACCEPT
    # Allow related and established
    -A INPUT   -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    -A OUTPUT  -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    # Drop invalid
    -A INPUT   -m conntrack --ctstate INVALID -j DROP
    -A OUTPUT  -m conntrack --ctstate INVALID -j DROP
    # Allow ssh
    -A INPUT -i eth0 -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT
    COMMIT
EOF
}
# Enable and set iptables
printf "Configuring firewall ..."; set_filter | iptables-restore &>/dev/null
printf %s\\n "$green done $reset"

comment(){
    while true; do
        read -rp "What type of traffic would you like to let in through the firewall (example: ssh nfs cifs )? "
        if case $REPLY ''|*[!0-9]*) false && printf %s\\n "Please enter a valid answer (example: ssh nfs cifs 22 2049).;; *) true;; esac; then
            case $REPLY in
                *"ssh"*);;
                *"nfs"*);;
                *"cifs"*);;
                *"ssh"*);;
                *"ssh"*);;
                *"ssh"*);;
                *"ssh"*);;
                *"ssh"*);;
                *"ssh"*);;
            esac
        done
    }
