import 'package:flutter/material.dart';
import 'screens/chat_input_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YaSÉ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00458F)),
        fontFamily: 'Roboto', 
      ),
      home: const ChatInputScreen(),
    );
  }
}
