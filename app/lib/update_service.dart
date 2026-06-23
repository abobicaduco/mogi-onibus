import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'config.dart';

class ReleaseInfo {
  final String tag;
  final String name;
  final String body;
  final String htmlUrl;
  final String? apkUrl;

  ReleaseInfo({
    required this.tag,
    required this.name,
    required this.body,
    required this.htmlUrl,
    this.apkUrl,
  });
}

/// Verifica o último release no GitHub e compara com a versão instalada.
class UpdateService {
  /// Retorna o release quando há uma versão MAIS NOVA que a instalada,
  /// caso contrário null.
  Future<ReleaseInfo?> checkAppUpdate() async {
    try {
      final pkg = await PackageInfo.fromPlatform();
      final current = pkg.version; // ex.: 1.0.0
      final resp = await http
          .get(Uri.parse(AppConfig.latestReleaseApi),
              headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return null;
      final j = jsonDecode(resp.body) as Map<String, dynamic>;
      final tag = ((j['tag_name'] ?? '') as String).replaceFirst('v', '');
      if (tag.isEmpty) return null;
      if (!_isNewerSemver(tag, current)) return null;

      String? apkUrl;
      for (final a in (j['assets'] ?? []) as List) {
        final name = (a['name'] ?? '').toString();
        if (name.toLowerCase().endsWith('.apk')) {
          apkUrl = a['browser_download_url'] as String?;
          break;
        }
      }
      return ReleaseInfo(
        tag: tag,
        name: (j['name'] ?? tag) as String,
        body: (j['body'] ?? '') as String,
        htmlUrl: (j['html_url'] ?? AppConfig.releasesPageUrl) as String,
        apkUrl: apkUrl,
      );
    } catch (_) {
      return null;
    }
  }

  /// Compara versões "1.2.3". Retorna true se [a] > [b].
  bool _isNewerSemver(String a, String b) {
    List<int> p(String s) => s
        .split('+')
        .first
        .split('.')
        .map((e) => int.tryParse(e.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    final pa = p(a), pb = p(b);
    for (var i = 0; i < 3; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }
}
