import 'package:car_mobile/ajout_rapport_page.dart';
import 'package:car_mobile/detailDemandeTechnicien.dart';
import 'package:car_mobile/rapport_maintenance_page.dart';
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
  Map<int, dynamic> _rapportsCache = {}; // Cache pour stocker les rapports

  @override
  void initState() {
    super.initState();
    _fetchDemandes();
  }

  Future<void> _fetchRapportForDemande(int demandeId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/rapport-maintenance/demande/$demandeId'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final rapport = jsonDecode(response.body);
        setState(() {
          _rapportsCache[demandeId] = rapport;
        });
      } else if (response.statusCode != 404) {
        throw Exception('Erreur lors du chargement du rapport');
      }
    } catch (e) {
      print('Erreur lors de la récupération du rapport: $e');
    }
  }

  Future<void> _fetchDemandes() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final userDataJson = await _storage.read(key: 'user_data');
      final userData = jsonDecode(userDataJson!);
      final technicienId = userData['id'];

      final response = await http.get(
        Uri.parse('http://localhost:8000/api/demandes/technicien/$technicienId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final demandes = jsonDecode(response.body);

        // Pour chaque demande, vérifier s'il y a un rapport
        for (var demande in demandes) {
          if (demande['id'] != null) {
            await _fetchRapportForDemande(demande['id']);
          }
        }

        setState(() {
          _demandes = demandes;
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

  Future<void> _showPiecesDialog(BuildContext context, List<dynamic> pieces) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/catalogues'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
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

    final hasRapport = _rapportsCache.containsKey(demande['id']);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        splashColor: Colors.blueGrey.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: 4,
                color: Colors.blue,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        demande['service']['titre'] ?? 'Service non spécifié',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(demande['status'] ?? 'Non spécifié'),
                  ],
                ),

                const SizedBox(height: 16),

                _buildInfoSection(
                  icon: Icons.person_outline,
                  title: 'Client',
                  content: '${demande['client']['prenom']} ${demande['client']['nom']}\n'
                      'Tél: ${demande['client']['phone']}',
                ),

                const Divider(height: 24, thickness: 1, color: Colors.grey),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: Colors.blueGrey[400],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INTERVENTION',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: Colors.blueGrey[300],
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dateMaintenance != null
                                ? '${dateFormat.format(dateMaintenance)} à ${demande['heure_maintenance']}'
                                : 'Date non spécifiée',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Type: ${demande['type_emplacement']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (demande['pieces_choisies'] != null && demande['pieces_choisies'].isNotEmpty) ...[
                  const Divider(height: 24, thickness: 1, color: Colors.grey),
                  Row(
                    children: [
                      Text(
                        'PIÈCES À UTILISER',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: Colors.blueGrey[300],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _showPiecesDialog(context, demande['pieces_choisies']),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Détails',
                              style: TextStyle(
                                color: Colors.blueGrey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: Colors.blueGrey[600],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],

                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.visibility_outlined, size: 18, color: Colors.blueGrey[600]),
                        label: Text(
                          'Détails',
                          style: TextStyle(color: Colors.blueGrey[600]),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(color: Colors.blueGrey.shade300),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(
                          hasRapport ? Icons.description : Icons.edit_document,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: Text(
                          hasRapport ? 'Voir rapport' : 'Créer rapport',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: hasRapport ? Colors.green : Colors.blueAccent,
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => hasRapport
                                  ? RapportMaintenancePage(
                                demande: demande,
                               
                              )
                                  : AjoutRapportPage(demande: demande),
                            ),
                          );

                          if (result == true) {
                            await _fetchRapportForDemande(demande['id']);
                            _fetchDemandes();
                          }
                        },
                      ),
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
        title: const Text('Mes Interventions', style: TextStyle(
          color: Colors.white,
          fontFamily: 'Roboto',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        )),
        backgroundColor:  Color(0xFF6C5CE7),
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