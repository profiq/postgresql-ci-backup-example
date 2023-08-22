#!/bin/sh

PGUSER="${PGUSER}"
PGHOST="${PGHOST}"
PGPASSWORD="${PGPASSWORD}"
DB_NAME="${DB_NAME}"
ACTION="${ACTION:-backup}"

R2_BUCKET="${R2_BUCKET}"
FILE_NAME="${FILE_NAME}"

R2_ENDPOINT="${R2_ENDPOINT}"
R2_ACCESS_KEY_ID="${R2_ACCESS_KEY_ID}"
R2_SECRET_ACCESS_KEY="${R2_SECRET_ACCESS_KEY}"
R2_DEFAULT_REGION="${R2_DEFAULT_REGION}"
R2_OUTPUT_FORMAT="${R2_OUTPUT_FORMAT}"
BACKUP_PUB_KEY="${BACKUP_PUB_KEY}"
BACKUP_PRIVATE_KEY="${BACKUP_PRIVATE_KEY}"

# # Set AWS CLI configuration values
aws configure set aws_access_key_id $R2_ACCESS_KEY_ID
aws configure set aws_secret_access_key $R2_SECRET_ACCESS_KEY
aws configure set default.region $R2_DEFAULT_REGION
aws configure set default.output $R2_OUTPUT_FORMAT

CURRENT_DATE=`date +"%Y%m%dT%T"`

echo "${BACKUP_PUB_KEY}" > public_key.pem.pub

if [ "$ACTION" = "backup" ]; then
    # Download the db_file
    echo "Starting to backup the DB"
    PGPASSWORD="${PGPASSWORD}" pg_dump -U "${PGUSER}" -h "${PGHOST}" -vvv -Fc "${DB_NAME}"  > "${FILE_NAME}_${CURRENT_DATE}.tar"
    if [ $? -eq 0 ]; then 
    echo "Backup success!"; \
    else 
    echo "Backup failed!!!" && exit 1; \
    fi
    # Encrypt backup_file
    echo "Encrypting the backup file..."
    bzip2 "${FILE_NAME}_${CURRENT_DATE}.tar"
    openssl smime -encrypt -aes256 -binary -outform DEM -in "${FILE_NAME}_${CURRENT_DATE}.tar.bz2" -out "${FILE_NAME}_${CURRENT_DATE}.tar.bz2.enc" "./public_key.pem.pub"

    # Upload backup to cloudflare bucket
    echo "Uploading the file to bucket" 
    aws s3 cp "${FILE_NAME}_${CURRENT_DATE}.tar.bz2.enc" "s3://$R2_BUCKET/${FILE_NAME}_${CURRENT_DATE}.tar.bz2.enc" --endpoint-url "${R2_ENDPOINT}"
    if [ $? -eq 0 ]; then 
    echo "Upload success!"; \
    else 
    echo "Upload failed!!!" && exit 1; \
    fi
fi
if [ "$ACTION" = "restore" ]; then
    echo "${BACKUP_PRIVATE_KEY}" > private_key.pem
    echo "Downloading file from bucket"
    # Download file from S3
    aws s3 cp "s3://${R2_BUCKET}/${FILE_NAME}" "${FILE_NAME}" --endpoint-url "${R2_ENDPOINT}"
    if [ $? -eq 0 ]; then 
    echo "Download backup file success!"; \
    else 
    echo "Download backup file failed!!!" && exit 1; \
    fi
    # Decrypt file
    echo "Decrypting the file"
    openssl smime -decrypt -in "${FILE_NAME}" -binary -inform DEM -inkey "./private_key.pem" -out "$(basename "${FILE_NAME}" .enc)"
    # Unzip file
    bzip2 -d "$(basename "${FILE_NAME}" .enc)"
    # Restore database
    echo "Restoring the DB"
    PGPASSWORD="${PGPASSWORD}" pg_restore -U "${PGUSER}" -h "${PGHOST}" -d "${DB_NAME}" -c -v < "$(basename "${FILE_NAME}" .bz2.enc)"
    if [ $? -eq 0 ]; then 
    echo "Restore success!"; \
    else 
    echo "Restore failed!!!" && exit 1; \
    fi 
fi

