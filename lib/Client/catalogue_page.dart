import 'package:car_mobile/Client/CatalogueDetail.dart';
import 'package:car_mobile/Client/PlusPage.dart';
import 'package:car_mobile/Client/TicketAssistancePage.dart';
import 'package:car_mobile/Client/homeClient.dart';
import 'package:car_mobile/Client/mes_voitures.dart';
import 'package:car_mobile/Client/profile_page.dart';
import 'package:car_mobile/home.dart';
import 'package:car_mobile/login.dart';
import 'package:car_mobile/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CataloguePage extends StatefulWidget {
  const CataloguePage({Key? key}) : super(key: key);

  @override
  _CataloguePageState createState() => _CataloguePageState();
}

class _CataloguePageState extends State<CataloguePage> {
  List<dynamic> _catalogues = [];
  List<dynamic> _filteredCatalogues = [];
  bool _isLoading = true;
  String _error = '';
  TextEditingController _searchController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  String? _nom = '';
  String? _prenom = '';
  static const String baseUrl = 'http://192.168.1.17:8000';

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
    _loadCatalogues();
    _searchController.addListener(_filterCatalogues);
    _loadUserData();
  }
  final primaryColor = const Color(0xFF6797A2);
  final secondaryColor = const Color(0xFF4CA1A3);
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalogues() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/catalogues'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _catalogues = List<dynamic>.from(data);
          _filteredCatalogues = List<dynamic>.from(data);
          _isLoading = false;
        });
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur: ${e.toString()}';
        _isLoading = false;
      });
      debugPrint('Erreur de chargement: $e');
    }
  }

  void _filterCatalogues() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCatalogues = _catalogues.where((item) {
        final name = item['nom_piece']?.toString().toLowerCase() ?? '';
        return name.contains(query);
      }).toList();
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

  Widget _buildImageWidget(String? imageUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: imageUrl == null
          ? const Icon(Icons.image, size: 50, color: Colors.blueGrey)
          : ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.blueGrey.withOpacity(0.7),
              ),
            ),
          ),
          errorWidget: (context, url, error) => const Icon(
            Icons.broken_image,
            color: Colors.blueGrey,
            size: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogueCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        shadowColor: Colors.grey.withOpacity(0.2),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final userId = await _storage.read(key: 'id');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CatalogueDetailPage(
                  piece: item,
                  userId: userId,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildImageWidget(item['photo_piece']),
                ),
                const SizedBox(height: 10),
                Expanded(
                  flex: 1,
                  child: Text(
                    item['nom_piece'] ?? 'Pièce sans nom',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item['type_voiture'],
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Catalogue des Pièces',
            style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.grey[200],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadCatalogues,
          ),
        ],
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
                  colors: [primaryColor, secondaryColor, secondaryColor],
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[100],
                hintText: 'Rechercher une pièce...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              style: const TextStyle(color: Colors.black87),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            )
                : _error.isNotEmpty
                ? Center(
              child: Text(
                _error,
                style: const TextStyle(color: Colors.black87),
              ),
            )
                : _filteredCatalogues.isEmpty
                ? const Center(
              child: Text(
                'Aucune pièce trouvée',
                style: TextStyle(color: Colors.black87),
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
              ),
              itemCount: _filteredCatalogues.length,
              itemBuilder: (context, index) {
                return _buildCatalogueCard(
                    _filteredCatalogues[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}