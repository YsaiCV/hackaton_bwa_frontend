class ChatMessage {
  final String id;
  String text;
  final bool isUser;
  
  List<String> steps;
  Map<String, dynamic>? finalResult;
  String? error;

  ChatMessage({
    required this.id,
    this.text = '',
    required this.isUser,
    this.steps = const [],
    this.finalResult,
    this.error,
  });
}
