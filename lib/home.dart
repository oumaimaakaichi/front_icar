
import 'package:flutter/material.dart';
import 'login.dart';
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Grand cercle décoratif en arrière-plan (simule le demi-cercle)
          Positioned(
            top: -100,
            left: -180,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                color: Color(0xFFE1F5FE),

                shape: BoxShape.circle,
              ),
            ),
          ),




          // Contenu principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 0),

                  // Image
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        'assets/images/9.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 0),

                  // Titre
                  const Text(
                    'Welcome To Icar',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Description
                  const Text(
                    'Manage your truck maintenance efficiently\nand ensure optimal performance every day.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Indicateurs de pages
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDot(true),
                      const SizedBox(width: 6),
                      _buildDot(false),
                      const SizedBox(width: 6),
                      _buildDot(false),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Bouton "Get Started"
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      },
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),


                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour les points de pagination
  Widget _buildDot(bool isActive) {
    return Container(
      width: isActive ? 10 : 8,
      height: isActive ? 10 : 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.blue : Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }
}
