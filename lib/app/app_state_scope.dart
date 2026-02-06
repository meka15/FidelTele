import 'package:flutter/widgets.dart';

import 'app_state.dart';

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState super.notifier,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    if (scope == null) {
      throw FlutterError('AppStateScope not found in widget tree');
    }
    return scope.notifier!;
  }
}
