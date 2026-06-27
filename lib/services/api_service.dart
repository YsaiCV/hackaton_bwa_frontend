import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:3000';

  Stream<Map<String, dynamic>> streamCitizenshipQuery(String query, [String? sessionId]) async* {
    final client = http.Client();
    try {
      final url = Uri.parse('$_baseUrl/citizenship/query/stream');
      final bodyData = {'query': query};
      if (sessionId != null) {
        bodyData['sessionId'] = sessionId;
      }
      final request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(bodyData);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        request.headers['Authorization'] = 'Bearer $token';
      }
      
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

  Future<List<Map<String, dynamic>>> getChatHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    
    final token = await user.getIdToken();
    final url = Uri.parse('$_baseUrl/conversations');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getChatMessages(String sessionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    
    final token = await user.getIdToken();
    final url = Uri.parse('$_baseUrl/conversations/$sessionId/messages');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }
}
