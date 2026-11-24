import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Loads the same published, versioned player catalogue on Android and web.
/// RTDB is the fast/native source; Firebase Hosting JSON keeps games available
/// when RTDB data or permissions have not been published yet.
class FootballCatalogRepository {
  FootballCatalogRepository._();

  static final Uri _webCatalogUri =
      Uri.parse('https://azoyun.web.app/football/catalog.json');
  static const _cacheKey = 'football_catalog_last_good_v1';

  static Future<FootballCatalogSnapshot> load({
    bool requireBox2Box = false,
    bool requireConnections = false,
  }) async {
    final failures = <String>[];

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('footballCatalog/current')
          .get()
          .timeout(const Duration(seconds: 7));
      final catalog = _decode(snapshot.value);
      _validate(
        catalog,
        requireBox2Box: requireBox2Box,
        requireConnections: requireConnections,
      );
      await _saveLastGood(catalog);
      return FootballCatalogSnapshot(catalog, FootballCatalogSource.realtimeDatabase);
    } catch (error) {
      failures.add('Firebase: ${_message(error)}');
    }

    try {
      final response = await http
          .get(_webCatalogUri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw StateError('HTTP ${response.statusCode}');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final catalog = _decode(decoded);
      _validate(
        catalog,
        requireBox2Box: requireBox2Box,
        requireConnections: requireConnections,
      );
      await _saveLastGood(catalog);
      return FootballCatalogSnapshot(catalog, FootballCatalogSource.webCatalog);
    } catch (error) {
      failures.add('Web kataloğu: ${_message(error)}');
    }

    try {
      final cached = await _loadLastGood();
      if (cached != null) {
        _validate(
          cached,
          requireBox2Box: requireBox2Box,
          requireConnections: requireConnections,
        );
        return FootballCatalogSnapshot(cached, FootballCatalogSource.localCache);
      }
    } catch (error) {
      failures.add('Yerel önbellek: ${_message(error)}');
    }

    throw FootballCatalogUnavailableException(failures);
  }

  static Future<void> _saveLastGood(Map<String, dynamic> catalog) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_cacheKey, jsonEncode(catalog));
    } catch (_) {
      // A cache write failure should not turn a valid online release into a
      // failed game launch.
    }
  }

  static Future<Map<String, dynamic>?> _loadLastGood() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_cacheKey);
    if (encoded == null || encoded.isEmpty) return null;
    return _decode(jsonDecode(encoded));
  }

  static Map<String, dynamic> _decode(Object? value) {
    if (value is! Map) throw const FormatException('Katalog nesnesi yok.');
    final catalog = Map<String, dynamic>.from(value);
    if (_entryCount(catalog['players']) < 20) {
      throw const FormatException('Oyuncu kataloğu boş veya eksik.');
    }
    return catalog;
  }

  static int _entryCount(Object? value) {
    if (value is List) return value.length;
    if (value is Map) return value.length;
    return 0;
  }

  static void _validate(
    Map<String, dynamic> catalog, {
    required bool requireBox2Box,
    required bool requireConnections,
  }) {
    if (requireBox2Box) {
      final grids = catalog['grids'];
      final box = grids is Map ? grids['box2box'] : null;
      final pack = box is Map ? box['current'] : null;
      final rows = pack is Map ? pack['rows'] : null;
      final columns = pack is Map ? pack['columns'] : null;
      if (_entryCount(rows) != 3 || _entryCount(columns) != 3) {
        throw const FormatException('Günlük 3×3 tahta paketi bulunamadı.');
      }
    }
    if (requireConnections) {
      final grids = catalog['grids'];
      final connections = grids is Map ? grids['connections'] : null;
      final pack = connections is Map ? connections['current'] : null;
      final groups = pack is Map ? pack['groups'] : null;
      if (_entryCount(groups) != 4) {
        throw const FormatException('Günlük Connections paketi bulunamadı.');
      }
    }
  }

  static String _message(Object error) {
    final text = error.toString().replaceFirst(RegExp(r'^(Exception|Error):\s*'), '');
    return text.length > 220 ? '${text.substring(0, 220)}…' : text;
  }
}

enum FootballCatalogSource { realtimeDatabase, webCatalog, localCache }

class FootballCatalogSnapshot {
  const FootballCatalogSnapshot(this.data, this.source);

  final Map<String, dynamic> data;
  final FootballCatalogSource source;

  String get sourceLabel => switch (source) {
        FootballCatalogSource.realtimeDatabase => 'canlı Firebase kataloğu',
        FootballCatalogSource.webCatalog => 'web kataloğu',
        FootballCatalogSource.localCache => 'cihazdaki son iyi katalog · çevrimdışı olabilir',
      };
}

class FootballCatalogUnavailableException implements Exception {
  const FootballCatalogUnavailableException(this.failures);

  final List<String> failures;

  @override
  String toString() =>
      'Futbol verisine bağlanılamadı. İnternet bağlantısını kontrol edip yeniden dene. '
      '${failures.join(' · ')}';
}

class FootballCatalogUnavailableView extends StatelessWidget {
  const FootballCatalogUnavailableView({
    super.key,
    required this.title,
    required this.details,
    required this.onRetry,
    this.retrying = false,
  });

  final String title;
  final String details;
  final VoidCallback onRetry;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(details,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: retrying ? null : onRetry,
                icon: retrying
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(retrying ? 'Bağlanıyor…' : 'Yeniden dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
