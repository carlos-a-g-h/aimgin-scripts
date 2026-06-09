#!/bin/bash

# Removes AIMGIN to your system

set -e

TMP=$(realpath -e "$0")
CURRDIR=$(dirname "$TMP")

rm -vrf /usr/lib/aimgin/
rm /usr/share/applications/aimgin.desktop

echo "
AIMGIN removed"

if [ -z "$INTERACTIVE" ];then INTERACTIVE=0;fi
if [ $INTERACTIVE -eq 1 ]
then
	echo "Press ENTER to close"
	read
fi
