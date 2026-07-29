import 'dart:io';

void main(List<String> args) async {
  print('====================================================');
  print('        ShareHarbor Doctor Diagnostic Tool          ');
  print('====================================================\n');

  int passes = 0;
  int warnings = 0;
  int failures = 0;

  void reportPass(String checkName) {
    print('  [PASS] $checkName');
    passes++;
  }

  void reportWarn(String checkName, String details, String remedy) {
    print('  [WARN] $checkName');
    print('         Cause:  $details');
    print('         Remedy: $remedy\n');
    warnings++;
  }

  void reportFail(String checkName, String details, String remedy) {
    print('  [FAIL] $checkName');
    print('         Cause:  $details');
    print('         Remedy: $remedy\n');
    failures++;
  }

  // Check 1: Dart / Flutter Environment
  reportPass('Dart SDK Version: ${Platform.version.split(' ').first}');

  // Check 2: Android Receiver Activity Manifest Check
  final androidManifestFile = File('android/src/main/AndroidManifest.xml');
  if (androidManifestFile.existsSync()) {
    final manifestContent = androidManifestFile.readAsStringSync();
    if (manifestContent.contains('ShareHarborReceiverActivity') &&
        manifestContent.contains('android:exported="true"')) {
      reportPass('Android Manifest Receiver Activity declared and exported');
    } else {
      reportFail(
        'Android Manifest Configuration',
        'ShareHarborReceiverActivity missing or not set to exported="true".',
        'Declare <activity android:name=".ShareHarborReceiverActivity" android:exported="true"> in android/src/main/AndroidManifest.xml',
      );
    }
  } else {
    reportWarn(
      'Android Manifest File',
      'android/src/main/AndroidManifest.xml not found in current working directory.',
      'Run doctor from the package or target integration app root folder.',
    );
  }

  // Check 3: iOS Podspec & SPM Setup
  final podspecFile = File('ios/share_harbor.podspec');
  if (podspecFile.existsSync()) {
    reportPass('iOS CocoaPods Podspec exists (share_harbor.podspec)');
  } else {
    reportFail(
      'iOS Podspec Missing',
      'ios/share_harbor.podspec is missing.',
      'Ensure ios/share_harbor.podspec is present in the package directory.',
    );
  }

  final spmFile = File('ios/Package.swift');
  if (spmFile.existsSync()) {
    reportPass(
        'iOS Swift Package Manager configuration exists (Package.swift)');
  } else {
    reportWarn(
      'iOS SPM Configuration',
      'ios/Package.swift missing.',
      'Ensure Package.swift is present for SwiftPM support.',
    );
  }

  // Check 4: iOS Privacy Manifest
  final privacyManifestFile = File('ios/PrivacyInfo.xcprivacy');
  if (privacyManifestFile.existsSync()) {
    reportPass('iOS Privacy Manifest present (PrivacyInfo.xcprivacy)');
  } else {
    reportWarn(
      'iOS Privacy Manifest Missing',
      'PrivacyInfo.xcprivacy not found in ios/',
      'Create PrivacyInfo.xcprivacy declaring required file timestamp access reasons.',
    );
  }

  print('\n----------------------------------------------------');
  print('Doctor Summary: $passes PASS, $warnings WARN, $failures FAIL');
  print('----------------------------------------------------\n');

  if (failures > 0) {
    exit(1);
  }
}
