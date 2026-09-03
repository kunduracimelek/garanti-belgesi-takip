import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Fatura/garanti belgesi fotoğrafından okunan metinden çıkarılan
/// alanlar. Tüm alanlar "tahmin"dir — kullanıcı formda kontrol edip
/// düzeltebilir, otomatik olarak sessizce kaydedilmez.
class ExtractedInvoiceInfo {
  final String? storeName;
  final String? invoiceNumber;
  final DateTime? purchaseDate;
  final double? totalAmount;
  final String rawText;

  ExtractedInvoiceInfo({
    this.storeName,
    this.invoiceNumber,
    this.purchaseDate,
    this.totalAmount,
    required this.rawText,
  });

  bool get hasAnyMatch =>
      storeName != null || invoiceNumber != null || purchaseDate != null || totalAmount != null;
}

class OcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Sadece görsel dosyalar için çalışır (fotoğraf / galeri).
  /// PDF olarak yüklenen belgeler cihaz üzerinde otomatik taranmaz;
  /// kullanıcı bilgileri elle girer. Bu, ek bir PDF-render/bulut OCR
  /// entegrasyonu gerektirmeden dürüst bir sınırdır.
  Future<ExtractedInvoiceInfo?> extractFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final result = await _recognizer.processImage(inputImage);
      final text = result.text;
      if (text.trim().isEmpty) return null;
      return _parse(text);
    } catch (_) {
      return null;
    }
  }

  ExtractedInvoiceInfo _parse(String text) {
    return ExtractedInvoiceInfo(
      storeName: _guessStoreName(text),
      invoiceNumber: _guessInvoiceNumber(text),
      purchaseDate: _guessDate(text),
      totalAmount: _guessAmount(text),
      rawText: text,
    );
  }

  String? _guessStoreName(String text) {
    final knownStores = [
      'Trendyol', 'Hepsiburada', 'Apple Store', 'MediaMarkt', 'Teknosa',
      'Vatan Bilgisayar', 'Amazon', 'N11', 'Migros', 'Boyner', 'ÇiçekSepeti',
      'Koçtaş', 'İkea', 'IKEA',
    ];
    for (final store in knownStores) {
      if (text.toLowerCase().contains(store.toLowerCase())) return store;
    }
    // "A.Ş." veya "Ltd" geçen ilk satırı satıcı adı olarak tahmin et.
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (RegExp(r'(A\.?Ş\.?|Ltd\.?|Şti\.?)', caseSensitive: false).hasMatch(trimmed)) {
        return trimmed;
      }
    }
    return null;
  }

  String? _guessInvoiceNumber(String text) {
    final match = RegExp(
      r'(Fatura\s*No|Fiş\s*No|Sipariş\s*No)\s*[:\-]?\s*([A-Za-z0-9\-\/]{4,})',
      caseSensitive: false,
    ).firstMatch(text);
    return match?.group(2);
  }

  DateTime? _guessDate(String text) {
    // dd.MM.yyyy / dd/MM/yyyy / dd-MM-yyyy
    final numeric = RegExp(r'(\d{1,2})[./-](\d{1,2})[./-](\d{4})').firstMatch(text);
    if (numeric != null) {
      final day = int.tryParse(numeric.group(1)!);
      final month = int.tryParse(numeric.group(2)!);
      final year = int.tryParse(numeric.group(3)!);
      if (day != null && month != null && year != null && month <= 12 && day <= 31) {
        try {
          return DateTime(year, month, day);
        } catch (_) {}
      }
    }

    // "12 Ocak 2025" biçimi
    const months = {
      'ocak': 1, 'şubat': 2, 'subat': 2, 'mart': 3, 'nisan': 4, 'mayıs': 5,
      'mayis': 5, 'haziran': 6, 'temmuz': 7, 'ağustos': 8, 'agustos': 8,
      'eylül': 9, 'eylul': 9, 'ekim': 10, 'kasım': 11, 'kasim': 11,
      'aralık': 12, 'aralik': 12,
    };
    final worded = RegExp(r'(\d{1,2})\s+([A-Za-zÇçĞğİıÖöŞşÜü]+)\s+(\d{4})')
        .firstMatch(text);
    if (worded != null) {
      final day = int.tryParse(worded.group(1)!);
      final monthName = worded.group(2)!.toLowerCase();
      final year = int.tryParse(worded.group(3)!);
      final month = months[monthName];
      if (day != null && month != null && year != null) {
        try {
          return DateTime(year, month, day);
        } catch (_) {}
      }
    }
    return null;
  }

  double? _guessAmount(String text) {
    final match = RegExp(
      r'(Toplam|Genel\s*Toplam|Ödenen)\s*[:\-]?\s*([\d\.,]+)\s*(₺|TL|TRY)?',
      caseSensitive: false,
    ).firstMatch(text);
    final raw = match?.group(2);
    if (raw == null) return null;
    // Türkçe biçim: binlik nokta, ondalık virgül -> normalize et.
    final normalized = raw.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  void dispose() {
    _recognizer.close();
  }
}
