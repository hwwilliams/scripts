#!/usr/bin/env bash

# This script will take a valid FQDN and check for any 
# available backups if backups exist it will ask if it
# should restore them and set the machine up as the FQDN
# implies, if not it will ignore any backups and ask if
# you wish to install docker. 


## Variables
blue=$( tput setaf 14 )
green=$( tput setaf 2 )
lightred=$( tput setaf 9 )
notroot="hunter"
red=$( tput setaf 1 )
reset=$( tput sgr0 )
tmpdir=$( mktemp -d -t tmp.XXXX )
yellow=$( tput setaf 11 )
## Arrays
docker=(
[1]="mainland"
[2]="quarantine"
[3]="servant"
)
declare -A phrases=(
[backup]="Fetching backup"
[creds]="Configuring share credentials"
[docker]="Installing & configuring docker"
[fstab]="Configuring fstab"
[mount]="Mounting shares"
[rundoc]="Starting docker containers"
)
plex=(
[1]="servant"
)
declare -A share=(
[backup]="//192.168.1.240/backup /mnt/backup cifs credentials=/home/$notroot/.smblogin.d/media-host,uid=1000,gid=1000,file_mode=0664,dir_mode=0775 0 0"
[downloads]="//192.168.1.240/downloads/ /mnt/downloads cifs credentials=/home/$notroot/.smblogin.d/media-host,uid=1000,gid=$dockergid,file_mode=0664,dir_mode=0775 0 0"
[logarr]="//192.168.1.240/logarrlogs /mnt/logarrlogs cifs credentials=/home/$notroot/.smblogin.d/media-host,uid=1000,gid=$dockergid,file_mode=0664,dir_mode=0775 0 0"
[music]="//192.168.1.240/media/music /mnt/music cifs credentials=/home/$notroot/.smblogin.d/media-host,uid=1000,gid=$dockergid,file_mode=0664,dir_mode=0775 0 0"
[plex]="//192.168.1.240/media/plex /mnt/plex cifs credentials=/home/$notroot/.smblogin.d/media-host,uid=1000,gid=$dockergid,file_mode=0664,dir_mode=0775 0 0"
[private]="//192.168.1.242/torrent-private /mnt/torrent-private cifs credentials=/home/$notroot/smblogin.d/hunter-pc,uid=1000,gid=$dockergid,file_mode=0664,dir_mode=0775 0 0"
[plxlogs]="192.168.1.241:/plex-logs /mnt/plex-logs nfs auto 0 0"
[other]="192.168.1.242:/hunter-pc/other /mnt/hunter-pc/other nfs auto 0 0"
[pass]="192.168.1.242:/hunter-pc/pass /mnt/hunter-pc/pass nfs auto 0 0"
[pics]="192.168.1.242:/hunter-pc/pictures /mnt/hunter-pc/pictures nfs auto 0 0"
)
## Null variables
dockergid=0
fqdn=0
hostname=0
rundoc=0
sharepass=0
shareuser=0
yn=0

