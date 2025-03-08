#!/usr/bin/env python3
"""
pf-process-statements.py - CAMT.053 File Processor for Odoo Integration

Author: whotopia (GitHub ID: whotopia)
Company: Entuura (Asia) Ltd
Date: 8 March 2025

Description:
This script processes CAMT.053 XML files from a specified directory, checks for blank files,
and imports valid statements into an Odoo instance via XML-RPC. It also includes a
connection test to validate Odoo credentials before processing.

This script has been primarily tested with PostFinance Bank files, which are automatically downloaded
via the PostFinance FDS service at `mftp1.postfinance.ch`. The program is designed solely to process
previously downloaded CAMT.053 statements and automatically load them into Odoo.
The actual download of statements is handled by a separate program, which should be executed before
running this script.

Features:
- Validates Odoo connection credentials before proceeding.
- Detects and logs blank CAMT.053 files (no transactions present).
- Extracts statement IDs from XML files.
- Skips duplicate statements that already exist in Odoo.
- Encodes and uploads valid XML files into Odoo's `account.statement.import` model.
- Provides logging and debug options for detailed tracking.

Usage:
- Run the script with the required arguments:
  ```
  python3 camt053_processor.py /path/to/directory --odoo-url=http://odoo.example.com --db=mydb --username=admin --password=secret
  ```
- Use `--blank` to only detect blank CAMT.053 files.
- Use `--test-connection` to validate Odoo credentials.
- Use `--debug` for verbose logging.

Dependencies:
- Python 3
- Standard libraries: os, logging, argparse, xml.etree.ElementTree, xmlrpc.client, base64

License:
This software is licensed under the MIT License. You are free to use, modify, and distribute it,
provided that proper attribution is given to the original author. See the LICENSE file for more details.
"""


import os
import logging
import argparse
import xml.etree.ElementTree as ET
import xmlrpc.client
import base64


import os
import logging
import argparse
import xml.etree.ElementTree as ET
import xmlrpc.client
import base64

def setup_logging(debug_mode):
    """Sets up logging."""
    logging.basicConfig(
        level=logging.DEBUG if debug_mode else logging.INFO,
        format="%(asctime)s - %(levelname)s - %(message)s",
    )
    logging.debug("Logging setup complete. Debug mode is active.")

def validate_odoo_connection(url, db, username, password):
    """Tests the connection to the Odoo database."""
    logging.debug(f"Validating connection to Odoo: {url}, DB: {db}, User: {username}")
    try:
        common = xmlrpc.client.ServerProxy(f"{url}/xmlrpc/2/common")
        uid = common.authenticate(db, username, password, {})
        if uid:
            logging.debug(f"Connection successful. User ID: {uid}")
            print(f"Connection successful: User ID {uid}")
            return uid
        else:
            logging.error("Authentication failed.")
            print("Authentication failed.")
            return None
    except Exception as e:
        logging.exception("Error connecting to Odoo:")
        return None

def is_blank_camt053(file_path):
    """Checks if a CAMT.053 file is blank (no transactions)."""
    logging.debug(f"Checking file for blank status: {file_path}")
    try:
        tree = ET.parse(file_path)
        root = tree.getroot()
        ns = {'ns': 'urn:iso:std:iso:20022:tech:xsd:camt.053.001.04'}
        entries = root.findall(".//ns:Ntry", ns)
        if not entries:
            logging.debug(f"File is blank: {file_path}")
            return True
        logging.debug(f"File has transactions: {file_path}")
        return False
    except ET.ParseError as e:
        logging.error(f"Error parsing XML file {file_path}: {e}")
        return False

def process_directory_for_blanks(directory):
    """Processes all CAMT.053 files in a directory to find blank files."""
    logging.debug(f"Processing directory for blank files: {directory}")
    for file_name in os.listdir(directory):
        file_path = os.path.join(directory, file_name)
        logging.debug(f"Inspecting file: {file_name}")
        if not file_name.lower().startswith("camt.053") or not file_name.endswith(".xml"):
            logging.debug(f"Skipping non-CAMT.053 file: {file_name}")
            continue

        if is_blank_camt053(file_path):
            print(f"Blank file detected: {file_name}")
            logging.info(f"Blank file: {file_name}")


