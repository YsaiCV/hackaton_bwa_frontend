import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import '../screens/dynamic_form_screen.dart';

class ProcedureDocument {
  final String name;
  final bool requiresRequestLetter;
  final List<Map<String, String>> requestLetterFields;

  ProcedureDocument({
    required this.name,
    this.requiresRequestLetter = false,
    this.requestLetterFields = const [],
  });

  factory ProcedureDocument.fromJson(dynamic json) {
    if (json is String) {
      return ProcedureDocument(name: json);
    }
    return ProcedureDocument(
      name: json['name'] ?? 'Documento',
      requiresRequestLetter: json['requiresRequestLetter'] ?? false,
      requestLetterFields: (json['requestLetterFields'] as List?)
          ?.map((e) => {
                'name': e['name']?.toString() ?? '',
                'label': e['label']?.toString() ?? '',
              })
          .toList() ?? [],
    );
  }
}

class ProcedureData {
  final String title;
  final String institution;
  final String cost;
  final String time;
  final String modality;
  final String iconEmoji;
  final List<String> steps;
  final List<ProcedureDocument> documents;
  final List<String> recommendations;
  final String whoCanDoIt;
  final String whoCanDoItSubtitle;
  final List<String> whereToDoIt;
  final List<Map<String, String>> sources;
  final bool hasDownloadableDocs;
  final bool hasDynamicFill;

  ProcedureData({
    required this.title,
    required this.institution,
    required this.cost,
    required this.time,
    required this.modality,
    required this.iconEmoji,
    required this.steps,
    required this.documents,
    required this.recommendations,
    required this.whoCanDoIt,
    required this.whoCanDoItSubtitle,
    required this.whereToDoIt,
    this.sources = const [],
    this.hasDownloadableDocs = false,
    this.hasDynamicFill = false,
  });
}

class ProcedureCard extends StatelessWidget {
  final ProcedureData data;

