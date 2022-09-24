#!/bin/env bash
GOOGLE_SERVICES_PATH="$CM_BUILD_DIR/android/app/google_services.json"
echo $GOOGLE_SERVICES | base64 --decode >$GOOGLE_SERVICES_PATH
