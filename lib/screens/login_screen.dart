import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _currentTab = 0; // 0: Iniciar sesión, 1: Registrarse
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInAnonymously() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar sesión: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error con Google Sign-In: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildAvatarIllustration() {
    return Container(
      width: 100,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background soft glow
          Positioned(
            top: 22,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF00B8B8).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00B8B8).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
          ),
          // Head (cyan circle)
          Positioned(
            top: 27,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFF00B8B8),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Body (lavender/blue body)
          Positioned(
            top: 60,
            child: Container(
              width: 46,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF003C9E).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Arms
          Positioned(
            top: 66,
            left: 18,
            child: Container(
              width: 8,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF003C9E).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            top: 66,
            right: 18,
            child: Container(
              width: 8,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF003C9E).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Legs
          Positioned(
            bottom: 12,
            left: 36,
            child: Container(
              width: 10,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF003C9E).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 36,
            child: Container(
              width: 10,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF003C9E).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, IconData icon) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00B8B8).withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00B8B8), size: 16),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF003C9E),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
              Color(0xFF003C9E), // Azul oscuro principal
              Color(0xFF00B1D1), // Celeste brillante
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
                        color: Colors.white,
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
                        child: Column(
                          children: [
                            // 1. Status Bar (44px)
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
                            
                            // Unified body background with Stack for accent circles and scrollable content
                            Expanded(
                              child: Container(
                                color: Colors.white,
                                child: Stack(
                                  children: [
                                    // Accent Circle 1: Top-Left
                                    Positioned(
                                      top: -65,
                                      left: -65,
                                      child: CircleAvatar(
                                        radius: 90,
                                        backgroundColor: const Color(0xFF00B1D1).withValues(alpha: 0.05),
                                      ),
                                    ),
                                    // Accent Circle 2: Mid-Right
                                    Positioned(
                                      top: 220,
                                      right: -80,
                                      child: CircleAvatar(
                                        radius: 100,
                                        backgroundColor: const Color(0xFF00B8B8).withValues(alpha: 0.05),
                                      ),
                                    ),
                                    
                                    // Scrollable content
                                    Positioned.fill(
                                      child: SingleChildScrollView(
                                        physics: const ClampingScrollPhysics(),
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            // Logo en fila horizontal centrado
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Image.asset(
                                                  'assets/images/yase_icon.png',
                                                  height: 48,
                                                  fit: BoxFit.contain,
                                                ),
                                                const SizedBox(width: 10),
                                                Image.asset(
                                                  'assets/images/yase_wordmark.png',
                                                  height: 38,
                                                  fit: BoxFit.contain,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            
                                            // Title
                                            const Text(
                                              'Tu asistente de trámites\npúblicos con IA',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: Color(0xFF003C9E),
                                                fontWeight: FontWeight.w800,
                                                height: 1.25,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            
                                            // Description
                                            const Text(
                                              'Resuelve tus dudas, conoce requisitos y realiza\ntus trámites en Bolivia fácilmente.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: Color(0xFF8DA0A5),
                                                fontWeight: FontWeight.w500,
                                                height: 1.35,
                                              ),
                                            ),
                                            const SizedBox(height: 18),
                                            
                                            // Feature Row
                                            Row(
                                              children: [
                                                _buildAvatarIllustration(),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                                    children: [
                                                      _buildFeatureCard('Búsqueda inteligente', Icons.auto_awesome),
                                                      const SizedBox(height: 6),
                                                      _buildFeatureCard('Checklist de docs', Icons.checklist_rtl),
                                                      const SizedBox(height: 6),
                                                      _buildFeatureCard('Recordatorios', Icons.notifications_none_outlined),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 24),
                                            
                                            // Tabs Pill
                                            Container(
                                              height: 48,
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE6F4F8),
                                                borderRadius: BorderRadius.circular(24),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                          _currentTab = 0;
                                                        });
                                                      },
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          color: _currentTab == 0 ? Colors.white : Colors.transparent,
                                                          borderRadius: BorderRadius.circular(20),
                                                          boxShadow: _currentTab == 0
                                                              ? [
                                                                  BoxShadow(
                                                                    color: Colors.black.withValues(alpha: 0.05),
                                                                    blurRadius: 6,
                                                                    offset: const Offset(0, 3),
                                                                  ),
                                                                ]
                                                              : null,
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            'Iniciar sesión',
                                                            style: TextStyle(
                                                              color: _currentTab == 0 ? const Color(0xFF003C9E) : const Color(0xFF8DA0A5),
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 13.5,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                          _currentTab = 1;
                                                        });
                                                      },
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          color: _currentTab == 1 ? Colors.white : Colors.transparent,
                                                          borderRadius: BorderRadius.circular(20),
                                                          boxShadow: _currentTab == 1
                                                              ? [
                                                                  BoxShadow(
                                                                    color: Colors.black.withValues(alpha: 0.05),
                                                                    blurRadius: 6,
                                                                    offset: const Offset(0, 3),
                                                                  ),
                                                                ]
                                                              : null,
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            'Registrarse',
                                                            style: TextStyle(
                                                              color: _currentTab == 1 ? const Color(0xFF003C9E) : const Color(0xFF8DA0A5),
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 13.5,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            
                                            // Google Button
                                            SizedBox(
                                              height: 50,
                                              child: ElevatedButton(
                                                onPressed: _isLoading ? null : _signInWithGoogle,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.white,
                                                  surfaceTintColor: Colors.white,
                                                  elevation: 1,
                                                  shadowColor: Colors.black.withValues(alpha: 0.05),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                    side: BorderSide(
                                                      color: const Color(0xFF00B8B8).withValues(alpha: 0.15),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    ShaderMask(
                                                      shaderCallback: (bounds) => const SweepGradient(
                                                        colors: [
                                                          Color(0xFFEA4335), // Red
                                                          Color(0xFFFBBC05), // Yellow
                                                          Color(0xFF34A853), // Green
                                                          Color(0xFF4285F4), // Blue
                                                          Color(0xFFEA4335), // Red
                                                        ],
                                                        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                                                      ).createShader(bounds),
                                                      child: const Text(
                                                        'G',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.w900,
                                                          fontSize: 22,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    const Text(
                                                      'Iniciar sesión con Google',
                                                      style: TextStyle(
                                                        color: Color(0xFF003C9E),
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 13.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            
                                            // Separator
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Divider(
                                                    color: const Color(0xFF8DA0A5).withValues(alpha: 0.15),
                                                    thickness: 1,
                                                  ),
                                                ),
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                                  child: Text(
                                                    'o con tu correo',
                                                    style: TextStyle(
                                                      color: Color(0xFF8DA0A5),
                                                      fontSize: 12.5,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Divider(
                                                    color: const Color(0xFF8DA0A5).withValues(alpha: 0.15),
                                                    thickness: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 14),
                                            
                                            // Email field
                                            const Text(
                                              'Correo electrónico',
                                              style: TextStyle(
                                                color: Color(0xFF003C9E),
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            SizedBox(
                                              height: 60,
                                              child: TextField(
                                                controller: _emailController,
                                                keyboardType: TextInputType.emailAddress,
                                                style: const TextStyle(color: Color(0xFF003C9E), fontSize: 14.5),
                                                decoration: InputDecoration(
                                                  hintText: 'correo@ejemplo.com',
                                                  hintStyle: const TextStyle(color: Color(0xFF8DA0A5), fontSize: 13.5),
                                                  prefixIcon: const Icon(Icons.mail_outline, color: Color(0xFF0047C7), size: 20),
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                    borderSide: BorderSide(
                                                      color: const Color(0xFF00B8B8).withValues(alpha: 0.15),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                    borderSide: const BorderSide(color: Color(0xFF0047C7), width: 2),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 14),
                                            
                                            // Password field
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text(
                                                  'Contraseña',
                                                  style: TextStyle(
                                                    color: Color(0xFF003C9E),
                                                    fontSize: 14.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (_currentTab == 0)
                                                  GestureDetector(
                                                    onTap: () {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Recuperación de contraseña se implementará después')),
                                                      );
                                                    },
                                                    child: const Text(
                                                      '¿La olvidaste?',
                                                      style: TextStyle(
                                                        color: Color(0xFF00B8B8),
                                                        fontSize: 13.5,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            SizedBox(
                                              height: 60,
                                              child: TextField(
                                                controller: _passwordController,
                                                obscureText: _obscurePassword,
                                                style: const TextStyle(color: Color(0xFF003C9E), fontSize: 14.5),
                                                decoration: InputDecoration(
                                                  hintText: 'Tu contraseña',
                                                  hintStyle: const TextStyle(color: Color(0xFF8DA0A5), fontSize: 13.5),
                                                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF8DA0A5), size: 20),
                                                  suffixIcon: IconButton(
                                                    icon: Icon(
                                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                                      color: const Color(0xFF8DA0A5),
                                                      size: 20,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        _obscurePassword = !_obscurePassword;
                                                      });
                                                    },
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                    borderSide: BorderSide(
                                                      color: const Color(0xFF00B8B8).withValues(alpha: 0.15),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                    borderSide: const BorderSide(color: Color(0xFF0047C7), width: 2),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            
                                            // Main Button
                                            _isLoading
                                                ? const Center(child: CircularProgressIndicator())
                                                : SizedBox(
                                                    height: 60,
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        final msg = _currentTab == 0
                                                            ? 'Inicio con correo se implementará después'
                                                            : 'Registro con correo se implementará después';
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text(msg)),
                                                        );
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: const Color(0xFF0047C7),
                                                        shadowColor: const Color(0xFF0047C7).withValues(alpha: 0.25),
                                                        elevation: 3,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(16),
                                                        ),
                                                        padding: EdgeInsets.zero,
                                                      ),
                                                      child: Text(
                                                        _currentTab == 0 ? 'Iniciar sesión' : 'Registrarse',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                            const SizedBox(height: 18),
                                            
                                            // Link Explorar sin cuenta (Entrar sin iniciar sesión)
                                            GestureDetector(
                                              onTap: _signInAnonymously,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: const [
                                                  Text(
                                                    'Entrar sin iniciar sesión',
                                                    style: TextStyle(
                                                      color: Color(0xFF7D8FAE),
                                                      fontSize: 14.5,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(width: 6),
                                                  Icon(
                                                    Icons.arrow_forward,
                                                    color: Color(0xFF0047C7),
                                                    size: 16,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            
                                            // Footer
                                            Center(
                                              child: RichText(
                                                textAlign: TextAlign.center,
                                                text: const TextSpan(
                                                  style: TextStyle(fontSize: 11, color: Color(0xFF8DA0A5), height: 1.4),
                                                  children: [
                                                    TextSpan(text: 'Al continuar aceptas los '),
                                                    TextSpan(
                                                      text: 'Términos de uso',
                                                      style: TextStyle(
                                                        color: Color(0xFF0047C7),
                                                        decoration: TextDecoration.underline,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    TextSpan(text: ' y la '),
                                                    TextSpan(
                                                      text: 'Política de privacidad',
                                                      style: TextStyle(
                                                        color: Color(0xFF0047C7),
                                                        decoration: TextDecoration.underline,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
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
                            ),
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
