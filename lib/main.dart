import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/remote_config.dart';
import 'services/task_store.dart';
import 'services/update_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final store = TaskStore()..load();
  final remote = RemoteConfigService()..init();
  final updates = UpdateService()..init();
  runApp(TodoApp(store: store, remote: remote, updates: updates));
}

class TodoApp extends StatefulWidget {
  const TodoApp({
    super.key,
    required this.store,
    required this.remote,
    required this.updates,
  });

  final TaskStore store;
  final RemoteConfigService remote;
  final UpdateService updates;

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// كل ما رجع المستخدم للتطبيق نفحص التحديثات والإعدادات.
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      widget.remote.refresh();
      widget.updates.check();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.remote,
      builder: (context, _) {
        final cfg = widget.remote.config;
        ThemeData theme(Brightness b) => ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: cfg.primaryColor,
                brightness: b,
              ),
            );
        return MaterialApp(
          title: cfg.appTitle,
          debugShowCheckedModeBanner: false,
          theme: theme(Brightness.light),
          darkTheme: theme(Brightness.dark),
          // واجهة عربية من اليمين لليسار.
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
          home: HomeScreen(
            store: widget.store,
            remote: widget.remote,
            updates: widget.updates,
          ),
        );
      },
    );
  }
}
