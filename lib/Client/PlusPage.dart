import 'package:car_mobile/Client/MesDemandesPage.dart';
import 'package:car_mobile/Client/OffresPage.dart';
import 'package:car_mobile/Client/calendrier.dart';
import 'package:car_mobile/Client/contact.dart';
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
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );
    _animationController!.forward();
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
      'title': 'Mes demandes',
      'icon': Icons.assignment_rounded,
      'gradient': [Color(0xFF00B894), Color(0xFF00B894)],
      'lightColor': Color(0xFFF0FFF4),
    },
    {
      'title': 'Offres',
      'icon': Icons.local_offer_rounded,
      'gradient': [Color(0xFFE84393), Color(0xFFE84393)],
      'lightColor': Color(0xFFFFF5F8),
    },
    {
      'title': 'Paramètres',
      'icon': Icons.tune_rounded,
      'gradient': [Color(0xFF6C5CE7), Color(0xFF6C5CE7)],
      'lightColor': Color(0xFFF5F3FF),
    },
    {
      'title': 'Notifications',
      'icon': Icons.notifications_active_rounded,
      'gradient': [Color(0xFF0984E3), Color(0xFF0984E3)],
      'lightColor': Color(0xFFFFF8F8),
    },
    {
      'title': 'Calendrier',
      'icon': Icons.event_rounded,
      'gradient': [Color(0xFF0984E3), Color(0xFF0984E3)],
      'lightColor': Color(0xFFF0F8FF),
    },
    {
      'title': 'Contacts',
      'icon': Icons.people_rounded,
      'gradient': [Color(0xFFFF6B6B), Color(0xFFFF6B6B)],
      'lightColor': Color(0xFFFFFDF0),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF6797A2),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6797A2),
              Color(0xFF6797A2),
            ],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildModernHeader(),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 32),
                  decoration: BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: _fadeAnimation != null ? FadeTransition(
                    opacity: _fadeAnimation!,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                      child: _buildModernGrid(),
                    ),
                  ) : Padding(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                    child: _buildModernGrid(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.apps_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '    Dashboard',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1.0,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Gérez vos services en un clic',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w500,
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

  Widget _buildModernGrid() {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.0,
      ),
      itemCount: cardItems.length,
      itemBuilder: (context, index) {
        if (_animationController == null) {
          return _buildGlassmorphicCard(context, cardItems[index], index);
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
                  (index * 0.15).clamp(0.0, 0.8),
                  1.0,
                  curve: Curves.easeOutCubic, // Changed from Curves.elasticOut
                ),
              ),
            );

            // Clamp the animation value to ensure it stays within 0.0-1.0 range
            final clampedValue = delayedAnimation.value.clamp(0.0, 1.0);

            return Transform.scale(
              scale: clampedValue,
              child: Opacity(
                opacity: clampedValue, // Use clamped value
                child: _buildGlassmorphicCard(context, cardItems[index], index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGlassmorphicCard(BuildContext context, Map<String, dynamic> item, int index) {
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
            color: item['gradient'][0].withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _handleCardTap(item, context),
          splashColor: item['gradient'][0].withOpacity(0.1),
          highlightColor: item['gradient'][0].withOpacity(0.05),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
              border: Border.all(
                color: item['gradient'][0].withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                // Effet de gradient subtil en arrière-plan
                Positioned(
                  top: -15,
                  right: -15,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          item['gradient'][0].withOpacity(0.1),
                          item['gradient'][1].withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                ),
                // Contenu principal
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: item['gradient'],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: item['gradient'][0].withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          item['icon'],
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'],
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D3748),
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: item['lightColor'],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Accéder',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: item['gradient'][0],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 10,
                                  color: item['gradient'][0],
                                ),
                              ],
                            ),
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
    // Animation de feedback tactile avec vibration légère

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
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: Duration(milliseconds: 400),
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
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: Duration(milliseconds: 400),
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
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            transitionDuration: Duration(milliseconds: 400),
          ),
        );
      } else {
        _showModernSnackBar(context, 'Veuillez vous connecter pour continuer');
      }
    } else if (item['title'] == 'Contacts') {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ContactsPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: Duration(milliseconds: 400),
        ),
      );
    }
    else if (item['title'] == 'Calendrier') {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => CalendrierDemandesPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: Duration(milliseconds: 400),
        ),
      );
    }
    else {
      // Pour les autres fonctionnalités non implémentées
      _showModernSnackBar(context, '${item['title']} - Fonctionnalité en développement');
    }
  }

  void _showModernSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 20
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF667EEA),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.all(20),
        duration: Duration(seconds: 3),
        elevation: 12,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}