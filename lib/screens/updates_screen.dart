import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/remote_config.dart';
import '../services/update_service.dart';

class UpdatesScreen extends StatelessWidget {
  const UpdatesScreen({super.key, required this.remote, required this.updates});

  final RemoteConfigService remote;
  final UpdateService updates;

  String _stateText(OtaState s) => switch (s) {
        OtaState.idle => 'لم يتم الفحص بعد',
        OtaState.checking => 'جاري البحث عن تحديث…',
        OtaState.downloading => 'جاري تنزيل التحديث…',
        OtaState.upToDate => 'أنت على آخر نسخة ✅',
        OtaState.readyToRestart => 'التحديث جاهز — أعد فتح التطبيق',
        OtaState.unavailable =>
          'التحديث عن بُعد غير مفعّل في هذه النسخة (بُنيت بدون Shorebird)',
        OtaState.error => 'تعذّر الفحص',
      };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([remote, updates]),
      builder: (context, _) {
        final busy = updates.state == OtaState.checking ||
            updates.state == OtaState.downloading;
        final cfg = remote.config;
        return Scaffold(
          appBar: AppBar(title: const Text('التحديثات')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Column(children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('إصدار التطبيق'),
                    subtitle: Text(
                        '${updates.appVersion} (build ${updates.buildNumber})'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.bolt),
                    title: const Text('رقم التحديث (Patch)'),
                    subtitle: Text(updates.currentPatch?.toString() ??
                        'لا يوجد — النسخة الأصلية'),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('تحديث الكود عن بُعد (Shorebird)',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Row(children: [
                        if (busy)
                          const Padding(
                            padding: EdgeInsetsDirectional.only(end: 8),
                            child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                        Expanded(child: Text(_stateText(updates.state))),
                      ]),
                      if (updates.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(updates.error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12)),
                        ),
                      const SizedBox(height: 12),
                      if (updates.state == OtaState.readyToRestart)
                        FilledButton.icon(
                          onPressed: updates.closeToApply,
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('إغلاق التطبيق لتفعيل التحديث'),
                        )
                      else
                        FilledButton.tonalIcon(
                          onPressed: busy || !updates.shorebirdAvailable
                              ? null
                              : updates.check,
                          icon: const Icon(Icons.refresh),
                          label: const Text('البحث عن تحديث'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('الإعدادات عن بُعد',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(remote.lastFetched == null
                          ? 'لم يتم الجلب بعد'
                          : 'آخر جلب: ${TimeOfDay.fromDateTime(remote.lastFetched!).format(context)}'),
                      if (remote.lastError != null)
                        Text(remote.lastError!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12)),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: remote.refresh,
                        icon: const Icon(Icons.cloud_sync_outlined),
                        label: const Text('تحديث الإعدادات'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse(cfg.apkUrl),
                    mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.download),
                label: const Text('تحميل آخر نسخة APK كاملة'),
              ),
            ],
          ),
        );
      },
    );
  }
}
