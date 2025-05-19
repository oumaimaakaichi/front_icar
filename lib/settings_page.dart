import 'package:car_mobile/login.dart';
import 'package:car_mobile/main.dart';
import 'package:car_mobile/ticketAssistance.dart';
import 'package:car_mobile/user_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDarkMode = false;
  String selectedLanguage = 'Français';
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
        bool isSelected = false,
        Color? color,
      }) {
    final theme = Theme.of(context);
    final blueGrey = Colors.blueGrey;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? blueGrey.withOpacity(0.3) // Utilisation de blueGrey
              : blueGrey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isSelected ? blueGrey : color ?? theme.iconTheme.color, // Utilisation de blueGrey
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? blueGrey : color ?? theme.textTheme.bodyLarge?.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Roboto',
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
                    Colors.lightBlueAccent,
                    BlendMode.dstATop,
                  ),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 10),
                children: [
                  _buildDrawerTile(
                    context,
                    icon: Icons.dashboard,
                    title: 'Home',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UserHomePage()),
                      );
                    },
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
                      Navigator.pop(context);
                    },
                    isSelected: true, // Marque cette option comme sélectionnée
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
                  ),
                ],
              ),
            ),
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Mode Sombre'),
              value: isDarkMode,
              onChanged: (bool value) {
                setState(() {
                  isDarkMode = value;
                  themeNotifier.toggleTheme(value);
                });
              },
              secondary: const Icon(Icons.dark_mode),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Langue',
                border: OutlineInputBorder(),
              ),
              value: selectedLanguage,
              items: ['Français', 'Anglais', 'Espagnol']
                  .map((lang) => DropdownMenuItem(
                value: lang,
                child: Text(lang),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedLanguage = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}