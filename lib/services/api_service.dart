import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:3000';

  Stream<String> streamResearch(String query) async* {
    final client = http.Client();
    try {
      final url = Uri.parse('$_baseUrl/procedures/research/stream?query=${Uri.encodeQueryComponent(query)}');
      final request = http.Request('GET', url);
      
      final response = await client.send(request);
      
      if (response.statusCode != 200) {
        throw Exception('Error ${response.statusCode}');
      }

      await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (line.startsWith('data: ')) {
          final dataString = line.substring(6).trim();
          if (dataString.isNotEmpty) {
            try {
              // Intenta parsear si el backend envía JSON (NestJS suele enviar JSON en data)
              final decoded = jsonDecode(dataString);
              if (decoded is Map && decoded.containsKey('data')) {
                yield decoded['data'].toString();
              } else {
                yield dataString;
              }
            } catch (e) {
              // Si no es JSON, enviarlo crudo
              yield dataString;
            }
          }
        }
      }
    } finally {
      client.close();
    }
  }
}
