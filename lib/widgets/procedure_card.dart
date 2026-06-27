import 'package:flutter/material.dart';

class ProcedureData {
  final String title;
  final String institution;
  final String cost;
  final String time;
  final String modality;
  final String iconEmoji;
  final List<String> steps;
  final List<String> documents;
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
            children: data.documents.map((d) => _buildListItem(d)).toList(),
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
          
          if (data.hasDownloadableDocs || data.hasDynamicFill)
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFFF9FBFF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (data.hasDownloadableDocs)
                    OutlinedButton.icon(
                      onPressed: () {},
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
                      onPressed: () {},
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
            child: Text(
              text,
              style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
            ),
          ),
        ],
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
}
