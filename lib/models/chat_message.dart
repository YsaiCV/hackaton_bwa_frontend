import '../widgets/procedure_card.dart';

class ChatMessage {
  final String id;
  String text;
  final bool isUser;
  final String? sessionId;
  final DateTime? createdAt;

  List<String> steps;
  Map<String, dynamic>? finalResult;
  ProcedureData? procedureData;
  Map<String, dynamic>? procedureList;
  String? error;

  ChatMessage({
    required this.id,
    this.text = '',
    required this.isUser,
    this.sessionId,
    this.createdAt,
    this.steps = const [],
    this.finalResult,
    this.procedureData,
    this.procedureList,
    this.error,
  });
}
