import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'providers/product_provider.dart';
import 'screens/root_shell.dart';
import 'theme/app_theme.dart';
import 'widgets/biometric_gate.dart';
import 'models/app_settings.dart';

class VaultifyApp extends StatelessWidget {
  const VaultifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final productProvider = context.watch<ProductProvider>();

    if (!settingsProvider.loaded || !productProvider.loaded) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final settings = settingsProvider.settings;

    return MaterialApp(
      title: 'Vaultify',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(settings.fontScale.factor),
          ),
          child: settings.biometricLock ? BiometricGate(child: child!) : child!,
        );
      },
      home: const RootShell(),
    );
  }
}
