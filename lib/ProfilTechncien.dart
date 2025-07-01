import 'package:car_mobile/Client/PlusPage.dart';
import 'package:car_mobile/Client/TicketAssistancePage.dart';
import 'package:car_mobile/Client/catalogue_page.dart';
import 'package:car_mobile/Client/homeClient.dart';
import 'package:car_mobile/TechnicienDemandesPage.dart';

import 'package:car_mobile/login.dart';
import 'package:car_mobile/settings_page.dart';
import 'package:car_mobile/user_home.dart';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class ProfileTechPage extends StatefulWidget {
  const ProfileTechPage({super.key});

  @override
  State<ProfileTechPage> createState() => _ProfileTechPageState();
}

class _ProfileTechPageState extends State<ProfileTechPage> {
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
  Widget _buildModernMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isSelected = false,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: isSelected ? Colors.blueGrey.withOpacity(0.1) : Colors.transparent,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isLogout
                ? Colors.red.withOpacity(0.1)
                : isSelected
                ? Colors.blueGrey.withOpacity(0.15)
                : Colors.grey.withOpacity(0.1),
          ),
          child: Icon(
            icon,
            color: isLogout
                ? Colors.red
                : isSelected
                ? Colors.blueGrey
                : Colors.grey.shade600,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isLogout ? Colors.red : Colors.grey.shade800,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
          ),
        ),
        trailing: isSelected
            ? Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.blueGrey,
            borderRadius: BorderRadius.circular(2),
          ),
        )
            : Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.grey.shade400,
          size: 16,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
  Widget _buildDrawer(ThemeData theme, Color primaryColor) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header avec design moderne
            Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor,
                    primaryColor,
                    primaryColor,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Pattern d'arrière-plan
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        image: DecorationImage(
                          image: NetworkImage(
                            'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAiIGhlaWdodD0iNDAiIHZpZXdCb3g9IjAgMCA0MCA0MCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPGNpcmNsZSBjeD0iMjAiIGN5PSIyMCIgcj0iMSIgZmlsbD0id2hpdGUiIGZpbGwtb3BhY2l0eT0iMC4xIi8+Cjwvc3ZnPgo=',
                          ),
                          repeat: ImageRepeat.repeat,
                          opacity: 0.1,
                        ),
                      ),
                    ),
                  ),
                  // Contenu du header
                  Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 5),
                        // Photo de profil avec design moderne
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 0,
                                offset: const Offset(0, 10),
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
                        const SizedBox(height: 5),
                        // Nom et prénom
                        Text(
                          '$_prenom $_nom',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        // Badge premium
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Technicien Premium',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Statistiques rapides
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildQuickStat('24', 'Interventions', Icons.build),
                            Container(
                              height: 30,
                              width: 1,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            _buildQuickStat('18', 'Terminées', Icons.check_circle),
                            Container(
                              height: 30,
                              width: 1,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            _buildQuickStat('4', 'En cours', Icons.access_time),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Menu items avec design moderne
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 15),
                children: [
                  _buildModernMenuItem(
                    icon: Icons.home_rounded,
                    title: 'Accueil',
                    subtitle: 'Dashboard principal',

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UserHomePage()),
                      );
                    },
                  ),
                  _buildModernMenuItem(
                    icon: Icons.assignment_rounded,
                    title: 'Mes interventions',
                    subtitle: 'Gérer vos tâches',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DemandesTechnicienPage()),
                      );
                    },
                  ),

                  _buildModernMenuItem(
                    icon: Icons.person_rounded,
                    title: 'Mon profil',
                    subtitle: 'Informations personnelles',
                    isSelected: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfileTechPage()),
                      );
                    },
                  ),
                  _buildModernMenuItem(
                    icon: Icons.settings_rounded,
                    title: 'Paramètres',
                    subtitle: 'Configuration',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                      );
                    },
                  ),

                  // Separateur
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Divider(
                      color: Colors.grey.shade300,
                      thickness: 1,
                    ),
                  ),

                  _buildModernMenuItem(
                    icon: Icons.logout_rounded,
                    title: 'Déconnexion',
                    subtitle: 'Quitter l\'application',
                    isLogout: true,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Footer avec version
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Version 1.0.0',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildQuickStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 16,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryColor = Color(0xFF73B1BD); // Changé vers blueGrey
    const secondaryColor = Color(0x81B4CBFF); // Bleu clair
    const accentColor = Color(0xD585A0FF);
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
        backgroundColor: Color(0xFF73B1BD),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(theme, primaryColor),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 30),

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

            const SizedBox(height: 20),

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