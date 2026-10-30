/// إعدادات عامة للتطبيق.
///
/// غيّر [githubOwner] و [githubRepo] لو نقلت المستودع لحساب آخر.
class AppConfig {
  AppConfig._();

  static const githubOwner = 'qbrahym02-cmyk';
  static const githubRepo = 'flutter-todo-ota';
  static const branch = 'main';

  /// ملف الإعدادات عن بُعد. أي تعديل عليه في GitHub يظهر في التطبيق
  /// خلال دقائق بدون أي تحديث أو تثبيت.
  static const remoteConfigUrl =
      'https://raw.githubusercontent.com/$githubOwner/$githubRepo/$branch/remote/config.json';

  /// رابط تحميل آخر نسخة APK (يُستخدم فقط عند تغييرات Native كبيرة).
  static const latestApkUrl =
      'https://github.com/$githubOwner/$githubRepo/releases/latest/download/app-release.apk';
}
