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

class _TechnicienDemandesPageState extends State<DemandesTechnicienPage>
    with TickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();
  List<dynamic> _demandes = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<int, dynamic> _rapportsCache = {};
  late AnimationController _animationController;
  Animation<double>? _fadeAnimation; // Made nullable and will be initialized properly
  String _selectedFilter = 'Toutes';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchDemandes();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchRapportForDemande(int demandeId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse('http://192.168.1.11:8000/api/rapport-maintenance/demande/$demandeId'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final rapport = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _rapportsCache[demandeId] = rapport;
          });
        }
      } else if (response.statusCode != 404) {
        throw Exception('Erreur lors du chargement du rapport');
      }
    } catch (e) {
      print('Erreur lors de la récupération du rapport: $e');
    }
  }

  Future<void> _fetchDemandes() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final token = await _storage.read(key: 'auth_token');
      final userDataJson = await _storage.read(key: 'user_data');
      final userData = jsonDecode(userDataJson!);
      final technicienId = userData['id'];

      final response = await http.get(
        Uri.parse('http://192.168.1.11:8000/api/demandes/technicien/$technicienId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final demandes = jsonDecode(response.body);

        for (var demande in demandes) {
          if (demande['id'] != null) {
            await _fetchRapportForDemande(demande['id']);
          }
        }

        if (mounted) {
          setState(() {
            _demandes = demandes;
            _isLoading = false;
          });
          _animationController.forward();
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Erreur lors du chargement des demandes';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de connexion: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> get _filteredDemandes {
    if (_selectedFilter == 'Toutes') return _demandes;
    return _demandes.where((d) => d['status']?.toLowerCase() == _selectedFilter.toLowerCase()).toList();
  }

  Future<void> _showPiecesDialog(BuildContext context, List<dynamic> pieces) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse('http://192.168.1.11:8000/api/catalogues'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors du chargement du catalogue');
      }

      final catalogues = jsonDecode(response.body);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 500),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A73E8).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.build_circle_outlined,
                          color: Color(0xFF1A73E8),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Pièces requises',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: pieces.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final piece = pieces[index];
                        final catalogueMatch = catalogues.firstWhere(
                              (c) => c['id'] == piece['piece_id'],
                          orElse: () => null,
                        );

                        final nomPiece = catalogueMatch != null
                            ? catalogueMatch['nom_piece']
                            : piece['nom_piece'] ?? 'Pièce ${index + 1}';

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1A73E8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nomPiece,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Color(0xFF2D3748),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Type: ${piece['type'] ?? 'Inconnu'}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Text(
                                  '${piece['prix'] ?? '0'} €',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context, 'Impossible de charger les détails des pièces : $e');
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade600),
              const SizedBox(width: 8),
              const Text('Erreur'),
            ],
          ),
          content: Text(message),
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
    IconData icon;

    switch (status.toLowerCase()) {
      case 'assignée':
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        icon = Icons.assignment_outlined;
        break;
      case 'en cours':
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        icon = Icons.work_outline;
        break;
      case 'terminée':
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle_outline;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Toutes', 'Assignée', 'En cours', 'Terminée'];

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (mounted) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                }
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF1A73E8).withOpacity(0.1),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF1A73E8) : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? const Color(0xFF1A73E8) : Colors.grey.shade300,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDemandeCard(Map<String, dynamic> demande, int index) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    DateTime? dateMaintenance;
    if (demande['date_maintenance'] != null) {
      dateMaintenance = DateTime.parse(demande['date_maintenance']);
    }

    final hasRapport = _rapportsCache.containsKey(demande['id']);

    // Check if animation is ready before using it
    if (_fadeAnimation == null) {
      return Container(); // Return empty container if animation not ready
    }

    return FadeTransition(
      opacity: _fadeAnimation!,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 1.0),
            ((index * 0.1) + 0.5).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        )),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DemandeDetailPage(demande: demande),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header avec titre et statut
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                demande['service']['titre'] ?? 'Service non spécifié',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),

                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildStatusBadge(demande['status'] ?? 'Non spécifié'),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Informations client
                    _buildInfoRow(
                      icon: Icons.person_outline,
                      iconColor: Colors.blue.shade600,
                      title: 'Client',
                      content: '${demande['client']['prenom']} ${demande['client']['nom']}',
                      subtitle: 'Tél: ${demande['client']['phone']}',
                    ),

                    const SizedBox(height: 20),

                    // Informations intervention
                    _buildInfoRow(
                      icon: Icons.calendar_today_outlined,
                      iconColor: Colors.orange.shade600,
                      title: 'Intervention',
                      content: dateMaintenance != null
                          ? '${dateFormat.format(dateMaintenance)} à ${demande['heure_maintenance']}'
                          : 'Date non spécifiée',
                      subtitle: 'Type: ${demande['type_emplacement']}',
                    ),

                    // Pièces si disponibles
                    if (demande['pieces_choisies'] != null && demande['pieces_choisies'].isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.build_circle_outlined,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${demande['pieces_choisies'].length} pièce(s) requise(s)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _showPiecesDialog(context, demande['pieces_choisies']),
                              icon: const Icon(Icons.visibility_outlined, size: 16),
                              label: const Text('Voir'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Boutons d'action
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.visibility_outlined, size: 18),
                            label: const Text('Détails'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.grey.shade400),
                              foregroundColor: Colors.grey.shade700,
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
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(
                              hasRapport ? Icons.description_outlined : Icons.edit_document,
                              size: 18,
                            ),
                            label: Text(hasRapport ? 'Voir rapport' : 'Créer rapport'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasRapport ? Colors.green.shade600 : const Color(0xFF1A73E8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => hasRapport
                                      ? RapportMaintenancePage(demande: demande)
                                      : AjoutRapportPage(demande: demande),
                                ),
                              );

                              if (result == true && mounted) {
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
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedFilter == 'Toutes'
                ? 'Aucune intervention assignée'
                : 'Aucune intervention ${_selectedFilter.toLowerCase()}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _selectedFilter == 'Toutes'
                ? 'Vous n\'avez aucune intervention programmée pour le moment'
                : 'Aucune intervention avec ce statut n\'est disponible',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _refreshData() {
    if (mounted) {
      _animationController.reset();
      _fetchDemandes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Mes Interventions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF73B1BD),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Rafraîchir',
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
        ),
      )
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Oups ! Une erreur s\'est produite',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          : Column(
        children: [
          const SizedBox(height: 16),
          _buildFilterChips(),
          const SizedBox(height: 16),
          Expanded(
            child: _filteredDemandes.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: () async {
                _refreshData();
              },
              color: const Color(0xFF1A73E8),
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 32),
                itemCount: _filteredDemandes.length,
                itemBuilder: (context, index) {
                  return _buildDemandeCard(_filteredDemandes[index], index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}