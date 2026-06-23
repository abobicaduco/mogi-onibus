import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'models.dart';

/// Carrega horários (cache local > asset embarcado) e verifica atualizações
/// remotas no GitHub.
class ScheduleRepository {
  static const _cacheKey = 'schedules_cache_json';
  static const _cacheVersionKey = 'schedules_cache_versao';

  /// Carrega a melhor fonte disponível imediatamente: o cache baixado, ou,
  /// na ausência dele, o JSON embarcado no APK.
  Future<SchedulesData> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null && cached.isNotEmpty) {
      try {
        return SchedulesData.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      } catch (_) {
        // cache corrompido — cai para o asset
      }
    }
    final bundled = await rootBundle.loadString('assets/schedules.json');
    return SchedulesData.fromJson(jsonDecode(bundled) as Map<String, dynamic>);
  }

  /// Versão dos horários atualmente em uso (cache ou asset).
  Future<String> currentVersion() async {
    final data = await loadLocal();
    return data.dataVersao;
  }

  /// Consulta o GitHub. Retorna os dados remotos apenas se forem MAIS NOVOS
  /// que a versão local; caso contrário retorna null.
  Future<SchedulesData?> checkRemote() async {
    try {
      final resp = await http
          .get(Uri.parse(AppConfig.schedulesRawUrl))
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return null;
      final jsonMap = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final remote = SchedulesData.fromJson(jsonMap);
      final local = await currentVersion();
      if (_isNewer(remote.dataVersao, local)) {
        // guarda o payload bruto para aplicar caso o usuário aceite
        _pendingRaw = utf8.decode(resp.bodyBytes);
        return remote;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String? _pendingRaw;

  /// Persiste no cache os horários remotos verificados por [checkRemote].
  Future<void> applyPending(SchedulesData remote) async {
    if (_pendingRaw == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, _pendingRaw!);
    await prefs.setString(_cacheVersionKey, remote.dataVersao);
    _pendingRaw = null;
  }

  /// Compara versões no formato AAAA-MM-DD (ordenação lexicográfica funciona).
  bool _isNewer(String remote, String local) {
    if (remote.isEmpty) return false;
    if (local.isEmpty) return true;
    return remote.compareTo(local) > 0;
  }
}