def process_directory(directory, odoo_url, db, username, password, debug):
    if debug:
        logging.debug(f"Processing directory: {directory}")
    common = xmlrpc.client.ServerProxy(f"{odoo_url}/xmlrpc/2/common")
    uid = common.authenticate(db, username, password, {})
    models = xmlrpc.client.ServerProxy(f"{odoo_url}/xmlrpc/2/object")
    
    for file_name in os.listdir(directory):
        file_path = os.path.join(directory, file_name)
        if not file_name.endswith(".xml"):
            if debug:
                logging.debug(f"Skipping non-XML file: {file_name}")
            continue
        
        if debug:
            logging.debug(f"Inspecting file: {file_name}")
        
        if is_blank_camt053(file_path):
            logging.info(f"Skipping blank file: {file_name}")
            continue
        
        # Extract the statement ID
        try:
            with open(file_path, "r", encoding="utf-8") as file:
                tree = ET.parse(file)
                root = tree.getroot()
                ns = {'ns': 'urn:iso:std:iso:20022:tech:xsd:camt.053.001.04'}
                stmt_id_node = root.find(".//ns:Stmt/ns:Id", namespaces=ns)
                if stmt_id_node is None or not stmt_id_node.text:
                    logging.error(f"Could not extract statement ID from file: {file_name}")
                    continue
                stmt_id = stmt_id_node.text.strip()
        except Exception as e:
            logging.error(f"Error extracting statement ID from file {file_name}: {e}")
            continue

        if debug:
            logging.debug(f"Extracted statement ID: {stmt_id} from file: {file_name}")
        
        # Check if statement already exists in Odoo
        try:
            existing_statement = models.execute_kw(
                db,
                uid,
                password,
                "account.bank.statement",
                "search",
                [[["name", "=", stmt_id]]],
            )
            if existing_statement:
                logging.info(f"Statement with ID {stmt_id} already exists in Odoo. Skipping file: {file_name}")
                continue
        except Exception as e:
            logging.error(f"Error checking statement existence in Odoo for {stmt_id}: {e}")
            continue

        # Upload the file to Odoo
        try:
            with open(file_path, "rb") as file:
                file_data = file.read()
                encoded_file = base64.b64encode(file_data).decode("utf-8")
                statement_id = models.execute_kw(
                    db,
                    uid,
                    password,
                    "account.statement.import",
                    "create",
                    [{"statement_filename": file_name, "statement_file": encoded_file}],
                )
                models.execute_kw(
                    db,
                    uid,
                    password,
                    "account.statement.import",
                    "import_file_button",
                    [[statement_id]],
                )
            logging.info(f"Successfully uploaded file: {file_name} to Odoo.")
        except Exception as e:
            logging.error(f"Error uploading file {file_name} to Odoo: {e}")


def main():
    parser = argparse.ArgumentParser(description="Process CAMT.053 files and import into Odoo.")
    parser.add_argument("directory", help="Directory containing CAMT.053 files")
    parser.add_argument("--odoo-url", help="Odoo instance URL")
    parser.add_argument("--db", help="Odoo database name")
    parser.add_argument("--username", help="Odoo username")
    parser.add_argument("--password", help="Odoo password")
    parser.add_argument("--test-connection", action="store_true", help="Test connection to Odoo")
    parser.add_argument("--blank", action="store_true", help="Show blank files")
    parser.add_argument("--debug", action="store_true", help="Enable debug mode for detailed logs")

    args = parser.parse_args()

    setup_logging(args.debug)

    if args.blank:
        logging.debug("--blank flag detected. Skipping database connection.")
        process_directory_for_blanks(args.directory)
        return

    # Validate connection to Odoo if not using --blank
    connection_valid = validate_odoo_connection(args.odoo_url, args.db, args.username, args.password)
    if not connection_valid:
        print("Failed to connect to Odoo. Exiting.")
        return

    # Process directory
    process_directory(
        args.directory,
        args.odoo_url,
        args.db,
        args.username,
        args.password,
        args.debug,  # Pass the debug argument to the function
    )

if __name__ == "__main__":
    main()
