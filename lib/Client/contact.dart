import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> with TickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  // Données de contacts d'exemple
  final List<Map<String, dynamic>> contacts = [
    {
      'name': 'Support Client',
      'role': 'Assistance technique',
      'phone': '+216 70 123 456',
      'email': 'support@carapp.tn',
      'avatar': '🎧',
      'color': Color(0xFF667EEA),
      'isOnline': true,
    },
    {
      'name': 'Service Commercial',
      'role': 'Ventes & Partenariats',
      'phone': '+216 70 789 012',
      'email': 'commercial@carapp.tn',
      'avatar': '💼',
      'color': Color(0xFF00B894),
      'isOnline': true,
    },
    {
      'name': 'Urgences',
      'role': 'Dépannage d\'urgence',
      'phone': '+216 70 000 911',
      'email': 'urgence@carapp.tn',
      'avatar': '🚨',
      'color': Color(0xFFFF7675),
      'isOnline': true,
    },
    {
      'name': 'Service Technique',
      'role': 'Réparations & Maintenance',
      'phone': '+216 70 345 678',
      'email': 'technique@carapp.tn',
      'avatar': '🔧',
      'color': Color(0xFFE84393),
      'isOnline': false,
    },
    {
      'name': 'Administration',
      'role': 'Gestion des comptes',
      'phone': '+216 70 567 890',
      'email': 'admin@carapp.tn',
      'avatar': '📋',
      'color': Color(0xFF6C5CE7),
      'isOnline': true,
    },
  ];

  final List<Map<String, dynamic>> quickActions = [
    {
      'title': 'Appel d\'urgence',
      'icon': Icons.emergency_rounded,
      'color': Color(0xFFFF7675),
      'action': 'emergency_call',
    },
    {
      'title': 'Chat en direct',
      'icon': Icons.chat_rounded,
      'color': Color(0xFF00B894),
      'action': 'live_chat',
    },
    {
      'title': 'Email support',
      'icon': Icons.email_rounded,
      'color': Color(0xFF667EEA),
      'action': 'email_support',
    },
    {
      'title': 'FAQ Application',
      'icon': Icons.help_rounded,
      'color': Color(0xFFE84393),
      'action': 'faq',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController!, curve: Curves.easeOutCubic));

    _animationController!.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

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
              Color(0xFF6797A2).withOpacity(0.8),
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
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation!,
                    child: SlideTransition(
                      position: _slideAnimation!,
                      child: Column(
                        children: [
                          _buildQuickActions(),
                          Expanded(child: _buildContactsList()),
                        ],
                      ),
                    ),
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contacts',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Nous sommes là pour vous aider',
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
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions rapides',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3748),
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: quickActions.map((action) {
              int index = quickActions.indexOf(action);
              return Expanded(
                child: AnimatedBuilder(
                  animation: _animationController!,
                  builder: (context, child) {
                    final delayedAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController!,
                        curve: Interval(
                          (index * 0.1).clamp(0.0, 0.8),
                          1.0,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                    );
                    return Transform.scale(
                      scale: delayedAnimation.value,
                      child: Container(
                        margin: EdgeInsets.only(
                          right: index < quickActions.length - 1 ? 12 : 0,
                        ),
                        child: _buildQuickActionCard(action),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(Map<String, dynamic> action) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: action['color'].withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 8),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _handleQuickAction(action['action']),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: action['color'].withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: action['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    action['icon'],
                    color: action['color'],
                    size: 24,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  action['title'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactsList() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Équipe support',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3748),
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              physics: BouncingScrollPhysics(),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _animationController!,
                  builder: (context, child) {
                    final delayedAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController!,
                        curve: Interval(
                          (index * 0.1 + 0.2).clamp(0.0, 0.8),
                          1.0,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                    );
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - delayedAnimation.value)),
                      child: Opacity(
                        opacity: delayedAnimation.value,
                        child: _buildContactCard(contacts[index]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showContactActions(contact),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: contact['color'].withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: contact['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          contact['avatar'],
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),

                  ],
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              contact['name'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                          ),


                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        contact['role'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF718096),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_rounded,
                            size: 16,
                            color: contact['color'],
                          ),
                          SizedBox(width: 6),
                          Text(
                            contact['phone'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4A5568),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF718096),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleQuickAction(String action) {
    HapticFeedback.lightImpact();

    switch (action) {
      case 'emergency_call':
        _showModernDialog(
          'Appel d\'urgence',
          'Voulez-vous appeler le service d\'urgence ?',
          Icons.emergency_rounded,
          Color(0xFFFF7675),
        );
        break;
      case 'live_chat':
        _showModernSnackBar('Chat en direct bientôt disponible');
        break;
      case 'email_support':
        _showModernSnackBar('Ouverture de l\'application email...');
        break;

        break;
    }
  }

  void _showContactActions(Map<String, dynamic> contact) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: contact['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      contact['avatar'],
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact['name'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        contact['role'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF718096),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Appeler',
                    Icons.phone_rounded,
                    contact['color'],
                        () => _makeCall(contact['phone']),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    'Email',
                    Icons.email_rounded,
                    Color(0xFF667EEA),
                        () => _sendEmail(contact['email']),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 8),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _makeCall(String phone) {
    Navigator.pop(context);
    _showModernSnackBar('Appel vers $phone...');
  }

  void _sendEmail(String email) {
    Navigator.pop(context);
    _showModernSnackBar('Ouverture de l\'email vers $email...');
  }

  void _showModernDialog(String title, String message, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3748),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF4A5568),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showModernSnackBar('Action confirmée');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Confirmer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showModernSnackBar(String message) {
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
                size: 20,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.all(20),
        duration: Duration(seconds: 3),
        elevation: 12,
      ),
    );
  }
}