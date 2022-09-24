#!/bin/env bash

local_path="android/local.properties"

function prop {
    grep "${1}" ${local_path} | cut -d'=' -f2
}

version_name=$(prop 'flutter.versionName')
version_code=$(prop 'flutter.versionCode')

version="$version_name-$version_code"

cd build/**/outputs

function allAPK() {

    local array=($(echo flutter-apk/*.apk))

    for i in "${array[@]}"; do
        mv $i "${i%.apk}-$version.apk"
    done
}

function allAppBundle() {

    local array=($(echo bundle/**/*.aab))

    for i in "${array[@]}"; do
        mv $i "${i%.aab}-$version.aab"
    done
}

allAPK

allAppBundle
