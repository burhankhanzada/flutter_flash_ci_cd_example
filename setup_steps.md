# CI/CD Code to Release Pipeline

&nbsp;

## Repostiry Setup

---

- Create github reposiotry
- Clone the repository

&nbsp;

## Flutter Setup

---

```cmd
flutter create . --platforms android --org com.flutterflash.cicd 
```

> flutter_app/pubspec.yaml

```diff
...
-version: 1.0.0+1
+version: 0.0.0+0
...
```

> Note: This step is because if we use release-please on default version then on the first release we will be releaseing a production version app idicated by major part of the version which is not realistic because project develop over time so does version.

&nbsp;

## Setup Github Actions workflows

> flutter_app/.github/workflows/check_flutter.yml

```yaml
name: Check flutter formating, lints & Run Tests

on:
  pull_request:
    types: opened

jobs:
  check-flutter:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Setup flutter
        uses: subosito/flutter-action@v2

      - name: Install dependencies
        run: flutter pub get

      - name: Check formatting
        run: flutter format . -o none --set-exit-if-changed

      - name: Check lints
        run: flutter analyze

      - name: Run tests
        run: flutter test
```

### Release please

> flutter_app/.github/workflows/release_please.yml

```yaml
name: Release Please

on:
  push:
    branches: main

jobs:
  release-please:
    runs-on: ubuntu-latest
    steps:
      - uses: google-github-actions/release-please-action@v3
        with:
          command: manifest
```

> flutter_app/release-please-config.json

```json
{
  "packages": {
    ".": {
      "release-type": "dart",
      "changelog-path": "CHANGELOG.md",
      "include-component-in-tag": false
    }
  }
}
```

> flutter_app/.release-please-manifest.json

```json
{
  ".": "0.0.0"
}
```

&nbsp;

## Setup Codemagic config

> flutter_app/codemagic.yaml

```yaml
workflows:
  android-workflow:
    name: Android Workflow

    environment:
      groups:
        - keystore_credentials
        - github
        - firebase
        - play_console

    triggering:
      events:
        - tag

      cancel_previous_builds: true

      branch_patterns:
        - pattern: '*'
          include: true
          source: true

      tag_patterns:
        - pattern: '*'
          include: true

    cache:
      cache_paths:
        - $FLUTTER_ROOT/.pub-cache
        - $HOME/.gradle/caches

    scripts:
      - name: Print enviroment varaibles
        script: |
          set -ex
          printenv

      - name: Setup local.properties
        script: bash cm_scripts/android/build_local_properties.sh

      - name: Get Flutter packages
        script: flutter packages pub get

      - name: Generate files
        script: flutter pub run build_runner build

      - name: Build APK
        script: flutter build apk

      - name: Build AAB
        script: flutter build appbundle

    #   - name: Build Admin AAB
    #     script: flutter build appbundle --flavor admin -t "lib/main_admin.dart" --verbose

    #   - name: Build User AAB
    #     script: flutter build appbundle --flavor user -t "lib/main_user.dart" --verbose

    artifacts:
      - build/**/outputs/flutter-apk/**/*.apk
      - build/**/outputs/bundle/**/*.aab
      - build/**/outputs/**/mapping.txt
```

> flutter_app/cm_scripts/android/setup_local_properties.sh

```bash
#!/bin/env bash
LOCAL="$CM_BUILD_DIR/android/local.properties"
echo "flutter.sdk=$HOME/programs/flutter" >$LOCAL
```

&nbsp;

## Android Setup

### Generate keystore using keytool from Java JDK

```cmd
keytool -genkey -v -keystore flutterflash.keystore -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -storepass FlutterFlash -keypass FlutterFlash -alias FlutterFlash
```

> flutter_app/android/key.properties

```properties
storePassword=FlutterFlash
keyPassword=FlutterFlash
keyAlias=FlutterFlash
storeFile="E:\\Folder Name\\flutterflash.keystore"
```

> flutter_app/android/app/build.gradle

```diff

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0'
}

+def keystoreProperties = new Properties()
+def keystorePropertiesFile = rootProject.file('key.properties')
+if (keystorePropertiesFile.exists()) {
+    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
+}

...

+    signingConfigs {
+        release {
+            keyAlias keystoreProperties['keyAlias']
+            keyPassword keystoreProperties['keyPassword']
+            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
+            storePassword keystoreProperties['storePassword']
+        }
+    }
+
    buildTypes {
+       debug {
+           signingConfig signingConfigs.release
+       }
        release {
-            // TODO: Add your own signing config for the release build.
-            // Signing with the debug keys for now, so `flutter run --release` works.
-            signingConfig signingConfigs.debug
+            signingConfig signingConfigs.release
        }
    }

+   // flavorDimensions "flavor"
+
+   // productFlavors {
+   //    user {
+   //        dimension "flavor"
+   //    }
+   //    admin {
+   //        dimension "flavor"
+   //        applicationIdSuffix ".admin"
+   //        versionNameSuffix "-admin"
+   //    }
+   // }
...
```

> flutter_app/codemagic.yaml

```diff
...
      - name: Setup local.properties
        script: bash cm_scripts/android/build_local_properties.sh

+      - name: Setup keystore
+        script: bash cm_scripts/android/build_keystore.sh
+
+      - name: Setup key.properties
+        script: bash cm_scripts/android/build_key_properties.sh
...
```

> flutter_app/cm_scripts/android/build_keystore.sh

```bash
#!/bin/env bash
echo $CM_KEYSTORE | base64 --decode >$CM_KEYSTORE_PATH
keytool -list -v -keystore $CM_KEYSTORE_PATH \
-storepass $CM_KEYSTORE_PASSWORD -alias $CM_KEY_ALIAS
```

