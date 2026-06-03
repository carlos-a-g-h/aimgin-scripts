# AppImage Installation Scripts

## What is this about

These scripts install an AppImage by decompressing it and integrating it to the system. These scripts can work with AppImages and SQUASHFS compressed AppDirs

## Hear me out

Installing AppImages by decompressing them goes against what AppImages are supposed to be used, yes, but this is not a disadvantage on systems that are ran from compressed media, such as live systems

## Size comparisons

Comparing the disk space occupied by SQUASHFS filesystems

<img width="1920" height="1080" alt="SQUASHFS filesystems" src="https://github.com/carlos-a-g-h/aimgin-scripts/blob/main/2026-05-22-142133_1920x1080_scrot.png?raw=true" />

Comparing the disk space occupied by bundled AppImages

<img width="1920" height="1080" alt="AppImages VS decompressed AppImages" src="https://github.com/carlos-a-g-h/aimgin-scripts/blob/main/2026-05-22-142414_1920x1080_scrot.png?raw=true" />

The SQUASHFS compressed filesystem with bundled appimages is heavier, because AppImages are files that are already compressed and MKSQUASHFS cannot compress them when building the filesystem image

The SQUASHFS compressed filesystem with decompressed AppImages (the one with the date in the filename) is lighter, in this case even with almost 4 times the occupied size in AppImages, this is because MKSQUASHFS is taking care of the compression of the entire filesystem including the applications that are provided as AppImages
