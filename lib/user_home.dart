import 'package:car_mobile/login.dart';
import 'package:car_mobile/settings_page.dart';
import 'package:car_mobile/ticketAssistance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final _storage = const FlutterSecureStorage();
  String? _nom = '';
  String? _prenom = '';

  Future<void> _logout() async {
    await _storage.delete(key: 'auth_token');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _loadUserData() async {
    final userDataJson = await _storage.read(key: 'user_data');
    print("bbbbbbbbbbbb $userDataJson");

    if (userDataJson != null) {
      final userData = jsonDecode(userDataJson);
      if (!mounted) return;
      setState(() {
        _nom = userData['nom'] ?? '';
        _prenom = userData['prenom'] ?? '';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Widget _buildDrawerTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        Color? color,
      }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: color ?? theme.iconTheme.color,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? theme.textTheme.bodyLarge?.color,
          fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      minLeadingWidth: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Roboto', // Remplace par ta police si elle est bien ajoutée dans pubspec.yaml
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor: Colors.blueGrey,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header avec image de fond
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.blueGrey,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                image: const DecorationImage(
                  image: AssetImage('assets/images/background_pattern.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.blueGrey,
                    BlendMode.dstATop,
                  ),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Photo de profil
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/9.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      '$_prenom $_nom',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Utilisateur Premium',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Liste des options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 10),
                children: [
                  _buildDrawerTile(
                    context,
                    icon: Icons.dashboard,
                    title: 'Home',
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.analytics,
                    title: 'Tickets Assistance',
                      onTap: () {
            Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>  TechnicienTicketsPage()),
            );
            },
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.history,
                    title: 'Historique',
                    onTap: () {},
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.settings,
                    title: 'Paramètres',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                      );
                    },
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.help_center,
                    title: 'Aide & Support',
                    onTap: () {},
                  ),
                  const Divider(height: 20, indent: 20, endIndent: 20),
                  _buildDrawerTile(
                    context,
                    icon: Icons.logout,
                    title: 'Déconnexion',

                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                  )

                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(15),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text(
          '',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}