#!/bin/env bash
KEY_PROPERTIES_PATH="$CM_BUILD_DIR/android/key.properties"
cat >>$KEY_PROPERTIES_PATH <<EOF
storePassword=$CM_KEYSTORE_PASSWORD
keyPassword=$CM_KEY_PASSWORD
keyAlias=$CM_KEY_ALIAS
storeFile=$CM_KEYSTORE_PATH
EOF
