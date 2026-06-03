#!/bin/bash

# AppImage installer by github.com/carlos-a-g-h

# Step (script) name: Installer
# Installs the contents of an AppDir into the system
# Runs after the extractor step

# Env vars explained
#
# NO_SYMLINKS
# Do not create symlinks to /usr/bin/
#
# ANY_AIMG
# Use general installation method for any AppImage
# It may be forced to 1 in case some specific files aren't found

# DNC
# Used by the previous step (the extractor)
# Do not set this env var manually for this specific step, this env var being
# used as a reference to wether print or to not print certain things on screen

if [ -z "$NO_SYMLINKS" ];then NO_SYMLINKS=0; fi
if [ -z "$ANY_AIMG" ];then ANY_AIMG=0; fi
if [ -z "$DNC" ];then DNC=0; fi

set -e

# Argument 1: AppImage Name
AIMG_NAME="$1"

# Argument 2: Decompressed AppDir
AIMG_APPDIR="$(realpath -e $2)"

# find dot desktop file

SRC_DESKTOP_RAW=""
if [ $(ls "$AIMG_APPDIR"|grep ".desktop$"|wc -l) -eq 1 ]
then
	SRC_DESKTOP_RAW=$(ls "$AIMG_APPDIR"|grep ".desktop$"|sed -n 1p)
fi
if [ -z "$SRC_DESKTOP_RAW" ]; then exit 1; fi
SRC_DESKTOP=$(realpath -e "$AIMG_APPDIR"/"$SRC_DESKTOP_RAW")

# determine entrypoint

# TODO: pull out the main binary name from the .desktop file and use it
# as a pattern for replacing it with the path that leads to the AppRun

# $SRC_DESKTOP

# AIMG_EPOINT=""

AIMG_APPRUN="$AIMG_APPDIR"/AppRun


# install using setup script

SH_SETUP="$AIMG_APPDIR"/bin/setup

if [ $ANY_AIMG -eq 0 ]
then

	if ! [ -f "$SH_SETUP" ]; then ANY_AIMG=1;fi

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

	# if [ -f "$SH_SETUP" ]
	# then
	# 	export APPDIR="$AIMG_APPDIR"
	# 	if [ "$NO_SYMLINKS" -eq 1 ]
	# 	then
	# 		export URUNTIME="$AIMG_APPRUN"
	# 		"$SH_SETUP" --install --force --no-links
	# 	else
	# 		export URUNTIME=""
	# 		"$SH_SETUP" --install --force
	# 	fi
	# else
	# 	ANY_AIMG=1
	# fi
fi

# install any kind of appimage

if [ $ANY_AIMG -eq 1 ]
then

	CONST_PNG="PNG image data"
	CONST_SVG="SVG Scalable Vector Graphics image"
	CONST_XPM="X pixmap image"

	# find dot dir icon and get icon filename

	ICON_FILENAME=""
	SRC_DIRICON=$(realpath -e "$AIMG_APPDIR"/".DirIcon")
	SRC_DIRICON_NAME=$(basename "$SRC_DIRICON")

	if [ "$SRC_DIRICON_NAME" == ".DirIcon" ]
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
		if [ -z "$ICON_FILENAME" ]
		then
			echo "Unable to get the file format of the icon file"
			exit 1
		fi

		LINE_ICON=$(awk "/^Icon=/" "$SRC_DESKTOP"|head -n1)
		if ! [ -z "$LINE_ICON" ]
		then
			echo "x"
			# len("Icon=") = 5
			ICON_FILENAME="${LINE_ICON:5}""$ICON_FILENAME"
		else
			ICON_FILENAME="$AIMG_NAME""$ICON_FILENAME"
		fi

	fi

	if [ -z "$ICON_FILENAME" ]
	then
		"Icon filename unknown"
		exit 1
	fi

	echo "ICON:$ICON_FILENAME:$SRC_DIRICON"

	# Copy desktop file

	


fi

# TODO: finish this
