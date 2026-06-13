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

USE_YAD=0
if [ -z "$DISPLAY" ]
then
	echo "[!] Not running on a graphical environment"
else
	if [ -x /usr/bin/yad ]; then USE_YAD=1; fi
fi

mkdir -vp "$CACHEDIR"

set +e

MAINPROC=$(basename "$0")

# Essential functions

STR_PRESS_ANY_KEY="
Press any key to continue"
function _util_wait_for_any_key () {
	echo "$STR_PRESS_ANY_KEY"
	read -n1
}

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

JOB_PARAMS=""
AIMG_FILEPATH=""

LOC_TYPE=0
STR_LOCATION=""
STR_NAME=""
CHK_NOSYMLINK=-1
CHK_ANYAIMG=-1

function _ui_main() {

	#LOC_TYPE=0
	#STR_LOCATION=""
	#STR_NAME=""
	#CHK_NOSYMLINK=-1
	#CHK_ANYAIMG=-1

	FIELD1=""
	FIELD2=""
	FIELD3=""

	if [ $USE_YAD -eq 1 ]
	then

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
				--field="$UI_FIELD3:CHK"
		)
		if ! [ $? -eq 0 ];then exit 0; fi

		FIELD1=$(echo "$JOB_PARAMS"|sed -n 2p)
		FIELD2=$(echo "$JOB_PARAMS"|sed -n 3p)
		FIELD3=$(echo "$JOB_PARAMS"|sed -n 4p)

	fi

	if [ $USE_YAD -eq 0 ]
	then

		clear

		echo "$UI_LBL"

		echo "$UI_FIELD1"
		read FIELD1

		echo "$UI_FIELD2"
		read FIELD2

		echo "$UI_FIELD3"
		read FIELD3

	fi

	# Get STR_Location

	TMP="$FIELD1"
	if [ $(echo "$TMP"|grep "^/"|wc -l) -eq 1 ]; then LOC_TYPE=1;fi

	if [ $LOC_TYPE -eq 0 ]
	then
		if [ $(echo "$TMP"|grep -e "^http://" -e "^https://"|wc -l) -eq 1 ];then LOC_TYPE=2;fi
	fi

	if [ $LOC_TYPE -eq 0 ];then return 1;fi

	STR_LOCATION="$TMP"

	# Get STR_NAME (AIMG_NAME)

	TMP="$FIELD2"
	STR_NAME=$(echo "$TMP"|sed -e "s/:/_/g" -e 's/ /_/g' -e "s:/:_:g")

	# Get CHK_NOSYMLINK (NO_SYMLINK)

	TMP="$FIELD3"
	if [ -z "$TMP" ]
	then

		CHK_NOSYMLINK=1

	else

		if [ $(echo "$TMP"|grep -i -e "^true$" -e "^y$" -e "^yes$" -e "^yeah$" -e "^si$"|wc -l) -gt 0 ];then CHK_NOSYMLINK=1;fi

		if [ $(echo "$TMP"|grep -i -e "^false$" -e "^n$" -e "^no$" -e "^nay$"|wc -l) -gt 0 ];then CHK_NOSYMLINK=0;fi

	fi

	if [ $CHK_NOSYMLINK -eq -1 ]; then return 1; fi

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
	AIMG_FILEPATH=$(realpath -e "$DL_DIR"/"$TMP")
}

function _ui_show_results() {

	ECODE=$1

	if [ $ECODE -eq 0 ]
	then

		AIMG_NAME=$(cat "$CACHEDIR"/"results.AIMG_NAME"|head -n1)
		AIMG_APPDIR=$(cat "$CACHEDIR"/"results.AIMG_APPDIR"|head -n1)

		MSG="SUCCESSFULLY INSTALLED THE APPLICATION\n\nName: $AIMG_NAME\n\nPath: $AIMG_APPDIR"

		if [ $USE_YAD -eq 1 ]
		then
			ICON_FILEPATH=$(cat "$CACHEDIR"/"results.ICON_FILEPATH"|head -n1)
			yad --title="$UI_TITLE" \
				--window-icon="$UI_ICON" \
				--width=480 --height=240 \
				--fixed --center \
				--escape-ok \
				--image="$ICON_FILEPATH" \
				--text "$MSG" \
				--button="OK"
		fi
		if [ $USE_YAD -eq 0 ]
		then
			clear
			echo -e "$MSG"
			_util_wait_for_any_key
		fi

		rm "$CACHEDIR"/results.*

		return 0

	fi

	MSG="There has been an error"
	if [ $USE_YAD -eq 1 ]
	then

		yad --title="$UI_TITLE" \
			--window-icon="$UI_ICON" \
			--width=320 --height=160 \
			--fixed --center \
			--escape-ok \
			--text "$MSG" \
			--button="OK"

	fi
	if [ $USE_YAD -eq 0 ]
	then

		echo -e "$MSG"
		_util_wait_for_any_key

	fi

}

function _ui_try_again() {

	TMP="Try again or install another one?"

	if [ $# -gt 0 ]
	then

		TMP="$1\n\n$TMP"

	fi

	if [ $USE_YAD -eq 1 ]
	then

		yad --title="$UI_TITLE" \
			--window-icon="$UI_ICON" \
			--fixed --center \
			--width=320 --height=160 \
			--text="$TMP" \
			--button="Yes:0" \
			--button="No:1" \
			--buttons-layout=spread

		EC=$?

		echo "message EC: $EC"

		if ! [ $EC -eq 0 ];then exit 0; fi

	fi

	if [ $USE_YAD -eq 0 ]
	then

		echo "$TMP"

		_util_wait_for_any_key

		exit 0

	fi

}

###############################################################################

MSG=""

while true; do

	# echo "LOOP $(date)"

	if ! [ -z "$MSG" ];then _ui_try_again "$MSG";fi

	MSG=""

	_ui_main

	if [ $LOC_TYPE -eq 1 ]
	then

		_get_file_from_fs
		if ! [ $? -eq 0 ]
		then
			MSG="Failed to grab file from the filesystem"
			continue
		fi

	fi
	if [ $LOC_TYPE -eq 2 ]
	then

		_get_file_from_web
		if ! [ $? -eq 0 ]
		then
			MSG="Failed to download"
			continue
		fi

	fi

	if [ -z "$AIMG_FILEPATH" ]
	then

		MSG="App filepath not found...?"
		continue

	fi

	echo "AIMG_FILEPATH: $AIMG_FILEPATH"
	break

done

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

set +e

chmod +x "$NEXT_STEP"
"$NEXT_STEP" "$AIMG_FILEPATH"

_ui_show_results $?

_ui_try_again

exec $(realpath -e $0)
