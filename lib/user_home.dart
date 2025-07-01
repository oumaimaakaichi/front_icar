import 'package:car_mobile/ProfilTechncien.dart';
import 'package:car_mobile/TechnicienDemandesPage.dart';
import 'package:car_mobile/demandes_page..dart';
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
  int? _userId = 0;
  int _selectedIndex = 0;

  Future<void> _loadUserData() async {
    final userDataJson = await _storage.read(key: 'user_data');
    if (userDataJson != null) {
      final userData = jsonDecode(userDataJson);
      if (!mounted) return;
      setState(() {
        _nom = userData['nom'] ?? '';
        _prenom = userData['prenom'] ?? '';
        _userId = userData['id'] ?? 0;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryColor = Color(0xFF73B1BD); // Changé vers blueGrey
    const secondaryColor = Color(0x81B4CBFF); // Bleu clair
    const accentColor = Color(0xD585A0FF); // Rose corail
    const backgroundColor = Color(0xFFF5F6FA); // Gris très clair

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Bienvenue, $_prenom',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _buildDrawer(theme, primaryColor),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec statistiques
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Votre activité',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard(
                        value: '24',
                        label: 'Interventions',
                        icon: Icons.construction,
                        color: Colors.white,
                        textColor: primaryColor,
                      ),
                      _buildStatCard(
                        value: '18',
                        label: 'Terminées',
                        icon: Icons.check_circle,
                        color: Colors.white,
                        textColor: Colors.green,
                      ),
                      _buildStatCard(
                        value: '4',
                        label: 'En cours',
                        icon: Icons.access_time,
                        color: Colors.white,
                        textColor: Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Section principale
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre section
                  const Text(
                    'Actions rapides',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Grille d'actions
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                    childAspectRatio: 1.1,
                    children: [
                      _buildActionCard(
                        title: 'Panne Inconnus',
                        icon: Icons.add_circle_outline,
                        color: Color(0xFF73B1BD),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DemandesTechniciensInconnuPage(),
                            ),
                          );

                        },

                      ),
                      _buildActionCard(
                        title: 'Pannes connues',
                        icon: Icons.verified_outlined,
                        color: Color(0xFF73B1BD),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DemandesTechnicienPage(),
                              settings: const RouteSettings(arguments: 'known'),
                            ),
                          );
                        },
                      ),
                      _buildActionCard(
                        title: 'Historique',
                        icon: Icons.history,
                        color: Color(0xFF73B1BD),
                        onTap: () {},
                      ),
                      _buildActionCard(
                        title: 'Assistance',
                        icon: Icons.support_agent,
                        color: Color(0xFF73B1BD),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => TechnicienTicketsPage()),
                          );
                        },
                      ),
                    ],
                  ),

                  // Section récentes interventions
                  const SizedBox(height: 30),


                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Interventions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',

          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 10,
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
                    isSelected: true,
                    onTap: () {
                      Navigator.pop(context);
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

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor ?? Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor?.withOpacity(0.8) ?? Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? subtitle,
    bool isElevated = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: isElevated ? [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.8),
                  color.withOpacity(0.9),
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section icône avec effet glassmorphism
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                      // Petit indicateur de flèche
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Section texte
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    ],
                  ),

                  // Barre de progression ou indicateur (optionnel)
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.6),
                          Colors.white.withOpacity(0.3),
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
  }

// Version alternative avec style plus minimaliste
  Widget _buildActionCardMinimal({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icône avec fond coloré
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    size: 26,
                    color: color,
                  ),
                ),

                const SizedBox(height: 16),

                // Titre
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF2D3748),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF718096),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const Spacer(),

                // Indicateur de couleur en bas
                Container(
                  height: 2,
                  width: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Version avec effet néomorphisme
  Widget _buildActionCardNeumorphic({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          // Ombre extérieure (sombre)
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(8, 8),
          ),
          // Ombre intérieure (claire)
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(-8, -8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône avec effet enfoncé
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F3),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(4, 4),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(-4, -4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 30,
                    color: color,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Exemple d'utilisation dans votre GridView
  Widget buildActionGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildActionCard(
          title: 'Pannes Inconnues',
          subtitle: 'Nouvelles demandes',
          icon: Icons.help_outline_rounded,
          color: const Color(0xFF6366F1), // Indigo
          onTap: () {
            // Navigation
          },
        ),
        _buildActionCard(
          title: 'Pannes Connues',
          subtitle: 'Solutions rapides',
          icon: Icons.verified_rounded,
          color: const Color(0xFF10B981), // Emerald
          onTap: () {
            // Navigation
          },
        ),
        _buildActionCard(
          title: 'Historique',
          subtitle: 'Voir tout',
          icon: Icons.history_rounded,
          color: const Color(0xFF8B5CF6), // Violet
          onTap: () {
            // Navigation
          },
        ),
        _buildActionCard(
          title: 'Assistance',
          subtitle: 'Support technique',
          icon: Icons.support_agent_rounded,
          color:  Colors.brown, // Cyan
          onTap: () {
            // Navigation
          },
        ),
      ],
    );
  }
  Widget _buildRecentIntervention({
    required String title,
    required String date,
    required String status,
    required Color statusColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blueGrey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.construction,
            color: Colors.blueGrey,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          date,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}