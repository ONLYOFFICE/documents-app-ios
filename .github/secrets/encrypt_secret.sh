#!/bin/bash

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
cd $BASE_DIR

SECRETS=(
    "../../fastlane/.env.secret"
    "../../Documents/Documents/GoogleService-Info.plist"
    "../../Documents/Documents/Internal.plist"
    "../../Documents/Keys/api-project-948651087073-firebase-crashreporting-0ashu-f1015e074c.json"
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