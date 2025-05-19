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

class _PlusPageState extends State<PlusPage> {
  final _storage = const FlutterSecureStorage();
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
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
      'icon': Icons.settings,
      'color': Colors.blue.shade700,
    },
    {
      'title': 'Mes demandes',
      'icon': Icons.list_alt_rounded, // icône liste plus formelle
      'color': Colors.green.shade600,
    },
    {
      'title': 'Offres',
      'icon': Icons.local_offer_rounded, // icône "offre" classique, style étiquette
      'color': Colors.orange.shade600,
    },

    {
      'title': 'Notifications',
      'icon': Icons.notifications_active_rounded,
      'color': Colors.purple.shade600,
    },
    {
      'title': 'Calendrier',
      'icon': Icons.calendar_month_rounded,
      'color': Colors.red.shade600,
    },
    {
      'title': 'Contacts',
      'icon': Icons.contacts_rounded,
      'color': Colors.teal.shade600,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fonctionnalités',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF007896),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 1.0,
          ),
          itemCount: cardItems.length,
          itemBuilder: (context, index) {
            return _buildFeatureCard(context, cardItems[index]);
          },
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, Map<String, dynamic> item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.0),
        onTap: () {
          if (item['title'] == 'Mes demandes') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MesDemandesPage()),
            );
          } else if (item['title'] == 'Paramètres') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsPage()),
            );
          } else if (item['title'] == 'Offres') {
            if (_userId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OffresPage(clientId: _userId!)),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Veuillez vous connecter'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        },
        splashColor: item['color'].withOpacity(0.2),
        highlightColor: item['color'].withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: item['color'].withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: item['color'].withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  item['icon'],
                  size: 28,
                  color: item['color'],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item['title'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
