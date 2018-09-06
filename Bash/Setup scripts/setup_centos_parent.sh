#!/usr/bin/env bash


# A script to setup a base environment on a CentOS parent
# disk for usage on Hyper-V in conjunction with a
# differencing disk.

# This script installs packages that I want as
# a base for my CentOS installation, all packages
# are then upgraded. Both the .bashrc and .vimrc files
# are overwritten with my specifications in the root home
# folder and the user folder found under "/home/$notroot".

# Firewalld is stopped and masked, iptables is enabled
# and started. Iptables is set to allow all outgoing and
# deny all incoming except SSH. Allow established and related
# for all chains, drop invalid for all chains.

# The UUID/HWADDR is removed from the ifcfg-eth0 config file and
# all SSH keys are also removed. The user name set in the 
# notroot variable below is given sudo privileges and login
# is disabled for the root account.

# Wget dotfiles, set host, and set iptables scripts.

# The end of this script asks if a reboot or shutdown is wanted,
# if reboot is chosen you should run the script again to remove any
# newly created SSH keys, if shutdown is chosen this script deletes
# itself before shutting down.

# It is advised to shutdown using this script so that it may clean any
# left over log files.

# Run this script as the root user.


### Variables
## Arrays
declare -A phrases=(
[base]="Installing base packages"
[bashrc]="Configuring user aliases"
[general]="Generalizing environment"
[grub]="Installing grub workaround"
[home]="Checking home folder permissions"
[iptables]="Configuring iptables"
[notroot]="Generalizing environment "
[pip]="Checking pip for upgrades"
[priv]="Setting user account privileges"
[scripts]="Fetching user scripts"
[update]="Checking for updates"
[upgrade]="Upgrading packages"
[vimrc]="Configuring vim config"
)
## Pre-set variables
blue=$( tput setaf 14 )
green=$( tput setaf 2 )
notroot="hunter"
red=$( tput setaf 1 )
lightred=$( tput setaf 9)
reset=$( tput sgr0 )
tmpdir=$( mktemp -d -t tmp.XXXX )
whosonline=$( who | cut -d' ' -f1 | uniq )
yellow=$( tput setaf 11 )
## Null variables
amroot=0
forceroot=0
instrc=0
length=0
param=0
setpad=0
tablerc=0
width=0
yumdrc=0
yumupg=0

