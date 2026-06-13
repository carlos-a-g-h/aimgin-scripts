#!/bin/bash

# Installs AIMGIN to your system

set -e

TMP=$(realpath -e "$0")
CURRDIR=$(dirname "$TMP")
DPATH_INST="/usr/lib/aimgin"
DPATH_DESK="/usr/share/applications"

mkdir -vp "$DPATH_INST"

cp -va aimgin.*.sh "$DPATH_INST"/

chmod +x "$DPATH_INST"/aimgin.*

cp -va aimgin.desktop "$DPATH_DESK"/

chmod +x "$DPATH_DESK"/aimgin.desktop

ls -l "$DPATH_DESK"/aimgin.desktop

echo "
AIMGIN installed!"

if [ -z "$INTERACTIVE" ];then INTERACTIVE=0;fi
if [ $INTERACTIVE -eq 1 ]
then
	echo "Press any key to close"
	read -n1
fi
