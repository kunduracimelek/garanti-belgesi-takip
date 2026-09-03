import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/gradient_hero_card.dart';
import '../../widgets/section_title.dart';
import '../../widgets/warranty_card.dart';
import '../../widgets/category_chip.dart';
import '../product/add_edit_product_screen.dart';
import '../product/product_detail_screen.dart';
import '../warranties/warranties_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ProductCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final userName = settingsProvider.settings.userName;

    final filtered = productProvider.byCategory(_selectedCategory);
    final upcoming = productProvider.upcoming.take(4).toList();
    final recent = productProvider.recentlyAdded.take(4).toList();
    final criticalProduct = productProvider.upcoming
        .where((p) => p.status == WarrantyStatus.critical)
        .cast<WarrantyProduct?>()
        .firstWhere((p) => true, orElse: () => null);

    return Scaffold(
      appBar: GlassAppBar(
        title: Row(
          children: [
            Icon(Icons.shield_moon_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('Vaultify', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            child: Text(
              userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'V',
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Ürün'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<ProductProvider>().load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            Text('Merhaba, $userName! 👋', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Her şey kontrol altında.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            GradientHeroCard(
              activeCount: productProvider.activeCount,
              criticalCount: productProvider.criticalCount,
              criticalProductName: criticalProduct?.name,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  CategoryChip(
                    label: 'Tümü',
                    selected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                  const SizedBox(width: 8),
                  for (final c in ProductCategory.values) ...[
                    CategoryChip(
                      label: c.label,
                      selected: _selectedCategory == c,
                      onTap: () => setState(() => _selectedCategory = c),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (upcoming.isNotEmpty) ...[
              SectionTitle(
                title: 'Yaklaşanlar',
                onSeeAll: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WarrantiesScreen()),
                ),
              ),
              const SizedBox(height: 12),
              ...upcoming.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: WarrantyCard(
                    product: p,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (filtered.isEmpty && upcoming.isEmpty)
              _EmptyState(onAdd: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
              )),
            if (recent.isNotEmpty) ...[
              const SectionTitle(title: 'Son Eklenenler'),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recent.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (context, i) {
                  final p = recent[i];
                  return _RecentTile(
                    product: p,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id)),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  final WarrantyProduct product;
  final VoidCallback onTap;
  const _RecentTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(product.category.icon, color: AppColors.primary, size: 20),
              ),
              const Spacer(),
              Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, size: 12, color: AppColors.secondaryFixedDim),
                  const SizedBox(width: 4),
                  Text('Kayıtlı', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.secondaryFixedDim)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 56, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text('Henüz kayıtlı ürün yok', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Garantisi olan bir ürün ekleyerek başlayın.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Ürün Ekle')),
        ],
      ),
    );
  }
}
