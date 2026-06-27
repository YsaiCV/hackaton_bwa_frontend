import 'package:flutter/material.dart';

class ProcedureData {
  final String title;
  final String institution;
  final String cost;
  final String time;
  final String modality;
  final String iconEmoji;
  final String description;
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
    this.description = '',
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
  final VoidCallback onTap;

  const ProcedureCard({super.key, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/app-icono-yase.png',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
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
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: onTap,
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '¿Qué es este trámite?',
                                  style: TextStyle(
                                    color: const Color(0xFF00B8B8).withValues(alpha: 0.9),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right,
                                  color: const Color(0xFF00B8B8).withValues(alpha: 0.9),
                                  size: 16,
                                ),
                              ],
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
          
          // Secciones desplegables (Tarjeta Resumen - Max 3 pasos visibles)
          _buildExpansionTile(
            title: 'Pasos principales',
            subtitle: '${data.steps.length} pasos',
            icon: Icons.description_outlined,
            children: data.steps.length > 3
                ? data.steps.take(3).map((s) => _buildListItem(s)).toList()
                : data.steps.map((s) => _buildListItem(s)).toList(),
          ),
          // Botones PDF y WhatsApp (absorbiendo tap para evitar abrir modal)
          GestureDetector(
            onTap: () {}, // Evita propagación al parent card
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Descargando guía PDF...')),
                        );
                      },
                      icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                      label: const Text(
                        'Descargar PDF',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0047D7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Compartiendo por WhatsApp...')),
                        );
                      },
                      icon: const Icon(Icons.share, color: Colors.white, size: 18),
                      label: const Text(
                        'WhatsApp',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
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
}
