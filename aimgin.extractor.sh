#!/usr/bin/bash

# AppImage installer by github.com/carlos-a-g-h

# Script (step) name: Extractor
# Next script (step): Installer
# Extracts the contents of a selected AppImage or a compressed AppDir
# It also determines the name of the AppImage as an application before
# running the actual installation script

# Env vars explained
#
# NO_SYMLINKS
# Do not create symlinks to /usr/bin/
# Only works on the installer step
#
# ANY_AIMG
# Use general installation method for any AppImage
# Only works on the installer step
# 
# AIMG_NAME
# Force a specific name for the AppImage
# Only works on the installer step
#
# DNC
# Do Not Continue to the next step
# Very useful for debugging
#
# FORCE
# Make shit happen
# Convenient if ran by a GUI or unnatended/automated
# Unsafe when running manually or debugging

# Env Vars

if [ -z "$DEBUG" ];then DEBUG=0;fi
if [ $DEBUG -eq 1 ]
then
	set -x
fi

if [ -z "$NO_SYMLINKS" ];then NO_SYMLINKS=0; fi
if [ -z "$ANY_AIMG" ];then ANY_AIMG=0; fi
if [ -z "$AIMG_NAME" ];then AIMG_NAME=""; fi
if [ -z "$DNC" ];then DNC=0; fi
if [ -z "$FORCE" ];then FORCE=0; fi

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

# Argument 1: AppImage filepath
AIMG_FILEPATH=$(realpath -e "$1")
_util_assert $?

# Functions

TMP_DIR=""
TMP_NAME=""
function _action_Get_TMP() {

	TMP=$(echo "$AIMG_FILEPATH"|md5sum|head -n1)
	TMP_NAME="${TMP:0:32}"
	TMP_DIR="$APPSDIR"/"$TMP_NAME"

}

AIMG_DESKTOP=""
function _action_Get_AIMG_DESKTOP() {

	SEL_APPDIR="$TMP_DIR"

	if ! [ $(find "$SEL_APPDIR"|grep ".desktop$"|wc -l) -eq 1 ]; then _util_explode "Desktop file not found???";fi
	XXX=$(find "$SEL_APPDIR"|grep ".desktop$"|head -n1)
	AIMG_DESKTOP=$(realpath -e "$XXX")
}

AIMG_APPDIR=""
function _action_Get_AIMG_NAME() {

	# Get AIMG_NAME

	if ! [ -z "$AIMG_NAME" ]; then return 0; fi

	# If the AppImage was made by github.com/carlos-a-g-h

	SRC_NAME="$TMP_DIR""/_details/name.txt"
	if [ -f "$SRC_NAME" ];
	then
		AIMG_NAME=$(sed -n 1p "$SRC_NAME")
		if ! [ -z "$AIMG_NAME" ]; then return 0; fi
	fi

	# If the AppImage was X-AppImage-* fields on its dot desktop (AppImages by github.com/pkgforge-dev, or AnyLinux)

	if [ $(awk "/^X-AppImage-Name=/ || /^X-AppImage-Version=/ || /^X-AppImage-Arch=/" "$AIMG_DESKTOP"|wc -l) -eq 3 ]
	then

		X_NAME=$(awk "/^X-AppImage-Name=/" "$AIMG_DESKTOP"|sed 's/^X-AppImage-Name=//')
		X_ARCH=$(awk "/^X-AppImage-Arch=/" "$AIMG_DESKTOP"|sed 's/^X-AppImage-Arch=//')

		AIMG_NAME=$(echo "$X_NAME"_"$X_ARCH")
		if ! [ -z "$AIMG_NAME" ]; then return 0; fi
	fi

	# Use the "Name" field in the dot desktop file

	if [ $(awk "/^Name=/" "$AIMG_DESKTOP"|wc -l) -eq 1 ]
	then

		AIMG_NAME=$(awk "/^Name=/" "$AIMG_DESKTOP"|sed 's/^Name=//')

		if ! [ -z "$AIMG_NAME" ]; then return 0; fi
	fi

	# As a last method, use the filename as THE name for the app

	AIMG_NAME=$(basename "$AIMG_FILEPATH")
}

