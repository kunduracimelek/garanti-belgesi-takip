import 'package:flutter/material.dart';

enum FontScale { small, medium, large }

extension FontScaleX on FontScale {
  double get factor {
    switch (this) {
      case FontScale.small:
        return 0.92;
      case FontScale.medium:
        return 1.0;
      case FontScale.large:
        return 1.15;
    }
  }

  String get label {
    switch (this) {
      case FontScale.small:
        return 'Küçük';
      case FontScale.medium:
        return 'Orta';
      case FontScale.large:
        return 'Büyük';
    }
  }

}

class AppSettings {
  ThemeMode themeMode;
  FontScale fontScale;
  bool notifyOneMonthBefore;
  bool notifyLastWeek;
  bool notifyDailySummary;
  bool biometricLock;
  bool cloudBackupEnabled;
  String userName;
  String userEmail;

  AppSettings({
    this.themeMode = ThemeMode.dark,
    this.fontScale = FontScale.medium,
    this.notifyOneMonthBefore = true,
    this.notifyLastWeek = true,
    this.notifyDailySummary = false,
    this.biometricLock = false,
    this.cloudBackupEnabled = false,
    this.userName = 'Kullanıcı',
    this.userEmail = '',
  });

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'fontScale': fontScale.name,
        'notifyOneMonthBefore': notifyOneMonthBefore,
        'notifyLastWeek': notifyLastWeek,
        'notifyDailySummary': notifyDailySummary,
        'biometricLock': biometricLock,
        'cloudBackupEnabled': cloudBackupEnabled,
        'userName': userName,
        'userEmail': userEmail,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == json['themeMode'],
        orElse: () => ThemeMode.dark,
      ),
      fontScale: FontScale.values.firstWhere(
        (f) => f.name == json['fontScale'],
        orElse: () => FontScale.medium,
      ),
      notifyOneMonthBefore: json['notifyOneMonthBefore'] as bool? ?? true,
      notifyLastWeek: json['notifyLastWeek'] as bool? ?? true,
      notifyDailySummary: json['notifyDailySummary'] as bool? ?? false,
      biometricLock: json['biometricLock'] as bool? ?? false,
      cloudBackupEnabled: json['cloudBackupEnabled'] as bool? ?? false,
      userName: json['userName'] as String? ?? 'Kullanıcı',
      userEmail: json['userEmail'] as String? ?? '',
    );
  }
}
