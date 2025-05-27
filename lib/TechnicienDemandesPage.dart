import 'package:car_mobile/detailDemandeTechnicien.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class DemandesTechnicienPage extends StatefulWidget {
  const DemandesTechnicienPage({super.key});

  @override
  _TechnicienDemandesPageState createState() => _TechnicienDemandesPageState();
}

class _TechnicienDemandesPageState extends State<DemandesTechnicienPage> {
  final _storage = const FlutterSecureStorage();
  List<dynamic> _demandes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDemandes();
  }
  Future<void> _showPiecesDialog(BuildContext context, List<dynamic> pieces) async {
    try {
      // Récupérer les catalogues depuis l'API
      final response = await http.get(
        Uri.parse('http://192.168.1.17:8000/api/catalogues'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors du chargement du catalogue');
      }

      final catalogues = jsonDecode(response.body);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Détails des pièces'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: pieces.length,
              itemBuilder: (context, index) {
                final piece = pieces[index];

                // Trouver la pièce correspondante dans le catalogue
                final catalogueMatch = catalogues.firstWhere(
                      (c) => c['id'] == piece['piece_id'],
                  orElse: () => null,
                );

                final nomPiece = catalogueMatch != null
                    ? catalogueMatch['nom_piece']
                    : piece['nom_piece'] ?? 'Pièce ${index + 1}';

                return ListTile(
                  title: Text(nomPiece),
                  subtitle: Text('Type: ${piece['type'] ?? 'Inconnu'}'),
                  trailing: Text('${piece['prix'] ?? '0'} €'),
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
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erreur'),
          content: Text('Impossible de charger les détails des pièces : $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
  Future<void> _fetchDemandes() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final userDataJson = await _storage.read(key: 'user_data');
      final userData = jsonDecode(userDataJson!);
      final technicienId = userData['id'];

      final response = await http.get(
        Uri.parse('http://192.168.1.17:8000/api/demandes/technicien/$technicienId'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _demandes = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des demandes';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'assignée':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      case 'en cours':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'terminée':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      default:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDemandeCard(Map<String, dynamic> demande) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    DateTime? dateMaintenance;
    if (demande['date_maintenance'] != null) {
      dateMaintenance = DateTime.parse(demande['date_maintenance']);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Action lorsqu'on clique sur la carte
        },
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
                      demande['service']['titre'] ?? 'Service non spécifié',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(demande['status'] ?? 'Non spécifié'),
                ],
              ),

              const SizedBox(height: 8),

              // Section Client
              _buildInfoSection(
                icon: Icons.person,
                title: 'Client',
                content: '${demande['client']['prenom']} ${demande['client']['nom']}\n'
                    'Tél: ${demande['client']['phone']}',
              ),

              const Divider(height: 24, thickness: 1),

              // Section Voiture
              _buildInfoSection(
                icon: Icons.directions_car,
                title: 'Véhicule',
                content: '${demande['voiture']['company']} ${demande['voiture']['model']}\n'
                    'Série: ${demande['voiture']['serie']}\n'
                    'Année: ${demande['voiture']['date_fabrication']}',
              ),

              const Divider(height: 24, thickness: 1),

              // Section Intervention
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Intervention',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateMaintenance != null
                              ? '${dateFormat.format(dateMaintenance)} à ${demande['heure_maintenance']}'
                              : 'Date non spécifiée',
                          style: const TextStyle(fontSize: 15),
                        ),
                        Text(
                          'Type: ${demande['type_emplacement']}',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Pièces choisies
              // Pièces choisies
              if (demande['pieces_choisies'] != null && demande['pieces_choisies'].isNotEmpty) ...[
                const Divider(height: 24, thickness: 1),
                Row(
                  children: [
                    const Text(
                      'Pièces à utiliser:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _showPiecesDialog(context, demande['pieces_choisies']),
                      child: const Text('Voir détails'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: demande['pieces_choisies'].map<Widget>((piece) {
                    return Chip(
                      backgroundColor: Colors.blueGrey.shade50,
                      label: Text(
                        piece['type'] ?? 'Type inconnu',
                        style: const TextStyle(fontSize: 13),
                      ),
                      avatar: Icon(
                        Icons.settings,
                        size: 16,
                        color: Colors.blueGrey.shade700,
                      ),
                    );
                  }).toList(),
                ),
              ],
              // Boutons d'action
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Détails'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DemandeDetailPage(demande: demande),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.assignment_turned_in, size: 18),
                      label: const Text('Commencer'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        // Action pour commencer l'intervention
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Interventions' , style: TextStyle(
          color: Colors.white,
          fontFamily: 'Roboto', // Remplace par ta police si elle est bien ajoutée dans pubspec.yaml
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),),
        backgroundColor: Colors.blueGrey,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: _fetchDemandes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDemandes,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      )
          : _demandes.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/empty.png',
              height: 150,
              width: 150,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune intervention assignée',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vous n\'avez aucune intervention programmée pour le moment',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchDemandes,
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          itemCount: _demandes.length,
          itemBuilder: (context, index) {
            return _buildDemandeCard(_demandes[index]);
          },
        ),
      ),
    );
  }
}