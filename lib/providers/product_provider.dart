import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class ProductProvider extends ChangeNotifier {
  final StorageService _storage;
  ProductProvider(this._storage);

  List<WarrantyProduct> _products = [];
  bool _loaded = false;
  bool get loaded => _loaded;

  List<WarrantyProduct> get products => List.unmodifiable(_products);

  Future<void> load() async {
    _products = await _storage.loadProducts();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    await _storage.saveProducts(_products);
    notifyListeners();
  }

  Future<void> addProduct(WarrantyProduct product, AppSettings settings) async {
    _products.add(product);
    await _persist();
    await NotificationService.instance.scheduleForProduct(product, settings);
  }

  Future<void> updateProduct(WarrantyProduct product, AppSettings settings) async {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index == -1) return;
    _products[index] = product;
    await _persist();
    await NotificationService.instance.scheduleForProduct(product, settings);
  }

  Future<void> deleteProduct(String id) async {
    _products.removeWhere((p) => p.id == id);
    await _persist();
    await NotificationService.instance.cancelForProduct(id);
  }

  List<WarrantyProduct> get upcoming {
    final active = _products.where((p) => !p.isExpired).toList()
      ..sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
    return active;
  }

  List<WarrantyProduct> byCategory(ProductCategory? category) {
    if (category == null) return [..._products];
    return _products.where((p) => p.category == category).toList();
  }

  List<WarrantyProduct> get recentlyAdded {
    final sorted = [..._products]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  int get activeCount => _products.where((p) => !p.isExpired).length;

  int get criticalCount =>
      _products.where((p) => p.status == WarrantyStatus.critical).length;
}
