#!/bin/bash

# Removes AIMGIN to your system

set -e

TMP=$(realpath -e "$0")
CURRDIR=$(dirname "$TMP")
DPATH_INST="/usr/lib/aimgin"
DPATH_DESK="/usr/share/applications"

rm -vrf "$DPATH_INST"
rm "$DPATH_DESK"/aimgin.desktop

echo "
AIMGIN removed"

if [ -z "$INTERACTIVE" ];then INTERACTIVE=0;fi
if [ $INTERACTIVE -eq 1 ]
then
	echo "Press any key to close"
	read -n1
fi
