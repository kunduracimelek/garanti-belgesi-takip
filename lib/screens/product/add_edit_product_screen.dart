import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/ocr_service.dart';
import '../../theme/app_theme.dart';

class AddEditProductScreen extends StatefulWidget {
  final WarrantyProduct? existing;
  const AddEditProductScreen({super.key, this.existing});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ocr = OcrService();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _storeCtrl;
  late final TextEditingController _invoiceNoCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _serialCtrl;
  late final TextEditingController _notesCtrl;

  ProductCategory _category = ProductCategory.elektronik;
  DateTime _purchaseDate = DateTime.now();
  int _warrantyMonths = 24;
  String? _invoiceFilePath;
  bool _isExtracting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _storeCtrl = TextEditingController(text: e?.store ?? '');
    _invoiceNoCtrl = TextEditingController(text: e?.invoiceNumber ?? '');
    _priceCtrl = TextEditingController(text: e?.price?.toStringAsFixed(2) ?? '');
    _serialCtrl = TextEditingController(text: e?.serialNumber ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    if (e != null) {
      _category = e.category;
      _purchaseDate = e.purchaseDate;
      _warrantyMonths = e.warrantyMonths;
      _invoiceFilePath = e.invoiceFilePath;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _storeCtrl.dispose();
    _invoiceNoCtrl.dispose();
    _priceCtrl.dispose();
    _serialCtrl.dispose();
    _notesCtrl.dispose();
    _ocr.dispose();
    super.dispose();
  }

  Future<void> _pickAndExtract({required ImageSource? source}) async {
    String? path;
    if (source != null) {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source, imageQuality: 85);
      path = file?.path;
    } else {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf']);
      path = result?.files.single.path;
    }
    if (path == null) return;

    // Belgeyi uygulamanın kendi dizinine kopyala ki geçici dosya silinse
    // bile fatura kalıcı olarak saklanabilsin.
    final savedPath = await _persistFile(path);
    setState(() {
      _invoiceFilePath = savedPath;
    });

    final isImage = savedPath.toLowerCase().endsWith('.jpg') ||
        savedPath.toLowerCase().endsWith('.jpeg') ||
        savedPath.toLowerCase().endsWith('.png');
    if (!isImage) {
      // PDF'ler cihaz üzerinde otomatik taranmaz; kullanıcı alanları elle doldurur.
      return;
    }

    setState(() => _isExtracting = true);
    final info = await _ocr.extractFromImage(File(savedPath));
    setState(() => _isExtracting = false);

    if (info == null || !info.hasAnyMatch) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belgeden otomatik bilgi okunamadı, alanları elle doldurabilirsiniz.')),
        );
      }
      return;
    }

    setState(() {
      if (info.storeName != null && _storeCtrl.text.isEmpty) _storeCtrl.text = info.storeName!;
      if (info.invoiceNumber != null && _invoiceNoCtrl.text.isEmpty) _invoiceNoCtrl.text = info.invoiceNumber!;
      if (info.purchaseDate != null) _purchaseDate = info.purchaseDate!;
      if (info.totalAmount != null && _priceCtrl.text.isEmpty) _priceCtrl.text = info.totalAmount!.toStringAsFixed(2);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belgeden bilgiler alındı, lütfen kontrol edin.')),
      );
    }
  }

  Future<String> _persistFile(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = sourcePath.split('.').last;
    final newPath = '${dir.path}/invoice_${const Uuid().v4()}.$ext';
    await File(sourcePath).copy(newPath);
    return newPath;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final settings = context.read<SettingsProvider>().settings;
    final provider = context.read<ProductProvider>();
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.'));

    if (_isEditing) {
      final updated = widget.existing!.copyWith(
        name: _nameCtrl.text.trim(),
        category: _category,
        store: _storeCtrl.text.trim().isEmpty ? null : _storeCtrl.text.trim(),
        invoiceNumber: _invoiceNoCtrl.text.trim().isEmpty ? null : _invoiceNoCtrl.text.trim(),
        purchaseDate: _purchaseDate,
        warrantyMonths: _warrantyMonths,
        price: price,
        serialNumber: _serialCtrl.text.trim().isEmpty ? null : _serialCtrl.text.trim(),
        invoiceFilePath: _invoiceFilePath,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      await provider.updateProduct(updated, settings);
    } else {
      final product = WarrantyProduct(
        id: const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        category: _category,
        store: _storeCtrl.text.trim().isEmpty ? null : _storeCtrl.text.trim(),
        invoiceNumber: _invoiceNoCtrl.text.trim().isEmpty ? null : _invoiceNoCtrl.text.trim(),
        purchaseDate: _purchaseDate,
        warrantyMonths: _warrantyMonths,
        price: price,
        serialNumber: _serialCtrl.text.trim().isEmpty ? null : _serialCtrl.text.trim(),
        invoiceFilePath: _invoiceFilePath,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      await provider.addProduct(product, settings);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Ürünü Düzenle' : 'Yeni Ekle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // Fatura / garanti belgesi hızlı içe aktarma
            Material(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showImportSheet(context),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                        child: _isExtracting
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.receipt_long_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _invoiceFilePath == null ? 'Fatura / Garanti Belgesi Yükle' : 'Belge Yüklendi ✓',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Fotoğraf çekin, galeriden veya dosyalardan seçin — bilgiler otomatik doldurulmaya çalışılır',
                              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Ürün Adı'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ürün adı zorunlu' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ProductCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: [
                for (final c in ProductCategory.values)
                  DropdownMenuItem(value: c, child: Row(children: [Icon(c.icon, size: 18), const SizedBox(width: 8), Text(c.label)])),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Satın Alma Tarihi'),
                child: Text('${_purchaseDate.day}.${_purchaseDate.month}.${_purchaseDate.year}'),
              ),
            ),
            const SizedBox(height: 20),
            Text('Garanti Süresi', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                _WarrantyChip(label: '+1 Yıl', selected: _warrantyMonths == 12, onTap: () => setState(() => _warrantyMonths = 12)),
                const SizedBox(width: 8),
                _WarrantyChip(label: '+2 Yıl (Yasal)', selected: _warrantyMonths == 24, onTap: () => setState(() => _warrantyMonths = 24)),
                const SizedBox(width: 8),
                _WarrantyChip(label: '+3 Yıl', selected: _warrantyMonths == 36, onTap: () => setState(() => _warrantyMonths = 36)),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(controller: _storeCtrl, decoration: const InputDecoration(labelText: 'Satıcı (opsiyonel)')),
            const SizedBox(height: 16),
            TextFormField(controller: _invoiceNoCtrl, decoration: const InputDecoration(labelText: 'Fatura No (opsiyonel)')),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceCtrl,
              decoration: const InputDecoration(labelText: 'Toplam Tutar (opsiyonel)', suffixText: '₺'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(controller: _serialCtrl, decoration: const InputDecoration(labelText: 'Seri No (opsiyonel)')),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Not (opsiyonel)'),
              maxLines: 3,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.rocket_launch_rounded),
                label: Text(_isEditing ? 'Güncelle' : 'Kaydet'),
                style: FilledButton.styleFrom(
                  backgroundColor: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                  foregroundColor: isDark ? AppColors.darkBgMain : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Fotoğraf Çek'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndExtract(source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeriden Seç'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndExtract(source: ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Dosyalardan Seç (PDF/Görsel)'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndExtract(source: null);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WarrantyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _WarrantyChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: selected ? Colors.white : null, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
