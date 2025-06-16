import 'package:car_mobile/Client/PlusPage.dart';
import 'package:car_mobile/Client/catalogue_page.dart';
import 'package:car_mobile/Client/homeClient.dart';
import 'package:car_mobile/Client/profile_page.dart';
import 'package:car_mobile/login.dart';
import 'package:car_mobile/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class TypeTicket {
  final int id;
  final String type;

  TypeTicket({required this.id, required this.type});

  factory TypeTicket.fromJson(Map<String, dynamic> json) {
    return TypeTicket(
      id: json['id'],
      type: json['type_ticket'],
    );
  }

  @override
  String toString() => type;
}

class TicketAssistancePage extends StatefulWidget {
  const TicketAssistancePage({Key? key}) : super(key: key);

  @override
  _TicketAssistancePageState createState() => _TicketAssistancePageState();
}

class _TicketAssistancePageState extends State<TicketAssistancePage> {
  final _storage = const FlutterSecureStorage();
  List<dynamic> _currentWeekTickets = [];
  List<dynamic> _previousTickets = [];
  bool _isLoading = true;
  String _error = '';
  int? _userId;
  int _selectedTab = 0;
  String? _nom = '';
  String? _prenom = '';
  static const String baseUrl = 'http://192.168.1.17:8000';
  final primaryColor = const Color(0xFF6797A2);
  final secondaryColor = const Color(0xFF4CA1A3);
  // Pour les types de tickets
  List<TypeTicket> _ticketTypes = [];
  bool _isLoadingTypes = false;
  String _typesError = '';

