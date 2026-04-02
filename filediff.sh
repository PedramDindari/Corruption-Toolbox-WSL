#!/bin/bash
BACKUP_DIR="/mnt/wsl/bak"
CURRENT_DIR="/mnt/wslg/distro"

echo "Scanning... this may take a long time."
echo : > ./differrs.log

# Generate list of files in backup dir, get size, date modified and md5 (if attributes match)
find "$BACKUP_DIR" -type f -printf "%P|%s|%T@\n" | while read -r line; do
    rel_path=$(echo "$line" | cut -d'|' -f1)
    bak_size=$(echo "$line" | cut -d'|' -f2)
    bak_date=$(echo "$line" | cut -d'|' -f3 | cut -d'.' -f1)

    cur_file="$CURRENT_DIR/$rel_path"

    if [ -f "$cur_file" ]; then
        cur_size=$(stat -c%s "$cur_file")
        cur_date=$(stat -c%Y "$cur_file")

        if [ "$cur_size" -eq "$bak_size" ] && [ "$cur_date" -eq "$bak_date" ]; then
            bak_md5=$(md5sum "$BACKUP_DIR/$rel_path" | cut -d' ' -f1)
            cur_md5=$(md5sum "$cur_file" | cut -d' ' -f1)

            if [ "$cur_md5" != "$bak_md5" ]; then
                echo "[!] HASH MISMATCH: $rel_path" | tee --append ./differrs.log
            fi
        fi
    fi
done

echo "Done! check ./differrs.log"
