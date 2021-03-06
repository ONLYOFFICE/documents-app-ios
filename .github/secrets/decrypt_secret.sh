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

decrypt() {
    local file=$1
    echo "Create decrypt ${BASE_DIR}/$file"
    gpg --quiet --batch --yes --decrypt --passphrase="$GIT_DOCUMENTS_PASSPHRASE" --output "${BASE_DIR}/$file" "${BASE_DIR}/$file".gpg
}

for secret in ${SECRETS[@]}; do
    decrypt $secret
done