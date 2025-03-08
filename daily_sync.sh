#!/bin/bash
set -e
#############################################################
# daily_sync.sh - Daily Sync Script for PostFinance Statements
#
# Author: whotopia (GitHub ID: whotopia)
# Company: Entuura (Asia) Ltd
# Date: 8 March 2025
#
# Description:
# This script processes PostFinance CAMT.053 bank statements
# by calling the `pf-process-statements.py` program.
#
# Features:
# - Calls the Python script to import statements into Odoo.
# - Ensures the configuration file (`pf-lftp-config.sh`) exists before proceeding.
# - Logs output to a specified log file.
#
# Usage:
# 1. Ensure `pf-lftp-config.sh` exists and is properly configured.
# 2. Run the script:
#    ```
#    ./daily_sync.sh
#    ```
#
# Example pf-lftp-config.sh:
# ---------------------------
# # SFTP credentials for downloading bank statements
# USER="your_sftp_user"
# HOST="your.sftp.server"
# PORT=22
# KEYFILE="$HOME/.ssh/your_ssh_key.pem"
# LOCALDIR="$HOME/your_local_directory"
# LOGFILE="$HOME/logs/sftp_sync.log"
# LOGFILEDAILY="$HOME/logs/pfs-to-odoo.log"
#
# # Odoo credentials for processing statements
# ODOO_URL="http://localhost:8069"
# ODOO_DB="your_database"
# ODOO_USERNAME="your_username"
# ODOO_PASSWORD="your_password"
#
# # Odoo environment and script location
# ODOO_VENV="$HOME/odoo-venv"
# ODOO_SCRIPT_DIR="$HOME/scripts"
#
# ---------------------------
# Ensure this file exists and contains the correct values.
#
# Typical Crontab Setup:
# ---------------------------
# 0 1 * * * /home/odoo/pf-lftp-synch.sh
# 0 2 * * * /home/odoo/daily-sync.sh
# ---------------------------
# This sets up automated execution:
# - `pf-lftp-synch.sh` runs at 1:00 AM to download new statements.
# - `daily-sync.sh` runs at 2:00 AM to process the downloaded statements.
#
#
# Dependencies:
# - `bash`
# - `python3`
# - `pf-process-statements.py`
#
# License:
# This software is licensed under the MIT License. You are free to use,
# modify, and distribute it, provided that proper attribution is given to
# the original author. See the LICENSE file for more details.
#############################################################

# Load configuration variables
CONFIG_FILE=$(dirname "$0")/pf-lftp-config.sh
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Configuration file '$CONFIG_FILE' not found. Exiting."
  exit 1
fi
source "$CONFIG_FILE"

# Ensure required variables are set
REQUIRED_VARS=("LOGFILEDAILY" "ODOO_URL" "ODOO_DB" "ODOO_USERNAME" "ODOO_PASSWORD" "ODOO_VENV" "ODOO_SCRIPT_DIR")
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    echo "Error: Required variable '$var' is not set in pf-lftp-config.sh. Exiting."
    exit 1
  fi
done

# Change to home directory
cd "$HOME"

# Run the Python script to process statements
"$ODOO_VENV/bin/python" "$HOME/pf-process-statements.py" \
    "$LOCALDIR/yellow-net-reports" \
    --odoo-url "$ODOO_URL" \
    --db "$ODOO_DB" \
    --username "$ODOO_USERNAME" \
    --password "$ODOO_PASSWORD" \
    > "$LOGFILEDAILY" 2> "$LOGFILEDAILY"
