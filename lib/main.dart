import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hackaton BWA Frontend',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasData) {
            return const ProcedureResearchPage();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class ProcedureResearchPage extends StatefulWidget {
  const ProcedureResearchPage({super.key});

  @override
  State<ProcedureResearchPage> createState() => _ProcedureResearchPageState();
}

class _ProcedureResearchPageState extends State<ProcedureResearchPage> {
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _procedureTypeController = TextEditingController();

  bool _isLoading = false;
  String _result = '';

  Future<void> _submitResearch() async {
    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      // 10.0.2.2 is for Android Emulator, 127.0.0.1 for iOS/Web/Mac
      // Update this IP if you are testing on a real device.
      final url = Uri.parse('http://127.0.0.1:3000/procedures/research');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': _queryController.text,
          'city': _cityController.text.isNotEmpty ? _cityController.text : null,
          'procedureType': _procedureTypeController.text.isNotEmpty ? _procedureTypeController.text : null,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _result = 'Success!\n\n${response.body}';
        });
      } else {
        setState(() {
          _result = 'Error ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Connection Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    _cityController.dispose();
    _procedureTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Research Procedure'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _queryController,
              decoration: const InputDecoration(
                labelText: 'Query (min 3 chars)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _procedureTypeController,
              decoration: const InputDecoration(
                labelText: 'Procedure Type (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitResearch,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Start Research'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _result,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
