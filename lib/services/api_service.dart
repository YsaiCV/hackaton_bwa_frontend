import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:3000';

  Stream<Map<String, dynamic>> streamCitizenshipQuery(String query) async* {
    final client = http.Client();
    try {
      final url = Uri.parse('$_baseUrl/citizenship/query/stream');
      final request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({'query': query});
      
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
}
