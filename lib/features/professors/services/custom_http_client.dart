import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CustomHttpClient extends http.BaseClient {
  final http.Client _inner;

  CustomHttpClient() : _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.host.contains('thapar.edu')) {
      // For Thapar domain, bypass SSL certificate verification
      final httpClient = HttpClient();
      httpClient.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

      final httpRequest = await httpClient.openUrl(request.method, request.url);
      request.headers.forEach(
        (name, value) => httpRequest.headers.set(name, value),
      );

      if (request is http.Request && request.body.isNotEmpty) {
        httpRequest.add(request.bodyBytes);
      }

      final httpResponse = await httpRequest.close();

      // Convert HttpHeaders to Map<String, String>
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
  static final CustomHttpClient _client = CustomHttpClient();

  static Future<Uint8List?> loadImageBytes(String imageUrl) async {
    try {
      final response = await _client.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading image: $e');
      }
    }
    return null;
  }
}
