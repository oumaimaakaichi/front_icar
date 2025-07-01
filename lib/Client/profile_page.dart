import 'package:car_mobile/Client/PlusPage.dart';
import 'package:car_mobile/Client/TicketAssistancePage.dart';
import 'package:car_mobile/Client/catalogue_page.dart';
import 'package:car_mobile/Client/homeClient.dart';
import 'package:car_mobile/Client/mes_voitures.dart';
import 'package:car_mobile/login.dart';
import 'package:car_mobile/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _storage = const FlutterSecureStorage();
  String? _nom = '';
  String? _prenom = '';
  String? _email = '';
  bool _isActive = false;

  Future<void> _loadUserData() async {
    final userDataJson = await _storage.read(key: 'user_data');
    print("bbbbbbbbbbbb $userDataJson");

    if (userDataJson != null) {
      final userData = jsonDecode(userDataJson);
      if (!mounted) return;
      setState(() {
        _nom = userData['nom'] ?? '';
        _prenom = userData['prenom'] ?? '';
        _email = userData['email'] ?? '';
        _isActive = userData['isActive'] ?? false;
      });
    }
  }
  final primaryColor = const Color(0xFF6797A2);
  final secondaryColor = const Color(0xFF4CA1A3);
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
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Roboto',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF6797A2),
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
              height: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryColor, primaryColor, primaryColor],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Stack(
                children: [
                  // Motif de fond décoratif
                  Positioned.fill(
                    child: CustomPaint(
                      painter: CirclePatternPainter(),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Hero(
                          tag: 'profile_image',
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/profile.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '$_prenom $_nom',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Client Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Liste des options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 10),
                children: [
                  _buildDrawerTile(
                    context,
                    icon: Icons.home,
                    title: 'Home',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ClientHomePage()),
                      );
                    },
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.account_circle,
                    title: 'Profile',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfilePage()),
                      );
                    },
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.help_outline,
                    title: 'Ticket assistance',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TicketAssistancePage()),
                      );
                    },
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.build,
                    title: 'Pièces de rechange',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CataloguePage()),
                      );
                    },
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.add,
                    title: 'Plus',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>  PlusPage()),
                      );
                    },
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // Profile Picture
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color(0xFF007896).withOpacity(0.5),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF007896).withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/profile.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF007896),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // User Information Cards
            _buildInfoCard(
              context,
              title: 'Informations Personnelles',

              icon: Icons.person,

              children: [
                _buildInfoItem(context, 'Nom', _nom ?? '', Icons.person_outline),
                _buildInfoItem(context, 'Prénom', _prenom ?? '', Icons.person_outlined),
                _buildInfoItem(context, 'Email', _email ?? '', Icons.email_outlined),
              ],
            ),

            const SizedBox(height: 10),

            _buildInfoCard(
              context,
              title: 'Statut du Compte',
              icon: Icons.verified_user,
              children: [
                Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10), // marge à gauche
                      child: Icon(
                        _isActive ? Icons.verified : Icons.warning,
                        color: _isActive ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isActive ? 'Compte vérifié' : 'Compte non vérifié',
                      style: TextStyle(
                        color: _isActive ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],

                ),
                const SizedBox(height: 10),
                Text(
                  _isActive
                      ? 'Vous bénéficiez de tous les avantages Premium'
                      : 'Mettez à jour votre compte pour accéder à toutes les fonctionnalités',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                if (!_isActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF007896),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        // Upgrade account logic
                      },
                      child: const Text(
                        'Passer à Premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.car_repair
                        , size: 25),
                    label: const Text('Voir mes voitures'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF007896),
                      side: const BorderSide(color: Color(0xFF007896)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MesVoituresPage()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),

              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color backgroundColor = Colors.white,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: backgroundColor, // Ajout de la couleur de fond
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF007896).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Color(0xFF007896),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007896),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white70,
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFF007896).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Color(0xFF007896),
              size: 20,
            ),
          ),
          title: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: value.isEmpty ? 'Non renseigné' : value,
                  style: TextStyle(
                    color: value.isEmpty ? Colors.grey : Colors.blueGrey[800],
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}