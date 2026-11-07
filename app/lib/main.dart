import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/app_state.dart';
import 'core/connectivity.dart';
import 'core/notification_service.dart';
import 'core/offline_sync.dart';
import 'core/storage.dart';
import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final token = await TokenStorage.read();
  ApiClient.instance.token = token;
  await AppState.instance.load();
  await ConnectivityService.instance.init();
  await NotificationService.instance.init();
  if (token != null) {
    await OfflineSync.instance.init();
  }
  runApp(WalletgekApp(loggedIn: token != null));
}

class WalletgekApp extends StatelessWidget {
  final bool loggedIn;
  const WalletgekApp({super.key, required this.loggedIn});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppState.instance.themeModeNotifier,
      builder: (context, mode, _) {
        final themeMode = mode == 'dark'
            ? ThemeMode.dark
            : mode == 'light'
                ? ThemeMode.light
                : ThemeMode.system;
        return MaterialApp(
          title: 'walletgek',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: themeMode,
          home: loggedIn ? const MainShell() : const LoginScreen(),
        );
      },
    );
  }
}
