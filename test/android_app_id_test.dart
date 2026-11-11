import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Each product flavor packages its own `google-services.json`, and the
/// google-services Gradle plugin fails the build ("No matching client found")
/// when the flavor's applicationId is not registered in that file.
void main() {
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();
  final baseAppId =
      RegExp(r'applicationId = "([^"]+)"').firstMatch(gradle)!.group(1)!;
  final devSuffix =
      RegExp(r'applicationIdSuffix = "([^"]+)"').firstMatch(gradle)!.group(1)!;

  Map<String, dynamic> services(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  List<String> packages(String path) => (services(path)['client'] as List)
      .map((client) =>
          client['client_info']['android_client_info']['package_name'] as String)
      .toList();

  String projectId(String path) =>
      services(path)['project_info']['project_id'] as String;

  const devFlavor = 'android/app/src/dev/google-services.json';
  const prodFlavor = 'android/app/src/prod/google-services.json';

  test('Android applicationId is a real id and dev only adds a suffix', () {
    expect(baseAppId, 'com.snoozefriend.snoozemate');
    expect(baseAppId, isNot(startsWith('com.example')));
    expect(devSuffix, '.dev');
  });

  test('prod flavor google-services.json registers the base applicationId', () {
    expect(packages(prodFlavor), contains(baseAppId));
  });

  test('dev flavor google-services.json registers the suffixed applicationId',
      () {
    expect(packages(devFlavor), contains('$baseAppId$devSuffix'));
  });

  test('flavors point at different Firebase projects', () {
    expect(projectId(devFlavor), 'sleep-optimizer-dev');
    expect(projectId(prodFlavor), 'sleep-optimizer-59c83');
  });

  test('no unflavored google-services.json shadows the flavor configs', () {
    // Gradle would silently pick android/app/google-services.json for both
    // flavors and register the wrong project.
    expect(File('android/app/google-services.json').existsSync(), isFalse);
  });
}
