#!/bin/env bash
gh release upload $CM_TAG \
    build/**/outputs/flutter-apk/*.apk \
    build/**/outputs/bundle/**/*.aab
