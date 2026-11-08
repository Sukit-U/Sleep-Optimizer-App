import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `applicationId` and the packaged `google-services.json` must agree, or the
/// google-services Gradle plugin fails the build with "No matching client found".
void main() {
  test('Android applicationId is a real id and matches google-services.json', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final appId = RegExp(r'applicationId = "([^"]+)"').firstMatch(gradle)!.group(1);

    final services = jsonDecode(
      File('android/app/google-services.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final packages = (services['client'] as List)
        .map((client) => client['client_info']['android_client_info']['package_name'] as String)
        .toList();

    expect(packages, contains(appId));
    expect(appId, isNot(startsWith('com.example')));
  });
}
