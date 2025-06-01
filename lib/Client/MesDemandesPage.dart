import 'package:car_mobile/Client/PieceRecommandeePage.dart';
import 'package:car_mobile/Client/PlusPage.dart';
import 'package:car_mobile/Client/TicketAssistancePage.dart';
import 'package:car_mobile/Client/catalogue_page.dart';
import 'package:car_mobile/Client/demandePrecedentes.dart';
import 'package:car_mobile/Client/homeClient.dart';
import 'package:car_mobile/Client/profile_page.dart';
import 'package:car_mobile/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class MesDemandesPage extends StatefulWidget {
  @override
  _MesDemandesPageState createState() => _MesDemandesPageState();
}

class _MesDemandesPageState extends State<MesDemandesPage> {
  final _storage = const FlutterSecureStorage();
  String? _nom = '';
  String? _prenom = '';
  int? _userId;
  List<dynamic> _demandes = [];
  bool _isLoading = true;

  Future<void> _loadUserData() async {
    final userDataJson = await _storage.read(key: 'user_data');
    print("Données utilisateur: $userDataJson");

    if (userDataJson != null) {
      final userData = jsonDecode(userDataJson);
      if (!mounted) return;
      setState(() {
        _nom = userData['nom'] ?? '';
        _prenom = userData['prenom'] ?? '';
        _userId = userData['id'] != null ? int.tryParse(userData['id'].toString()) : null;
      });
    }
  }

  Future<void> _fetchDemandes() async {
    if (_userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/demandes/$_userId'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _demandes = data is List ? data : [];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load demandes');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des demandes: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData().then((_) => _fetchDemandes());
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
        title: const Text(
          'Mes Demandes',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF007896),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.handyman),
            tooltip: 'Demandes avec technicien',
            onPressed: () {
              if (_userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DemandesAvecTechnicienPage(userId: _userId!),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("ID utilisateur introuvable.")),
                );
              }
            },
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
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Color(0xFF007896),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                image: const DecorationImage(
                  image: AssetImage('assets/images/background_pattern.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.teal,
                    BlendMode.dstATop,
                  ),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfilePage()),
                        );
                      },
                      child: Container(
                        width: 100,
                        height: 100,
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
                            'assets/images/profile.png',
                            fit: BoxFit.cover,
                          ),
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
                        MaterialPageRoute(builder: (context) => PlusPage()),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Mes  nouvelles Demandes",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _demandes.isEmpty
                  ? Center(child: Text("Aucune demande trouvée"))
                  : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _demandes.length,
                itemBuilder: (context, index) {
                  final demande = _demandes[index];
                  final servicePanne = demande['service_panne'] ?? {};
                  final voiture = demande['voiture'] ?? {};
                  final dateCreation = demande['created_at'];
                  final hasPiece = demande['has_piece_recommandee'] ?? false;
                  final typeEmplacement = demande['type_emplacement'];
                  final dateMaintenance = demande['date_maintenance'];
                  final atelier = demande['atelier'];

                  final parsedDate = DateTime.tryParse(dateCreation ?? '');
                  final formattedDate = parsedDate != null
                      ? DateFormat('dd/MM/yyyy à HH:mm').format(parsedDate)
                      : 'Date invalide';

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            servicePanne['titre'] ?? 'Titre non défini',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF007896),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.directions_car, color: Colors.grey[600], size: 18),
                              const SizedBox(width: 6),
                              Text(
                                "Voiture: ${voiture['model'] ?? 'Inconnu'}",
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.grey[600], size: 18),
                              const SizedBox(width: 6),
                              Text(
                                "Créée le : $formattedDate",
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: _buildActionButton(
                                context,
                                demande: demande,
                                typeEmplacement: typeEmplacement,
                                dateMaintenance: dateMaintenance,
                                hasPiece: hasPiece,
                                atelier: atelier,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, {
        required dynamic demande,
        required dynamic typeEmplacement,
        required dynamic dateMaintenance,
        required bool hasPiece,
        required dynamic atelier,
      }) {
    // Vérifie si c'est une demande avec rendez-vous (fixe ou mobile)
    final hasAppointment = dateMaintenance != null ||
        (typeEmplacement != null &&
            (typeEmplacement == 'fixe' || typeEmplacement == 'mobile'));

    if (hasAppointment) {
      return ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmationPage(
                demandeId: demande['id'],
                isFixed: typeEmplacement == 'fixe',
                date: dateMaintenance != null ? DateTime.tryParse(dateMaintenance) : null,
                atelier: atelier,
              ),
            ),
          );
        },
        icon: const Icon(Icons.visibility),
        label: const Text('View'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } else if (hasPiece) {
      return ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PieceRecommandeePage(
                demandeId: demande['id'],
              ),
            ),
          );
        },
        icon: const Icon(Icons.attach_money),
        label: const Text('Voir Prix'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF007896),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }
}

