import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// حالة التحديث كما تظهر للمستخدم.
enum OtaState { idle, checking, downloading, upToDate, readyToRestart, unavailable, error }

/// يدير التحديثات عن بُعد عبر Shorebird Code Push.
///
/// - عند إرسال `shorebird patch android` (أو push على main عبر GitHub Actions)
///   يُنزّل التطبيق كود Dart الجديد في الخلفية.
/// - يُطبَّق التحديث عند إعادة فتح التطبيق — بدون تحميل APK جديد.
class UpdateService extends ChangeNotifier {
  final ShorebirdUpdater _updater = ShorebirdUpdater();

  OtaState state = OtaState.idle;
  int? currentPatch;
  String appVersion = '';
  int buildNumber = 0;
  String? error;

  bool get shorebirdAvailable => _updater.isAvailable;

  Future<void> init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = info.version;
      buildNumber = int.tryParse(info.buildNumber) ?? 0;
    } catch (_) {}

    if (!_updater.isAvailable) {
      state = OtaState.unavailable;
      notifyListeners();
      return;
    }
    try {
      currentPatch = (await _updater.readCurrentPatch())?.number;
    } catch (_) {}
    notifyListeners();
    // لا نوقف الإقلاع بانتظار الشبكة.
    check();
  }

  /// يفحص وجود تحديث، وينزّله تلقائياً إن وُجد.
  Future<void> check() async {
    if (!_updater.isAvailable) {
      state = OtaState.unavailable;
      notifyListeners();
      return;
    }
    if (state == OtaState.checking || state == OtaState.downloading) return;
    state = OtaState.checking;
    error = null;
    notifyListeners();
    try {
      final status = await _updater.checkForUpdate();
      switch (status) {
        case UpdateStatus.outdated:
          state = OtaState.downloading;
          notifyListeners();
          await _updater.update();
          state = OtaState.readyToRestart;
        case UpdateStatus.restartRequired:
          state = OtaState.readyToRestart;
        case UpdateStatus.upToDate:
          state = OtaState.upToDate;
        case UpdateStatus.unavailable:
          state = OtaState.unavailable;
      }
    } on UpdateException catch (e) {
      state = OtaState.error;
      error = e.message;
    } catch (e) {
      state = OtaState.error;
      error = e.toString();
    }
    notifyListeners();
  }

  /// يغلق التطبيق؛ عند فتحه مجدداً يعمل بالتحديث الجديد.
  Future<void> closeToApply() async {
    await SystemNavigator.pop();
  }
}
