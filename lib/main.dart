import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/product_provider.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/update_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('tr_TR');
  await NotificationService.instance.init();

  final storage = StorageService();
  final settingsProvider = SettingsProvider(storage);
  final productProvider = ProductProvider(storage);
  await Future.wait([settingsProvider.load(), productProvider.load()]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: productProvider),
      ],
      child: const VaultifyApp(),
    ),
  );

  unawaited(UpdateService.checkForUpdate());
}
