# AppImage Installation Scripts

## What is this about

These scripts install an AppImage by decompressing it and integrating it to the system. These scripts can work with AppImages and SQUASHFS compressed AppDirs

## Hear me out

We can all aggree that Installing AppImages by decompressing them goes against what AppImages are supposed to be used, yes, but this is not a disadvantage on systems that are ran from compressed media, such as live systems for example

Bundling AppImages into live systems is very easy, but the problem is that the size of the resulting image file grows by a lot depending on the blobs that are being added, and this is the problem that I'm solving with these scripts

## Size comparisons

I have two SQUASHFS filesystems

- File A, "asere.squashfs" has AppImages directly copied inside it, these are normal dot AppImage files

- File B, "asere-2026-05-22.squashfs" has all of its AppImages decompressed

In the following picture, I'm comparing the disk space occupied by two SQUASHFS filesystems

<img width="1920" height="1080" alt="SQUASHFS filesystems" src="https://github.com/carlos-a-g-h/aimgin-scripts/blob/main/2026-05-22-142133_1920x1080_scrot.png?raw=true" />

In the following picture I mounted both filesystems to analyze the real size of "/usr/appimages/" in each of them

<img width="1920" height="1080" alt="AppImages VS decompressed AppImages" src="https://github.com/carlos-a-g-h/aimgin-scripts/blob/main/2026-05-22-142414_1920x1080_scrot.png?raw=true" />

The SQUASHFS compressed filesystem with bundled appimages (File A) is heavier, because AppImages are files that are already compressed and MKSQUASHFS cannot compress them when building the filesystem image

The SQUASHFS compressed filesystem with decompressed AppImages (File B) is lighter, in this case even with almost 4 times the occupied size in AppImages, this is because MKSQUASHFS is taking care of the compression of the entire filesystem including the applications that are provided as AppImages
