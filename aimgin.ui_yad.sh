#!/bin/bash

# AppImage installer by github.com/carlos-a-g-h

# Script (step) name: YAD UI
# Next script (step): Extractor
# Launches a simple UI that runs the extractor and installer scripts
# The UI can also download files from the internet

# Print PWD
echo "PWD is: $PWD"

# Installation directory (you can change this)
APPSDIR="/usr/appimages"

# Cache directory (it should match the $PWD)
CACHEDIR="/tmp/aimgin.cache"

################################################################################

set -e

if [ -z "$DEBUG" ];then DEBUG=0;fi
if [ $DEBUG -eq 1 ]
then
	set -x
fi

if [ -z "$DISPLAY" ]
then
	echo "[!] Not running on a graphical environment"
	exit 1
fi

mkdir -vp "$CACHEDIR"

set +e

MAINPROC=$(basename "$0")

# Essential functions

function _util_guard() {
	EC=$1
	if [ $? -eq $EC ]; then exit 0;fi
}

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

# Variables

UI_TITLE="AppImage Installer"
UI_LBL="
[Quick help]

The Location
This field is mandatory, it must lead to the AppImage file. You can either use
an absolute file path or a direct link to the application (like from a github
releases page, for example). Compressed AppDirs (in SQUASHFS) are also accepted

The Name
This field is optional. During the installation, the name will be obtained
automatically by different means, but you can put any name you want. Be aware
that if an application already has an existing name, it will be replaced

Symlinks to /usr/bin ?
By default, the installer will integrate the application by symlinking all its
binaries to /usr/bin. If you don't want this to happen, checkmark this
"

UI_ICON="emblem-package"
UI_FIELD1="Location"
UI_FIELD2="Name"
UI_FIELD3="Do not symlink the app's main binary (or any binaries) into /usr/bin"
UI_FIELD4="Use general strategy for any AppImage"

JOB_PARAMS=""
AIMG_FILEPATH=""

LOC_TYPE=0
STR_LOCATION=""
STR_NAME=""
CHK_NOSYMLINK=-1
CHK_ANYAIMG=-1

#function _reset_vars() {
#	JOB_PARAMS=""
#	AIMG_FILEPATH=""
#	LOC_TYPE=0
#	STR_LOCATION=""
#	STR_NAME=""
#	CHK_NOSYMLINK=-1
#	CHK_ANYAIMG=-1
#}

function _ui_main() {

	# LOC_TYPE=0
	# STR_LOCATION=""
	# STR_NAME=""
	# CHK_NOSYMLINK=-1
	# CHK_ANYAIMG=-1

	JOB_PARAMS=$(
		yad --title="$UI_TITLE" \
			--fixed --center \
			--width=640 --height=480 \
			--window-icon="$UI_ICON" \
			--form \
			--separator="\n" \
			--field="$UI_LBL:LBL" \
			--field="$UI_FIELD1" \
			--field="$UI_FIELD2" \
			--field="$UI_FIELD3:CHK" \
			--field="$UI_FIELD4:CHK"
	)
	ECODE=$?
	echo "$ECODE"
	echo "$JOB_PARAMS"

	if ! [ $ECODE -eq 0 ]; then return $ECODE;fi
}

function _get_str_location() {

	# Get STR_Location

	TMP=$(echo "$JOB_PARAMS"|sed -n 2p)
	if [ $(echo "$TMP"|grep "^/"|wc -l) -eq 1 ]; then LOC_TYPE=1;fi
	if [ $LOC_TYPE -eq 0 ]
	then
		if [ $(echo "$TMP"|grep -e "^http://" -e "^https://"|wc -l) -eq 1 ]
		then
			LOC_TYPE=2
		fi
	fi
	if [ $LOC_TYPE -eq 0 ];then return 1;fi
	STR_LOCATION="$TMP"
}

function _get_str_name() {

	# Get STR_NAME (AIMG_NAME)

	TMP=$(echo "$JOB_PARAMS"|sed -n 3p)
	STR_NAME=$(echo "$TMP"|sed -e "s/:/_/g" -e 's/ /_/g' -e "s:/:_:g")
}