## Start functions
# Ask to reboot and remove script
askBoot(){
    while true; do
        printf %s\\n "${lightred}WARNING: Answering 'Yes' will remove this script${reset}"
        read -rp "${blue}Would you like to reboot this computer (y/N)?${reset} " yn
        case "$yn" in
            [Yy]*) printf %s\\n "${yellow}Rebooting computer in 5 seconds.${reset}"
                rm -r "$tmpdir" &>/dev/null; rm -- "$0"; sleep 5; reboot;;
            [Nn]*|'') printf %s\\n "${yellow}No.${reset}"; break;;
            *)printf %s\\n "${lightred}Please answer answer reboot or no.${reset}"
        esac
    done
}
# Check if array contains string
checkArray(){
    local string match="$1"
    shift
    for string; do [[ "$string" == "$match" ]] && return 0; done
    return 1
}
# Color tail log output
colorTail(){
    printf "$lightred"
    tail "$1"
    printf "$reset"
}
# Grab borg backup
fetchBackup(){
    local archpath
    if checkArray "$1" "${docker[@]}"; then
        archpath=$(borg list --short -P "$1" /mnt/backup/docker/ | tail -n1)
        cd / && borg extract "/mnt/backup/docker::$archpath" docker || return 1
    fi
    if checkArray "$1" "${plex[@]}"; then
        archpath=$(borg list --short -P "$1" /mnt/backup/plex/ | tail -n1)
        cd / && borg extract "/mnt/backup/plex::$archpath" docker || return 1
    fi
}
# Look for hostname in backup
checkBorg(){
    if [[ "$forcebackup" == "true" ]]; then
        "$1"="$param2"
    fi
    local dir
    for dir in /mnt/backup/{docker,plex}; do
        borg list --short -P "$1" "$dir" &>>"$tmpdir/borg-list.log"
    done
    grep -i "$1" "$tmpdir/borg-list.log"
}
# Print phrases in color
printPhrase(){
    printf "$yellow"
    printf '%-*s' "$setpad" "${phrases[$1]}"
    printf "$reset"
    printf '%.s.' {1..3}
}
# Print done/failed statements in color
printDF(){
    case $1 in
        "d") printf ' %s\n' "${green}done${reset}";;
        "f") printf ' %s\n' "${red}failed${reset}";;
        *) printf ' %s\n' "${red}function encountered an error${reset}"
    esac
}
# Pull images and start containers
runDocker(){
    docker-compose -f /docker/compose/docker-compose.yml pull || return 1
    docker-compose -f /docker/compose/docker-compose.yml up -d || return 1
}
# Setup fstab
setupfStab(){
    case $1 in
        "backup"*)
            mkdir -p /mnt/backup || return 1
            printf %s\\n "${share[backup]}" >> /etc/fstab || return 1
            ;;
        "mainland"*)
            mkdir -p /mnt/{backup,downloads,logarrlogs,music,plex,torrent-private,plex-logs} || return 1
            mkdir -p /mnt/hunter-pc/{other,pass,pictures} || return 1
            cat <<EOF>>/etc/fstab || return 1
            ${share[downloads]}
            ${share[logarr]}
            ${share[music]}
            ${share[plex]}
            ${share[private]}
            ${share[plxlogs]}
            ${share[other]}
            ${share[pass]}
            ${share[pics]}
EOF
;;
        "quarantine"*)
            mkdir -p /mnt/{backup,downloads} || return 1
            cat <<EOF>>/etc/fstab || return 1
        ${share[downloads]}
EOF
;;
    "servant"*)
        mkdir -p /mnt/{backup,music,plex} || return 1
        cat <<EOF>>/etc/fstab || return 1
           ${share[music]}
           ${share[plex]}
