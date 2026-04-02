#!/bin/bash
BACKUP_DIR="/mnt/wsl/bak" # Path to known good backup root, leave empty for checking current root
mkdir -p ./mime_types  # Path to temporary scratch and Output folder
cd ./mime_types
exts=("so" "journal~" "journal" "gz" "xz" "bz2" "tar" "bin" "ko" "wasm" "dat" "0-linux-x64" "1-linux-x64" "md5sums" "basic" "gresource" "list" "symbols" "info" "msg" "gold" "afm" "inl" "mts" "proto" "tiktoken" "ids" "tsv" "cache" "templates" "tiny" "pl" "a" "mjs" "enc" "tcl" "cuh" "hwdb" "mgc" "npz" "db" "cjs" "mo" "tm" "cts" "conf" "scss" "bfd" "ucm" "cc" "bc" "utf-8" "pod" "patch" "real" "ppm" "tsbuildinfo" "zi" "toml" "triggers" "postinst" "vim" "node" "pm" "inc") # List of extensions to check files for, currently these are the ones taking most space

for ext in "${exts[@]}"; do
    : > mimes.txt
    : > octets.txt
    echo "==> common mime types for $ext: <=="
    find "$BACKUP_DIR/usr" "$BACKUP_DIR/var" "$BACKUP_DIR/snap" "$BACKUP_DIR/opt" "$BACKUP_DIR/etc" "$BACKUP_DIR/srv" "$BACKUP_DIR/home" "$BACKUP_DIR/root" -name "*.$ext" -type f -print0 2>/dev/null | xargs -0 file --mime-type -N >> mimes.txt 2>/dev/null
    cut -s -d':' -f2 mimes.txt | sort -b | uniq -c | sort -bgr | tee "$ext types.txt"
    grep -Z "application/octet-stream\|application/x-data" mimes.txt | tr '\n' '\0' | cut -sz -d':' -f1 | xargs -0 file -bN 2>/dev/null | cut -d',' -f1 >> octets.txt
    sort octets.txt | uniq -c | sort -bgr | tee -a "$ext types.txt"
    echo ""
done
rm mimes.txt octets.txt
