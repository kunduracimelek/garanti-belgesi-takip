import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class SecuritySettingsScreen extends StatelessWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final settings = settingsProvider.settings;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Güvenlik ve Gizlilik')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(Icons.security_rounded, size: 34, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 12),
                Text('Verileriniz Bu Cihazda', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  'Garanti ve fatura bilgileriniz yalnızca cihazınızda saklanır; bir sunucuya gönderilmez.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('Gelişmiş Koruma', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary, letterSpacing: 1)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: isDark ? AppColors.darkCard : theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SwitchListTile(
              secondary: const Icon(Icons.fingerprint_rounded),
              title: const Text('Biyometrik Kilit'),
              subtitle: const Text('Parmak izi veya yüz tanıma'),
              value: settings.biometricLock,
              onChanged: (v) async {
                if (v) {
                  final auth = LocalAuthentication();
                  final canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();
                  if (!canCheck) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bu cihazda biyometrik kimlik doğrulama bulunamadı.')),
                      );
                    }
                    return;
                  }
                }
                settingsProvider.setBiometricLock(v);
              },
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: isDark ? AppColors.darkCard : theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SwitchListTile(
              secondary: const Icon(Icons.cloud_sync_outlined),
              title: const Text('Bulut Yedekleme'),
              subtitle: const Text('Şu an için bu tercih yalnızca kaydedilir; bulut senkronizasyonu henüz aktif değildir.'),
              value: settings.cloudBackupEnabled,
              onChanged: settingsProvider.setCloudBackupEnabled,
            ),
          ),
          const SizedBox(height: 28),
          Text('Tehlikeli Bölge', style: theme.textTheme.labelLarge?.copyWith(color: AppColors.error, letterSpacing: 1)),
          const SizedBox(height: 10),
          Material(
            color: AppColors.errorContainer.withValues(alpha: isDark ? 0.25 : 0.5),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _confirmReset(context),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.delete_forever_rounded, color: AppColors.error),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Verilerimi Sıfırla', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Bu işlem geri alınamaz', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    final productProvider = context.read<ProductProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tüm Verileri Sil'),
        content: const Text('Tüm ürünler ve ayarlar kalıcı olarak silinecek. Bu işlem geri alınamaz. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await StorageService().clearAll();
              await productProvider.load();
              await settingsProvider.load();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