function _action_Decompress() {

	# Decompresses the AppImage or SQUASHFS compressed AppDir into TMP_DIR

	# NOTE:
	# Being an executable doesn't necessarily means that it's an AppImage, and in
	# the case of the SQUASHFS file type, that is just a VERY niche case

	# IS_SFS=0
	# IS_EXE=0
	TYPE_INDEX=0

	TYPE_EXE1="ELF 64-bit LSB executable"
	TYPE_EXE2="ELF 64-bit LSB pie executable"
	TYPE_SQUASHFS="Squashfs filesystem"

	WTFIT=$(file -b "$AIMG_FILEPATH")

	# NOTE:
	# WTFIT stands for "What The Fuck Is This"

	if [ $(echo "$WTFIT"|grep "$TYPE_SQUASHFS"|wc -l) -gt 0 ]; then TYPE_INDEX=1; fi
	if [ $(echo "$WTFIT"|grep -e "$TYPE_EXE1" -e "$TYPE_EXE2"|wc -l) -gt 0 ]; then TYPE_INDEX=2; fi

	if [ $TYPE_INDEX -eq 0 ]; then _util_explode "File type does not match: $WTFIT"; fi

	if [ $TYPE_INDEX -eq 1 ]
	then

		# SQUASHFS compressed AppDir

		unsquashfs -i -f -d "$TMP_DIR" "$AIMG_FILEPATH"
		return 0
	fi

	# Normal AppImage file

	TMP="squashfs-root"
	if [ -d "$TMP" ] || [ -f "$TMP" ]
	then
		if [ $FORCE -eq 0 ]; then _util_explode "Remove this yourself: $TMP";fi
		rm -rf "$TMP"
	fi
	TMP="AppDir"
	if [ -d "$TMP" ] || [ -f "$TMP" ]
	then
		if [ $FORCE -eq 0 ]; then _util_explode "Remove this yourself: $TMP";fi
		rm -rf "$TMP"
	fi

	chmod +x "$AIMG_FILEPATH"
	"$AIMG_FILEPATH" --appimage-extract

	# Get the AppDir or squashfs-root
	# NOTE:
	# When you decompress an AppImage, you get an "AppDir" directory with the
	# contents, but with the AnyLinux AppImages (pkgforge-dev) you get the
	# AppDir + squashfs-root symlink to that AppDir

	TMP=""
	if [ -d "squashfs-root" ]; then TMP=$(realpath -e "squashfs-root"); fi
	if [ -z "$TMP" ]
	then
		if [ -d "AppDir" ]; then TMP=$(realpath -e "AppDir"); fi
	fi
	if [ -z "$TMP" ]; then _util_explode "I cant't find the decompressed AppImage, wtf";fi
	if [ -d "$TMP_DIR" ]; then rm -rf $TMP_DIR; fi
	mv -f -T "$TMP" "$TMP_DIR"
}

###############################################################################

set -e

mkdir -vp "$APPSDIR"

_action_Get_TMP

_action_Decompress

# Show AppDir contents

ls -l "$TMP_DIR"

# Check wether we need to continue or not

if [ "$DNC" -eq 1 ]
then
	echo "[!] Avoided jumping to the next step"
	exit 0
fi

TMP=$(realpath -e "$0")
TMP1=$(dirname "$TMP")
NEXT_STEP="$TMP1"/"aimgin.installer.sh"

_action_Get_AIMG_DESKTOP

_action_Get_AIMG_NAME

# Fix characters in AIMG_NAME

TMP=$(echo "$AIMG_NAME"|sed -e 's/ /_/g' -e 's/:/_/g' -e 's:/:_:g')
AIMG_NAME="$TMP"

# Rename AppDIr

AIMG_APPDIR="$APPSDIR"/"$AIMG_NAME"".installed"
if [ -d "$AIMG_APPDIR" ]; then rm -rf "$AIMG_APPDIR";fi
mv -v -T "$TMP_DIR" "$AIMG_APPDIR"

# Adapt AIMG_DESKTOP variable to the new AppDir

echo "CONVERTING..."
echo "FROM:$AIMG_DESKTOP"
TMP=$(echo "$AIMG_DESKTOP"|sed "s:$TMP_NAME:$AIMG_NAME.installed:g")
AIMG_DESKTOP=$(echo "$TMP"|head -n1)
echo "TO:$AIMG_DESKTOP"

# Write known results

if [ $WRITE_RESULTS -eq 1 ]
then
	echo "$AIMG_NAME" > "$CACHEDIR"/"results.AIMG_NAME"
	echo "$AIMG_APPDIR" > "$CACHEDIR"/"results.AIMG_APPDIR"
fi

# Run next script

set +e

export NO_SYMLINKS
export ANY_AIMG
export AIMG_NAME
export AIMG_DESKTOP

export CACHEDIR
export APPSDIR
export MAINPROC
export WRITE_RESULTS

chmod +x "$NEXT_STEP"
"$NEXT_STEP" "$AIMG_NAME" "$AIMG_APPDIR"
if [ $? -eq 0 ]
then
	if [ $IS_MAINPROC -eq 1 ]
	then
		echo "[!] Installed: $AIMG_NAME"
	fi
	exit 0
fi

# Destroy the AppDir in case of failure

set -e

if [ $IS_MAINPROC -eq 1 ]
then
	echo "[!] Failed to install: $AIMG_NAME"
fi

if [ -d "$AIMG_APPDIR" ]
then
	echo "[!] Deleting AppDir..."
	rm -rf "$AIMG_APPDIR"
fi
exit 1
