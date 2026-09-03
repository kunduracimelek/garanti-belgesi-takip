import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'notification_service.dart';

/// GitHub'daki son yayınla yüklü uygulama sürümünü karşılaştırır.
/// Kontrol uygulama açıldığında yapılır; cihaz çevrimdışıyken sessizce atlanır.
class UpdateService {
  UpdateService._();

  static const _latestReleaseUrl =
      'https://api.github.com/repos/kunduracimelek/garanti-belgesi-takip/releases/latest';

  static Future<void> checkForUpdate() async {
    try {
      final response = await http.get(
        Uri.parse(_latestReleaseUrl),
        headers: const {'Accept': 'application/vnd.github+json'},
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;

      final release = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = (release['tag_name'] as String? ?? '')
          .replaceFirst(RegExp(r'^v'), '');
      final downloadUrl = release['html_url'] as String? ?? '';
      if (tag.isEmpty || downloadUrl.isEmpty) return;

      final current = (await PackageInfo.fromPlatform()).version;
      if (_isNewer(tag, current)) {
        await NotificationService.instance.showUpdateAvailable(
          version: tag,
          downloadUrl: downloadUrl,
        );
      }
    } catch (_) {
      // Güncelleme denetimi uygulamanın açılışını engellememelidir.
    }
  }

  static bool _isNewer(String remote, String current) {
    List<int> parse(String version) => version
        .split(RegExp(r'[.+-]'))
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
    final remoteParts = parse(remote);
    final currentParts = parse(current);
    final length = remoteParts.length > currentParts.length
        ? remoteParts.length
        : currentParts.length;
    for (var i = 0; i < length; i++) {
      final r = i < remoteParts.length ? remoteParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;
      if (r != c) return r > c;
    }
    return false;
  }
}
