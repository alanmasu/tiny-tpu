#!/bin/bash

# Directory sorgenti
SRC_DIR="src"

# Directory destinazione
DST_DIR="verilog"

# File di log
LOG_DIR="log"
LOG_FILE="${LOG_DIR}/sv2v_conversion.log"

# Crea la directory destinazione se non esiste
mkdir -p "$DST_DIR"
mkdir -p "$LOG_DIR"

# Pulisce il log precedente
echo "Conversione iniziata il $(date)" > "$LOG_FILE"

# Ciclo di conversione
for file in "$SRC_DIR"/*.sv; do
    base=$(basename "$file" .sv)
    echo "Converting $file → $DST_DIR/$base.v"
    
    # Converte e appende stdout + stderr al log
    sv2v "$file" > "$DST_DIR/$base.v" 2>&1 | tee -a "$LOG_FILE"
    
    # Scrive anche un separatore nel log
    echo "=== $file conversion finished ===" >> "$LOG_FILE"
done

echo " Conversione completata! Tutti i log sono in $LOG_FILE"
