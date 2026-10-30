import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../app_config.dart';

/// إعدادات تُقرأ من ملف JSON على GitHub.
/// عدّل `remote/config.json` في المستودع ← يتغير التطبيق عند كل المستخدمين
/// فوراً (خلال ~5 دقائق بسبب كاش GitHub) بدون أي تثبيت.
class RemoteConfig {
  final String appTitle;
  final Color primaryColor;
  final bool announcementEnabled;
  final String announcementText;
  final String? announcementUrl;
  final String emptyMessage;
  final bool showStats;
  final bool showPriority;
  final int minBuild;
  final int latestBuild;
  final String apkUpdateMessage;
  final String apkUrl;

  const RemoteConfig({
    this.appTitle = 'مهامي',
    this.primaryColor = const Color(0xFF4F46E5),
    this.announcementEnabled = false,
    this.announcementText = '',
    this.announcementUrl,
    this.emptyMessage = 'لا توجد مهام بعد — أضف أول مهمة!',
    this.showStats = true,
    this.showPriority = true,
    this.minBuild = 0,
    this.latestBuild = 0,
    this.apkUpdateMessage = 'يتوفر إصدار جديد من التطبيق.',
    this.apkUrl = AppConfig.latestApkUrl,
  });

  static Color _parseColor(dynamic v, Color fallback) {
    if (v is! String) return fallback;
    var hex = v.replaceAll('#', '').trim();
    if (hex.length == 6) hex = 'FF$hex';
    final n = int.tryParse(hex, radix: 16);
    return n == null ? fallback : Color(n);
  }

  factory RemoteConfig.fromJson(Map<String, dynamic> j) {
    const d = RemoteConfig();
    final ann = (j['announcement'] as Map?)?.cast<String, dynamic>() ?? {};
    final feat = (j['features'] as Map?)?.cast<String, dynamic>() ?? {};
    final upd = (j['apk_update'] as Map?)?.cast<String, dynamic>() ?? {};
    return RemoteConfig(
      appTitle: j['app_title'] as String? ?? d.appTitle,
      primaryColor: _parseColor(j['primary_color'], d.primaryColor),
      announcementEnabled: ann['enabled'] as bool? ?? false,
      announcementText: ann['text'] as String? ?? '',
      announcementUrl: ann['url'] as String?,
      emptyMessage: j['empty_message'] as String? ?? d.emptyMessage,
      showStats: feat['show_stats'] as bool? ?? true,
      showPriority: feat['show_priority'] as bool? ?? true,
      minBuild: (upd['min_build'] as num?)?.toInt() ?? 0,
      latestBuild: (upd['latest_build'] as num?)?.toInt() ?? 0,
      apkUpdateMessage: upd['message'] as String? ?? d.apkUpdateMessage,
      apkUrl: upd['apk_url'] as String? ?? d.apkUrl,
    );
  }
}

class RemoteConfigService extends ChangeNotifier {
  static const _cacheKey = 'remote_config_cache';

  RemoteConfig config = const RemoteConfig();
  DateTime? lastFetched;
  String? lastError;

  /// يحمّل آخر نسخة محفوظة (للعمل بدون إنترنت) ثم يجلب الجديد.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        config = RemoteConfig.fromJson(jsonDecode(cached));
        notifyListeners();
      } catch (_) {}
    }
    // لا ننتظر الشبكة عند الإقلاع.
    refresh();
  }

  Future<bool> refresh() async {
    try {
      // معامل عشوائي لتقليل أثر الكاش.
      final uri = Uri.parse(
          '${AppConfig.remoteConfigUrl}?t=${DateTime.now().millisecondsSinceEpoch}');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        lastError = 'HTTP ${res.statusCode}';
        notifyListeners();
        return false;
      }
      final body = utf8.decode(res.bodyBytes);
      config = RemoteConfig.fromJson(jsonDecode(body));
      lastFetched = DateTime.now();
      lastError = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, body);
      notifyListeners();
      return true;
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
      return false;
    }
  }
}
