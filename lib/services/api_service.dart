import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:3000';

  Stream<Map<String, dynamic>> streamCitizenshipQuery(String query, {String? sessionId}) async* {
    final client = http.Client();
    try {
      final url = Uri.parse('$_baseUrl/citizenship/query/stream');
      final body = <String, dynamic>{'query': query};
      if (sessionId != null) {
        body['sessionId'] = sessionId;
      }
      final request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);

      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Error ${response.statusCode}');
      }

      String currentEvent = '';

      await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (line.startsWith('event: ')) {
          currentEvent = line.substring(7).trim();
        } else if (line.startsWith('data: ')) {
          final dataString = line.substring(6).trim();
          if (dataString.isNotEmpty) {
            try {
              final decoded = jsonDecode(dataString);
              if (decoded is Map<String, dynamic>) {
                decoded['__eventName'] = currentEvent;
                yield decoded;
              }
            } catch (e) {
              yield {'rawText': dataString, '__eventName': currentEvent};
            }
          }
        }
      }
    } finally {
      client.close();
    }
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    final url = Uri.parse('$_baseUrl/conversations');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Error al obtener conversaciones: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getMessages(String sessionId) async {
    final url = Uri.parse('$_baseUrl/conversations/$sessionId/messages');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Error al obtener mensajes: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }
}
