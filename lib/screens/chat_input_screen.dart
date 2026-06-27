import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/custom_header.dart';

class ChatInputScreen extends StatefulWidget {
  const ChatInputScreen({super.key});

  @override
  State<ChatInputScreen> createState() => _ChatInputScreenState();
}

class _ChatInputScreenState extends State<ChatInputScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  
  void _submitResearch() {
    if (_queryController.text.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });

    final query = _queryController.text;
    String accumulatedData = '';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // We listen to the stream inside the dialog lifecycle, 
            // but we need to do it only once.
            // Using a Future or initializing it outside is safer.
            return AlertDialog(
              title: const Text('Resultado de la búsqueda'),
              content: SingleChildScrollView(
                child: StreamBuilder<String>(
                  stream: _apiService.streamResearch(query),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && accumulatedData.isEmpty) {
                      return const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Generando respuesta...'),
                        ],
                      );
                    }
                    
                    if (snapshot.hasError && accumulatedData.isEmpty) {
                      return Text('Error: ${snapshot.error}');
                    }

                    if (snapshot.hasData && snapshot.data != null) {
                      // Append new data on each emission
                      // Note: StreamBuilder might rebuild for other reasons, so 
                      // we only append when connection is active. 
                      // Actually, Flutter StreamBuilder caches the latest snapshot.data.
                      // So we must be careful not to append the SAME data multiple times.
                      // A cleaner approach is a local variable updated by listening to the stream directly.
                    }

                    return const SizedBox.shrink(); // We will implement the manual listen approach below
                  },
                ),
              ),
            );
          }
        );
      },
    );
  }

  // To properly handle Stream without duplicate appends from StreamBuilder rebuilds:
  void _submitResearchStreaming() {
    if (_queryController.text.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });

    final query = _queryController.text;
    String accumulatedData = '';
    bool isDone = false;
    String? errorMessage;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            
            // Listen exactly once when dialog opens
            // To ensure we only subscribe once, we check if it's the first build
            // Alternatively, we start the subscription BEFORE showDialog
            return AlertDialog(
              title: const Text('Resultado de la búsqueda'),
              content: SingleChildScrollView(
                child: accumulatedData.isEmpty && !isDone && errorMessage == null
                    ? const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Pensando...'),
                        ],
                      )
                    : Text(
                        errorMessage ?? accumulatedData,
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
              actions: [
                if (isDone || errorMessage != null)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _isLoading = false);
                    },
                    child: const Text('Cerrar'),
                  ),
              ],
            );
          },
        );
      },
    );

    // Start listening to the stream
    _apiService.streamResearch(query).listen(
      (chunk) {
        // Find the StatefulBuilder's context to setStateDialog? 
        // We can just use the Navigator's context or a GlobalKey, but since showDialog 
        // doesn't return the setState, we can use the Navigator approach, OR 
        // start listening BEFORE showDialog and use a local variable inside StatefulBuilder.
      },
      onError: (e) {
      },
      onDone: () {
      }
    );
  }

  // Final correct approach:
  void _startStreaming() {
    if (_queryController.text.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });

    String accumulatedData = '';
    bool isDone = false;
    String? errorMessage;

    // Start stream
    final subscription = _apiService.streamResearch(_queryController.text).listen(
      (chunk) {}, // Will be overridden inside the dialog
      onError: (e) {},
      onDone: () {}
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            
            // Update callbacks to trigger dialog rebuild
            subscription.onData((chunk) {
              setStateDialog(() {
                accumulatedData += chunk;
              });
            });
            
            subscription.onError((e) {
              setStateDialog(() {
                errorMessage = e.toString();
              });
            });

            subscription.onDone(() {
              setStateDialog(() {
                isDone = true;
              });
              // Update main screen state to re-enable button
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            });

            return AlertDialog(
              title: const Text('Resultado de la búsqueda'),
              content: SingleChildScrollView(
                child: accumulatedData.isEmpty && !isDone && errorMessage == null
                    ? const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Pensando...'),
                        ],
                      )
                    : Text(
                        errorMessage ?? accumulatedData,
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
              actions: [
                if (isDone || errorMessage != null)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    },
                    child: const Text('Cerrar'),
                  ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // In case dialog is dismissed by other means, cancel subscription
      subscription.cancel();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
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
              // Static Header
              const CustomHeader(),
              
              // Centered Input Box
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
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
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
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
