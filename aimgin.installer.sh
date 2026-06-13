#!/bin/bash

# AppImage installer by github.com/carlos-a-g-h

# Script (step) name: Installer
# Installs the contents of an AppDir into the system
# Runs after the extractor step

# Env vars explained
#
# NO_SYMLINKS
# Do not create symlinks to /usr/bin/
#
# ANY_AIMG
# Use general installation strategy for any AppImage
# It may be forced to 1 automatically in case some specific files aren't found

# AIMG_DESKTOP
# Absolute file path or name of the dot Desktop file
# If it's not given, it will be obtained during this step
#
# There are other env vars used by this script but those are a bit more
# irrelevant for an end user

if [ -z "$DEBUG" ];then DEBUG=0;fi
if [ $DEBUG -eq 1 ]
then
	set -x
fi

if [ -z "$NO_SYMLINKS" ];then NO_SYMLINKS=0; fi
if [ -z "$ANY_AIMG" ];then ANY_AIMG=0; fi
if [ -z "$AIMG_DESKTOP" ];then AIMG_DESKTOP=0; fi

if [ -z "$APPSDIR" ];then APPSDIR="/usr/appimages";fi
if [ -z "$CACHEDIR" ];then APPSDIR="/tmp/aimgin.cache";fi
if [ -z "$WRITE_RESULTS" ];then WRITE_RESULTS=0;fi


IS_MAINPROC=0
TMP=$(basename "$0")
if [ -z "$MAINPROC" ]
then
	MAINPROC="$TMP"
	IS_MAINPROC=1
fi
if [ $IS_MAINPROC -eq 0 ]
then
	if [ $(echo "$MAINPROC"|grep "$TMP"|wc -c) -gt 0 ]
	then
		IS_MAINPROC=1
	fi
fi

CACHEDIR="/tmp/aimgin.cache"

# Essential functions

function _util_assert() {
	EC=$1
	MSG=""
	if [ $# -eq 1 ];then MSG="[ E.Code: ""$EC ]";fi
	if [ $# -eq 2 ];then MSG="[ E.Code: ""$EC"" ] ""$2";fi
	echo "$MSG"
	if [ $EC -eq 0 ];then return 0;fi
	exit $EC
}

function _util_explode() {
	echo "[!] ""$1"
	exit 1
}

# Argument 1: AppImage Name
AIMG_NAME="$1"

# Argument 2: Decompressed AppDir
AIMG_APPDIR="$(realpath -e $2)"
_util_assert $?

# Variables

AIMG_APPRUN="$AIMG_APPDIR"/AppRun
SH_SETUP="$AIMG_APPDIR"/bin/setup
if ! [ -f "$SH_SETUP" ]; then ANY_AIMG=1;fi

# Functions

function _get_AIMG_DESKTOP() {

	# Get AIMG_DESKTOP (if not provided through ENV)

	if ! [ -z "$AIMG_DESKTOP" ]
	then
		echo "[!] AIMG_DESKTOP already provided: $AIMG_DESKTOP"
		return 0
	fi

	SEL_APPDIR="$AIMG_APPDIR"

	QTTY=$(ls "$SEL_APPDIR"|grep ".desktop$"|wc -l)
	if ! [ $QTTY -eq 1 ]; then _util_explode "Desktop file not found??? (from installer)";fi
	TMP=$(ls "$SEL_APPDIR"|grep ".desktop$"|head -n1)
	AIMG_DESKTOP=$(realpath -e "$SEL_APPDIR"/"$TMP")

}

###############################################################################

set -e

_get_AIMG_DESKTOP

# Install application using the internal setup script

if [ $ANY_AIMG -eq 0 ]
then
	export APPDIR="$AIMG_APPDIR"
	if [ "$NO_SYMLINKS" -eq 1 ]
	then
		export URUNTIME="$AIMG_APPRUN"
		"$SH_SETUP" --install --force --no-links
	else
		export URUNTIME=""
		"$SH_SETUP" --install --force
	fi
fi

# install application using general strategy

if [ $ANY_AIMG -eq 1 ]
then

	CONST_PNG="PNG image data"
	CONST_SVG="SVG Scalable Vector Graphics image"
	CONST_XPM="X pixmap image"

	# find dot dir icon and get icon filename

	ICON_FILENAME=""
	SRC_DIRICON=$(realpath -e "$AIMG_APPDIR"/".DirIcon")
	SRC_DIRICON_NAME=$(basename "$SRC_DIRICON")

	if ! [ "$SRC_DIRICON_NAME" == ".DirIcon" ]
	then

		ICON_FILENAME="$SRC_DIRICON_NAME"

	else

		# Get the file extension

		WTFIT=$(file -b "$SRC_DIRICON")
		if [ $(file "$SRC_DIRICON"|grep -e "$CONST_PNG" -e "$CONST_SVG" -e "$CONST_XPM"|wc -l) -gt 0 ]
		then
			if [ $(echo "$WTFIT"|grep "$CONST_PNG"|wc -l) -gt 0 ];then ICON_FILENAME=".png";fi
			if [ $(echo "$WTFIT"|grep "$CONST_SVG"|wc -l) -gt 0 ];then ICON_FILENAME=".svg";fi
			if [ $(echo "$WTFIT"|grep "$CONST_XPM"|wc -l) -gt 0 ];then ICON_FILENAME=".xpm";fi
		fi
		if [ -z "$ICON_FILENAME" ];then _util_explode "Unable to get the file format of the icon file";fi

		ICON_STEM=""
		LINE_ICON=$(awk "/^Icon=/" "$AIMG_DESKTOP"|head -n1)
		if ! [ -z "$LINE_ICON" ]
		then
			ICON_STEM=$(echo "$LINE_ICON"|sed 's/^Icon=//')
			ICON_FILENAME="$ICON_STEM""$ICON_FILENAME"
		else
			ICON_FILENAME="$AIMG_NAME""$ICON_FILENAME"
		fi
	fi

	if [ -z "$ICON_FILENAME" ];then _util_explode "Icon filename unknown";fi

	echo "ICON:$ICON_FILENAME:$SRC_DIRICON"

	ICON_FILEPATH="/usr/share/icons/""$ICON_FILENAME"

	cp -va "$SRC_DIRICON" "$ICON_FILEPATH"

	# Copy desktop file

	TMP=$(basename "$AIMG_DESKTOP")
	DESKTOP_OK="/usr/share/applications/""$TMP"

	# Replace Exec with AppRun

	TMP=$(cat "$AIMG_DESKTOP"|grep "^Exec="|head -n1)

	cat "$AIMG_DESKTOP"|sed 's:'"$TMP"':Exec='"$AIMG_APPRUN"':' > "$DESKTOP_OK"

	chmod +x "$DESKTOP_OK"
fi

# Add Icon to results

if [ $WRITE_RESULTS -eq 1 ]
then

	TMP="$(realpath -e "$AIMG_APPDIR"/".DirIcon")"

	echo "$TMP" > "$CACHEDIR"/"results.ICON_FILEPATH"

fi

if [ $IS_MAINPROC -eq 1 ]
then
	echo "[!] Installed: $AIMG_NAME"
fi
