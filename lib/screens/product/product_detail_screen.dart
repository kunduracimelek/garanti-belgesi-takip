import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';
import 'add_edit_product_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().products;
    final product = products.where((p) => p.id == productId).cast<WarrantyProduct?>().firstWhere((p) => true, orElse: () => null);

    if (product == null) {
      return const Scaffold(body: Center(child: Text('Ürün bulunamadı')));
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = AppTheme.statusColor(context, isDark: isDark, daysRemaining: product.daysRemaining, expired: product.isExpired);
    final dateFmt = DateFormat('d MMMM yyyy', 'tr_TR');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün Detay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AddEditProductScreen(existing: product)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _confirmDelete(context, product),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                child: Text(
                  product.isExpired ? 'Süresi Doldu' : 'Aktif Garanti · ${product.remainingLabel}',
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(product.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          if (product.serialNumber != null && product.serialNumber!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Seri No: ${product.serialNumber}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.receipt_long_rounded,
                  label: 'Faturayı Aç',
                  onTap: product.invoiceFilePath == null ? null : () => OpenFilex.open(product.invoiceFilePath!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.ios_share_rounded,
                  label: 'Paylaş',
                  onTap: () => Share.share(
                    '${product.name}\nGaranti Bitiş: ${dateFmt.format(product.endDate)}\nDurum: ${product.remainingLabel}',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text('Garanti Süreci', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _Timeline(product: product, dateFmt: dateFmt, statusColor: statusColor),
          const SizedBox(height: 28),
          Text('Satın Alma Detayları', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _DetailsCard(product: product),
          if (product.notes != null && product.notes!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Notlar', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(product.notes!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WarrantyProduct product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ürünü Sil'),
        content: Text('"${product.name}" kalıcı olarak silinecek. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<ProductProvider>().deleteProduct(product.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: onTap == null ? theme.disabledColor : theme.colorScheme.primary),
              const SizedBox(height: 6),
              Text(label, style: theme.textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final WarrantyProduct product;
  final DateFormat dateFmt;
  final Color statusColor;
  const _Timeline({required this.product, required this.dateFmt, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TimelineRow(dotColor: theme.colorScheme.primary, title: 'Satın Alma', subtitle: dateFmt.format(product.purchaseDate)),
          const SizedBox(height: 16),
          _TimelineRow(
            dotColor: statusColor,
            title: 'Bugün',
            subtitle: product.remainingLabel,
            progress: product.progressFraction,
          ),
          const SizedBox(height: 16),
          _TimelineRow(dotColor: theme.colorScheme.onSurfaceVariant, title: 'Garanti Bitiş', subtitle: dateFmt.format(product.endDate), muted: true),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final Color dotColor;
  final String title;
  final String subtitle;
  final double? progress;
  final bool muted;
  const _TimelineRow({required this.dotColor, required this.title, required this.subtitle, this.progress, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 12, height: 12, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.labelLarge?.copyWith(color: muted ? theme.colorScheme.onSurfaceVariant : null)),
              Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: muted ? theme.colorScheme.onSurfaceVariant : dotColor, fontWeight: FontWeight.w500)),
              if (progress != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(dotColor),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final WarrantyProduct product;
  const _DetailsCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

    final rows = <MapEntry<String, String>>[
      if (product.store != null && product.store!.isNotEmpty) MapEntry('Satıcı', product.store!),
      if (product.invoiceNumber != null && product.invoiceNumber!.isNotEmpty) MapEntry('Fatura No', product.invoiceNumber!),
      if (product.price != null) MapEntry('Toplam Tutar', currencyFmt.format(product.price)),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          if (rows.isEmpty)
            Text('Satın alma bilgisi girilmedi.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))
          else
            for (int i = 0; i < rows.length; i++) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(rows[i].key, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  Text(rows[i].value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              if (i != rows.length - 1) const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
            ],
          if (product.invoiceFilePath != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => OpenFilex.open(product.invoiceFilePath!),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Belgeyi Aç'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
