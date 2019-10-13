#!/usr/bin/env bash

# This script pulls new docker container images
# and lists any images that have been updated,
# it will then ask if you'd like to upgrade any
# existing containers with the new images.

blue=$( tput setaf 14 )
green=$( tput setaf 2 )
red=$( tput setaf 1 )
reset=$( tput sgr0 )
tmpdir=$( mktemp -d -t tmp.XXXXXXX )
yellow=$( tput setaf 11 )

trap 'rm -rf "$tmpdir" &>/dev/null; trap - INT; kill -INT $$' INT

printf "${yellow}Checking for docker image updates${reset} ... "
if docker-compose -f /docker/compose/* pull &>/dev/null; then
    if docker images | grep none &>"$tmpdir/doc-images.log"; then
        printf %s\\n "${green}available${reset}" 
        printf %s\\n "${yellow}Updates are available for the following images${reset}"
        printf "$blue"; cut -d' ' -f1 "$tmpdir/doc-images.log"; printf "$reset"
        while true; do
            read -rp "${yellow}Would you like to upgrade any existing containers (Y/n)? ${reset}" yn
            case "$yn" in
                [Yy]*|'') printf %s\\n "${blue}Yes.${reset}"
                    printf "${yellow}Upgrading containers${reset} ... "
                    if docker-compose -f /docker/compose/* up -d &>/dev/null; then
                        yes y | docker image prune &>/dev/null
                        printf %s\\n "${green}done${reset}"
                    else
                        printf %s\\n "${red}failed${reset}"; exit 1
                    fi
                    break;;
                [Nn]*) printf %s\\n "${blue}No.${reset}"; break;;
                *) printf %s\\n "${lightred}Please answer yes or no.${reset}"
            esac
        done
    else
        printf %s\\n "${blue}none${reset}"
    fi
    rm -rf "$tmpdir" &>/dev/null
else
    printf %s\\n "${red}failed${reset}"; exit 1
fi
