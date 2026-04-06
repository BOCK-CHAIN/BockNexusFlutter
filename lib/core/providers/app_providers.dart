import 'package:flutter_riverpod/flutter_riverpod.dart';

// Mock SharedPreferences — simulates first launch detection
final hasOnboardedProvider = NotifierProvider<HasOnboardedNotifier, bool>(HasOnboardedNotifier.new);

class HasOnboardedNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

// Splash finished loading
final splashCompleteProvider = NotifierProvider<SplashCompleteNotifier, bool>(SplashCompleteNotifier.new);

class SplashCompleteNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}
