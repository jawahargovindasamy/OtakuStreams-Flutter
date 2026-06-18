import 'dart:io' show Platform;
import 'dart:math' show Random;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'environment.dart';
import '../widgets/update_dialog.dart';

class UpdateService {
  static const String _lastCheckKey = 'last_update_check_time';
  static const String _deviceIdKey = 'update_device_id';
  static const int _cacheDurationHours = 6;

  static Future<void> checkAndShowUpdate(BuildContext context, {bool forceCheck = false}) async {
    // Web is always updated on reload, skip update check
    if (kIsWeb) return;

    // Only support Android and iOS update checks
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Check cache throttle
      if (!forceCheck) {
        final lastCheck = prefs.getInt(_lastCheckKey) ?? 0;
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        final difference = currentTime - lastCheck;
        final cacheDurationMs = _cacheDurationHours * 60 * 60 * 1000;

        if (difference < cacheDurationMs) {
          // Cached recently, skip remote check
          return;
        }
      }

      // Resolve or generate deviceId for rollout buckets
      String? deviceId = prefs.getString(_deviceIdKey);
      if (deviceId == null) {
        final rand = Random();
        deviceId = '${DateTime.now().microsecondsSinceEpoch}_${rand.nextInt(100000)}';
        await prefs.setString(_deviceIdKey, deviceId);
      }

      // Fetch package info
      final packageInfo = await PackageInfo.fromPlatform();
      
      // Calculate versionCode using the collision-free formula for current client version
      final versionParts = packageInfo.version.split('+')[0].split('.');
      int major = 1;
      int minor = 0;
      int patch = 0;
      
      if (versionParts.isNotEmpty) major = int.tryParse(versionParts[0]) ?? 1;
      if (versionParts.length > 1) minor = int.tryParse(versionParts[1]) ?? 0;
      if (versionParts.length > 2) patch = int.tryParse(versionParts[2]) ?? 0;
      
      final clientVersionCode = (major * 10000000) + (minor * 10000) + patch;

      final dio = Dio();
      final response = await dio.get(
        '${Environment.baseUrl}/app/version',
        queryParameters: {
          'platform': Platform.isAndroid ? 'android' : 'ios',
          'versionCode': clientVersionCode,
          'channel': Environment.channel,
          'environment': Environment.current,
          'deviceId': deviceId,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        
        // Save check timestamp
        await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);

        final bool updateAvailable = data['updateAvailable'] ?? false;
        if (updateAvailable && data['latest'] != null) {
          final bool forceUpdate = data['forceUpdate'] ?? false;
          final latest = data['latest'];
          final String versionName = latest['versionName'] ?? '';
          final int latestVersionCode = latest['versionCode'] ?? 0;
          final Map<String, dynamic> artifact = Map<String, dynamic>.from(latest['artifact'] ?? {});
          final List<dynamic> notesData = latest['releaseNotes'] ?? [];
          final List<String> releaseNotes = notesData.map((e) => e.toString()).toList();

          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: !forceUpdate,
              builder: (dialogContext) {
                return UpdateDialog(
                  versionName: versionName,
                  versionCode: latestVersionCode,
                  downloadUrl: artifact['url'] ?? '',
                  sha256: artifact['sha256'] ?? '',
                  size: artifact['size'] ?? 0,
                  releaseNotes: releaseNotes,
                  forceUpdate: forceUpdate,
                );
              },
            );
          }
        }
      }
    } catch (e) {
      // Silently fail update checks to avoid disrupting user experience
      debugPrint('Update check failed: $e');
    }
  }
}
