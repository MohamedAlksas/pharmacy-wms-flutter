import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import 'package:package_info_plus/package_info_plus.dart';

import 'package:pharmacy_wms/Models/app_version.dart';
import 'package:pharmacy_wms/Services/api_config.dart';


class UpdateService {
  static const String _fallbackUrl =
      'https://raw.githubusercontent.com/test-pharm/pharmacy-wms-flutter/main/version.json';

  static AppVersion? _cachedRemote;
  static PackageInfo? _packageInfo;

  static Future<PackageInfo> get packageInfo async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    return _packageInfo!;
  }



  static Future<String> get currentVersion async {
    final info = await packageInfo;
    return info.version;
  }



  static Future<int> get currentBuildNumber async {
    final info = await packageInfo;
    return int.tryParse(info.buildNumber) ?? 0;
  }

  static Future<AppVersion?> _fetchFrom(String url) async {
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    return AppVersion.fromJson(decoded);
  }

  static Future<AppVersion?> fetchLatestVersion() async {
    // Try backend first (most reliable, no GitHub dependency)
    try {
      final backendUrl = '${ApiConfig.baseUrl}/Update';
      final remote = await _fetchFrom(backendUrl);
      if (remote != null) {
        _cachedRemote = remote;
        return remote;
      }
    } catch (e) {
      debugPrint('[UpdateService] Backend check failed: $e');
    }

    // Fall back to GitHub raw URL
    try {
      final remote = await _fetchFrom(_fallbackUrl);
      if (remote != null) {
        _cachedRemote = remote;
        return remote;
      }
    } catch (e) {
      debugPrint('[UpdateService] GitHub fallback failed: $e');
    }

    return _cachedRemote;
  }



  static Future<bool> isUpdateAvailable() async {
    try {
      final remote = await fetchLatestVersion();
      if (remote == null) return false;

      final localVersion = await currentVersion;
      final localBuild = await currentBuildNumber;

      return remote.isNewerThan(localVersion, localBuild);
    } catch (_) {
      return false;
    }
  }

}




  static Future<String> get currentVersion async {
    final info = await packageInfo;
    return info.version;
  }




  static Future<int> get currentBuildNumber async {
    final info = await packageInfo;
    return int.tryParse(info.buildNumber) ?? 0;
  }




  static Future<AppVersion?> fetchLatestVersion() async {
    try {
      final response = await http
          .get(Uri.parse(_versionUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      _cachedRemote = AppVersion.fromJson(decoded);
      return _cachedRemote;
    } catch (e) {
      debugPrint('[UpdateService] Failed to fetch latest version: $e');
      return _cachedRemote;
    }
  }




  static Future<bool> isUpdateAvailable() async {
    try {
      final remote = await fetchLatestVersion();
      if (remote == null) return false;

      final localVersion = await currentVersion;
      final localBuild = await currentBuildNumber;

      return remote.isNewerThan(localVersion, localBuild);
    } catch (_) {
      return false;
    }
  }

}
