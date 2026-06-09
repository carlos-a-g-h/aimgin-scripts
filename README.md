# AIMGIN: The AppImage "Installer"

## About this repo

I made an installer for AppImages, that is composed of two main scripts. These scripts install an AppImage by decompressing it and integrating it to the system. They can work with AppImages and AppDirs compressed as SQUASHFS files

For the sake of not repeating myself throughout this README file, I will refer to both AppImages and AppDirs compressed as SQUASHFS files as "application files" or "app files"

### Ok, hear me out

We can all aggree that installing AppImages by decompressing them goes against how AppImages are supposed to be used, yes, but this is not a disadvantage on systems that are ran from compressed media (such as live systems for example), it is an improvement

### Size comparisons

For the following real test I had two SQUASHFS filesystems

- File A, "asere.squashfs" has AppImages directly copied inside it, these are normal AppImage files and they are not decompressed

- File B, "asere-2026-05-22.squashfs" has all of its AppImages decompressed

In the following picture, I'm comparing the disk space occupied by two SQUASHFS filesystems

<img width="1920" height="1080" alt="SQUASHFS filesystems" src="https://github.com/carlos-a-g-h/aimgin-scripts/blob/main/2026-05-22-142133_1920x1080_scrot.png?raw=true" />

In the following picture I mounted both filesystems to analyze the real size of "/usr/appimages/" in each of them

<img width="1920" height="1080" alt="AppImages VS decompressed AppImages" src="https://github.com/carlos-a-g-h/aimgin-scripts/blob/main/2026-05-22-142414_1920x1080_scrot.png?raw=true" />

The SQUASHFS compressed filesystem with bundled AppImages (File A) is heavier, because AppImages are files that are already compressed and MKSQUASHFS cannot compress them when building the filesystem image

The SQUASHFS compressed filesystem with decompressed AppImages (File B) is lighter, in this case even with almost 4 times the occupied size in AppImages, this is because MKSQUASHFS compressed the entire filesystem including the applications that are provided as AppImages

### Conclusion

This is just yet another way to use AppImages, again, NOT recommended for traditional systems due to disk space usage, but you can use it in a traditional setup if you think disk space is cheap (if you already use Flatpaks or Snaps, you probably already think like that lmao)

## How to use

[![Easier than your mom](https://raw.githubusercontent.com/carlos-a-g-h/aimgin-scripts/refs/heads/main/Screenshot_20260607_175040_mpv.jpg)](ttps://ia902909.us.archive.org/5/items/appimage_installer_sh/appImage_installer_demo_by_carlos-a-g-h.mp4)

Watch a video [here](https://archive.org/download/appimage_installer_sh/appImage_installer_demo_by_carlos-a-g-h.mp4)

The video was uploaded to [archive dot org](https://archive.org/details/appimage_installer_sh)

### Requirements

The requirements depend on how much you want to do. If you want the full experience, install "yad" (for the UI), "wget" (to grab files from the internet using the UI) and "squashfs-tools" (for dealing with SQUASHFS files)

### Installation instructions

Step 1: [Download this repo](https://github.com/carlos-a-g-h/aimgin-the-appimage-installer/archive/refs/heads/main.zip) and unzip it

Step 2: Run "Setup.Install.desktop"

Step 3: Run "aimgin.desktop" or "AIMGIN, The AppImage Installer" from your DE's app launcher

### Easy mode

If you really want to install decompressed AppImages on your normal system, you can use the UI script ( aimgin.ui_yad.sh ). This UI is a frontend for the scripts, it can even download any app file from the internet by giving it an HTTP link instead of a path on your system

### Hard mode

#### Extractor script

aimgin.extractor.sh [FilePath]

The extractor script extracts the contents of the application file. After extracting, the script will run the installer script

"FilePath" is a path that leads to the application file, wether it's a normal AppImage or a SQUASHFS file

#### Installer script

aimgin.installer.sh [Name] [AppDir]

Performs the installation of an extracted application

"Name" is the name for the application, make sure it does not have any special characters such as spaces or slashes

"AppDir" is the path to an AppDir
