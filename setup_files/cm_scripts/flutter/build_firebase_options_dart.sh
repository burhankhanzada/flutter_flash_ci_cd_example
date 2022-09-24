#!/bin/env bash
FIREBASE_OPTIONS_PATH="$CM_BUILD_DIR/lib/firebase_options.dart"
echo $FIREBASE_OPTIONS | base64 --decode >$FIREBASE_OPTIONS_PATH
