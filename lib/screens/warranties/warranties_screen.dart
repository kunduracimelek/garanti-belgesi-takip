import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/warranty_card.dart';
import '../../widgets/category_chip.dart';
import '../product/add_edit_product_screen.dart';
import '../product/product_detail_screen.dart';

class WarrantiesScreen extends StatefulWidget {
  const WarrantiesScreen({super.key});

  @override
  State<WarrantiesScreen> createState() => _WarrantiesScreenState();
}

class _WarrantiesScreenState extends State<WarrantiesScreen> {
  ProductCategory? _category;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    var list = productProvider.byCategory(_category);
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q) || (p.store ?? '').toLowerCase().contains(q)).toList();
    }
    list.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));

    return Scaffold(
      appBar: const GlassAppBar(title: Text('Garantiler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddEditProductScreen())),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Ürün veya satıcı ara...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                CategoryChip(label: 'Tümü', selected: _category == null, onTap: () => setState(() => _category = null)),
                const SizedBox(width: 8),
                for (final c in ProductCategory.values) ...[
                  CategoryChip(label: c.label, selected: _category == c, onTap: () => setState(() => _category = c)),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text('Sonuç bulunamadı', style: Theme.of(context).textTheme.bodyMedium),
              ),
            )
          else
            ...list.map(
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
        ],
      ),
    );
  }
}
