#!/usr/bin/env bash

### This script has been scrapped as it wasn't working properly
### and I've stopped caring about getting notifcations for updates

# This script runs eopkg update-repo and eopkg list-upgrades
# if upgradable packages are found it pushes a notification to dunst.
# I run it through root systemd timer.


## update-notify.service ##
#[Unit]
#Description=Check for system updates
#After=dunst.service
#
#[Service]
#Type=simple
#Environment="Display=:0"
#ExecStart=/home/hunter/bin/update-notify.sh

## update-notify.timer ##
#[Unit]
#Description=Check for system updates
#
#[Timer]
#Persistent=True
#OnCalendar=hourly
#Unit=update-notify.service
#
#[Install]
#WantedBy=timers.target

if eopkg update-repo >/dev/null 2>&1; then
    if  upgrade=$( eopkg list-upgrades ); then
        case "$upgrade" in
            *"No packages to upgrade."*) exit 0;;
            *) if sudo -u hunter Display=:0 $DBUS_SESSION_BUS_ADDRESS notify-send -u critical 'System Updates Available'; then
                exit 0
            else
                exit 1
            fi
            ;;
    esac
else
    exit 1
fi
else 
    exit 1
fi


