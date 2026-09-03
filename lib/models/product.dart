import 'package:flutter/material.dart';

/// Uygulamada sadece garantisi/değişim hakkı olan dayanıklı ürünler
/// takip edilir. Gıda / son kullanma tarihi takibi bilinçli olarak
/// desteklenmez.
enum ProductCategory { elektronik, beyazEsya, mobilya, saglikCihazi, diger }

extension ProductCategoryX on ProductCategory {
  String get label {
    switch (this) {
      case ProductCategory.elektronik:
        return 'Elektronik';
      case ProductCategory.beyazEsya:
        return 'Beyaz Eşya';
      case ProductCategory.mobilya:
        return 'Mobilya';
      case ProductCategory.saglikCihazi:
        return 'Sağlık Cihazı';
      case ProductCategory.diger:
        return 'Diğer';
    }
  }

  IconData get icon {
    switch (this) {
      case ProductCategory.elektronik:
        return Icons.devices_other_rounded;
      case ProductCategory.beyazEsya:
        return Icons.kitchen_rounded;
      case ProductCategory.mobilya:
        return Icons.chair_rounded;
      case ProductCategory.saglikCihazi:
        return Icons.medical_services_rounded;
      case ProductCategory.diger:
        return Icons.inventory_2_rounded;
    }
  }
}

enum WarrantyStatus { critical, warning, safe, expired }

class WarrantyProduct {
  final String id;
  String name;
  ProductCategory category;
  String? store;
  String? invoiceNumber;
  DateTime purchaseDate;
  int warrantyMonths;
  double? price;
  String currency;
  String? serialNumber;
  String? invoiceFilePath;
  String? notes;
  final DateTime createdAt;

  WarrantyProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.purchaseDate,
    required this.warrantyMonths,
    this.store,
    this.invoiceNumber,
    this.price,
    this.currency = 'TRY',
    this.serialNumber,
    this.invoiceFilePath,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  DateTime get endDate {
    final totalMonths = purchaseDate.month + warrantyMonths;
    final year = purchaseDate.year + ((totalMonths - 1) ~/ 12);
    final month = ((totalMonths - 1) % 12) + 1;
    // Ay taşmalarında geçersiz günleri (örn. 31 Şubat) güvenle sınırla.
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final day = purchaseDate.day > lastDayOfMonth ? lastDayOfMonth : purchaseDate.day;
    return DateTime(year, month, day);
  }

  int get daysRemaining => endDate.difference(_today()).inDays;

  bool get isExpired => daysRemaining < 0;

  WarrantyStatus get status {
    if (isExpired) return WarrantyStatus.expired;
    if (daysRemaining <= 7) return WarrantyStatus.critical;
    if (daysRemaining <= 30) return WarrantyStatus.warning;
    return WarrantyStatus.safe;
  }

  String get remainingLabel {
    if (isExpired) return 'Süresi Doldu';
    final d = daysRemaining;
    if (d < 30) return 'Son $d Gün';
    final months = (d / 30).floor();
    if (months < 12) return '$months Ay Kaldı';
    final years = months ~/ 12;
    final remMonths = months % 12;
    return remMonths == 0 ? '$years Yıl Kaldı' : '$years Yıl $remMonths Ay Kaldı';
  }

  double get progressFraction {
    final total = endDate.difference(purchaseDate).inMinutes;
    if (total <= 0) return 1;
    final elapsed = _today().difference(purchaseDate).inMinutes;
    return (elapsed / total).clamp(0, 1).toDouble();
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  WarrantyProduct copyWith({
    String? name,
    ProductCategory? category,
    String? store,
    String? invoiceNumber,
    DateTime? purchaseDate,
    int? warrantyMonths,
    double? price,
    String? currency,
    String? serialNumber,
    String? invoiceFilePath,
    String? notes,
  }) {
    return WarrantyProduct(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      store: store ?? this.store,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      serialNumber: serialNumber ?? this.serialNumber,
      invoiceFilePath: invoiceFilePath ?? this.invoiceFilePath,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'store': store,
        'invoiceNumber': invoiceNumber,
        'purchaseDate': purchaseDate.toIso8601String(),
        'warrantyMonths': warrantyMonths,
        'price': price,
        'currency': currency,
        'serialNumber': serialNumber,
        'invoiceFilePath': invoiceFilePath,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory WarrantyProduct.fromJson(Map<String, dynamic> json) {
    return WarrantyProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      category: ProductCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => ProductCategory.diger,
      ),
      store: json['store'] as String?,
      invoiceNumber: json['invoiceNumber'] as String?,
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      warrantyMonths: json['warrantyMonths'] as int,
      price: (json['price'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'TRY',
      serialNumber: json['serialNumber'] as String?,
      invoiceFilePath: json['invoiceFilePath'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
