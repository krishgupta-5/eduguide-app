import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:eduguide/core/utils/image_utils.dart';

class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();

  final Map<String, Uint8List> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, Future<Uint8List?>> _loadingFutures = {};
  final Set<String> _failedUrls = {};
  final Duration _cacheExpiry = const Duration(hours: 1);
  final Duration _failedUrlExpiry = const Duration(minutes: 30);
  final Map<String, DateTime> _failedUrlTimestamps = {};
  final int _maxCacheSize = 100;
  int _activeRequests = 0;
  static const int _maxConcurrentRequests = 6;

  Future<Uint8List?> loadImageBytes(String imageUrl) async {
    // Skip URLs that have already failed recently
    if (_failedUrls.contains(imageUrl)) {
      final failedAt = _failedUrlTimestamps[imageUrl];
      if (failedAt != null &&
          DateTime.now().difference(failedAt) < _failedUrlExpiry) {
        return null;
      }
      // Expired failure - allow retry
      _failedUrls.remove(imageUrl);
      _failedUrlTimestamps.remove(imageUrl);
    }

    // Check memory cache first
    if (_memoryCache.containsKey(imageUrl)) {
      final timestamp = _cacheTimestamps[imageUrl];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheExpiry) {
        return _memoryCache[imageUrl];
      } else {
        // Remove expired cache
        _memoryCache.remove(imageUrl);
        _cacheTimestamps.remove(imageUrl);
      }
    }

    // Check if already loading
    if (_loadingFutures.containsKey(imageUrl)) {
      return await _loadingFutures[imageUrl];
    }

    // Throttle concurrent requests to avoid flooding the server
    while (_activeRequests >= _maxConcurrentRequests) {
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Start loading
    final loadingFuture = _fetchImageBytes(imageUrl);
    _loadingFutures[imageUrl] = loadingFuture;

    try {
      final bytes = await loadingFuture;
      if (bytes != null) {
        _cacheImage(imageUrl, bytes);
      } else {
        // Mark as failed to avoid retrying immediately
        _failedUrls.add(imageUrl);
        _failedUrlTimestamps[imageUrl] = DateTime.now();
      }
      return bytes;
    } finally {
      _loadingFutures.remove(imageUrl);
    }
  }

  Uint8List? getCachedImageSync(String imageUrl) {
    // Synchronous cache check for immediate display
    if (_memoryCache.containsKey(imageUrl)) {
      final timestamp = _cacheTimestamps[imageUrl];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheExpiry) {
        return _memoryCache[imageUrl];
      } else {
        // Remove expired cache
        _memoryCache.remove(imageUrl);
        _cacheTimestamps.remove(imageUrl);
      }
    }
    return null;
  }

  Future<Uint8List?> _fetchImageBytes(String imageUrl) async {
    const maxRetries = 1;
    const timeout = Duration(seconds: 30);

    _activeRequests++;
    try {
      for (int attempt = 0; attempt < maxRetries; attempt++) {
        try {
          final client = CustomHttpClient();
          final response = await client.get(Uri.parse(imageUrl)).timeout(timeout);

          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            return response.bodyBytes;
          }
        } catch (e) {
          // Only log on final failure to reduce spam
          if (attempt == maxRetries - 1 && kDebugMode) {
            print('Image failed: ${imageUrl.split('/').last}: ${e.runtimeType}');
          }

          // Wait before retry (exponential backoff)
          if (attempt < maxRetries - 1) {
            await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          }
        }
      }
    } finally {
      _activeRequests--;
    }

    return null;
  }

  void _cacheImage(String imageUrl, Uint8List bytes) {
    // Clean old cache if needed
    if (_memoryCache.length >= _maxCacheSize) {
      _cleanOldestCache();
    }

    _memoryCache[imageUrl] = bytes;
    _cacheTimestamps[imageUrl] = DateTime.now();
  }

  void _cleanOldestCache() {
    if (_cacheTimestamps.isEmpty) return;

    final sortedEntries = _cacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Remove oldest 20% of cache
    final removeCount = (_maxCacheSize * 0.2).ceil();
    for (int i = 0; i < removeCount && i < sortedEntries.length; i++) {
      final key = sortedEntries[i].key;
      _memoryCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  void preloadImages(List<String> imageUrls) {
    int delay = 0;
    for (final url in imageUrls) {
      if (isValidImageUrl(url) && !_memoryCache.containsKey(url)) {
        Future.delayed(
          Duration(milliseconds: delay),
          () => loadImageBytes(url),
        );
        delay += 100;
      }
    }
  }

  void clearCache() {
    _memoryCache.clear();
    _cacheTimestamps.clear();
  }

  int get cacheSize => _memoryCache.length;
}

class CustomHttpClient extends http.BaseClient {
  final http.Client _inner;
  static CustomHttpClient? _instance;

  // Reuse a single HttpClient instead of creating one per request
  static final HttpClient _thaparClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15)
    ..idleTimeout = const Duration(seconds: 30)
    ..badCertificateCallback = (cert, host, port) => true;

  factory CustomHttpClient() {
    _instance ??= CustomHttpClient._internal();
    return _instance!;
  }

  CustomHttpClient._internal() : _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.host.contains('thapar.edu')) {
      final httpRequest = await _thaparClient.openUrl(
        request.method,
        request.url,
      );
      request.headers.forEach(
        (name, value) => httpRequest.headers.set(name, value),
      );

      if (request is http.Request && request.body.isNotEmpty) {
        httpRequest.add(request.bodyBytes);
      }

      final httpResponse = await httpRequest.close();
      final headers = <String, String>{};
      httpResponse.headers.forEach((name, values) {
        headers[name] = values.join(', ');
      });

      return http.StreamedResponse(
        httpResponse,
        httpResponse.statusCode,
        contentLength: httpResponse.contentLength,
        request: request,
        headers: headers,
        isRedirect: httpResponse.isRedirect,
        persistentConnection: httpResponse.persistentConnection,
        reasonPhrase: httpResponse.reasonPhrase,
      );
    }

    return _inner.send(request);
  }
}

class CustomImageLoader {
  static final ImageCacheManager _cacheManager = ImageCacheManager();

  static Future<Uint8List?> loadImageBytes(String imageUrl) async {
    return await _cacheManager.loadImageBytes(imageUrl);
  }

  static void preloadImages(List<String> imageUrls) {
    _cacheManager.preloadImages(imageUrls);
  }

  static void clearCache() {
    _cacheManager.clearCache();
  }

  static int get cacheSize => _cacheManager.cacheSize;
}
