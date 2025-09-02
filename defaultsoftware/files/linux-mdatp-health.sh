#!/bin/bash

# Get current timestamp (YYYYMMDD_HHMMSS)
timestamp=$(date +"%Y%m%d_%H%M%S")

# Generate a random suffix to avoid collisions
random=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 6)

# Construct filename
outfile="/tmp/mdatp_health_${timestamp}_${random}.txt"

# Run commands, print to terminal and save to file
{
    echo "=== mdatp health ==="
    mdatp health
    echo

    echo "=== mdatp health --details antivirus ==="
    mdatp health --details antivirus
    echo

    echo "=== mdatp health --details cloud ==="
    mdatp health --details cloud
    echo

    echo "=== mdatp health --details definitions ==="
    mdatp health --details definitions
    echo

    echo "=== mdatp health --details edr ==="
    mdatp health --details edr
    echo

    echo "=== mdatp health --details engine ==="
    mdatp health --details engine
    echo

    echo "=== mdatp health --details features ==="
    mdatp health --details features
    echo

    echo "=== mdatp health --details network_protection ==="
    mdatp health --details network_protection
    echo

    echo "=== mdatp health --details permissions ==="
    mdatp health --details permissions
    echo

    echo "=== mdatp health --details scheduled_scan ==="
    mdatp health --details scheduled_scan
    echo

} | tee "$outfile"

# Empty line before file path
echo
echo "Output also written to: $outfile"
