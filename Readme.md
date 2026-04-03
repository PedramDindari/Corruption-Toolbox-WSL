# Corruption Toolbox for Linux (WSL2)

## Usage

0. Make sure the WSl installation and windows' virtualization stack is healthy. update/reinstall them if necessary.
    > Beside the main vhdx disk for each wsl instance, there are two extra vhd files associated to all wsl instances that are located in wsl installation directory (by default `C:\Program Files\WSL\system.vhd` and `C:\Program Files\WSL\tools\modules.vhd`), you can copy them and run simillar checks on them as below. **DO NOT TOUCH THESE TWO FILES DIRECTLY! COPY THEM IN ANOTHER LOCATION AND THEN MOUNT THEM AS INSTRUCTED, AND THEN REPLACE THEM IF NEEDED AFTER SHUTTING DOWN WSL!**
1. To check the integrity of the vhdx virtual disk file (located at ), you should run `fsck` on it while it is not mounted in the running wsl instance. So you need another minimal wsl instance to run this step in. you can import the backup vhdx itself as a new wsl instance and later unregister it.

    ```powershell
    wsl --import Rescue "path\to\temp\location" "path\to\sane\backup.vhdx" --vhd --version 2
    ```

    then you must mount the corrupt vhdx without mounting it as filesystem.

    ```powershell
    wsl --mount "path\to\corrupt.vhdx" --vhd --type ext4 --bare
    ```

    Now make sure the corrupt wsl instance isn't running and in the new "rescue" instance run `fsck` on the newly mounted drive (wsl usually prints where it is mounted, but you can always check inside linux with `sudo fdisk -l` or `lsblk`). Here we assume it is in sde:

    ```bash
    sudo fsck.ext4 -fvp /dev/sde
    ```

    After you're done, you can unmount that disk, and unregister the new wsl instance if you like.

    ```powershell
    wsl --unmount "path\to\corrupt.vhdx"
    wsl --unregister Rescue
    ```

2. If you have a known good backup from WSL's past, you can mount it in your WSL instance and do the checks.

    ```powershell
    wsl --mount "path\to\sane\backup.vhdx" --vhd --type ext4 --name bak
    ```

3. Run `filediffroot.sh` to check all real files in wsl against the past backup. Or use `filediff.sh` for a specific directory. (change the first lines in the scripts to point to the paths). Check the output file and replace files safely!
4. Run `heuristic_corruption_detector_root.sh` for heuristic checks on files that the backup doesn't cover. This will use file characteristics for known file types and try to hunt files that are possibly damaged.
5. After you're done, you can unmount that backup drive:

    ```powershell
    wsl --unmount "path\to\sane\backup.vhdx"
    ```

## Prerequisites

1. `ldd` is used in `heuristic_corruption_detector_root.sh` script but is not installed by default in ubuntu for wsl. The respective lines are commented out; uncomment them after installing `ldd`.
