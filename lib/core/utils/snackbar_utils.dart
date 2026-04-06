import 'package:flutter/material.dart';

/// Shows a floating snack bar after the current frame so it does not race with
/// provider-driven rebuilds (e.g. cart refresh) that can clear or reset timers.
void showAppSnackBar(
  BuildContext context,
  String message, {
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 3),
  EdgeInsetsGeometry? margin,
}) {
  if (!context.mounted) return;

  void present() {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 16),
          dismissDirection: DismissDirection.horizontal,
          action: action,
        ),
      );
  }

  WidgetsBinding.instance.addPostFrameCallback((_) => present());
}
