import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/procedure_card.dart';
import 'platform_helper.dart' as platform;

class DocumentsService {
  static const String baseUrl = 'http://127.0.0.1:3000';

  Future<void> downloadProcedurePdf(ProcedureData procedure) async {
    final url = Uri.parse('$baseUrl/documents/generate-procedure');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': procedure.title,
        'institution': procedure.institution,
        'cost': procedure.cost,
        'time': procedure.time,
        'modality': procedure.modality,
        'steps': procedure.steps,
        'documents': procedure.documents,
        'recommendations': procedure.recommendations,
        'whoCanDoIt': procedure.whoCanDoIt,
        'whereToDoIt': procedure.whereToDoIt,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to download PDF: ${response.statusCode}');
    }

    List<int> pdfBytes;
    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('application/pdf')) {
      pdfBytes = response.bodyBytes;
    } else {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final base64str = decoded['pdf'] ?? decoded['base64'] ?? decoded['data'] ?? '';
          pdfBytes = base64Decode(base64str.trim());
        } else if (decoded is String) {
          pdfBytes = base64Decode(decoded.trim());
        } else {
          pdfBytes = response.bodyBytes;
        }
      } catch (_) {
        try {
          pdfBytes = base64Decode(response.body.trim());
        } catch (_) {
          pdfBytes = response.bodyBytes;
        }
      }
    }

    if (pdfBytes.isEmpty) {
      throw Exception('PDF bytes are empty');
    }

    platform.saveFile(pdfBytes, 'yase-guia-tramite.pdf');
  }

  Future<void> shareProcedureToWhatsApp(ProcedureData procedure) async {
    final String text = '''
*Trámite:* ${procedure.title}
*Institución:* ${procedure.institution}
*Costo:* ${procedure.cost}
*Duración:* ${procedure.time}
*Modalidad:* ${procedure.modality}

Consulta esta guía generada por YaSé.
''';

    final String url = 'https://wa.me/?text=${Uri.encodeComponent(text)}';
    platform.openInNewTab(url);
  }
}
