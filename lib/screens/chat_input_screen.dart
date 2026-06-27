import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/chat_message.dart';
import '../widgets/procedure_card.dart';
import '../widgets/procedure_detail_sheet.dart';

class ChatInputScreen extends StatefulWidget {
  const ChatInputScreen({super.key});

  @override
  State<ChatInputScreen> createState() => _ChatInputScreenState();
}

class BotStep {
  final String number;
  final String title;
  final String description;

  BotStep({required this.number, required this.title, required this.description});
}

class _ChatInputScreenState extends State<ChatInputScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isChatMode = false;
  bool _showProcedureDetail = false;
  ProcedureData? _selectedProcedureData;
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  ProcedureData _getMockProcedureData() {
    return ProcedureData(
      title: 'Pago de impuesto municipal a la propiedad de bienes inmuebles',
      institution: 'Gobierno Autónomo Municipal de La Paz',
      cost: 'Bs. 100-500',
      time: '1 día',
      modality: 'Presencial / Virtual',
      iconEmoji: '🏠',
      steps: [
        'Verifica si tienes deuda pendiente.',
        'Reúne tus documentos.',
        'Ingresa al portal oficial o acude a la oficina.',
        'Genera la boleta o liquidación.',
        'Realiza el pago correspondiente.',
        'Guarda tu comprobante.',
      ],
      documents: [
        'Documento de Identidad del propietario (original y copia).',
        'Última boleta de pago del impuesto municipal realizado.',
        'Testimonio de propiedad del bien inmueble registrado.',
        'Plano de ubicación y uso de suelo aprobado.',
      ],
      recommendations: [
        'Verifica los descuentos por pago anticipado vigentes en el portal tributario.',
        'Realiza el pago en entidades financieras autorizadas.',
      ],
      whoCanDoIt: 'El trámite puede ser realizado por el propietario registrado o un tercero autorizado.',
      whoCanDoItSubtitle: 'Titular o tercero',
      whereToDoIt: [
        'Oficinas del Gobierno Autónomo Municipal de La Paz.',
        'Entidades financieras autorizadas.',
        'Portal de Internet oficial (RUAT).',
      ],
      sources: const [],
      hasDownloadableDocs: true,
      hasDynamicFill: false,
    );
  }

  List<BotStep> _parseBotSteps(String text) {
    if (text.trim().isEmpty || text.trim().startsWith('{')) {
      return [];
    }

    final List<BotStep> steps = [];
    final lines = text.split('\n');
    
    String currentNumber = '';
    String currentTitle = '';
    String currentDesc = '';

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      final matchNumber = RegExp(r'^(\d+)\s*[\.\-]\s*').firstMatch(line);
      final matchBullet = RegExp(r'^[\-\*]\s*').firstMatch(line);

      if (matchNumber != null) {
        if (currentTitle.isNotEmpty || currentDesc.isNotEmpty) {
          steps.add(BotStep(
            number: currentNumber.isNotEmpty ? currentNumber : '${steps.length + 1}',
            title: _cleanMarkdown(currentTitle),
            description: _cleanMarkdown(currentDesc),
          ));
        }
        currentNumber = matchNumber.group(1) ?? '${steps.length + 1}';
        var remaining = line.substring(matchNumber.end).trim();
        
        final titleMatch = RegExp(r'^\*\*(.*?)\*\*').firstMatch(remaining);
        if (titleMatch != null) {
          currentTitle = titleMatch.group(1) ?? '';
          currentDesc = remaining.substring(titleMatch.end).trim();
          if (currentDesc.startsWith(':')) {
            currentDesc = currentDesc.substring(1).trim();
          }
        } else {
          final colonIdx = remaining.indexOf(':');
          if (colonIdx != -1) {
            currentTitle = remaining.substring(0, colonIdx).trim();
            currentDesc = remaining.substring(colonIdx + 1).trim();
          } else {
            currentTitle = remaining;
            currentDesc = '';
          }
        }
      } else if (matchBullet != null) {
        if (currentTitle.isNotEmpty || currentDesc.isNotEmpty) {
          steps.add(BotStep(
            number: currentNumber.isNotEmpty ? currentNumber : '${steps.length + 1}',
            title: _cleanMarkdown(currentTitle),
            description: _cleanMarkdown(currentDesc),
          ));
        }
        currentNumber = '•';
        var remaining = line.substring(matchBullet.end).trim();
        final titleMatch = RegExp(r'^\*\*(.*?)\*\*').firstMatch(remaining);
        if (titleMatch != null) {
          currentTitle = titleMatch.group(1) ?? '';
          currentDesc = remaining.substring(titleMatch.end).trim();
          if (currentDesc.startsWith(':')) {
            currentDesc = currentDesc.substring(1).trim();
          }
        } else {
          final colonIdx = remaining.indexOf(':');
          if (colonIdx != -1) {
            currentTitle = remaining.substring(0, colonIdx).trim();
            currentDesc = remaining.substring(colonIdx + 1).trim();
          } else {
            currentTitle = remaining;
            currentDesc = '';
          }
        }
      } else {
        final titleMatch = RegExp(r'^\*\*(.*?)\*\*').firstMatch(line);
        if (titleMatch != null) {
          if (currentTitle.isNotEmpty || currentDesc.isNotEmpty) {
            steps.add(BotStep(
              number: currentNumber.isNotEmpty ? currentNumber : '${steps.length + 1}',
              title: _cleanMarkdown(currentTitle),
              description: _cleanMarkdown(currentDesc),
            ));
          }
          currentNumber = '${steps.length + 1}';
          currentTitle = titleMatch.group(1) ?? '';
          currentDesc = line.substring(titleMatch.end).trim();
          if (currentDesc.startsWith(':')) {
            currentDesc = currentDesc.substring(1).trim();
          }
        } else {
          if (currentTitle.isNotEmpty) {
            if (currentDesc.isEmpty) {
              currentDesc = line;
            } else {
              currentDesc += '\n$line';
            }
          } else {
            currentDesc = currentDesc.isEmpty ? line : '$currentDesc\n$line';
          }
        }
      }
    }

    if (currentTitle.isNotEmpty || currentDesc.isNotEmpty) {
      steps.add(BotStep(
        number: currentNumber.isNotEmpty ? currentNumber : '${steps.length + 1}',
        title: _cleanMarkdown(currentTitle),
        description: _cleanMarkdown(currentDesc),
      ));
    }

    return steps;
  }

  String _cleanMarkdown(String text) {
    var clean = text.replaceAll('**', '')
                    .replaceAll('###', '')
                    .replaceAll('##', '')
                    .replaceAll('#', '')
                    .trim();
    if (clean.startsWith('"') && clean.endsWith('"') && clean.length > 1) {
      clean = clean.substring(1, clean.length - 1).trim();
    }
    return clean;
  }

  bool _isQuotaExceededError(String errorText) {
    final clean = errorText.toLowerCase();
    return clean.contains('quota exceeded') ||
           clean.contains('current quota') ||
           clean.contains('código: 429') ||
           clean.contains('429') ||
           clean.contains('resource_exhausted');
  }

  bool _isProcedureQuery(String query, String text) {
    final q = query.toLowerCase();
    final keywords = [
      'impuesto', 'casa', 'inmueble', 'propiedad', 'municipal',
      'titulación', 'umsa', 'título', 'graduación', 'egreso',
      'pasaporte', 'renovar', 'renovación', 'visa', 'trámite',
      'licencia', 'negocio', 'transferir', 'registrar'
    ];
    for (var kw in keywords) {
      if (q.contains(kw)) return true;
    }
    if (_parseBotSteps(text).length >= 2) {
      return true;
    }
    return false;
  }

  ProcedureData _parseOrBuildProcedureData(String text, String query) {
    final cleanQuery = query.toLowerCase();
    
    String title = 'Trámite Requerido';
    String institution = 'Entidad Estatal';
    String description = 'Detalle de los pasos e información del trámite solicitado.';
    String cost = 'Según arancel';
    String time = 'Variable';
    String modality = 'Presencial';
    
    if (cleanQuery.contains('impuesto') || 
        cleanQuery.contains('casa') || 
        cleanQuery.contains('inmueble') || 
        cleanQuery.contains('propiedad') || 
        cleanQuery.contains('municipal')) {
      title = 'Pago de impuesto municipal a la propiedad de bienes inmuebles';
      institution = 'Gobierno Autónomo Municipal de La Paz';
      description = 'Es el pago anual obligatorio que deben realizar los propietarios de inmuebles (casas, terrenos, departamentos) ubicados dentro del municipio de La Paz, como contribución al Gobierno Autónomo Municipal (GAMLP).';
      cost = 'Bs. 100–500';
      time = '1 día';
      modality = 'Presencial / Virtual';
    } else if (cleanQuery.contains('titulación') || 
               cleanQuery.contains('umsa') || 
               cleanQuery.contains('título') || 
               cleanQuery.contains('graduación') ||
               cleanQuery.contains('egreso')) {
      title = 'Trámite de Titulación en la UMSA';
      institution = 'Universidad Mayor de San Andrés (UMSA)';
      description = 'El trámite de titulación en la Universidad Mayor de San Andrés (UMSA) es el proceso académico y administrativo mediante el cual se otorga el título profesional a los graduados que cumplieron con el plan de estudios.';
      cost = 'Desde Bs. 2000';
      time = 'Varias semanas';
      modality = 'Presencial';
    } else if (cleanQuery.contains('pasaporte') || 
               cleanQuery.contains('renovar') || 
               cleanQuery.contains('renovación')) {
      title = 'Renovación de pasaporte';
      institution = 'Servicio General de Identificación Personal';
      description = 'La renovación u obtención de pasaporte es el trámite oficial requerido para ciudadanos bolivianos que viajan al exterior, gestionado por la Dirección General de Migración.';
      cost = 'Según arancel vigente';
      time = 'Variable';
      modality = 'Presencial';
    } else {
      final lines = text.split('\n');
      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty) continue;
        final boldMatch = RegExp(r'^\*\*(.*?)\*\*').firstMatch(line);
        if (boldMatch != null) {
          title = boldMatch.group(1) ?? title;
          break;
        } else if (line.length > 5 && line.length < 60 && !line.startsWith(RegExp(r'\d'))) {
          title = line;
          break;
        }
      }
    }

    final parsedSteps = _parseBotSteps(text);
    final List<String> steps = [];
    if (parsedSteps.isNotEmpty) {
      for (var s in parsedSteps) {
        if (s.title.isNotEmpty) {
          steps.add('**${s.title}:** ${s.description}');
        } else {
          steps.add(s.description);
        }
      }
    } else {
      if (cleanQuery.contains('impuesto')) {
        steps.addAll([
          'Verifica si tienes deuda pendiente.',
          'Reúne tus documentos.',
          'Ingresa al portal oficial o acude a la oficina.',
          'Genera la boleta o liquidación.',
          'Realiza el pago correspondiente.',
          'Guarda tu comprobante.',
        ]);
      } else if (cleanQuery.contains('titulación') || cleanQuery.contains('egreso')) {
        steps.addAll([
          'Homologa tu Título de Bachiller: Asegúrate de que tu título esté legalizado o apostillado si corresponde.',
          'Postula y obtén admisión en la UMSA: Cumple con los requisitos académicos establecidos por tu carrera.',
          'Reúne tus documentos: Prepara certificados, kardex, cédula de identidad y formularios requeridos.',
          'Realiza los pagos correspondientes: Verifica aranceles vigentes y guarda tus comprobantes.',
          'Presenta la solicitud: Entrega la documentación en la unidad correspondiente.',
          'Haz seguimiento del trámite: Consulta el estado del proceso hasta la emisión del título.',
        ]);
      } else if (cleanQuery.contains('pasaporte')) {
        steps.addAll([
          'Verifica los requisitos vigentes: Revisa los documentos solicitados por la entidad correspondiente.',
          'Agenda tu cita: Selecciona fecha y hora disponibles.',
          'Prepara tus documentos: Lleva cédula, pasaporte anterior y comprobantes requeridos.',
          'Realiza el pago: Cancela el arancel correspondiente.',
          'Asiste a la cita: Presenta documentos y realiza el registro biométrico.',
          'Recoge tu pasaporte: Consulta la fecha de entrega y retira el documento.',
        ]);
      } else {
        final sentences = text.split(RegExp(r'[\.\?\!]'));
        for (var s in sentences) {
          s = s.trim();
          if (s.length > 10 && steps.length < 5) {
            steps.add(s);
          }
        }
      }
    }

    return ProcedureData(
      title: title,
      institution: institution,
      cost: cost,
      time: time,
      modality: modality,
      iconEmoji: '📄',
      description: description,
      steps: steps,
      documents: [
        'Documento de Identidad vigente (original y copia).',
        'Formulario de solicitud del trámite correspondiente.',
        'Comprobante de depósito bancario original.',
      ],
      recommendations: [
        'Verifica los requisitos específicos de tu trámite antes de asistir.',
        'Realiza los pagos únicamente en los bancos autorizados.',
      ],
      whoCanDoIt: 'El trámite puede ser realizado por el interesado directo o apoderado legal.',
      whoCanDoItSubtitle: 'Titular o apoderado',
      whereToDoIt: [
        'Oficinas centrales de la institución.',
        'Entidades bancarias habilitadas.',
      ],
    );
  }

  void _applyQuotaFallback(ChatMessage botMessage, String query) {
    // Fallback temporal para pruebas cuando Gemini excede cuota.
    final cleanQuery = query.toLowerCase();
    
    if (cleanQuery.contains('impuesto') || 
        cleanQuery.contains('casa') || 
        cleanQuery.contains('inmueble') || 
        cleanQuery.contains('propiedad') || 
        cleanQuery.contains('municipal')) {
      botMessage.text = '¡Hola! Encontré el trámite que necesitas. Aquí tienes la guía completa:';
      botMessage.procedureData = _parseOrBuildProcedureData('', query);
      botMessage.error = null;
    } else if (cleanQuery.contains('titulación') || 
               cleanQuery.contains('umsa') || 
               cleanQuery.contains('título') || 
               cleanQuery.contains('graduación') ||
               cleanQuery.contains('egreso')) {
      botMessage.text = '¡Hola! Encontré el trámite que necesitas. Aquí tienes la guía completa:';
      botMessage.procedureData = _parseOrBuildProcedureData('', query);
      botMessage.error = null;
    } else if (cleanQuery.contains('pasaporte') || 
               cleanQuery.contains('renovar') || 
               cleanQuery.contains('renovación')) {
      botMessage.text = '¡Hola! Encontré el trámite que necesitas. Aquí tienes la guía completa:';
      botMessage.procedureData = _parseOrBuildProcedureData('', query);
      botMessage.error = null;
    } else {
      botMessage.text = 'El asistente está temporalmente ocupado por límite de uso. Mientras tanto, te muestro una guía de ejemplo para validar la interfaz.';
      botMessage.procedureData = null;
      botMessage.error = null;
    }
  }

  void _startStreaming() {
    if (_queryController.text.trim().isEmpty) return;
    
    final query = _queryController.text.trim();
    
    setState(() {
      _isLoading = true;
      _isChatMode = true;
      
      // Add User Message
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: query,
        isUser: true,
      ));
      
      // Add Bot Message Placeholder
      _messages.add(ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_bot',
        isUser: false,
        text: '',
        steps: [],
      ));
      
      _queryController.clear();
    });

    _scrollToBottom();

    final botMessage = _messages.last;

    _apiService.streamCitizenshipQuery(query).listen(
      (chunkMap) {
        if (mounted) {
          setState(() {
            final eventName = chunkMap['__eventName'];
            
            if (eventName == 'agent_event') {
              final newSteps = List<String>.from(botMessage.steps);
              final msg = chunkMap['message'] ?? chunkMap['action'] ?? chunkMap['name'] ?? chunkMap['step'] ?? 'Procesando...';
              newSteps.add(msg.toString());
              botMessage.steps = newSteps;
            } else if (eventName == 'final') {
              botMessage.finalResult = chunkMap;
              final summaryStr = chunkMap['summary']?.toString() ?? '';
              
              String cleanStr = summaryStr.trim();
              if (cleanStr.startsWith('```json')) {
                cleanStr = cleanStr.substring(7);
              } else if (cleanStr.startsWith('```')) {
                cleanStr = cleanStr.substring(3);
              }
              if (cleanStr.endsWith('```')) {
                cleanStr = cleanStr.substring(0, cleanStr.length - 3);
              }
              cleanStr = cleanStr.trim();

              if (cleanStr.startsWith('{')) {
                try {
                  final dataMap = jsonDecode(cleanStr);
                  botMessage.procedureData = ProcedureData(
                    title: dataMap['title'] ?? 'Trámite',
                    institution: dataMap['institution'] ?? '',
                    cost: dataMap['cost'] ?? '',
                    time: dataMap['time'] ?? '',
                    modality: dataMap['modality'] ?? '',
                    iconEmoji: dataMap['iconEmoji'] ?? '📄',
                    description: dataMap['description'] ?? '',
                    steps: List<String>.from(dataMap['steps'] ?? []),
                    documents: List<String>.from(dataMap['documents'] ?? []),
                    recommendations: List<String>.from(dataMap['recommendations'] ?? []),
                    whoCanDoIt: dataMap['whoCanDoIt'] ?? '',
                    whoCanDoItSubtitle: dataMap['whoCanDoItSubtitle'] ?? '',
                    whereToDoIt: List<String>.from(dataMap['whereToDoIt'] ?? []),
                    sources: (dataMap['sources'] as List?)?.map<Map<String, String>>((s) => {
                      'title': s['title']?.toString() ?? '',
                      'url': s['url']?.toString() ?? ''
                    }).toList() ?? <Map<String, String>>[],
                    hasDownloadableDocs: dataMap['hasDownloadableDocs'] ?? false,
                    hasDynamicFill: dataMap['hasDynamicFill'] ?? false,
                  );
                } catch (e) {
                  debugPrint('Error parsing JSON from summary: $e');
                  botMessage.error = 'Error dibujando el componente visual: $e';
                }
              }
            } else if (eventName == 'error') {
              final errMsg = chunkMap['message']?.toString() ?? 'Error en el proceso';
              if (_isQuotaExceededError(errMsg)) {
                _applyQuotaFallback(botMessage, query);
              } else {
                botMessage.error = errMsg;
              }
              _isLoading = false;
            } else if (eventName == 'done') {
              _isLoading = false;
            } else {
               if (chunkMap.containsKey('rawText')) {
                 botMessage.text += chunkMap['rawText'].toString();
               }
            }
          });
          _scrollToBottom();
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            final errMsg = e.toString();
            if (_isQuotaExceededError(errMsg)) {
              _applyQuotaFallback(botMessage, query);
            } else {
              botMessage.error = 'Error de conexión: $e';
            }
            _isLoading = false;
          });
          _scrollToBottom();
        }
      },
      onDone: () {
        if (mounted) {
          setState(() {
            _isLoading = false;
            if (_isQuotaExceededError(botMessage.text) || _isQuotaExceededError(botMessage.error ?? '')) {
              _applyQuotaFallback(botMessage, query);
            } else {
              if (_isProcedureQuery(query, botMessage.text)) {
                final textToParse = botMessage.text;
                botMessage.text = '¡Hola! Encontré el trámite que necesitas. Aquí tienes la guía completa:';
                botMessage.procedureData = _parseOrBuildProcedureData(textToParse, query);
              }
            }
          });
        }
      }
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildChipsRow() {
    final chips = ['Requisitos', 'Costos', 'Horarios', 'Descargar guía'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      child: Row(
        children: chips.map((chipText) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Filtrando por: $chipText')),
                );
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF00B8B8), width: 1),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                chipText,
                style: const TextStyle(
                  color: Color(0xFF0047C7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBotMessageContent(ChatMessage message) {
    if (message.error != null) {
      return Text(
        message.error!,
        style: const TextStyle(color: Colors.red, fontSize: 14.5),
      );
    }

    if (message.procedureData != null) {
      final cleanText = _cleanMarkdown(message.text);
      return Text(cleanText, style: const TextStyle(fontSize: 14.5, color: Color(0xFF001B4D)));
    }

    if (message.finalResult != null) {
      final result = message.finalResult!;
      final summaryStr = _cleanMarkdown(result['summary']?.toString() ?? '');
      final reqList = (result['requirements'] as List?)?.map((r) => _cleanMarkdown(r.toString())).toList() ?? [];
      final warnList = (result['warnings'] as List?)?.map((w) => _cleanMarkdown(w.toString())).toList() ?? [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summaryStr.isNotEmpty) ...[
            Text(
              summaryStr,
              style: const TextStyle(fontSize: 14.5, color: Color(0xFF001B4D)),
            ),
            const SizedBox(height: 12),
          ],
          if (reqList.isNotEmpty) ...[
            const Text('Requisitos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF001B4D))),
            const SizedBox(height: 6),
            ...reqList.map((req) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 14.5, color: Color(0xFF00B8B8), fontWeight: FontWeight.bold)),
                  Expanded(child: Text(req, style: const TextStyle(fontSize: 14.5, color: Color(0xFF001B4D)))),
                ],
              ),
            )),
            const SizedBox(height: 12),
          ],
          if (warnList.isNotEmpty) ...[
            const Text('Avisos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.orange)),
            const SizedBox(height: 6),
            ...warnList.map((warn) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                  const SizedBox(width: 6),
                  Expanded(child: Text(warn, style: const TextStyle(fontSize: 14, color: Color(0xFF001B4D)))),
                ],
              ),
            )),
          ],
        ],
      );
    }

    if (message.steps.isNotEmpty) {
      final currentStep = _cleanMarkdown(message.steps.last);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00B8B8)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              currentStep,
              style: const TextStyle(color: Colors.black54, fontStyle: FontStyle.italic, fontSize: 13.5),
            ),
          ),
        ],
      );
    }

    if (message.text.isNotEmpty) {
      final parsedSteps = _parseBotSteps(message.text);
      if (parsedSteps.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: parsedSteps.map((step) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00B8B8),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      step.number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (step.title.isNotEmpty) ...[
                          Text(
                            step.title,
                            style: const TextStyle(
                              color: Color(0xFF001B4D),
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (step.description.isNotEmpty)
                          Text(
                            step.description,
                            style: const TextStyle(
                              color: Color(0xFF001B4D),
                              fontSize: 13.5,
                              height: 1.4,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      }

      final cleanText = _cleanMarkdown(message.text);
      return Text(cleanText, style: const TextStyle(fontSize: 14.5, color: Color(0xFF001B4D)));
    }

    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00B8B8)),
        ),
        SizedBox(width: 12),
        Text('Iniciando...', style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic, fontSize: 13.5)),
      ],
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF0047D7),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(6),
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message.text,
              style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00B8B8),
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/app-icono-yase.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFFDFE8F5),
                        width: 1.5,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildBotMessageContent(message),
                  ),
                ),
              ],
            ),
            if (message.procedureData != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: ProcedureCard(
                  data: message.procedureData!,
                  onTap: () {
                    setState(() {
                      _selectedProcedureData = message.procedureData;
                      _showProcedureDetail = true;
                    });
                  },
                ),
              ),
            ],
          ],
        ),
      );
    }
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE6EFFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: isActive ? const Color(0xFF0047C7) : const Color(0xFF8DA0A5),
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF0047C7) : const Color(0xFF8DA0A5),
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF003C9E),
              Color(0xFF00B1D1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double verticalPadding = constraints.maxHeight * 0.04;
              return Padding(
                padding: EdgeInsets.symmetric(vertical: verticalPadding),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: 390,
                    height: 844,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F7FE),
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 25,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(36),
                        child: Stack(
                          children: [
                            Scaffold(
                              backgroundColor: const Color(0xFFF3F7FE),
                              key: _scaffoldKey,
                              body: Column(
                                children: [
                                  // 1. Status Bar
                                  Container(
                                    height: 44,
                                    color: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          '9:41',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF003C9E),
                                            fontSize: 14,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.signal_cellular_4_bar, color: Color(0xFF003C9E), size: 14),
                                            const SizedBox(width: 5),
                                            const Icon(Icons.wifi, color: Color(0xFF003C9E), size: 14),
                                            const SizedBox(width: 5),
                                            Container(
                                              width: 20,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                border: Border.all(color: const Color(0xFF003C9E), width: 1),
                                                borderRadius: BorderRadius.circular(2.5),
                                              ),
                                              padding: const EdgeInsets.all(1),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF003C9E),
                                                  borderRadius: BorderRadius.circular(1),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // 2. Action Bar / Header
                                  Container(
                                    height: 56,
                                    color: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Back button
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFF7F9FD),
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(Icons.arrow_back, color: Color(0xFF0047C7), size: 18),
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ),
                                        
                                        // Center logo + info
                                        Row(
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF00B8B8),
                                                shape: BoxShape.circle,
                                              ),
                                              alignment: Alignment.center,
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(18),
                                                child: Image.asset(
                                                  'assets/images/app-icono-yase.png',
                                                  width: 36,
                                                  height: 36,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Ya Sé',
                                                  style: TextStyle(
                                                    color: Color(0xFF003C9E),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 6,
                                                      height: 6,
                                                      decoration: const BoxDecoration(
                                                        color: Color(0xFF34A853),
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Text(
                                                      'Asistente inteligente',
                                                      style: TextStyle(
                                                        color: Color(0xFF8DA0A5),
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        
                                        // Menu button
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFF7F9FD),
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(Icons.more_vert, color: Color(0xFF0047C7), size: 18),
                                            onPressed: () {},
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // 3. Chat Messages / Content
                                  Expanded(
                                    child: _isChatMode
                                        ? ListView.builder(
                                            controller: _scrollController,
                                            padding: const EdgeInsets.only(top: 10, bottom: 20),
                                            itemCount: _messages.length,
                                            itemBuilder: (context, index) {
                                              return _buildChatBubble(_messages[index]);
                                            },
                                          )
                                        : Center(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Image.asset(
                                                    'assets/images/logo-yase.png',
                                                    height: 70,
                                                    fit: BoxFit.contain,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  const Text(
                                                    '¿En qué te puedo ayudar hoy?',
                                                    style: TextStyle(
                                                      color: Color(0xFF003C9E),
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  const Text(
                                                    'Pregúntame sobre trámites, requisitos o pasos en Bolivia.',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: Color(0xFF8DA0A5),
                                                      fontSize: 13.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                              bottomNavigationBar: Container(
                                color: Colors.white,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isChatMode) _buildChipsRow(),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 4),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(24),
                                                border: Border.all(
                                                  color: const Color(0xFFDFE8F5),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                                    child: Icon(Icons.search, color: Color(0xFF00B8B8), size: 20),
                                                  ),
                                                  Expanded(
                                                    child: TextField(
                                                      controller: _queryController,
                                                      style: const TextStyle(fontSize: 14.5, color: Color(0xFF001B4D)),
                                                      decoration: const InputDecoration(
                                                        hintText: '¿Qué necesitas hacer?',
                                                        hintStyle: TextStyle(color: Color(0xFF8DA0A5), fontSize: 13.5),
                                                        border: InputBorder.none,
                                                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                                                      ),
                                                      onSubmitted: (_) => _startStreaming(),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.attach_file, color: Color(0xFF8DA0A5), size: 20),
                                                    onPressed: () {},
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF0047C7),
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              icon: _isLoading
                                                  ? const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : const Icon(Icons.send, color: Colors.white, size: 18),
                                              onPressed: _isLoading ? null : _startStreaming,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      height: 80,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        border: Border(
                                          top: BorderSide(color: Color(0xFFDFE8F5), width: 1),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildNavItem(Icons.home_outlined, 'Inicio', false),
                                          _buildNavItem(Icons.chat_bubble_outline, 'IA', true),
                                          _buildNavItem(Icons.assignment_outlined, 'Docs', false),
                                          _buildNavItem(Icons.history_outlined, 'Historial', false),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_showProcedureDetail) ...[
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showProcedureDetail = false;
                                  });
                                },
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.5),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: ProcedureDetailSheet(
                                  data: _selectedProcedureData ?? _getMockProcedureData(),
                                  onClose: () {
                                    setState(() {
                                      _showProcedureDetail = false;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
