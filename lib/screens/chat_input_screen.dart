import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/custom_header.dart';
import '../models/chat_message.dart';
import '../widgets/procedure_card.dart';

class ChatInputScreen extends StatefulWidget {
  const ChatInputScreen({super.key});

  @override
  State<ChatInputScreen> createState() => _ChatInputScreenState();
}

class _ChatInputScreenState extends State<ChatInputScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isChatMode = false;
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
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
              // Handle potential keys for the agent message/action
              final msg = chunkMap['message'] ?? chunkMap['action'] ?? chunkMap['name'] ?? chunkMap['step'] ?? 'Procesando...';
              newSteps.add(msg.toString());
              botMessage.steps = newSteps;
            } else if (eventName == 'final') {
              botMessage.finalResult = chunkMap;
              final summaryStr = chunkMap['summary']?.toString() ?? '';
              
              // Limpiar posibles bloques de markdown que el LLM suele agregar (ej: ```json ... ```)
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
                  // The summary string is now a JSON returned by the new Prompt
                  final dataMap = jsonDecode(cleanStr);
                  botMessage.procedureData = ProcedureData(
                    title: dataMap['title'] ?? 'Trámite',
                    institution: dataMap['institution'] ?? '',
                    cost: dataMap['cost'] ?? '',
                    time: dataMap['time'] ?? '',
                    modality: dataMap['modality'] ?? '',
                    iconEmoji: dataMap['iconEmoji'] ?? '📄',
                    steps: List<String>.from(dataMap['steps'] ?? []),
                    documents: (dataMap['documents'] as List?)
                        ?.map((e) => ProcedureDocument.fromJson(e))
                        .toList() ?? [],
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
                  // Fallback: If parsing fails, it will render raw summary text and show error
                  print('Error parsing JSON from summary: $e');
                  botMessage.error = 'Error dibujando el componente visual: $e';
                }
              }
            } else if (eventName == 'error') {
              botMessage.error = chunkMap['message']?.toString() ?? 'Error en el proceso';
              _isLoading = false;
            } else if (eventName == 'done') {
              _isLoading = false;
            } else {
               // Fallback just in case
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
            botMessage.error = 'Error de conexión: $e';
            _isLoading = false;
          });
          _scrollToBottom();
        }
      },
      onDone: () {
        if (mounted) {
          setState(() {
            _isLoading = false;
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

  Widget _buildInputBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _queryController,
        decoration: InputDecoration(
          hintText: '¿Qué necesitas hacer?',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF00B8B8)),
          suffixIcon: Padding(
            padding: const EdgeInsets.all(6.0),
            child: InkWell(
              onTap: _isLoading ? null : _startStreaming,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0047C7),
                  shape: BoxShape.circle,
                ),
                child: _isLoading 
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onSubmitted: (_) => _startStreaming(),
      ),
    );
  }

  Widget _buildBotMessageContent(ChatMessage message) {
    if (message.error != null) {
      return Text(
        message.error!,
        style: const TextStyle(color: Colors.red, fontSize: 16),
      );
    }

    if (message.procedureData != null) {
      return ProcedureCard(data: message.procedureData!);
    }

    if (message.finalResult != null) {
      // Render final structured data
      final result = message.finalResult!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result['summary'] != null && result['summary'].toString().trim().isNotEmpty) ...[
            Text(
              result['summary'].toString(),
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 12),
          ],
          if (result['requirements'] != null && (result['requirements'] as List).isNotEmpty) ...[
            const Text('Requisitos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            ...(result['requirements'] as List).map((req) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(child: Text(req.toString(), style: const TextStyle(fontSize: 16))),
                ],
              ),
            )),
            const SizedBox(height: 12),
          ],
          if (result['warnings'] != null && (result['warnings'] as List).isNotEmpty) ...[
            const Text('Avisos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
            const SizedBox(height: 4),
            ...(result['warnings'] as List).map((warn) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Expanded(child: Text(warn.toString(), style: const TextStyle(fontSize: 14))),
                ],
              ),
            )),
          ],
        ],
      );
    }

    // Loading steps state
    if (message.steps.isNotEmpty) {
      final currentStep = message.steps.last;
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
              style: const TextStyle(color: Colors.black54, fontStyle: FontStyle.italic, fontSize: 14),
            ),
          ),
        ],
      );
    }

    if (message.text.isNotEmpty) {
      return Text(message.text, style: const TextStyle(fontSize: 16, color: Colors.black87));
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
        Text('Iniciando...', style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic, fontSize: 14)),
      ],
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/app-icono-yase.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser ? const Color(0xFF0047C7) : const Color(0xFFF5F8FC),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 0),
                  bottomRight: Radius.circular(message.isUser ? 0 : 20),
                ),
                boxShadow: [
                  if (!message.isUser)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: message.isUser 
                  ? Text(
                      message.text,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    )
                  : _buildBotMessageContent(message),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSidebarOpenDesktop = true;

  Widget _buildSidebarContent() {
    return Container(
      width: 280,
      color: const Color(0xFFF5F8FC),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _messages.clear();
                    _isChatMode = false;
                    _queryController.clear();
                  });
                  if (MediaQuery.of(context).size.width < 800) {
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Color(0xFF003C9E), size: 20),
                      SizedBox(width: 8),
                      Text('Nuevo chat', style: TextStyle(color: Color(0xFF003C9E), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Recientes',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem('¿Cómo obtener la visa?'),
                  _buildDrawerItem('Requisitos para pasaporte'),
                  _buildDrawerItem('Pago de impuestos 2024'),
                ],
              ),
            ),
            const Divider(),
            _buildDrawerItem('Configuración', icon: Icons.settings),
            _buildDrawerItem('Ayuda', icon: Icons.help_outline),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, {IconData? icon}) {
    return ListTile(
      leading: Icon(icon ?? Icons.chat_bubble_outline, size: 20, color: const Color(0xFF003C9E)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        if (MediaQuery.of(context).size.width < 800) {
          Navigator.pop(context);
        }
      },
    );
  }

  Widget _buildMainContent(bool isDesktop) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            if (!_isChatMode)
              CustomHeader(
                onMenuPressed: () {
                  if (isDesktop) {
                    setState(() => _isSidebarOpenDesktop = !_isSidebarOpenDesktop);
                  } else {
                    _scaffoldKey.currentState?.openDrawer();
                  }
                },
              )
            else
              // Header reducido en modo chat
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Row(
                  children: [
                    Builder(
                      builder: (context) {
                        return IconButton(
                          icon: const Icon(Icons.menu, color: Color(0xFF003C9E)),
                          onPressed: () {
                            if (isDesktop) {
                              setState(() => _isSidebarOpenDesktop = !_isSidebarOpenDesktop);
                            } else {
                              _scaffoldKey.currentState?.openDrawer();
                            }
                          },
                        );
                      }
                    ),
                    Image.asset(
                      'assets/images/logo-rectangular.png',
                      height: 36,
                    ),
                  ],
                ),
              ),
            
            if (!_isChatMode)
              // Modo centrado (Inicial)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: _buildInputBox(),
                  ),
                ),
              )
            else ...[
              // Modo Chat (Lista de mensajes)
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 20, bottom: 20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildChatBubble(_messages[index]);
                  },
                ),
              ),
              
              // Buscador en la parte inferior anclado
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildInputBox(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      key: _scaffoldKey,
      drawer: isDesktop ? null : Drawer(child: _buildSidebarContent()),
      body: Row(
        children: [
          if (isDesktop && _isSidebarOpenDesktop)
            _buildSidebarContent(),
          Expanded(child: _buildMainContent(isDesktop)),
        ],
      ),
      bottomNavigationBar: (_isChatMode || isDesktop) ? null : BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0047C7),
        unselectedItemColor: Colors.grey.shade500,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'IA',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_box_outlined),
            label: 'Checklist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Historial',
          ),
        ],
      ),
    );
  }
}