## Functions
# Ask to reboot/shutdown/neither
ask_boot(){
    while true; do
        read -rp "${yellow}Would you like to shutdown or reboot the computer, or neither (s/r/N)?${reset} " srn
        case $srn in
            [Ss]*) printf %s\\n "${blue}Shutting down computer in 5 seconds.${reset}"
                cleanup 2>/dev/null
                sleep 5; shutdown now;;
            [Rr]*) printf %s\\n "${blue}Rebooting computer in 5 seconds.${reset}"
                rm -rf "$tmpdir" 2>/dev/null
                sleep 5; reboot;;
            [Nn]*|"") printf %s\\n "${blue}Neither.${reset}"; exit 0;;
            *)printf %s\\n "${red}Please answer answer reboot, shutdown, or neither.${reset}"
        esac
    done
}
# Removes temp directory and this setup script
clean_up(){
    # Remove $tmpdir directory
    rm -rf "$tmpdir"
    # Remove this script
    rm -- "$0"
}
# Install grubx64.efi boot workaround
grub_boot(){
    cp -rf /boot/efi/EFI/centos/* /boot/efi/EFI/BOOT/
}
# Fix user home permissions
home_permis(){
    chown -R "$notroot":"$notroot" "/home/$notroot"
}
# Install packages to setup desired base CentOS image
instbase(){
    # Install epel-release before packages that rely on it
    yum install -y deltarpm epel-release || return 1
    yum install -y cifs-utils ethtool bash-completion python-pip \
        borgbackup bind-utils traceroute wget hyperv-daemons hypervkvpd \
        hyperv-daemons-license hyperv-tools hypervfcopyd hypervvssd mlocate \
        diffutils net-tools dosfstools dos2unix nftables rsync vim yum-utils \
        iptables-services iptables-utils arp-scan || return 1
}
# Print done/failed statements in color
print_df(){
    case $1 in
        "d") printf ' %s\n' "${green}done${reset}";;
        "f") printf ' %s\n' "${red}failed${reset}";;
        *) printf ' %s\n' "${red}function encountered an error${reset}"
    esac
}
# Print phrases in color
print_phrase(){
    printf "$yellow"
    printf '%-*s' "$setpad" "${phrases[$1]}"
    printf "$reset"
    printf '%.s.' {1..3}
}
# Color tail log output
color_tail(){
printf "$lightred"
tail $1
printf "$reset"
}
# Configure iptables using iptables-save
set_filter(){
    echo '*filter'
    # Set default policy
    echo ':INPUT    DROP'
    echo ':OUTPUT   ACCEPT'
    echo ':FORWARD  DROP'
    # Allow on localhost
    echo '-A INPUT  -i lo -j ACCEPT'
    echo '-A OUTPUT -o lo -j ACCEPT'
    # Allow related and established
    echo '-A INPUT   -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT'
    echo '-A OUTPUT  -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT'
    # Drop invalid
    echo '-A INPUT   -m conntrack --ctstate INVALID -j DROP'
    echo '-A OUTPUT  -m conntrack --ctstate INVALID -j DROP'
    # Allow ssh
    echo '-A INPUT -i eth0 -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT'
    # Commit changes using iptables-save
    echo 'COMMIT'
}
# Generalize by removing UUID/HWADDR and ssh keys
set_general(){
    # Delete line starting with UUID/HWADDR in file ifcfg-eth0
    sed -i '/^UUID/d' /etc/sysconfig/network-scripts/ifcfg-eth0
    sed -i '/^HWADDR/d' /etc/sysconfig/network-scripts/ifcfg-eth0
    # Force remove all SSH keys
    rm -f /etc/ssh/ssh_host_*
}
# Check for group wheel and disable root login
set_sudo(){
    # If group wheel not found, add it
    if ! grep "%wheel" /etc/sudoers; then
        cat <<EOF | EDITOR='tee -a' visudo

## Allow people in group wheel to run all commands
%wheel ALL=(ALL) ALL
EOF
fi
# If user isn't a member of group wheel, add user
id -Gn "$notroot" | grep wheel || usermod -aG wheel "$notroot"
# Disable root login
usermod -L -e 1 root
}
# Firewalld down, iptables up
set_table(){
    systemctl stop firewalld || return 1
    yum remove -y firewalld || return 1
    yum remove -y firewalld-filesystem || return 1
    systemctl mask firewalld || return 1
    systemctl daemon-reload || return 1
    systemctl enable iptables || return 1
    systemctl start iptables || return 1
}
# Find width to set for printf padding
set_width(){
    for phrase in "${phrases[@]}"; do
        length=${#phrase}
        (( length > width )) && width=$length
    done
    (( setpad = width + 1 ))
}
# Fetch .bashrc/.bash_aliases and copy to user directories 
wget_bash(){
    if ! wget -P "$tmpdir" "https://raw.githubusercontent.com/Saltystew/dotfiles/master/centos/.bashrc"; then
        wget -P "$tmpdir" "https://bitbucket.org/saltystew/dotfiles/raw/master/centos/.bashrc"
    fi
    if ! wget -P "$tmpdir" "https://raw.githubusercontent.com/Saltystew/dotfiles/master/.bash_aliases"; then
        wget -P "$tmpdir" "https://bitbucket.org/saltystew/dotfiles/raw/master/.bash_aliases"
    fi
    cp -f "$tmpdir/.bashrc" /root/.bashrc
    cp -f "$tmpdir/.bashrc" "/home/$notroot/.bashrc"
    cp -f "$tmpdir/.bash_aliases" /root/.bash_aliases
    cp -f "$tmpdir/.bash_aliases" "/home/$notroot/.bash_aliases"
}
# Fetch setup script
wget_script(){
    if ! wget -P "$tmpdir" "https://raw.githubusercontent.com/Saltystew/scripts/master/setup.sh"; then
        wget -P "$tmpdir" "https://bitbucket.org/saltystew/scripts/raw/master/setup.sh"
    fi
    if ! wget -P "$tmpdir" "https://raw.githubusercontent.com/Saltystew/scripts/master/set_iptables.sh"; then
        wget -P "$tmpdir" "https://bitbucket.org/saltystew/scripts/raw/master/set_iptables.sh"
    fi
    mkdir -p "/home/$notroot/bin/"
    cp -f "$tmpdir/setup.sh" "/home/$notroot/"
    cp -f "$tmpdir/set_iptables.sh" "/home/$notroot/bin/"
}
# Fetch .vimrc and copy to user directories
wget_vim(){
    if ! wget -P "$tmpdir" "https://raw.githubusercontent.com/Saltystew/dotfiles/master/.vimrc"; then
        wget -P "$tmpdir" "https://bitbucket.org/saltystew/dotfiles/raw/master/.vimrc"
    fi
    cp -f "$tmpdir/.vimrc" /root/.vimrc
    cp -f "$tmpdir/.vimrc" "/home/$notroot/.vimrc"
}
## End functions

# If script is interrupted remove temp directory
trap 'rm -rf "$tmpdir" 2>/dev/null; trap - INT; kill -INT $$' INT

# Check if script is being run with root privileges
if [ "$EUID" -ne 0 ]; then
    printf %s\\n "This script must be run with root privileges."; exit 1
fi

# Find $setpad width for printf padding
set_width &>/dev/null

# If user $notroot is logged in only generalize by removing UUID/HWADDR/SSH keys
# then ask to reboot/shutdown, if user $notroot is logged in and they have 
# provided script param -f or --force-root script is run as normal.
if [[ $# -gt 0 ]]; then param="$1"; else param=0; fi
case "$param" in -f|--force-root) forceroot=true;; *) forceroot=false;; esac
if [[ "$whosonline" == "$notroot" ]] &>/dev/null; then amroot=false; else amroot=true; fi
case "$amroot" in 
    false)
        case "$forceroot" in
            false) 
                print_phrase notroot; set_general &>/dev/null
                print_df d; ask_boot;;
            *)
        esac;;
        *)
esac

# Checking for updates
print_phrase update
yum check-update &>"$tmpdir/yum_upd.log"; yumdrc="$?"
case "$yumdrc" in
    0|100) print_df d;;
    *) print_df f; color_tail "$tmpdir/yum_upd.log"; exit 1
esac

# Install packages to setup desired base CentOS image
print_phrase base
instbase &>"$tmpdir/instbase.log"; instrc="$?"
case "$instrc" in
    0) print_df d;;
    *) print_df f; color_tail "$tmpdir/instbase.log"; exit 1
esac

# Upgrade all packages
print_phrase upgrade
yum upgrade -y &>"$tmpdir/yum_upg.log"; yumupg=$(tail "$tmpdir/yum_upg.log")
case "$yumupg" in
    *"No packages"*|*"Complete!"*) print_df d;;
    *) print_df f; color_tail "$tmpdir/yum_upg.log"; exit 1
esac

# Enable and set iptables
print_phrase iptables
set_table &>"$tmpdir/set_table.log"; tablerc="$?"
case "$tablerc" in
    0) set_filter | iptables-restore &>/dev/null
        print_df d;;
    *) print_df f; color_tail "$tmpdir/set_table.log"; exit 1
esac

# Upgrading pip
print_phrase pip
pip install --upgrade pip &>/dev/null
print_df d

# Set user aliases in root and $notroot user .bashrc file
print_phrase bashrc
wget_bash &>/dev/null
print_df d

# Set vimrc for root and $notroot user vimrc
print_phrase vimrc
wget_vim &>/dev/null
print_df d

# Install grubx64.efi boot workaround
print_phrase grub
grub_boot &>/dev/null
print_df d

# Generalize by remove UUID/HWADDR/SSH keys
print_phrase general
set_general &>/dev/null
print_df d

# Fetch user scripts 
print_phrase scripts
wget_scripts &>/dev/null
print_df d

# Fix user home permissions
print_phrase home
home_permis &>/dev/null
print_df d

# Add $notroot to group wheel and disable root login
print_phrase priv
set_sudo &>/dev/null
print_df d

# Ask to reboot/shutdown/neither
ask_boot

