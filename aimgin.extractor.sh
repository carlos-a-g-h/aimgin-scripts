#!/usr/bin/bash

# AppImage installer by github.com/carlos-a-g-h

# Step (script) name: Extractor
# Next step (script): Installer
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

if [ -z "$NO_SYMLINKS" ];then NO_SYMLINKS=0; fi
if [ -z "$ANY_AIMG" ];then ANY_AIMG=0; fi
if [ -z "$AIMG_NAME" ];then AIMG_NAME=""; fi
if [ -z "$DNC" ];then DNC=0; fi
if [ -z "$FORCE" ];then FORCE=0; fi

set -e

# Argument 1: AppImage filepath
AIMG_FILEPATH=$(realpath -e "$1")

# Temporary directory
TMP=$(echo "$AIMG_FILEPATH"|md5sum|head -n1)
TMP1="${TMP:0:32}"
TMP_DIR="/usr/appimages/""$TMP1"

_get_AIMG_NAME() {

	if ! [ -z "$AIMG_NAME" ]; then exit 0; fi

	SRC_NAME="$TMP_DIR""/_details/name.txt"
	if [ -f "$SRC_NAME" ];
	then
		AIMG_NAME=$(sed -n 1p "$SRC_NAME")
		if ! [ -z "$AIMG_NAME" ]; then exit 0; fi
	fi

	AIMG_NAME=$(basename "$AIMG_FILEPATH")
}

# NOTE:
# Being an executable doesn't necessarily means that it's an AppImage, and in
# the case of the SQUASHFS file type, that is just a VERY niche case

IS_SFS=0
IS_EXE=0
# CONST_SFS="Squashfs filesystem"
# CONST_EXE="ELF 64-bit LSB executable"
WTFIT=$(file -b "$AIMG_FILEPATH")
if [ $(echo "$WTFIT"|grep "Squashfs filesystem"|wc -l) -gt 0 ]; then IS_SFS=1; fi
if [ $(echo "$WTFIT"|grep -e "ELF 64-bit LSB executable" -e "ELF 64-bit LSB pie executable"|wc -l) -gt 0 ]; then IS_EXE=1; fi

if [ $IS_SFS -eq 0 ] && [ $IS_EXE -eq 0 ]
then
	echo "[!] File type does not match: $WTFIT"
	exit 1
fi

if [ $IS_SFS -eq 1 ]; then unsquashfs -i -f -d "$TMP_DIR" "$AIMG_FILEPATH"; fi

if [ $IS_EXE -eq 1 ]
then

	# Make sure we don't have any AppDir or squashfs-root on the CWD

	TMP="squashfs-root"
	if [ -d "$TMP" ] || [ -f "$TMP" ]
	then
		if [ $FORCE -eq 0 ]
		then
			echo "[!] Remove this yourself: $TMP"
			exit 1
		fi
		rm -vrf "$TMP"
	fi

	TMP="AppDir"
	if [ -d "$TMP" ] || [ -f "$TMP" ]
	then
		if [ $FORCE -eq 0 ]
		then
			echo "[!] Remove this yourself: $TMP"
			exit 1
		fi
		rm -vrf "$TMP"
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
	if [ -z "$TMP" ]
	then
		echo "[!] I cant't find the decompressed AppImage, wtf"
		ls -l
		exit 1
	fi
	if [ -d "$TMP_DIR" ]; then rm -vrf $TMP_DIR; fi
	mv -v -f -T "$TMP" "$TMP_DIR"
fi

ls -l "$TMP_DIR"

if [ "$DNC" -eq 1 ]
then
	echo "[!] Avoided jumping to the next step (exit zero)"
	exit 0
fi

TMP=$(realpath -e "$0")
TMP1=$(dirname -z "$TMP")
NEXT_STEP="$TMP1"/"aimgin.installer.sh"

set +e

_get_AIMG_NAME

AIMG_APPDIR="/usr/appimages/""$AIMG_NAME"".installed"
if [ -d "$AIMG_APPDIR" ]; then rm -vrf "$AIMG_APPDIR";fi
mv -v "$TMP_DIR" "$AIMG_APPDIR"

export NO_SYMLINKS
export ANY_AIMG
export AIMG_NAME
export DNC

chmod +x "$NEXT_STEP"
"$NEXT_STEP" "$AIMG_NAME" "$AIMG_APPDIR"

if [ $? -eq 0 ]
then
	echo "[!] Installed: $AIMG_NAME"
	exit 0
fi

# Destroy the AppDir in case of failure

set -e

echo "[!] Failed to install: $AIMG_NAME"

if [ -d "$AIMG_APPDIR" ]
then
	rm -vrf "$AIMG_APPDIR"
fi
exit 1