class ConfirmationPage extends StatelessWidget {
  final dynamic atelier;
  final DateTime? date;
  final bool isFixed;
  final int demandeId;

  const ConfirmationPage({
    Key? key,
    required this.atelier,
    required this.date,
    required this.isFixed,
    required this.demandeId,
  }) : super(key: key);

  Future<Map<String, dynamic>> _fetchDemandeDetails() async {
    final response = await http.get(
      Uri.parse('http://localhost:8000/api/demandes/$demandeId/confirmation-details'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load demande details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation'),
        backgroundColor: Colors.grey[200],
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchDemandeDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final details = snapshot.data!;
          final piecesChoisies = details['pieces_choisies'] as List<dynamic>;
          final totalPieces = details['total_pieces'] ?? 0;
          final totalMainOeuvre = details['total_main_oeuvre'] ?? 0;
          final dateMaintenance = details['date_maintenance'] != null
              ? DateTime.parse(details['date_maintenance'])
              : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 80),
                  const SizedBox(height: 20),
                  const Text(
                    'Rendez-vous confirmé!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.build),
                            title: const Text('Service'),
                            subtitle: Text(details['service_titre'] ?? 'Non spécifié'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.directions_car),
                            title: const Text('Voiture'),
                            subtitle: Text(details['voiture_model'] ?? 'Non spécifié'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.shopping_cart),
                            title: const Text('Total pièces'),
                            trailing: Text('$totalPieces €'),
                          ),

                          if (piecesChoisies.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.list),
                                label: const Text('Voir les pièces choisies'),
                                onPressed: () {
                                  _showPiecesDialog(context, piecesChoisies);
                                },
                              ),
                            ),
                          if (isFixed) ...[
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.business),
                              title: const Text('Atelier'),
                              subtitle: Text(atelier['nom_commercial']),
                            ),
                            ListTile(
                              leading: const Icon(Icons.location_on),
                              title: const Text('Adresse'),
                              subtitle: Text(
                                  '${atelier['adresse'] ?? ''}\n${atelier['ville'] ?? ''}'),
                            ),
                            if (dateMaintenance != null)
                              ListTile(
                                leading: const Icon(Icons.calendar_today),
                                title: const Text('Date et heure'),
                                subtitle: Text(
                                  DateFormat('EEEE dd MMMM yyyy - HH:mm', 'fr_FR')
                                      .format(dateMaintenance),
                                ),
                              ),
                          ] else ...[
                            const Divider(),
                            const ListTile(
                              leading: Icon(Icons.directions_car),
                              title: Text('Type de service'),
                              subtitle: Text('Maintenance à domicile'),
                            ),
                            const ListTile(
                              leading: Icon(Icons.info),
                              title: Text('Information'),
                              subtitle: Text(
                                  'Un technicien vous contactera pour convenir d\'un rendez-vous'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.blue
                    ),
                    child: const Text('Payer', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPiecesDialog(BuildContext context, List<dynamic> pieces) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pièces choisies'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: pieces.length,
            itemBuilder: (context, index) {
              final piece = pieces[index];
              return ListTile(
                title: Text(piece['nom'] ?? 'Pièce ${index + 1}'),
                subtitle: Text('Type: ${piece['type']}'),
                trailing: Text('${piece['prix']} €'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}