function _get_chk_nosymlink() {

	# Get CHK_NOSYMLINK (NO_SYMLINK)

	TMP=$(echo "$JOB_PARAMS"|sed -n 4p)
	if [[ "$TMP" == "FALSE" ]]; then CHK_NOSYMLINK=0; fi
	if [[ "$TMP" == "TRUE" ]]; then CHK_NOSYMLINK=1; fi
	if [ $CHK_NOSYMLINK -eq -1 ]; then return 1; fi
}

function _get_chk_anyaimg() {

	# Get CHK_ANYAIMG (ANY_AIMG)

	TMP=$(echo "$JOB_PARAMS"|sed -n 5p)
	if [[ "$TMP" == "FALSE" ]]; then CHK_ANYAIMG=0; fi
	if [[ "$TMP" == "TRUE" ]]; then CHK_ANYAIMG=1; fi
	if [ $CHK_ANYAIMG -eq -1 ]; then return 1; fi
}

function _get_file_from_web() {

	# Downloads a file from the web

	if [ -z "$DL_DIR" ]
	then
		TMP="$(echo "$STR_LOCATION"|md5sum)"
		DL_DIR="$CACHEDIR"/"_download.""${TMP:0:32}"
	fi
	mkdir -p "$DL_DIR"

	wget -t 10 -c "$STR_LOCATION" -P "$DL_DIR"/

	if ! [ $? -eq 0 ]
	then
		echo "[!] Download error"
		return 1
	fi
	if ! [ $(ls "$DL_DIR"|wc -l) -eq 1 ]
	then
		echo "[!] Expected one file"
		return 1
	fi
	TMP=$(ls "$DL_DIR"|head -n1)
	# mv -vf "$DL_DIR"/"$TMP" "$TMP"
	AIMG_FILEPATH=$(realpath -e "$DL_DIR"/"$TMP")
}

function _get_file_from_fs() {

	# Fetch a file from the filesystem

	if ! [ -f "$STR_LOCATION" ]
	then
		echo "[!] Expected a path to a file"
		return 1
	fi

	AIMG_FILEPATH="$(realpath -e $STR_LOCATION)"
}

###############################################################################

_ui_main

_get_str_location

_get_str_name

_get_chk_nosymlink

if [ $LOC_TYPE -eq 1 ]
then
	_get_file_from_fs
fi
if [ $LOC_TYPE -eq 2 ]
then
	_get_file_from_web
fi

if [ -z "$AIMG_FILEPATH" ]; then _util_explode "App filepath not found...?";fi

echo "AIMG_FILEPATH: $AIMG_FILEPATH"

export AIMG_NAME="$STR_NAME"
export NO_SYMLINKS=$CHK_NOSYMLINK
export ANY_AIMG=$CHK_ANYIMG
export DNC=0
export FORCE=1

export APPSDIR
export MAINPROC
export CACHEDIR
export WRITE_RESULTS=1

TMP=$(realpath -e "$0")
TMP1=$(dirname "$TMP")
NEXT_STEP="$TMP1"/"aimgin.extractor.sh"

echo "[!] Running extractor"

chmod +x "$NEXT_STEP"
"$NEXT_STEP" "$AIMG_FILEPATH"

set -e

if [ $? -eq 0 ]
then

	# Grab results

	AIMG_NAME=$(cat "$CACHEDIR"/"results.AIMG_NAME"|head -n1)
	AIMG_APPDIR=$(cat "$CACHEDIR"/"results.AIMG_APPDIR"|head -n1)
	ICON_FILEPATH=$(cat "$CACHEDIR"/"results.ICON_FILEPATH"|head -n1)

	echo "$AIMG_NAME"
	echo "$AIMG_APPDIR"
	echo "$ICON_FILEPATH"

	yad --title="$UI_TITLE" \
		--image="$ICON_FILEPATH" \
		--fixed --center \
		--width=480 --height=240 \
		--escape-ok \
		--window-icon="$UI_ICON" \
		--text "SUCCESSFULLY INSTALLED THE APPLICATION\n\nName: $AIMG_NAME\n\nPath: $AIMG_APPDIR" \
		--button="OK"

	rm "$CACHEDIR"/results.*

fi
