#!/bin/bash

# About this script

# This script bakes the AppImage into the system by decompressing it and
# integrating it to the system. If the AppImage has a setup script, that
# script will be ran

# POC for the aimgin.*.sh scripts, but it does not work with SQUASHFS files, only with AppImages

# Readable Env Vars

# {

# IS_SFS
# Wether the AppImage is a SQUASHFS of an AppDir rather than a propper AppImage
#if [ -z "$IS_SFS" ]
#then
#	IS_SFS=0
#fi

# NAME_SPECIFY
# Specifies a name for the installdir
if [ -z "$NAME_SPECIFY" ]
then
	NAME_SPECIFY=""
fi

# NO_SYMLINK
# Forces the URUNTIME to AppDir/AppRun, assuming that it has a single main binary

if [ -z "$NO_SYMLINK" ]
then
	NO_SYMLINK=0
fi

# NO_SETUP
# Implies that the AppImage has no internal setup script (wasn't made by github/carlos-a-g-h)

if [ -z "$NO_SETUP" ]
then
	NO_SETUP=0
fi
if [ $NO_SETUP -eq 1 ]
then
	NO_SYMLINK=1
fi

# ANYAT
# ANYAT Stands for Any Appimage Tech (sets NO_SYMLINK and NO_SETUP to 1)
# Basically, it will integrate the AppImage by using the essential files that
# are inside any AppImage, instead of specific files from any distributor

if [ -z "$ANYAT" ]
then
	ANYAT=0
fi
if [ $ANYAT -eq 1 ]
then
	NO_SETUP=1
	NO_SYMLINK=1
fi

# }

INSTALLDIR="/usr/appimages"

# Dash E mode

# {

set -eux

# Get filepath and filename

AIMG_FILEPATH=$(realpath -e "$1")
AIMG_FILENAME=$(basename "$AIMG_FILEPATH")

# Extract the file

chmod +x "$AIMG_FILEPATH"
"$AIMG_FILEPATH" --appimage-extract

# Locate the real AppDir

EAPPDIR=$(realpath -e squashfs-root)
WDIR=$(dirname "$EAPPDIR")

# Get the dirname and dirpath

AIMG_NAME=""
NAME_FILE="$EAPPDIR"/_details/name.txt
if [ -f "$NAME_FILE" ]
then
	AIMG_NAME=$(sed -n 1p "$NAME_FILE")
fi
if [ -z "$AIMG_NAME" ]
then
	if [ -z "$NAME_SPECIFY" ]
	then
		AIMG_NAME="$AIMG_FILENAME"
	else
		AIMG_NAME="$NAME_SPECIFY"
	fi
fi
AIMG_DIRNAME="$AIMG_NAME"".installed"
AIMG_DIRPATH="$INSTALLDIR"/"$AIMG_DIRNAME"

# Rename AppDir to the "name"

mv -vf "$EAPPDIR" "$WDIR"/"$AIMG_DIRNAME"

# Move to Installation directory

mkdir -vp "$INSTALLDIR"
if [ -d "$AIMG_DIRPATH" ]
then
	rm -rf "$AIMG_DIRPATH"
fi
mv -vf "$WDIR"/"$AIMG_DIRNAME" "$INSTALLDIR"

# Install the software

echo "NO_SYMLINK: $NO_SYMLINK"
echo "NO_SETUP: $NO_SETUP"
echo "ANYAT: $ANYAT"

if [ $ANYAT -eq 0 ]
then

	# AppImage with specific structure

	if [ $NO_SETUP -eq 0 ]
	then

		# There is a setup script

		export APPDIR="$AIMG_DIRPATH"
		SCR_SETUP="$AIMG_DIRPATH""/bin/setup"

		if [ -f "$SCR_SETUP" ]
		then

			chmod +x "$SCR_SETUP"

			if [ $NO_SYMLINK -eq 0 ]
			then

				# Make symlinks to /usr/bin/
				export URUNTIME=""
				"$SCR_SETUP" --install --force

			else

				# DO NOT make symlinks to /usr/bin (single bin)
				export URUNTIME="$INSTALLDIR"/AppRun
				"$SCR_SETUP" --install --force --no-links

			fi

		else

			# There is NO setup script
			ANYAT=1

		fi

	else

		# There is NO setup script
		ANYAT=1

	fi

