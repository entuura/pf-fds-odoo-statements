#!/bin/bash
set -e

#############################################################
# pf-lftp-synch.sh - PostFinance FDS SFTP Sync Script
#
# Author: whotopia (GitHub ID: whotopia)
# Company: Entuura (Asia) Ltd
# Date: 8 March 2025
#
# Description:
# This script downloads CAMT.053 bank statement files from the
# PostFinance FDS SFTP server (`mftp1.postfinance.ch`) using lftp.
# It ensures only new files are downloaded and logs the transfer.
#
# Features:
# - Securely connects to PostFinance SFTP server using an SSH key.
# - Downloads only new files to a local archive directory.
# - Logs all transfer activity.
# - Separates credentials and configuration variables into a
#   separate file (`pf-lftp-config.sh`) for security and flexibility.
# - Ensures all required programs (`lftp`, `ssh`) are installed before running.
#
# Usage:
# 1. Ensure `pf-lftp-config.sh` exists and is properly configured.
# 2. Run the script:
#    ```
#    ./pf-lftp-synch.sh
#    ```
#
# Example pf-lftp-config.sh:
# ---------------------------
# # SFTP credentials for downloading bank statements
# USER="your_sftp_user"
# HOST="mftp1.postfinance.ch"
# PORT=8022
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
# - `pf-lftp-synch.sh` runs at 1:00 AM to download new statements by calling this very python program
# - `daily-sync.sh` runs at 2:00 AM to process the downloaded statements.
#
# Ensure this file exists and contains the correct values.
#
# Dependencies:
# - `lftp`
# - `ssh`
# - `bash`
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
REQUIRED_VARS=("USER" "HOST" "PORT" "KEYFILE" "LOCALDIR" "LOGFILE")
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    echo "Error: Required variable '$var' is not set in pf-lftp-config.sh. Exiting."
    exit 1
  fi
done

# Ensure required programs are installed
REQUIRED_PROGRAMS=("lftp" "ssh")
for prog in "${REQUIRED_PROGRAMS[@]}"; do
  if ! command -v "$prog" &>/dev/null; then
    echo "Error: Required program '$prog' is not installed. Exiting."
    exit 1
  fi
done


RETURN=0

# set sftp:connect-program "ssh -a -x -i <keyfile>"
#ConnectParams="ssh -a -x -i $KEYFILE"
#set sftp:connect-program \"$ConnectParams\"

echo "Start sync: $(date)" >> "$LOGFILE"
mkdir -p "$LOCALDIR" || exit 1

lftp -c "
  set xfer:log 1
  set xfer:log-file $LOGFILE
  set sftp:connect-program \"ssh -a -x -i $KEYFILE -p $PORT\"
  open -u $USER,any_string_will_do sftp://$HOST
  pwd
  mirror --only-newer . $LOCALDIR/
  bye
" >> $LOGFILE


result=$?
if [ $result -ne 0 ]; then
  echo "ERROR in transfer" >> $LOGFILE
  echo "THERE WAS AN ERROR from PostFinance"
  RETURN=1
else
  echo "XFER Okay" >> $LOGFILE
fi

echo "End sync: $(date)" >> "$LOGFILE"
echo "............" >> "$LOGFILE"
exit $RETURN
