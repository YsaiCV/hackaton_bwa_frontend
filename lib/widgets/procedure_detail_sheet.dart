import 'package:flutter/material.dart';
import 'procedure_card.dart';

class ProcedureDetailSheet extends StatelessWidget {
  final ProcedureData data;
  final VoidCallback onClose;
  final VoidCallback? onShowFullFicha;

  const ProcedureDetailSheet({
    super.key,
    required this.data,
    required this.onClose,
    this.onShowFullFicha,
  });

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF00B8B8).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check,
              color: Color(0xFF00B8B8),
              size: 12,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF001B4D),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChip(String text, Color textColor, Color bgColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lowerTitle = data.title.toLowerCase();
    final isTax = lowerTitle.contains('impuesto') || lowerTitle.contains('tributo');
    final isGraduation = lowerTitle.contains('titulación') || lowerTitle.contains('título') || lowerTitle.contains('egreso');
    final isPassport = lowerTitle.contains('pasaporte');

    // Determine "¿Para qué sirve?" points
    final List<String> purposeItems = [];
    if (isTax) {
      purposeItems.addAll([
        'Mantiene al día tu situación tributaria como propietario.',
        'Es requisito indispensable para transferir, hipotecar o vender el inmueble.',
        'Permite obtener el certificado de no adeudo municipal.',
        'Evita multas, intereses y acciones legales del municipio.',
      ]);
    } else if (isGraduation) {
      purposeItems.addAll([
        'Acredita oficialmente tu condición de profesional licenciado.',
        'Habilita el ejercicio legal de la profesión en territorio nacional.',
        'Permite postular a puestos de trabajo y estudios de posgrado.',
        'Es indispensable para el registro en colegios de profesionales.',
      ]);
    } else if (isPassport) {
      purposeItems.addAll([
        'Sirve como documento oficial de viaje internacional.',
        'Permite el libre tránsito por países de convenio.',
        'Acredita tu identidad y nacionalidad boliviana en el exterior.',
        'Es obligatorio para el control migratorio de salida e ingreso.',
      ]);
    } else {
      purposeItems.addAll([
        'Permite formalizar y validar legalmente tu solicitud.',
        'Acredita el cumplimiento de los requisitos establecidos.',
        'Habilita la obtención del documento o certificado oficial.',
        'Evita retrasos o sanciones por incumplimiento normativo.',
      ]);
    }

    // Determine who can do it
    final whoCanDoItText = data.whoCanDoIt.isNotEmpty
        ? data.whoCanDoIt
        : 'Toda persona natural o jurídica interesada, o un apoderado legal debidamente autorizado mediante poder notariado.';

    // Default description if empty
    final displayDescription = data.description.isNotEmpty
        ? data.description
        : 'Este trámite permite gestionar la solicitud formal correspondiente ante la entidad gubernamental ${data.institution} de manera presencial o digital según la modalidad establecida.';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
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
                
                // Titulo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: const TextStyle(
                          color: Color(0xFF001B4D),
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00B8B8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isTax 
                                  ? 'Trámite municipal · La Paz' 
                                  : 'Trámite · ${data.institution}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF00B8B8),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Boton Cerrar X
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close, color: Color(0xFF8DA0A5), size: 18),
                    onPressed: onClose,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    displayDescription,
                    style: const TextStyle(
                      color: Color(0xFF001B4D),
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Para que sirve
                  Row(
                    children: const [
                      Icon(Icons.auto_awesome_outlined, color: Color(0xFF00B8B8), size: 18),
                      SizedBox(width: 8),
                      Text(
                        '¿Para qué sirve?',
                        style: TextStyle(
                          color: Color(0xFF001B4D),
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...purposeItems.map((item) => _buildCheckItem(item)),
                  const SizedBox(height: 16),

                  // Quien debe pagarlo/hacerlo
                  Row(
                    children: [
                      const Icon(Icons.person_outline, color: Color(0xFF00B8B8), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        isTax ? '¿Quién debe pagarlo?' : '¿Quién puede realizar este trámite?',
                        style: const TextStyle(
                          color: Color(0xFF001B4D),
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    whoCanDoItText,
                    style: const TextStyle(
                      color: Color(0xFF001B4D),
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Cuando se realiza/paga
                  Row(
                    children: [
                      const Icon(Icons.access_time_outlined, color: Color(0xFF00B8B8), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        isTax ? '¿Cuándo se paga?' : '¿Cuándo se realiza?',
                        style: const TextStyle(
                          color: Color(0xFF001B4D),
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (isTax)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTimeChip(
                          'Feb – May',
                          const Color(0xFF00B8B8),
                          const Color(0xFFE6F8F8),
                          const Color(0xFF00B8B8).withValues(alpha: 0.3),
                        ),
                        _buildTimeChip(
                          'Jun – Sep',
                          const Color(0xFFD97706),
                          const Color(0xFFFEF3C7),
                          const Color(0xFFD97706).withValues(alpha: 0.3),
                        ),
                        _buildTimeChip(
                          'Oct – Dic',
                          const Color(0xFFDC2626),
                          const Color(0xFFFEE2E2),
                          const Color(0xFFDC2626).withValues(alpha: 0.3),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        _buildTimeChip(
                          data.time.isNotEmpty ? data.time : 'Todo el año',
                          const Color(0xFF0047C7),
                          const Color(0xFFE6EFFF),
                          const Color(0xFF0047C7).withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // Bottom Buttons
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF9FBFF),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (onShowFullFicha != null) {
                        onShowFullFicha!();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0047C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Ver ficha completa →',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF001B4D),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
