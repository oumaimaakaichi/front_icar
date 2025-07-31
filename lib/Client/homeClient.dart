// Mise à jour de ClientHomePage pour utiliser le service de notifications
import 'package:car_mobile/Client/PanierPage.dart';
import 'package:car_mobile/Client/PlusPage.dart';
import 'package:car_mobile/Client/TicketAssistancePage.dart';
import 'package:car_mobile/Client/VoiturePanneInconnu.dart';
import 'package:car_mobile/Client/Voitures.dart';
import 'package:car_mobile/Client/catalogue_page.dart';
import 'package:car_mobile/Client/profile_page.dart';
import 'package:car_mobile/Client/notifications_page.dart';
import 'package:car_mobile/Client/notification_service.dart';
import 'package:car_mobile/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:badges/badges.dart' as badges;
import 'dart:convert';
import 'dart:async';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<ClientHomePage> {
  final _storage = const FlutterSecureStorage();
  String? _nom = '';
  String? _prenom = '';
  int? _userId;
  int _notificationCount = 0;
  bool _isLoading = true;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadNotificationCount();
    _startNotificationTimer();
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final userDataJson = await _storage.read(key: 'user_data');
    if (userDataJson != null) {
      final userData = jsonDecode(userDataJson);
      if (!mounted) return;
      setState(() {
        _nom = userData['nom'] ?? '';
        _prenom = userData['prenom'] ?? '';
        _userId = userData['id'] != null ? int.tryParse(userData['id'].toString()) : null;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Charger le count depuis le cache local d'abord, puis depuis l'API
  Future<void> _loadNotificationCount() async {
    // Charger depuis le cache local pour un affichage immédiat
    final localCount = await NotificationService.getLocalNotificationCount();
    if (mounted) {
      setState(() {
        _notificationCount = localCount;
      });
    }

    // Puis mettre à jour depuis l'API
    await _updateNotificationCountFromAPI();
  }

  Future<void> _updateNotificationCountFromAPI() async {
    try {
      final count = await NotificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _notificationCount = count;
        });
        // Sauvegarder localement pour la prochaine fois
        await NotificationService.saveNotificationCount(count);
      }
    } catch (e) {
      // En cas d'erreur, garder le count local
      print('Erreur lors de la mise à jour du count: $e');
    }
  }

  void _startNotificationTimer() {
    // Vérifier les notifications toutes les 30 secondes
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _updateNotificationCountFromAPI();
      }
    });
  }

  Future<void> _updateNotificationCount(int count) async {
    await NotificationService.saveNotificationCount(count);
    setState(() {
      _notificationCount = count;
    });
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
        child: Icon(icon, color: color ?? theme.iconTheme.color),
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF6797A2);
    final secondaryColor = const Color(0xFF4CA1A3);
    final accentColor = const Color(0xFF00BCD4);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Accueil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          badges.Badge(
            position: badges.BadgePosition.topEnd(top: 8, end: 8),
            badgeContent: Text(
              '$_notificationCount',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            showBadge: _notificationCount > 0,
            badgeStyle: badges.BadgeStyle(
              badgeColor: Colors.red,
              elevation: 2,
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsPage()),
                );

                // Rafraîchir le count après avoir visité la page notifications
                if (result == null) {
                  await _updateNotificationCountFromAPI();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              if (_userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PanierPage(userId: _userId!),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez vous connecter'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, primaryColor),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDarkMode ? Colors.grey[900]! : Colors.grey[50]!,
              isDarkMode ? Colors.grey[800]! : Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              _buildWelcomeSection(context, primaryColor, secondaryColor, accentColor),
              const SizedBox(height: 24),
              _buildQuickServicesSection(context, primaryColor),
              const SizedBox(height: 24),
              _buildMainFeaturesSection(context, isDarkMode, primaryColor),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Le reste des méthodes reste identique...
  Widget _buildDrawer(BuildContext context, Color primaryColor) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor, primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: CirclePatternPainter()),
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 10),
              children: [
                _buildDrawerTile(
                  context,
                  icon: Icons.home,
                  title: 'Home',
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const ClientHomePage()),
                  ),
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.account_circle,
                  title: 'Profile',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  ),
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.help_outline,
                  title: 'Ticket assistance',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TicketAssistancePage()),
                  ),
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.build,
                  title: 'Pièces de rechange',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CataloguePage()),
                  ),
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.add,
                  title: 'Plus',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PlusPage()),
                  ),
                ),
                const Divider(height: 20, indent: 20, endIndent: 20),
                _buildDrawerTile(
                  context,
                  icon: Icons.logout,
                  title: 'Déconnexion',
                  color: Colors.red,
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  ),
                )
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
    );
  }

  Widget _buildWelcomeSection(BuildContext context, Color primaryColor, Color secondaryColor, Color accentColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor, accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Hero(
            tag: 'profile_avatar',
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
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
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, $_prenom ! 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Prêt à prendre soin de votre véhicule ?',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickServicesSection(BuildContext context, Color primaryColor) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Services rapides',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.grey[800],
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Voir tout',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildQuickServiceButton(
                icon: Icons.build,
                label: 'Pièces',
                color: Colors.blueAccent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CataloguePage()),
                ),
              ),
              const SizedBox(width: 12),
              _buildQuickServiceButton(
                icon: Icons.schedule,
                label: 'RDV',
                color: Colors.deepOrangeAccent,
                onTap: () {},
              ),
              const SizedBox(width: 12),
              _buildQuickServiceButton(
                icon: Icons.history,
                label: 'Historique',
                color: Colors.lightGreen,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickServiceButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainFeaturesSection(BuildContext context, bool isDarkMode, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Que souhaitez-vous faire ?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            title: "Panne Connue",
            description: "Trouvez des solutions aux problèmes fréquents",
            icon: Icons.auto_fix_high,
            color: Colors.blueGrey,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Voiture()),
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            title: "Panne Inconnue",
            description: "Créez un ticket d'assistance personnalisé",
            icon: Icons.support_agent,
            color: primaryColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VoiturePanneInconnu()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
      BuildContext context, {
        required String title,
        required String description,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}

class CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final circles = [
      {'x': size.width * 0.2, 'y': size.height * 0.3, 'r': 50.0},
      {'x': size.width * 0.8, 'y': size.height * 0.2, 'r': 30.0},
      {'x': size.width * 0.9, 'y': size.height * 0.7, 'r': 40.0},
      {'x': size.width * 0.1, 'y': size.height * 0.8, 'r': 25.0},
    ];

    for (var circle in circles) {
      canvas.drawCircle(
        Offset(circle['x'] as double, circle['y'] as double),
        circle['r'] as double,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}