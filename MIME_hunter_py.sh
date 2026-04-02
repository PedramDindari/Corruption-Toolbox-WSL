#!/bin/bash
mkdir -p ./mime_types/inpy  # Path to temporary scratch and Output folder
cd ./mime_types/inpy
exts=("lib" "pb" "egg" "pyi" "mjs" "bin" "pyc" "whl" "gz" "bz2" "pem" "info" "mts" "inl" "scss" "bib" "tsv" "bat" "cjs" "afm" "cts" "sav" "template" "j2" "npy" "a" "npz" "tab" "solv" "pdb" "cmake" "onnx" "h5" "qml" "pyd" "dat" "map" "sip" "inc" "pri" "qm" "typed" "conf" "msg" "tcl" "pc" "ipp" "po" "sql" "mo" "prf" "prl" "ipynb" "pxd" "pyx" "bat" "qmltypes" "enc" "cc" "qdocconf" "mat" "jam" "patch" "proto" "ttf" "pak" "rst" "woff" "doctest" "cuh" "pxi") # List of extensions to check files for

for ext in "${exts[@]}"; do
    : > mimes.txt
    : > octets.txt
    echo "==> common mime types for $ext: <=="
    find "$HOME/micromamba" -name "*.$ext" -type f -print0 2>/dev/null | xargs -0 file --mime-type -N >> mimes.txt 2>/dev/null
    cut -s -d':' -f2 mimes.txt | sort -b | uniq -c | sort -bgr | tee "$ext types.txt"
    grep -Z "application/octet-stream\|application/x-data" mimes.txt | tr '\n' '\0' | cut -sz -d':' -f1 | xargs -0 file -bN 2>/dev/null | cut -d',' -f1 >> octets.txt
    sort octets.txt | uniq -c | sort -bgr | tee -a "$ext types.txt"
    echo ""
done
rm mimes.txt octets.txt
