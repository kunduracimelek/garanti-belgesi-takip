import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/app_settings.dart';

/// Tüm veriler cihazda (yerel) tutulur. Bulut senkronizasyonu bu sürümde
/// yoktur — "Bulut Yedekleme" tercihi arayüzde durur ancak bir sunucu
/// bağlanana kadar yalnızca yerel bir tercih olarak saklanır.
class StorageService {
  static const _productsKey = 'vaultify_products';
  static const _settingsKey = 'vaultify_settings';

  Future<List<WarrantyProduct>> loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_productsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => WarrantyProduct.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveProducts(List<WarrantyProduct> products) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(products.map((p) => p.toJson()).toList());
    await prefs.setString(_productsKey, raw);
  }

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) return AppSettings();
    return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_productsKey);
    await prefs.remove(_settingsKey);
  }
}
