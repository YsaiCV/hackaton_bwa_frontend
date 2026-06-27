import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:universal_html/html.dart' as html;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../widgets/procedure_card.dart';

class DynamicFormScreen extends StatefulWidget {
  final ProcedureDocument document;

  const DynamicFormScreen({super.key, required this.document});

  @override
  State<DynamicFormScreen> createState() => _DynamicFormScreenState();
}

class _DynamicFormScreenState extends State<DynamicFormScreen> {
  bool _isGenerating = false;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var field in widget.document.requestLetterFields) {
      final name = field['name'] ?? '';
      if (name.isNotEmpty) {
        _controllers[name] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF003C9E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.document.name,
          style: const TextStyle(color: Color(0xFF003C9E), fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildFormContent(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 10)],
        ),
        child: ElevatedButton(
          onPressed: _isGenerating ? null : () async {
            setState(() => _isGenerating = true);
            try {
              final body = _controllers.map((key, value) => MapEntry(key, value.text));
              final response = await http.post(
                Uri.parse('http://127.0.0.1:3000/documents/generate-letter'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(body),
              );

              if (response.statusCode == 200 || response.statusCode == 201) {
                if (kIsWeb) {
                  final blob = html.Blob([response.bodyBytes], 'application/pdf');
                  final url = html.Url.createObjectUrlFromBlob(blob);
                  final anchor = html.AnchorElement(href: url)
                    ..setAttribute('download', 'mi-carta.pdf')
                    ..click();
                  html.Url.revokeObjectUrl(url);
                } else {
                  final dir = await getTemporaryDirectory();
                  final file = File('${dir.path}/mi-carta.pdf');
                  await file.writeAsBytes(response.bodyBytes);
                  OpenFile.open(file.path);
                }
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Documento generado con éxito.')),
                  );
                }
              } else {
                throw Exception('Error al generar el documento: ${response.statusCode}');
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            } finally {
              if (mounted) {
                setState(() => _isGenerating = false);
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0047C7),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: _isGenerating
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
              : const Text('Generar Documento', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header del bloque
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0047C7),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Datos del documento',
                        style: TextStyle(
                          color: Color(0xFF003C9E),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              
              // Campos del formulario
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.document.requestLetterFields.map((field) {
                    final label = field['label'] ?? 'Campo';
                    final name = field['name'] ?? '';
                    
                    // Si el nombre sugiere cuerpo o descripción, hacemos el campo más grande
                    final isMultiline = name.toLowerCase().contains('cuerpo') || name.toLowerCase().contains('descripcion');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$label *',
                            style: const TextStyle(
                              color: Color(0xFF003C9E),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _controllers[name],
                            maxLines: isMultiline ? 4 : 1,
                            decoration: InputDecoration(
                              hintText: 'Ej. Ingrese $label',
                              hintStyle: const TextStyle(color: Colors.grey),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: Color(0xFF00B8B8), width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
