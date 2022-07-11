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

decrypt() {
    local file=$1
    echo "Create decrypt ${BASE_DIR}/$file"
    gpg --quiet --batch --yes --decrypt --passphrase="$GIT_DOCUMENTS_PASSPHRASE" --output "${BASE_DIR}/$file" "${BASE_DIR}/$file".gpg
}

for secret in ${SECRETS[@]}; do
    decrypt $secret
done