  // Couleurs personnalisées
  final Color _primaryColor = const Color(0xFF2E7D32);
  final Color _secondaryColor = const Color(0xFF7CB342);
  final Color _accentColor = const Color(0xFF689F38);
  final Color _lightBackground = const Color(0xFFF5F5F6);
  final Color _cardBackground = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTicketTypes();
  }

  Future<void> _loadTicketTypes() async {
    setState(() {
      _isLoadingTypes = true;
      _typesError = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tickets/type'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _ticketTypes = data.map((json) => TypeTicket.fromJson(json)).toList();
          _isLoadingTypes = false;
        });
      } else {
        throw Exception('Failed to load ticket types');
      }
    } catch (e) {
      setState(() {
        _typesError = 'Failed to load ticket types: ${e.toString()}';
        _isLoadingTypes = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userDataJson = await _storage.read(key: 'user_data');
      if (userDataJson != null) {
        final userData = jsonDecode(userDataJson);
        setState(() {
          _userId = userData['id'] != null ? int.tryParse(userData['id'].toString()) : null;
          _nom=userData['nom'];
          _prenom=userData['prenom'];
        });
        if (_userId != null) {
          _loadTickets();
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur de chargement des données utilisateur';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTickets() async {
    try {
      print(_userId);
      final response = await http.get(
        Uri.parse('$baseUrl/api/tickets/client/$_userId'),
      );
print(response.statusCode);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final allTickets = decoded['data'];
print(allTickets);
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

        setState(() {
          _currentWeekTickets = allTickets.where((ticket) {
            final createdAt = DateTime.parse(ticket['created_at']);
            return createdAt.isAfter(startOfWeek);
          }).toList();

          _previousTickets = allTickets.where((ticket) {
            final createdAt = DateTime.parse(ticket['created_at']);
            return !createdAt.isAfter(startOfWeek);
          }).toList();

          _isLoading = false;
        });
      } else {
        throw Exception('Erreur lors du chargement des tickets');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewTicket() async {
    if (_isLoadingTypes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chargement des types en cours...')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewTicketPage(
          primaryColor: _primaryColor,
          secondaryColor: _secondaryColor,
          ticketTypes: _ticketTypes,
        ),
      ),
    );

    if (result == true) {
      _loadTickets();
    }
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final createdAt = DateTime.parse(ticket['created_at']);
    final formattedDate = DateFormat('dd MMM yyyy - HH:mm').format(createdAt);
    final status = ticket['statut'] ?? 'En attente';
    Color statusColor;

    switch (status.toLowerCase()) {
      case 'en_attente':
        statusColor = Colors.blueAccent;
        break;
      case 'résolu':
        statusColor = Colors.green;
        break;
      case 'rejeté':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.blueGrey;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showTicketDetails(ticket);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                _cardBackground.withOpacity(0.9),
                _cardBackground.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        ticket['titre'] ?? 'Sans titre',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  ticket['description'] ?? 'Pas de description',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Color(0xFF007896)),
                    const SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    if (ticket['atelier'] != null)
                      Row(
                        children: [
                          Icon(Icons.build, size: 16, color: Color(0xFF007896)),
                          const SizedBox(width: 4),
                          Text(
                            ticket['atelier']['nom'] ?? 'Atelier',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTicketDetails(Map<String, dynamic> ticket) {
    final createdAt = DateTime.parse(ticket['created_at']);
    final formattedDate = DateFormat('dd MMM yyyy - HH:mm').format(createdAt);
    final status = ticket['statut'] ?? 'En attente';
    Color statusColor;

    switch (status.toLowerCase()) {
      case 'en cours':
        statusColor = Colors.orange;
        break;
      case 'résolu':
        statusColor = Colors.green;
        break;
      case 'rejeté':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.blueGrey;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _lightBackground.withOpacity(0.9),
                _lightBackground.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ticket['titre'] ?? 'Détails du ticket',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007896),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Type: ${ticket['type'] ?? 'Non spécifié'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007896),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Description:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ticket['description'] ?? 'Pas de description',
                  style: TextStyle(
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 20),
                if (ticket['atelier'] != null) ...[
                  const Text(
                    'Atelier assigné:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.build),
                    title: Text(ticket['atelier']['nom'] ?? 'Atelier inconnu'),
                    subtitle: Text(
                        ticket['atelier']['adresse'] ?? 'Adresse inconnue'),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF007896),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Fermer', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
  Widget _buildTabButton(int index, String text) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _selectedTab == index ? Color(0xFF007896) : Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: _selectedTab == index ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBackground,
      appBar: AppBar(
        title: const Text('Ticket d\'assistance  '),
        backgroundColor: Colors.grey[200],
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTickets,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewTicket,
        backgroundColor: Color(0xFF007896),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
        ),
      )
          : _error.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 50, color: Colors.red[400]),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _error,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadTickets,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildTabButton(0, 'Demandes Actuelles'),
                const SizedBox(width: 10),
                _buildTabButton(1, 'Historique'),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _selectedTab == 0
                  ? _currentWeekTickets.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined,
                        size: 60, color: Color(0xFF007896)),
                    const SizedBox(height: 20),
                    const Text(
                      'Aucune demande cette semaine',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: _loadTickets,
                color: _primaryColor,
                child: ListView.builder(
                  itemCount: _currentWeekTickets.length,
                  itemBuilder: (context, index) {
                    return _buildTicketCard(
                        _currentWeekTickets[index]);
                  },
                ),
              )
                  : _previousTickets.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history,
                        size: 60, color: Color(0xFF007896)),
                    const SizedBox(height: 20),
                    const Text(
                      'Aucune demande précédente',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: _loadTickets,
                color: _primaryColor,
                child: ListView.builder(
                  itemCount: _previousTickets.length,
                  itemBuilder: (context, index) {
                    return _buildTicketCard(
                        _previousTickets[index]);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NewTicketPage extends StatefulWidget {
  final Color primaryColor;
  final Color secondaryColor;
  final List<TypeTicket> ticketTypes;

  const NewTicketPage({
    Key? key,
    required this.primaryColor,
    required this.secondaryColor,
    required this.ticketTypes,
  }) : super(key: key);

  @override
  _NewTicketPageState createState() => _NewTicketPageState();
}

class _NewTicketPageState extends State<NewTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  TypeTicket? _selectedType;
  bool _isSubmitting = false;
  static const String baseUrl = 'http://192.168.113.216:8000';

  @override
  void initState() {
    super.initState();
    if (widget.ticketTypes.isNotEmpty) {
      _selectedType = widget.ticketTypes.first;
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un type de ticket')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userDataJson = await _storage.read(key: 'user_data');
      if (userDataJson == null) throw Exception('Utilisateur non connecté');

      final userData = jsonDecode(userDataJson);
      final userId = userData['id'];

      final response = await http.post(
        Uri.parse('$baseUrl/api/tickets'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'client_id': userId,
          'titre': _titreController.text,
          'description': _descriptionController.text,
          'type': _selectedType!.type,
          'statut': 'en attente',
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        throw Exception('Erreur lors de la création du ticket');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
        title: const Text('Nouvelle Demande'),
        backgroundColor: Colors.grey[200],
        elevation: 0,
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Décrivez votre problème',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Remplissez ce formulaire pour créer une nouvelle demande d\'assistance',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _titreController,
                  decoration: InputDecoration(
                    labelText: 'Titre du problème',
                    labelStyle: const TextStyle(color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: widget.primaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: widget.primaryColor, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.title, color: Colors.black),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un titre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<TypeTicket>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type de problème',
                    labelStyle: const TextStyle(color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: widget.primaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: widget.primaryColor, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.category, color: Colors.black),
                  ),
                  items: widget.ticketTypes.map((type) {
                    return DropdownMenuItem<TypeTicket>(
                      value: type,
                      child: Text(type.type),
                    );
                  }).toList(),
                  onChanged: (TypeTicket? newValue) {
                    setState(() {
                      _selectedType = newValue;
                    });
                  },
                  validator: (value) => value == null
                      ? 'Veuillez choisir un type'
                      : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Description détaillée',
                    labelStyle: const TextStyle(color: Colors.black),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: widget.primaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: widget.primaryColor, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une description';
                    }
                    if (value.length < 20) {
                      return 'La description doit faire au moins 20 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitTicket,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF007896),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      'Envoyer',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Annuler',
                    style: TextStyle(
                      color: Color(0xFF007896),
                      fontSize: 16,
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
}