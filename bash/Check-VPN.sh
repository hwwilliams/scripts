#!/usr/bin/env bash

Message = "VPN is down"
Title = "qBittorrent Notification"

App_Token = "ao8jo3m5xqif23mvqvsdaaxcvbcb6d"
User_Token = "uef6xex7hgp8xhkrzsdsuu5xvp6z8g"

if wget https://api.pushover.net/1/messages.json --post-data="token=$APP_TOKEN&user=$USER_TOKEN&message=$MESSAGE&title=$TITLE" -qO- > /dev/null 2>&1 &; then
	echo "GOOD" > /config/VPN-Status.log
else
	echo "BAD" > /config/VPN-Status.log
fi
