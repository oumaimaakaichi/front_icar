import 'package:car_mobile/login.dart';
import 'package:car_mobile/settings_page.dart';
import 'package:car_mobile/user_home.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class TechnicienTicketsPage extends StatefulWidget {
  @override
  _TechnicienTicketsPageState createState() => _TechnicienTicketsPageState();
}

class _TechnicienTicketsPageState extends State<TechnicienTicketsPage> {
  final _storage = const FlutterSecureStorage();
  List<dynamic> _tickets = [];
  bool _loading = true;
  int? _technicienId;
  String? _authToken;
  String? _nom = '';
  String? _prenom = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchTickets();
  }

  Future<void> _loadUserData() async {
    final userDataJson = await _storage.read(key: 'user_data');
    if (userDataJson != null) {
      final userData = jsonDecode(userDataJson);
      setState(() {
        _technicienId = userData['id'];
        _authToken = userData['token'];
        _nom = userData['nom'] ?? '';
        _prenom = userData['prenom'] ?? '';
      });
    }
  }

  Future<void> _fetchTickets() async {
    final userDataJsons = await _storage.read(key: 'user_data');

    if (userDataJsons == null) {
      // Handle the case when the user data is not available
      print("No user data found");
      return; // You can return or show an error depending on your needs
    }

    final userData = jsonDecode(userDataJsons);
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.162:8000/api/tickets/technicien/${userData["id"]}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _tickets = data['data'];
          _loading = false;
        });
      } else {
        throw Exception('Failed to load tickets');
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddTicketDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(20),
        child: _AddTicketForm(onTicketAdded: _fetchTickets),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'en_attente':
        return Colors.orange;
      case 'en_cours':
        return Colors.blue;
      case 'resolu':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'panne':
        return Icons.engineering;
      case 'maintenance':
        return Icons.engineering;
      case 'inspection':
        return Icons.search;
      default:
        return Icons.engineering;
    }
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mes Tickets                   ', style: TextStyle( color: Colors.white ,  fontFamily: 'Roboto')),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchTickets,
            tooltip: 'Actualiser',
          ),
        ],
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
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.blueGrey,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),

              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/9.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      '$_prenom $_nom',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Utilisateur Premium',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 10),
                children: [
                  _buildDrawerTile(
                    context,
                    icon: Icons.dashboard,
                    title: 'Home',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UserHomePage()),
                      );
                    },
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.analytics,
                    title: 'Tickets Assistance',
                    onTap: () {},
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.history,
                    title: 'Historique',
                    onTap: () {},
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.settings,
                    title: 'Paramètres',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                      );
                    },
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.help_center,
                    title: 'Aide & Support',
                    onTap: () {},
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
                  ),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTicketDialog,
        child: const Icon(Icons.add, size: 28, color: Colors.white),
        backgroundColor: Colors.blueGrey,
        elevation: 4,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchTickets,
        child: _tickets.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 20),
              Text(
                'Aucun ticket trouvé',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Appuyez sur le bouton + pour créer un ticket',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        )
            : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _tickets.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final ticket = _tickets[index];
            final date = DateTime.parse(ticket['created_at']).toLocal();
            final formattedDate = DateFormat('dd MMM yyyy - HH:mm').format(date);

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // Navigation vers les détails du ticket
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getTypeIcon(ticket['type']),
                          color: Colors.blueGrey,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ticket['titre'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color :  Colors.blueGrey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(ticket['statut'])
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getStatusColor(ticket['statut']),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            ticket['statut'].toString().replaceAll('_', ' '),
                            style: TextStyle(
                              color: _getStatusColor(ticket['statut']),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ticket['description'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),

                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'haute':
        return Colors.red;
      case 'moyenne':
        return Colors.orange;
      case 'basse':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class _AddTicketForm extends StatefulWidget {
  final VoidCallback onTicketAdded;

  const _AddTicketForm({required this.onTicketAdded});

  @override
  __AddTicketFormState createState() => __AddTicketFormState();
}

class __AddTicketFormState extends State<_AddTicketForm> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();

  String _titre = '';
  String _description = '';
  String _type = '';
  String _priorite = 'moyenne';
  int? _atelierId;
  int? _technicienId;
  String? _authToken;
  bool _loading = false;
  List<dynamic> _ticketTypes = [];
  bool _loadingTypes = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchTicketTypes();
  }

  Future<void> _loadUserData() async {
    final userDataJson = await _storage.read(key: 'user_data');
    if (userDataJson != null) {
      final userData = jsonDecode(userDataJson);
      if (!mounted) return;
      setState(() {
        _atelierId = userData['atelier_id'];
        _technicienId = userData['id'];
        _authToken = userData['token'];
      });
    }
  }

  Future<void> _fetchTicketTypes() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.162:8000/api/tickets/type'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _ticketTypes = data;
          if (_ticketTypes.isNotEmpty) {
            _type = _ticketTypes[0]['type_ticket'] ?? 'Panne';
          }
          _loadingTypes = false;
        });
      } else {
        throw Exception('Failed to load ticket types');
      }
    } catch (e) {
      setState(() => _loadingTypes = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des types: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.113.216:8000/api/tickets'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          "titre": _titre,
          "description": _description,
          "type": _type,

          "atelier_id": _atelierId,
          "technicien_id": _technicienId,
        }),
      );

      final responseData = jsonDecode(response.body);
      setState(() => _loading = false);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Ticket créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onTicketAdded();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Erreur lors de la création'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur réseau: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nouveau Ticket',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.blueGrey[400]),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Titre du ticket',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blueGrey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: 'Entrez un titre clair',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        prefixIcon: Icon(Icons.title, color: Colors.blueGrey[300]),
                      ),
                      style: TextStyle(color: Colors.blueGrey[800]),
                      onSaved: (val) => _titre = val!.trim(),
                      validator: (val) =>
                      val == null || val.isEmpty ? 'Ce champ est requis' : null,
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blueGrey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Décrivez le problème en détail...',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(bottom: 60),
                          child: Icon(Icons.description, color: Colors.blueGrey[300]),
                        ),
                      ),
                      style: TextStyle(color: Colors.blueGrey[800]),
                      onSaved: (val) => _description = val!.trim(),
                      validator: (val) =>
                      val == null || val.isEmpty ? 'Ce champ est requis' : null,
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Type de ticket',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blueGrey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _loadingTypes
                        ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    )
                        : Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:DropdownButtonFormField<String>(
                        value: _ticketTypes.isEmpty ? null : _type,
                        items: _ticketTypes
                            .map<DropdownMenuItem<String>>((dynamic type) => DropdownMenuItem<String>(
                          value: type['type_ticket'] as String, // Cast to String explicitly
                          child: Text(
                            type['type_ticket'] as String, // Cast to String explicitly
                            style: TextStyle(color: Colors.blueGrey[800]),
                          ),
                        ))
                            .toList(),
                        onChanged: (String? val) => setState(() => _type = val!),
                        validator: (val) => val == null ? 'Veuillez sélectionner un type' : null,
                      ),
                    ),
                    const SizedBox(height: 20),



                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitTicket,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: Colors.blueGrey.withOpacity(0.4),
                        ),
                        child: _loading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.send, size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Créer le ticket',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}