import 'package:flutter/material.dart';

class CustomHeader extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  
  const CustomHeader({super.key, this.onMenuPressed});

  Widget _buildTopIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F8FC), // Gris claro fondo
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: const Color(0xFF003C9E), size: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo and Menu
              Row(
                children: [
                  Builder(
                    builder: (context) {
                      return IconButton(
                        icon: const Icon(Icons.menu, color: Color(0xFF003C9E)),
                        onPressed: onMenuPressed ?? () => Scaffold.of(context).openDrawer(),
                      );
                    }
                  ),
                  Image.asset(
                    'assets/images/logo-rectangular.png',
                    height: 45,
                  ),
                ],
              ),
              // Action Icons
              Row(
                children: [
                  _buildTopIcon(Icons.notifications_none),
                  const SizedBox(width: 12),
                  _buildTopIcon(Icons.person_outline),
                ],
              )
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Greeting Text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Buenos días 👋',
                style: TextStyle(
                  color: Color(0xFF003C9E),
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '¿En qué trámite\nte ayudo hoy?',
                style: TextStyle(
                  color: Color(0xFF003C9E),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
