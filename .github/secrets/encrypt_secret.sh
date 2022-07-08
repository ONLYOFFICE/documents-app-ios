#!/bin/bash

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
cd $BASE_DIR

SECRETS=(
    "../../fastlane/.env.secret"
    "../../Documents/Documents/Services/GoogleService-Info-dev.plist"
    "../../Documents/Documents/Services/GoogleService-Info-prod.plist"
    "../../Documents/Documents/Internal.plist"
    "../../Documents/Keys/api-project-948651087073-firebase-crashreporting-0ashu-f1015e074c.json"
    "../../Documents/Keys/F8D434904F7142C49EB3E4CD738CFE01.lic"
)

if [ -z "$GIT_DOCUMENTS_PASSPHRASE" ]
then
    echo "ERROR: Decrypt passphrase is not set"
    exit 1
fi

encrypt() {
    local file=$1
    echo "Create encrypt ${BASE_DIR}/$file.gpg"
    gpg --quiet --batch --yes --symmetric --cipher-algo AES256 --passphrase="$GIT_DOCUMENTS_PASSPHRASE" --output "${BASE_DIR}/$file".gpg "${BASE_DIR}/$file"
}

for secret in ${SECRETS[@]}; do
    encrypt $secret
done