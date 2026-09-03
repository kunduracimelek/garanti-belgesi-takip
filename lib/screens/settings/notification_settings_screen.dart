import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final settings = settingsProvider.settings;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final productProvider = context.read<ProductProvider>();

    Future<void> rescheduleAll() async {
      await NotificationService.instance.rescheduleAll(productProvider.products, settingsProvider.settings);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bildirim Tercihleri')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                _NotifTile(
                  icon: Icons.calendar_month_rounded,
                  title: 'Garanti Bitmeden 1 Ay Önce Bildir',
                  subtitle: 'Süreniz dolmadan harekete geçin',
                  value: settings.notifyOneMonthBefore,
                  onChanged: (v) async {
                    await context.read<SettingsProvider>().setNotifyOneMonthBefore(v);
                    await requestPermsIfNeeded();
                    await rescheduleAll();
                  },
                ),
                const Divider(height: 24),
                _NotifTile(
                  icon: Icons.warning_amber_rounded,
                  title: 'Son Hafta Bildir',
                  subtitle: 'Son şansınız için kritik uyarı',
                  value: settings.notifyLastWeek,
                  onChanged: (v) async {
                    await settingsProvider.setNotifyLastWeek(v);
                    await requestPermsIfNeeded();
                    await rescheduleAll();
                  },
                ),
                const Divider(height: 24),
                _NotifTile(
                  icon: Icons.wb_sunny_outlined,
                  title: 'Her Sabah 09:00 Özeti',
                  subtitle: 'Gününüzü planlamak için günlük durum',
                  value: settings.notifyDailySummary,
                  onChanged: (v) async {
                    await requestPermsIfNeeded();
                    await settingsProvider.setNotifyDailySummary(v);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> requestPermsIfNeeded() async {
    await NotificationService.instance.requestPermissions();
  }
}

class _NotifTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _NotifTile({required this.icon, required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              Text(subtitle, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
