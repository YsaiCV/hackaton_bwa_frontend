import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/custom_header.dart';
import '../models/chat_message.dart';

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

    _apiService.streamResearch(query).listen(
      (chunkMap) {
        if (mounted) {
          setState(() {
            if (chunkMap.containsKey('step')) {
              // It's a step indicator
              final newSteps = List<String>.from(botMessage.steps);
              if (chunkMap['message'] != null) {
                newSteps.add(chunkMap['message'].toString());
              }
              botMessage.steps = newSteps;
            } else if (chunkMap.containsKey('summary')) {
              // It's the final result payload
              botMessage.finalResult = chunkMap;
            } else if (chunkMap.containsKey('rawText')) {
              // Fallback if not matching the structured JSON
              botMessage.text += chunkMap['rawText'].toString();
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
          prefixIcon: const Icon(Icons.search, color: Color(0xFF00ACC1)),
          suffixIcon: Padding(
            padding: const EdgeInsets.all(6.0),
            child: InkWell(
              onTap: _isLoading ? null : _startStreaming,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF002366),
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

    if (message.finalResult != null) {
      // Render final structured data
      final result = message.finalResult!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result['summary'] != null) ...[
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
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00ACC1)),
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
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00ACC1)),
        ),
        SizedBox(width: 12),
        Text('Iniciando...', style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic, fontSize: 14)),
      ],
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: message.isUser ? const Color(0xFF002366) : Colors.white,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Mantenemos siempre el gradiente principal según requerimiento
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF003C8F), // Dark blue
              Color(0xFF00ACC1), // Teal/Cyan
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              if (!_isChatMode)
                const CustomHeader()
              else
                // Header reducido en modo chat
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C8B6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.accessibility_new, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'YaSÉ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
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
      ),
      bottomNavigationBar: _isChatMode ? null : BottomNavigationBar(
        // The bar can be kept on both, but usually hidden in chat
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF002366),
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
