#!/bin/env bash
echo $CM_KEYSTORE | base64 --decode >$CM_KEYSTORE_PATH
keytool -list -v -keystore $CM_KEYSTORE_PATH \
    -storepass $CM_KEYSTORE_PASSWORD -alias $CM_KEY_ALIAS
