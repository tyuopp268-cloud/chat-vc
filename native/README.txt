
Voice Lab - Native Android Files

Required files:
- native/AndroidManifest.xml
- native/MainActivity.kt
- native/AudioService.kt
- native/app-build.gradle

These files are copied into the generated Flutter Android project by codemagic.yaml.

Main Flutter file:
- lib/main.dart

Root files:
- pubspec.yaml
- codemagic.yaml

Build output:
- build/app/outputs/flutter-apk/app-release.apk

Important:
The current AudioService is a prototype.
It captures microphone audio and processes samples in memory.
It does not yet output modified audio or inject audio into other apps.
