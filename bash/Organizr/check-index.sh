#!/usr/bin/env bash

# Check site index.php file for lines, if not found insert using file

# Variables
sitepath="/docker/letsencrypt/www/orgv2/"

if ! grep "West Media" "$sitepath/index.php"; then
    sed -i '|^<link href="plugins/images|d' "$sitepath/index.php"
    sed -i '|^<title>Org|d' "$sitepath/index.php"
    sed -i '/<meta content="CauseFX"/r ./insert-index' "$sitepath/index.php"
fi
