import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../models/meta_model.dart';
import '../network/dio_client.dart';

/// Singleton service caching global metadata (roles, units, users, sites).
class MetaService {
  MetaService._();
  static final MetaService instance = MetaService._();

  final Dio _dio = DioClient.instance;

  MetaDataModel _cachedMeta = MetaDataModel.empty;
  bool _isLoaded = false;
  Future<MetaDataModel>? _pendingRequest;

  MetaDataModel get meta => _cachedMeta;
  bool get isLoaded => _isLoaded;

  void setMockMeta(MetaDataModel mock) {
    _cachedMeta = mock;
    _isLoaded = true;
  }

  /// Loads metadata from /api/meta and /api/activities/by-site.
  Future<MetaDataModel> fetchMetadata({bool forceRefresh = false}) {
    if (_isLoaded && !forceRefresh && _cachedMeta.sites.isNotEmpty) {
      return Future.value(_cachedMeta);
    }
    if (_pendingRequest != null) {
      return _pendingRequest!;
    }
    _pendingRequest = _doFetch();
    return _pendingRequest!;
  }

  Future<MetaDataModel> _doFetch() async {
    try {
      // 1. Fetch /api/meta
      developer.log('🌐 Fetching Metadata from /api/meta...', name: 'MetaService');
      final metaResp = await _dio.get('/meta');
      MetaDataModel parsedMeta = MetaDataModel.empty;

      if (metaResp.data is Map) {
        parsedMeta = MetaDataModel.fromJson(
          Map<String, dynamic>.from(metaResp.data as Map),
        );
      } else if (metaResp.data is String && (metaResp.data as String).isNotEmpty) {
        final decoded = jsonDecode(metaResp.data as String);
        if (decoded is Map) {
          parsedMeta = MetaDataModel.fromJson(Map<String, dynamic>.from(decoded));
        }
      }

      // 2. Fetch /api/activities/by-site to get full enriched site codes & names
      try {
        developer.log('🌐 Fetching Sites from /api/activities/by-site...', name: 'MetaService');
        final sitesResp = await _dio.get('/activities/by-site');
        Map<String, dynamic>? sitesMap;
        if (sitesResp.data is Map) {
          sitesMap = Map<String, dynamic>.from(sitesResp.data as Map);
        } else if (sitesResp.data is String && (sitesResp.data as String).isNotEmpty) {
          final decoded = jsonDecode(sitesResp.data as String);
          if (decoded is Map) sitesMap = Map<String, dynamic>.from(decoded);
        }

        if (sitesMap != null && sitesMap['items'] is List) {
          final items = sitesMap['items'] as List<dynamic>;
          final sitesFromApi = <MetaSiteModel>[];
          for (final it in items) {
            if (it is Map) {
              sitesFromApi.add(MetaSiteModel.fromJson(Map<String, dynamic>.from(it)));
            }
          }
          parsedMeta = parsedMeta.mergeSites(sitesFromApi);
        }
      } catch (e) {
        developer.log('⚠️ /api/activities/by-site non-fatal warning: $e', name: 'MetaService');
      }

      _cachedMeta = parsedMeta;
      _isLoaded = true;
      developer.log(
        '✅ Metadata loaded successfully: ${_cachedMeta.users.length} users, ${_cachedMeta.sites.length} sites, ${_cachedMeta.units.length} units.',
        name: 'MetaService',
      );
      return _cachedMeta;
    } catch (e, stack) {
      developer.log('❌ Error fetching metadata: $e', error: e, stackTrace: stack, name: 'MetaService');
      return _cachedMeta;
    } finally {
      _pendingRequest = null;
    }
  }
}

