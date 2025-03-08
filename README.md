# pf-fds-odoo-statements

## Overview

This repository provides an automated solution for downloading and processing **PostFinance CAMT.053 bank statements** from the **PostFinance FDS SFTP service** and importing them into **Odoo 14**. The system consists of:

- **pf-lftp-synch.sh**: Downloads statements from the PostFinance SFTP server.
- **pf-process-statements.py**: Processes the statements and imports them into Odoo.
- **daily_sync.sh**: Calls `pf-process-statements.py` to process the downloaded statements.
- **pf-lftp-config.sh**: Stores all necessary credentials and settings (not included in the repo for security reasons).

This system supports multiple PostFinance accounts, provided the **account names in Odoo match the IBAN numbers** used by the bank.

## Features

- **Automated SFTP download** of CAMT.053 XML bank statements.
- **Odoo integration via XML-RPC** to import statements into the `account.bank.statement` module.
- **Ensures statements are not duplicated** in Odoo.
- **Debugging and logging options** for tracking issues.
- **Configurable and secure** credentials via a separate file (`pf-lftp-config.sh`).

## Requirements

- **Odoo 14** (Tested with this version only; may work with other versions but is unverified.)
- **A PostFinance FDS account** with SFTP access
- **A Linux server with Bash & Python 3 installed**
- **lftp and XML-RPC dependencies installed**
- **Odoo credentials** with sufficient permissions to import bank statements
- **Odoo installed using a virtual Python environment (venv)** (We assume that the correct Python environment has already been set up for running Odoo.)
- **Odoo OCA Addons**: The appropriate Odoo **OCA bank statement addons** must be installed to correctly process CAMT.053 files.

## Installation

1. Clone this repository:
   ```sh
   git clone https://github.com/yourusername/pf-fds-odoo-statements.git
   cd pf-fds-odoo-statements
   ```
2. Install dependencies:
   ```sh
   sudo apt install lftp
   ```
3. Configure **pf-lftp-config.sh** (see example below).
4. Ensure that the required **Odoo OCA addons** for processing CAMT.053 files are installed.
5. Set up a **cron job** (see below) to automate daily downloads and imports.

## Configuration File (`pf-lftp-config.sh`)

This file contains all necessary settings, including credentials and paths. **For security reasons, do not commit this file to GitHub.**

```sh
# SFTP credentials for downloading bank statements
USER="your_sftp_user"
HOST="your.sftp.server"
PORT=22
KEYFILE="$HOME/.ssh/your_ssh_key.pem"
LOCALDIR="$HOME/PostFinanceArchive2"
LOGFILE="$HOME/logs/sftp_sync.log"
LOGFILEDAILY="$HOME/logs/pfs-to-odoo.log"

# Odoo credentials for processing statements
ODOO_URL="http://localhost:8069"
ODOO_DB="your_database"
ODOO_USERNAME="your_username"
ODOO_PASSWORD="your_password"

# Odoo environment and script location
ODOO_VENV="$HOME/odoo-venv"
ODOO_SCRIPT_DIR="$HOME/scripts"
```

## Usage

1. **Download Statements Manually** (if needed):
   ```sh
   ./pf-lftp-synch.sh
   ```
2. **Process Statements Manually**:
   ```sh
   ./daily_sync.sh
   ```
3. **Automate with Cron** (Recommended):
   Add the following lines to your crontab (`crontab -e`) for the `odoo` user:
   ```sh
   0 1 * * * /home/odoo/pf-lftp-synch.sh
   0 2 * * * /home/odoo/daily-sync.sh
   ```
   - **1:00 AM**: Downloads new statements from PostFinance.
   - **2:00 AM**: Processes the downloaded statements and imports them into Odoo.

## How It Works

1. **pf-lftp-synch.sh** connects to PostFinance’s **SFTP FDS service** and downloads all new CAMT.053 XML statements.
2. **daily_sync.sh** ensures the **pf-lftp-config.sh** file is loaded correctly then calls **pf-process-statements.py** with the correct parameters.
3. **pf-process-statements.py** reads the downloaded statements, checks for duplicates, and imports valid statements into **Odoo 14**.
4. **Statements are mapped correctly** as long as the IBANs in the XML match the bank account names in Odoo.
5. **Odoo is assumed to be installed with a virtual Python environment (`venv`)**. If your setup differs, adjust the script paths accordingly.
6. **Odoo requires the appropriate OCA addons to correctly parse and process CAMT.053 files**.

## Troubleshooting

- Ensure **PostFinance FDS credentials** are correct in `pf-lftp-config.sh`.
- Check the **log files** (`logs/sftp_sync.log`, `logs/pfs-to-odoo.log`) for errors.
- Run scripts manually (`./pf-lftp-synch.sh`, `./daily_sync.sh`) and check outputs.
- If you encounter issues, report them via **GitHub Issues**.

## Contributing & Feedback

- **Report bugs** using the [GitHub Issues](https://github.com/entuura/pf-fds-odoo-statements/issues) tracker.
- **Submit Pull Requests** if you improve or extend functionality.
- For discussions, open a GitHub issue or start a conversation.

## License

This software is licensed under the **MIT License**. You are free to use, modify, and distribute it, provided that proper attribution is given to the original author.

---

This README provides **full documentation** for setting up **automated daily PostFinance statement imports into Odoo 14**. While tested with Odoo 14, it may work with other versions, but this has not been verified. **Ensure the appropriate Odoo OCA addons are installed for correct CAMT.053 processing.** Let me know if you need modifications before uploading to GitHub! 🚀


