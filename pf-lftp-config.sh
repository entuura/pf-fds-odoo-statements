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
