import 'dart:convert';

import 'package:http/http.dart' as http;

abstract class NetworkService {
  Future<http.Response> get(String path);
  Future<http.Response> post(String path, {Object? body});
}

class HttpNetworkService implements NetworkService {
  final String baseUrl;
  final http.Client client;

  HttpNetworkService({required this.baseUrl, http.Client? client})
    : client = client ?? http.Client();

  @override
  Future<http.Response> get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    return client.get(uri);
  }

  @override
  Future<http.Response> post(String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    return client.post(uri, body: body != null ? jsonEncode(body) : null);
  }
}