> flutter_app/cm_scripts/android/build_key_properties.sh

```bash
#!/bin/env bash
KEY_PROPERTIES_PATH="$CM_BUILD_DIR/android/key.properties"
cat >>$KEY_PROPERTIES_PATH <<EOF
storePassword=$CM_KEYSTORE_PASSWORD
keyPassword=$CM_KEY_PASSWORD
keyAlias=$CM_KEY_ALIAS
storeFile=$CM_KEYSTORE_PATH
EOF
```

&nbsp;

## Setup Firebase

### Cponnect project with firebase

```cmd
npm install -g firebase-tools
firebase login
firebase token:ci
dart pub global activate flutterfire_cli
flutterfire configure
```

> flutter_app/.gitignore

```yaml
...

# Firebase
android/app/google-services.json
lib/firebase_options.dart
```

> flutter_app/codemagic.yaml

```diff
...
      - name: Setup key.properties
        script: bash scripts/android/build_key_properties.sh

+     - name: Setup google_services.json
+        script: bash cm_scripts/android/build_google_services_json.sh
+
+     - name: Setup firebase_options.dart
+        script: bash cm_scripts/flutter/build_firebase_options_dart.sh
...
```

> flutter_app/cm_scripts/android/build_google_services_json.sh

```bash
#!/bin/env bash
GOOGLE_SERVICES_PATH="$CM_BUILD_DIR/android/app/google_services.json"
echo $GOOGLE_SERVICES | base64 --decode >$GOOGLE_SERVICES_PATH
```

> flutter_app/cm_scripts/flutter/build_firebase_options_dart.sh

```bash
#!/bin/env bash
FIREBASE_OPTIONS_PATH="$CM_BUILD_DIR/lib/firebase_options.dart"
echo $FIREBASE_OPTIONS | base64 --decode >$FIREBASE_OPTIONS_PATH
```

## Versioned names artifacts

> flutter_app/codemagic.yaml

```diff
...
      - name: Get Flutter packages
        script: flutter packages pub get

+     - name: Versioned name binaries
+       script: bash scripts/android/versioned_name_binaries.sh
...
```

## Upload artifacts to github release

> flutter_app/codemagic.yaml

```diff
...
+      - name: Upload to github release 
+        script: bash cm_scripts/upload_to_github_release.sh

      artifacts:
...
```

> flutter_app/cm_scripts/upload_to_github_release.sh

```bash
#!/bin/env bash
gh release upload $CM_TAG \
build/**/outputs/flutter-apk/*.apk \
build/**/outputs/bundle/**/*.aab
```

&nbsp;

## Publish artifacts to Firebase App Distrbution

```diff
    artifacts:
      - build/**/outputs/flutter-apk/**/*.apk
      - build/**/outputs/bundle/**/*.aab
      - build/**/outputs/**/mapping.txt

+   publishing:
+     firebase:
+       firebase_token: $FIREBASE_TOKEN
+       android:
+         app_id: $FIREBASE_ANDROID_APP_ID
+         groups:
+           - all
+         artifact_type: 'apk'
+       # android:
+       #   app_id: $FIREBASE_ANDROID_ADMIN_ID
+       #   groups:
+       #     - all
+       #   artifact_type: 'apk'
+       # android:
+       #   app_id: $FIREBASE_ANDROID_USER_ID
+       #   groups:
+       #     - all
+       #   artifact_type: 'apk'
```

> Note: Just uploading apk because firebase app distribution use play console internal app sharing for app bundle in which case app need to be setup on play console.

## Setup Project on Codemagic

1. Select git provider
2. Select repository
3. Choose project type as flutter App
4. Switch to YAML configuration
5. Go to enviroments variables
6. Add enviroments variables
7. Verify webhook add on git repository

### 6: Add enviroments variables

### According to group

`keystore_credentials` group

- `CM_KEYSTORE_PATH`
- `CM_KEYSTORE_PASSWORD`
- `CM_KEY_ALIAS`
- `CM_KEY_PASSWORD`
- `CM_KEYSTORE`

`github` group

- `GITHUB_TOKEN`

`firebase` group

- `FIREBASE_TOKEN`
- `FIREBASE_ANDROID_APP_ID`

`play_console` group

- `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS`

&nbsp;

### 7: Add webhook to github repository

1. Goto github repository
2. Goto repositry settings
3. Select webhook
4. Add webhook
5. Goto codemagic webhook settings
6. Copy the webhook from codemagic
7. Paste into `Payload URL` field of github webhook

&nbsp;

## First release as `0.1.0`

1. Stage all changes

2. Commit using conventional commit

```cmd
git commit --allow-empty -m "chore: release 0.1.0" -m "Release-As: 0.1.0"
```

>Note: second -m is for body/description in which `Release-As: x.x.x` must be included so that release-please will detect as release and set version to provided.

## Setup Play Console

Follow the steps on this [link](https://docs.codemagic.io/yaml-publishing/google-play/)

### Things to remember

- First time you have t manually upload the app bundle
- Package name can not be start as `com.example`
- Need to sign with your real keystore not android debug keystore
- Need to add privacy policy  
- If app is not reviwed yet only draft release will be created  

```diff
    publishing:
      firebase:
        firebase_token: $FIREBASE_TOKEN
        android:
          app_id: $FIREBASE_ANDROID_APP_ID
          groups:
            - all
          artifact_type: 'apk'
+
+     google_play:
+       credentials: $GCLOUD_SERVICE_ACCOUNT_CREDENTIALS
+       track: internal
+       rollout_fraction: 0.25
+       submit_as_draft: true 
```
