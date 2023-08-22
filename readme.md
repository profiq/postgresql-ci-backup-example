# Database Backuper

This repository contains a script and a set of GitHub Actions to backup and restore a PostgreSQL database.

## Overview

The backup script, `backuper.sh`, can be used to backup a database to a file. The file is then encrypted and uploaded to a Cloudflare R2 bucket.

The restore script can be used to restore a database from a backup file.

The GitHub Actions are used to automate the backup and restore process. The `docker_image.yml` workflow builds a Docker image for the backup script. The `backup-wf.yml` workflow runs the backup script, and the `production_database.yml` workflow runs the restore script.

## Requirements

* A PostgreSQL database
* A Cloudflare R2 bucket
* The AWS CLI
* The OpenSSL command-line tool


## Creating Encryption Key Pair

To secure your backup files, you can generate an encryption key pair using OpenSSL. 
Remember that the private key should be kept secret, and the public key can be shared as needed.

Please note that this self-signed certificate is typically used for encryption and authentication within your own systems. For more secure scenarios, you might want to consider obtaining certificates from a trusted Certificate Authority (CA).


Follow these steps:

1. Open a terminal window.
2. Navigate to the directory where you want to store the keypair.
3. Run the following command:

   ```bash
   openssl req -x509 -nodes -newkey rsa:4096 -keyout backup_key.pem -out backup_key.pem.pub
   ```

## Instructions

1. Create a Cloudflare R2 bucket.
2. Generate a Key pair for encryption
3. Clone this repository.
4. Update the workflow files (docker_image.yml, production_database.yml) to match your configuration and image references.
5. In the GitHub repository settings, add the required secrets listed below.
6. Run the `docker_image.yml` workflow to build the Docker image.
7. Run the `backup-wf.yml` workflow to backup the database.


## Mandatory Secrets (Repository Settings > Secrets)

1. **PGHOST**: PostgreSQL host or IP address.
2. **PGPASSWORD**: PostgreSQL password for the specified user.
3. **R2_ACCESS_KEY_ID**: Cloudflare Storage access key.
4. **R2_SECRET_ACCESS_KEY**: Cloudflare Storage secret key.
5. **BACKUP_PUB_KEY**: Public key for backup encryption. ( backup_key.pem.pub )
6. **BACKUP_PRIVATE_KEY**: Private key for backup decryption. ( backup_key.pem )