fi

if [ $ANYAT -eq 1 ]
then

	# For any kind of AppImage

	# Read from Desktop file

	if ! [ $(ls "$AIMG_DIRPATH"/*.desktop|wc -l) -eq 1 ]
	then
		echo "[!] Desktop file not found"
		exit 1
	fi
	DESKTOP_FILE=$(ls "$AIMG_DIRPATH"/*.desktop|head -n1)
	DESKTOP_RAW=$(realpath -e $DESKTOP_FILE)

	# Icon file

	ICON_SAME=1
	ICON_OK=""
	ICON_RAW=$(realpath -e "$AIMG_DIRPATH"/.DirIcon)

	ICON_NAME=$(awk "/^Icon=/" "$DESKTOP_RAW"|sed "s/^Icon=//")
	if [ -z "$ICON_NAME" ]
	then
		ICON_SAME=0
		ICON_NAME="$AIMG_NAME"
	fi

	if [ $(basename "$ICON_RAW") == ".DirIcon" ]
	then

		FORMAT=""
		if [ $(file "$ICON_RAW"|grep "PNG image data"|wc -l) -gt 0 ]
		then
			FORMAT="png"
		fi
		if [ -z $FORMAT ]
		then
			if [ $(file "$ICON_RAW"|grep "SVG Scalable Vector Graphics image"|wc -l) -gt 0 ]
			then
				FORMAT="svg"
			fi
		fi
		if [ -z $FORMAT ]
		then
			echo "[!] The icon has an unknown format"
			exit 1
		fi

		ICON_OK="$ICON_NAME"."$FORMAT"

	fi

	cp -va "$ICON_RAW" /usr/share/icons/"$ICON_OK"

	# Write new desktop file

	DESKTOP_OK="/usr/share/applications/""$AIMG_NAME"".desktop"
	touch "$DESKTOP_OK"
	echo "[Desktop Entry]" > "$DESKTOP_OK"
	echo "Version=1.0" >> "$DESKTOP_OK"
	echo "Type=Application" >> "$DESKTOP_OK"
	echo "Exec=$AIMG_DIRPATH/AppRun" >> "$DESKTOP_OK"
	if [ $ICON_SAME -eq 1 ]
	then
		awk "/^Icon=/" "$DESKTOP_RAW" >> "$DESKTOP_OK"
	else
		echo "Icon=$ICON_NAME" >> "$DESKTOP_OK"
	fi
	echo "StartupNotify=false" >> "$DESKTOP_OK"
	if [ $(awk "/^Name=/" "$DESKTOP_RAW"|wc -l) -eq 1 ]
	then
		awk "/^Name=/" "$DESKTOP_RAW" >> "$DESKTOP_OK"
	fi
	if [ $(awk "/^GenericName=/" "$DESKTOP_RAW"|wc -l) -eq 1 ]
	then
		awk "/^GenericName=/" "$DESKTOP_RAW" >> "$DESKTOP_OK"
	fi
	if [ $(awk "/^MimeType=/" "$DESKTOP_RAW"|wc -l) -eq 1 ]
	then
		awk "/^MimeType=/" "$DESKTOP_RAW" >> "$DESKTOP_OK"
	fi
	if [ $(awk "/^StartupWMClass=/" "$DESKTOP_RAW"|wc -l) -eq 1 ]
	then
		awk "/^StartupWMClass=/" "$DESKTOP_RAW" >> "$DESKTOP_OK"
	fi
	if [ $(awk "/^Categories=/" "$DESKTOP_RAW"|wc -l) -eq 1 ]
	then
		awk "/^Categories=/" "$DESKTOP_RAW" >> "$DESKTOP_OK"
	fi
	if [ $(awk "/^Keywords=/" "$DESKTOP_RAW"|wc -l) -eq 1 ]
	then
		awk "/^Keywords=/" "$DESKTOP_RAW" >> "$DESKTOP_OK"
	fi

	echo "contents of: $DESKTOP_OK : {"
	cat "$DESKTOP_OK"
	echo "}"

	# Setting permissions
	chmod +x "$DESKTOP_OK"
	chmod +x "$AIMG_DIRPATH"/AppRun
fi

# }

# All done

echo "
INSTALLED: $AIMG_NAME"
