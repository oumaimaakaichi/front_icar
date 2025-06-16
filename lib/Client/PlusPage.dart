import 'package:car_mobile/Client/MesDemandesPage.dart';
import 'package:car_mobile/Client/OffresPage.dart';
import 'package:car_mobile/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class PlusPage extends StatefulWidget {
  const PlusPage({super.key});

  @override
  State<PlusPage> createState() => _PlusPageState();
}

class _PlusPageState extends State<PlusPage> with TickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();
  int? _userId;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserId();

  }


  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final userDataJson = await _storage.read(key: 'user_data');
    if (userDataJson != null) {
      final userData = jsonDecode(userDataJson);
      setState(() {
        _userId = userData['id'] != null ? int.tryParse(userData['id'].toString()) : null;
      });
    }
  }

  final List<Map<String, dynamic>> cardItems = [
    {
      'title': 'Paramètres',

      'icon': Icons.settings_rounded,
      'gradient': [Color(0xFF667eea), Color(0xFF764ba2)],
    },
    {
      'title': 'Mes demandes',

      'icon': Icons.list_alt_rounded,
      'gradient': [Color(0xFF11998e), Color(0xFF38ef7d)],
    },
    {
      'title': 'Offres',

      'icon': Icons.local_offer_rounded,
      'gradient': [Color(0xFFfc4a1a), Color(0xFFf7b733)],
    },
    {
      'title': 'Notifications',

      'icon': Icons.notifications_active_rounded,
      'gradient': [Color(0xFF9D50BB), Color(0xFF6E48AA)],
    },
    {
      'title': 'Calendrier',

      'icon': Icons.calendar_month_rounded,
      'gradient': [Color(0xFFe53e3e), Color(0xFFfd5e53)],
    },
    {
      'title': 'Contacts',

      'icon': Icons.contacts_rounded,
      'gradient': [Color(0xFF00b4db), Color(0xFF0083b0)],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF007896),
              Color(0xFF005f7a),
              Color(0xFF004d63),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _fadeAnimation != null ? FadeTransition(
                    opacity: _fadeAnimation!,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                      child: _buildGrid(),
                    ),
                  ) : Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                    child: _buildGrid(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.dashboard_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fonctionnalités',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Accédez à tous vos services',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.85,
      ),
      itemCount: cardItems.length,
      itemBuilder: (context, index) {
        if (_animationController == null) {
          return _buildModernFeatureCard(context, cardItems[index], index);
        }

        return AnimatedBuilder(
          animation: _animationController!,
          builder: (context, child) {
            final delayedAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: _animationController!,
                curve: Interval(
                  (index * 0.1).clamp(0.0, 1.0),
                  1.0,
                  curve: Curves.elasticOut,
                ),
              ),
            );

            return Transform.scale(
              scale: delayedAnimation.value,
              child: _buildModernFeatureCard(context, cardItems[index], index),
            );
          },
        );
      },
    );
  }

  Widget _buildModernFeatureCard(BuildContext context, Map<String, dynamic> item, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _handleCardTap(item, context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: item['gradient'],
              ),
            ),
            child: Stack(
              children: [
                // Effet de brillance subtil
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                // Contenu principal
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          item['icon'],
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      Spacer(),
                      Text(
                        item['title'],
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 4),


                      // Indicateur d'action
                      Row(
                        children: [
                          Text(
                            'Ouvrir',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleCardTap(Map<String, dynamic> item, BuildContext context) {
    // Animation de feedback tactile


    if (item['title'] == 'Mes demandes') {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => MesDemandesPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            );
          },
          transitionDuration: Duration(milliseconds: 300),
        ),
      );
    } else if (item['title'] == 'Paramètres') {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => SettingsPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            );
          },
          transitionDuration: Duration(milliseconds: 300),
        ),
      );
    } else if (item['title'] == 'Offres') {
      if (_userId != null) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => OffresPage(clientId: _userId!),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOutCubic,
                )),
                child: child,
              );
            },
            transitionDuration: Duration(milliseconds: 300),
          ),
        );
      } else {
        _showModernSnackBar(context, 'Veuillez vous connecter');
      }
    } else {
      // Pour les autres fonctionnalités non implémentées
      _showModernSnackBar(context, '${item['title']} - Bientôt disponible');
    }
  }

  void _showModernSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF007896),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }
}