EOF
;;
*)
   esac
}
# Setup environment for docker
setupDocker(){
    yum install -y yum-utils device-mapper-persistent-data lvm2 || return 1
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo || return 1
    yum install -y docker-ce || return 1
    systemctl enable docker || return 1
    systemctl start docker || return 1
    usermod -aG docker "$notroot" || return 1
    pip install docker-compose || return 1
    useradd -ru 990 docuser || return 1
    usermod -aG docker docuser || return 1
    if ! wget -P "$tmpdir" "https://raw.githubusercontent.com/Saltystew/scripts/master/update-doc.sh"; then
        wget -P "$tmpdir" "https://bitbucket.org/saltystew/scripts/raw/master/update-doc.sh"
    fi
    cp -f "$tmpdir/update-doc.sh" "/home/$notroot/bin/"
    dockergid=$( getent group docker | cut -d: -f3 )
    rundoc="yes"
}
# Fetch share credentials and disallow others from using the directory
setupCreds(){
    mkdir -p "/home/$notroot/.smblogin.d"
    cat<<EOF>/home/${notroot}/.smblogin.d/hunter-pc
        username=${shareuser}
        password=${sharepass}
EOF
cat<<EOF>/home/${notroot}/.smblogin.d/media-host
        username=${shareuser}
        password=${sharepass}
        domain=${sharedomain}
EOF
chown -R root:root /home/"$notroot"/.smblogin.d || return 1
chmod -R 600 /home/"$notroot"/.smblogin.d/* || return 1
}
# Find width to set for printf padding
setWidth(){
    local length width
    for phrase in "${phrases[@]}"; do
        length=${#phrase}
        (( length > width )) && width=$length
    done
    (( setpad = width + 1 ))
}
## End functions


# Find $setpad width for printf padding
setWidth &>/dev/null

if [ "$EUID" -ne 0 ]; then
    printf %s\\n "This script must be run with root privileges"; exit 1
fi

if [[ "$#" -gt 0 -a "$#" -gt 1]]; then param1="$1"; param2="$2"; else param=0; fi
case "$param" in -fb|--force-backup) forcebackup=true;; *) forcebackup=false;; esac

while true; do
    read -rp "${yellow}What do you want to set as this computers FQDN? ${reset}" fqdn
    if case .$fqdn. in *..*|*-.*|*.-*|*[!-a-zA-Z0-9.]*) false;; .*.??*.|.localhost.) true;; *) false;; esac; then
        hostname=$( cut -d'.' -f1 <<< "$fqdn" )
        echo -n "127.0.0.1 $hostname $fqdn" >> /etc/hosts
        echo -n "$fqdn" > /etc/hostname
        while true; do
            read -srp "${blue}What is the username for credential share access? ${reset}" shareuser; echo
            case "$shareuser" in
                '') printf %s\\n "${lightred}Please enter the username for credential share access.${reset}";;
                *) break
            esac
        done
        while true; do
            read -srp "${yellow}What is the password for credential share access? ${reset}" sharepass; echo
            case "$sharepass" in
                '') printf %s\\n "${lightred}Please enter the password for credential share access.${reset}";;
                *) break
            esac
        done
        while true; do
            read -srp "${blue}What is the domain for credential share access? ${reset}" sharedomain; echo
            case "$sharedomain" in
                '') printf %s\\n "${lightred}Please enter the domain for credential share access.${reset}";;
                *) break
            esac
        done
        printPhrase creds
        if setupCreds &>"$tmpdir/setup_creds.log"; then printDF d
        else printDF f; colorTail "$tmpdir/setup_creds.log"; exit 1
        fi
        printPhrase fstab
        if setupfStab backup &>"$tmpdir/setup_fstab.log"; then printDF d
        else printDF f; colorTail "$tmpdir/setup_fstab.log"; exit 1
        fi
        printPhrase mount
        if mount -a &>"$tmpdir/mount.log"; then printDF d
        else printDF f; colorTail "$tmpdir/mount.log"; exit 1
        fi
        if checkBorg "$hostname"; then
            while true; do
                read -rp "${yellow}Hostname recognized, would you like to restore this computer (y/N)? ${reset}" yn
                case "$yn" in
                    [Yy]*) printf %s\\n "${blue}Yes.${reset}"
                        if [[ ! "$hostname" == "blackhole"* ]]; then 
                            printPhrase docker
                            if setupDocker "$hostname" &>"$tmpdir/setup_docker.log"; then printDF d
                            else printDF f; colorTail "$tmpdir/setup_docker.log"; exit 1
                            fi
                        fi
                        printPhrase fstab
                        if setupfStab "$hostname" &>"$tmpdir/setup_fstab.log"; then printDF d
                        else printDF f; colorTail "$tmpdir/setup_fstab.log"; exit 1
                        fi
                        print_phrase mount
                        if mount -a &>"$tmpdir/mount.log"; then printDF d
                        else printDF f; colorTail "$tmpdir/mount.log"; exit 1
                        fi
                        printPhrase backup
                        if fetchBackup "$hostname" &>"$tmpdir/borg_backup.log"; then printDF d
                        else printDF f; colorTail "$tmpdir/borg_backup.log"; exit 1
                        fi
                        if [[ "$rundoc" == "yes" ]]; then
                            printPhrase rundoc
                            if runDocker &>"$tmpdir/run_docker.log"; then printDF
                            else printDF f; colorTail "$tmpdir/run_docker.log"; exit 1
                            fi
                        fi
                        askBoot;;
                    [Nn]*|'') printf %s\\n "${blue}No.${reset}"; break;;
                    *) printf %s\\n "${lightred}Please answer yes or no.${reset}"
                esac
            done; break
        fi
        break
    else
        printf %s\\n "${lightred}Please enter a valid FQDN.${reset}"
    fi
done

while true; do
    read -rp "${yellow}Will this computer run docker (y/N)? ${reset}" yn
    case "$yn" in 
        [Yy]*)printPhrase docker
            if setupDocker &>"$tmpdir/setup_docker.log"; then printDF d
            else printDF f; tail "$tmpdir/setup_docker.log"; exit 1
            fi
            askboot;;
        [Nn]*|'') printf %s\\n "${blue}No.${reset}"; break;;
        *)printf %s\\n "${lightred}Please answer yes or no.${reset}"
    esac
done

