#!/bin/bash
echo "Starting heuristic scan. This may take longer the more things changed since the backup."

REPORT="$HOME/linux_corruption_report.txt"
BAK_DIR="/mnt/wsl/bak" # location of last healthy backup

echo "Path | Status | Issue | Details" > "$REPORT"

# Find files not in backup, ignoring symlinks
find /usr /var /snap /opt /etc /srv /home /root -type f | while read -r filepath; do

    # 1. Skip .pyc files (just delete them later)
    if [[ "$filepath" == *.pyc || "$filepath" == *__pycache__* ]]; then continue; fi

    # Construct the path to the backup version
    # This assumes the directory structure is identical
    bak_file="$BAK_DIR$filepath"

    cur_size=$(stat -c%s "$filepath")
    # 2. Check if file exists in backup
    STATUS="UNKNOWN"
    if [ ! -f "$bak_file" ]; then
        STATUS="GAP_NEW"
    else
        # 3. Compare sizes and date modifieds as a fast check
        bak_size=$(stat -c%s "$bak_file")
        cur_date=$(stat -c%Y "$filepath")
        bak_date=$(stat -c%Y "$bak_file")

        if [ "$cur_size" -eq "$bak_size" ] && [ "$cur_date" -eq "$bak_date" ]; then
            continue
        elif [ "$cur_size" -eq "$bak_size" ]; then
            STATUS="DATE_MISMATCH"
        elif [ "$cur_date" -eq "$bak_date" ]; then
            STATUS="SIZE_MISMATCH"
        else
            STATUS="GAP_MISMATCH"
        fi
    fi

    # 4. If we reached here, it's a "Gap" file or a "*-Mismatch" file.
    # Get MIME type and extension
    mime=$(file -b --mime-type "$filepath")
    ext="${filepath##*.}"
    ext="${ext,,}"
    filename="${filepath##*/}"
    filename="${filename,,}"

    # --- GROUP 1: TEXT AND SOURCE CODE ---
    # Python, JS, C, C++, Bash, configs
    if [[ "$mime" == text/* || "$ext" =~ ^(py|pyi|map|js|ts|c|cpp|h|hpp|inc|cs|sh|txt|json|xml|html|css|ini|yaml|yml|md)$ ]] && (( cur_size > 1 )); then
        # Check if libmagic thinks the text file is corrupted binary data
        if [[ "$mime" == "application/octet-stream" || "$mime" == "application/x-data" ]]; then
            echo "$filepath | $STATUS | MIME_MISMATCH | Source file reads as compiled binary data" >> "$REPORT"
        else
            # Check for NULL bytes (Cross-talk or zero-drops)
            if grep -qaP '\x00' "$filepath"; then
                echo "$filepath | $STATUS | TEXT_NULL_INTRUSION | Contains binary nulls in text file" >> "$REPORT"
            fi
        fi
    fi

    # --- GROUP 2: COMPILED BINARIES AND LIBRARIES (.so) ---
    # We check if the file claims to be an ELF, OR if it has a .so extension
    if [[ "$mime" == *"application/x-executable"* || "$mime" == *"application/x-sharedlib"* || "$ext" == "so" || "$filename" == *.so.* ]]; then
        # readelf -h parses the ELF header. If it fails, the structure is destroyed.
        if ! readelf -h "$filepath" >/dev/null 2>&1; then
            echo "$filepath | $STATUS | ELF_HEADER_BROKEN | readelf rejected the binary structure" >> "$REPORT"
        #else
            # Deep check: see if the dynamic linker can resolve its internal tables
            #if ! ldd "$filepath" >/dev/null 2>&1; then
            #     echo "$filepath | $STATUS | LNK_BROKEN | ldd could not read dynamic links" >> "$REPORT"
            #fi
        fi
    fi

    # --- GROUP 3: ARCHIVES (.tar, .gz, .zip) ---
    if [[ "$ext" =~ ^(tar)$ || "$filename" == *.tar.* ]]; then
        if ! tar -tf "$filepath" >/dev/null 2>&1; then
            echo "$filepath | $STATUS | ARCHIVE_CORRUPT | Tar sequential structure is broken" >> "$REPORT"
        fi
    elif [[ "$ext" == "zip" ]]; then
        if ! unzip -tq "$filepath" >/dev/null 2>&1; then
            echo "$filepath | $STATUS | ARCHIVE_CORRUPT | Zip central directory mismatch" >> "$REPORT"
        fi
    fi

done

echo "WSL Scan Complete. Review $REPORT"
