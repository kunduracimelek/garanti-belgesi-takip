import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/app_settings.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_app_bar.dart';
import 'notification_settings_screen.dart';
import 'security_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsProvider = context.watch<SettingsProvider>();
    final settings = settingsProvider.settings;
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: const GlassAppBar(title: Text('Ayarlar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          _ProfileCard(settings: settings),
          const SizedBox(height: 24),
          Text('Görünüm', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _SectionCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ThemeButton(
                        icon: Icons.light_mode_rounded,
                        label: 'Aydınlık',
                        selected: settings.themeMode == ThemeMode.light,
                        onTap: () => settingsProvider.setThemeMode(ThemeMode.light),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ThemeButton(
                        icon: Icons.dark_mode_rounded,
                        label: 'Koyu',
                        selected: settings.themeMode == ThemeMode.dark,
                        onTap: () => settingsProvider.setThemeMode(ThemeMode.dark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Yazı Boyutu', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(settings.fontScale.label, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<FontScale>(
                  segments: [
                    ButtonSegment(value: FontScale.small, label: Text(FontScale.small.label)),
                    ButtonSegment(value: FontScale.medium, label: Text(FontScale.medium.label)),
                    ButtonSegment(value: FontScale.large, label: Text(FontScale.large.label)),
                  ],
                  selected: {settings.fontScale},
                  onSelectionChanged: (selection) => settingsProvider.setFontScale(selection.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Veri Yönetimi', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _SectionCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.folder_zip_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tüm Garanti Kayıtları', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('${productProvider.products.length} Ürün Kayıtlı', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.ios_share_rounded),
                  onPressed: () {
                    final data = productProvider.products.map((p) => p.toJson()).toList();
                    Share.share(const JsonEncoder.withIndent('  ').convert(data));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Hesap', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Bildirim Tercihleri'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security_outlined),
                  title: const Text('Güvenlik ve Gizlilik'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SecuritySettingsScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.errorContainer, foregroundColor: const Color(0xFF93000A)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hesap senkronizasyonu bu sürümde bulunmuyor — tüm veriler yalnızca bu cihazda saklanıyor.')),
                );
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Çıkış Yap'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final AppSettings settings;
  const _ProfileCard({required this.settings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              settings.userName.isNotEmpty ? settings.userName.substring(0, 1).toUpperCase() : 'V',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(settings.userName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (settings.userEmail.isNotEmpty)
                  Text(settings.userEmail, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editProfile(context, settings),
          ),
        ],
      ),
    );
  }

  void _editProfile(BuildContext context, AppSettings settings) {
    final nameCtrl = TextEditingController(text: settings.userName);
    final emailCtrl = TextEditingController(text: settings.userEmail);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Profili Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'İsim')),
            const SizedBox(height: 12),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'E-posta')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () {
              context.read<SettingsProvider>().updateProfile(name: nameCtrl.text.trim(), email: emailCtrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const _SectionCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeButton({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : null),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: selected ? Colors.white : null, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
