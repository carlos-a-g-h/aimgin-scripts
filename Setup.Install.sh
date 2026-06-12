#!/bin/bash

# Installs AIMGIN to your system

set -e

TMP=$(realpath -e "$0")
CURRDIR=$(dirname "$TMP")

mkdir -vp /usr/lib/aimgin/

cp -va aimgin.*.sh /usr/lib/aimgin/

chmod +x /usr/lib/aimgin/aimgin.*

cp -va aimgin.desktop /usr/share/applications/

chmod +x /usr/share/applications/aimgin.desktop

ls -l /usr/share/applications/aimgin.desktop

echo "
AIMGIN installed!"

if [ -z "$INTERACTIVE" ];then INTERACTIVE=0;fi
if [ $INTERACTIVE -eq 1 ]
then
	echo "Press any key to close"
	read -n1
fi