  const ProcedureCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header azul
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF0047C7), // Azul profundo de la paleta
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        data.iconEmoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.account_balance, color: Colors.white70, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data.institution,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildChip(Icons.attach_money, data.cost),
                    _buildChip(Icons.access_time, data.time),
                    _buildChip(Icons.language, data.modality),
                  ],
                ),
              ],
            ),
          ),
          
          // Secciones desplegables
          _buildExpansionTile(
            title: 'Pasos principales',
            subtitle: '${data.steps.length} pasos',
            icon: Icons.description_outlined,
            children: data.steps.map((s) => _buildListItem(s)).toList(),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          
          _buildExpansionTile(
            title: 'Documentos necesarios',
            subtitle: '${data.documents.length} documentos',
            icon: Icons.check_box_outlined,
            children: [
              if (data.documents.any((d) => d.requiresRequestLetter))
                _buildFormulariosOficialesSection(context, data.documents.where((d) => d.requiresRequestLetter).toList()),
              ...data.documents.where((d) => !d.requiresRequestLetter).map((d) => _buildListItem(d.name)),
            ],
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          
          _buildExpansionTile(
            title: 'Recomendaciones',
            subtitle: 'Antes de ir',
            icon: Icons.info_outline,
            children: data.recommendations.map((r) => _buildListItem(r)).toList(),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          
          _buildExpansionTile(
            title: '¿Dónde puedes hacerlo?',
            subtitle: 'Ubicaciones y canales',
            icon: Icons.place_outlined,
            children: data.whereToDoIt.map((w) => _buildListItem(w)).toList(),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          _buildExpansionTile(
            title: '¿Quién puede realizar este trámite?',
            subtitle: data.whoCanDoItSubtitle,
            icon: Icons.person_outline,
            children: [_buildListItem(data.whoCanDoIt)],
          ),
          
          if (data.sources.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            _buildExpansionTile(
              title: 'Fuentes y Enlaces Oficiales',
              subtitle: 'Para más información',
              icon: Icons.link_rounded,
              children: data.sources.map((s) => _buildSourceItem(s)).toList(),
            ),
          ],
          
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFFF9FBFF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _downloadProcedureSummary(context, data),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Descargar resumen en PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003C9E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (data.hasDownloadableDocs || data.hasDynamicFill)
                  const SizedBox(height: 12),
                if (data.hasDownloadableDocs)
                  OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          final uri = Uri.parse('http://127.0.0.1:3000/documents/test-form');
                          final response = await http.get(uri);
                          if (response.statusCode == 200) {
                            if (kIsWeb) {
                              final blob = html.Blob([response.bodyBytes], 'application/pdf');
                              final url = html.Url.createObjectUrlFromBlob(blob);
                              final anchor = html.AnchorElement(href: url)
                                ..setAttribute('download', 'documentos_vacios.pdf')
                                ..click();
                              html.Url.revokeObjectUrl(url);
                            } else {
                              final dir = await getTemporaryDirectory();
                              final file = File('${dir.path}/documentos_vacios.pdf');
                              await file.writeAsBytes(response.bodyBytes);
                              OpenFile.open(file.path);
                            }
                          } else {
                            throw Exception('Error del servidor');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No se pudo descargar el documento')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Descargar documentos'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF003C9E),
                        side: const BorderSide(color: Color(0xFF003C9E)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  if (data.hasDownloadableDocs && data.hasDynamicFill)
                    const SizedBox(height: 12),
                  if (data.hasDynamicFill)
                    ElevatedButton.icon(
                      onPressed: () {
                        final fillableDocs = data.documents.where((d) => d.requiresRequestLetter).toList();
                        final docToFill = fillableDocs.isNotEmpty 
                            ? fillableDocs.first 
                            : ProcedureDocument(
                                name: 'Formulario de Trámite', 
                                requiresRequestLetter: true,
                                requestLetterFields: [
                                  {'name': 'nombre', 'label': 'Nombre completo'},
                                  {'name': 'ci', 'label': 'Nº Carnet de Identidad'},
                                  {'name': 'direccion', 'label': 'Dirección domiciliaria'},
                                ]
                              );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DynamicFormScreen(document: docToFill),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_document),
                      label: const Text('Llenado dinámico de documentos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B8B8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _downloadProcedureSummary(BuildContext context, ProcedureData data) async {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generando resumen en PDF...')),
        );
      }
      
      final payload = {
        "title": data.title,
        "institution": data.institution,
        "cost": data.cost,
        "time": data.time,
        "modality": data.modality,
        "steps": data.steps,
        "documents": data.documents.map((d) => d.name).toList(),
        "recommendations": data.recommendations,
        "whereToDoIt": data.whereToDoIt
      };

      final uri = Uri.parse('http://127.0.0.1:3000/documents/generate-procedure');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kIsWeb) {
          final blob = html.Blob([response.bodyBytes], 'application/pdf');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', 'resumen_tramite.pdf')
            ..click();
          html.Url.revokeObjectUrl(url);
        } else {
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/resumen_tramite.pdf');
          await file.writeAsBytes(response.bodyBytes);
          OpenFile.open(file.path);
        }
      } else {
        throw Exception('Error del servidor al generar resumen');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo descargar el resumen')),
        );
      }
    }
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpansionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F8FC), // Gris claro fondo
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF003C9E), size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF003C9E),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 13,
        ),
      ),
      collapsedIconColor: Colors.grey,
      iconColor: const Color(0xFF003C9E),
      children: children,
    );
  }

  Widget _buildListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 76, right: 20, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF00B8B8), fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: _buildMarkdownText(
              text,
              const TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownText(String text, TextStyle baseStyle) {
    final RegExp exp = RegExp(r'\*\*(.*?)\*\*');
    final matches = exp.allMatches(text);
    
    if (matches.isEmpty) {
      return Text(text, style: baseStyle);
    }
    
    int current = 0;
    List<TextSpan> spans = [];
    
    for (final match in matches) {
      if (match.start > current) {
        spans.add(TextSpan(text: text.substring(current, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      current = match.end;
    }
    
    if (current < text.length) {
      spans.add(TextSpan(text: text.substring(current)));
    }
    
    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: spans,
      ),
    );
  }

  Widget _buildSourceItem(Map<String, String> source) {
    final title = source['title'] ?? 'Enlace';
    final url = source['url'] ?? '';
    
    return Padding(
      padding: const EdgeInsets.only(left: 76, right: 20, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.open_in_new_rounded, color: Color(0xFF00B8B8), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                if (url.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    url,
                    style: const TextStyle(color: Color(0xFF0047C7), fontSize: 12, decoration: TextDecoration.underline),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildFormulariosOficialesSection(BuildContext context, List<ProcedureDocument> forms) {
    return Container(
      margin: const EdgeInsets.only(left: 76, right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD6E4FF)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header of the box
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.description, color: Color(0xFF003C9E), size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Formularios oficiales a llenar',
                    style: TextStyle(
                      color: Color(0xFF003C9E),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${forms.length}\nformularios',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF003C9E),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFD6E4FF)),
          ...forms.map((form) => _buildFormCard(context, form)).toList(),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, ProcedureDocument form) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF5F8FC))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon block
              Container(
                width: 48,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD6E4FF)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0047C7),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
                      ),
                      alignment: Alignment.center,
                      child: const Text('GA...', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                    const Expanded(
                      child: Center(
                        child: Icon(Icons.text_snippet, color: Color(0xFFD6E4FF), size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      form.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'GAMLP · 1 página',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2F1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${form.requestLetterFields.length} campos',
                            style: const TextStyle(color: Color(0xFF00B8B8), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Uso único',
                            style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DynamicFormScreen(document: form)),
                    );
                  },
                  icon: const Icon(Icons.description, size: 16),
                  label: const Text('Llenar en la app', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0047C7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () async {
                        try {
                          final uri = Uri.parse('http://127.0.0.1:3000/documents/test-form');
                          final response = await http.get(uri);
                          if (response.statusCode == 200) {
                            if (kIsWeb) {
                              final blob = html.Blob([response.bodyBytes], 'application/pdf');
                              final url = html.Url.createObjectUrlFromBlob(blob);
                              final anchor = html.AnchorElement(href: url)
                                ..setAttribute('download', '${form.name}_vacio.pdf')
                                ..click();
                              html.Url.revokeObjectUrl(url);
                            } else {
                              final dir = await getTemporaryDirectory();
                              final file = File('${dir.path}/${form.name}_vacio.pdf');
                              await file.writeAsBytes(response.bodyBytes);
                              OpenFile.open(file.path);
                            }
                          } else {
                            throw Exception('Error del servidor');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No se pudo descargar el formulario en blanco')),
                            );
                          }
                        }
                      },
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Descargar\nen blanco', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, height: 1.1)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF003C9E),
                    side: const BorderSide(color: Color(0xFFD6E4FF)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
