import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class DemandesAvecTechnicienPage extends StatefulWidget {
  final int userId;
  const DemandesAvecTechnicienPage({super.key, required this.userId});

  @override
  _DemandesAvecTechnicienPageState createState() => _DemandesAvecTechnicienPageState();
}

class _DemandesAvecTechnicienPageState extends State<DemandesAvecTechnicienPage> {
  List<dynamic> demandes = [];
  bool isLoading = true;
  Map<int, String?> meetLinks = {};
  Map<int, bool> meetLinkStatus = {};

  @override
  void initState() {
    super.initState();
    fetchDemandes();
  }

  Future<void> fetchDemandes() async {
    try {
      final url = Uri.parse('http://192.168.1.17:8000/api/demandes/user/${widget.userId}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          demandes = json.decode(response.body);
          isLoading = false;
        });

        // Précharger les liens Meet pour chaque demande
        for (var demande in demandes) {
          await checkMeetLinkAvailability(demande['id']);
        }
      } else {
        setState(() {
          isLoading = false;
        });
        _showSnackBar('Erreur lors du chargement des demandes', isError: true);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Erreur de connexion', isError: true);
    }
  }

  Future<void> checkMeetLinkAvailability(int demandeId) async {
    try {
      final url = Uri.parse('http://192.168.1.17:8000/api/demandes/$demandeId/meet-link');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          meetLinks[demandeId] = data['lien_meet'];
          meetLinkStatus[demandeId] = data['partage_with_client'] == 1 ||
              data['partage_with_client'] == true;
        });
      }
    } catch (e) {
      print('Erreur lors de la récupération du lien Meet: $e');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _navigateToDetailsPage(BuildContext context, dynamic demande) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DemandeDetailsPage(
          demande: demande,
          meetLink: meetLinks[demande['id']],
          isShared: meetLinkStatus[demande['id']] ?? false,
        ),
      ),
    );
  }

  String _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'terminé':
      case 'completed':
        return 'green';
      case 'en cours':
      case 'in_progress':
        return 'orange';
      case 'en attente':
      case 'pending':
        return 'blue';
      default:
        return 'grey';
    }
  }

  Color _getStatusBgColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'terminé':
      case 'completed':
        return Colors.green[100]!;
      case 'en cours':
      case 'in_progress':
        return Colors.orange[100]!;
      case 'en attente':
      case 'pending':
        return Colors.blue[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'terminé':
      case 'completed':
        return Colors.green[800]!;
      case 'en cours':
      case 'in_progress':
        return Colors.orange[800]!;
      case 'en attente':
      case 'pending':
        return Colors.blue[800]!;
      default:
        return Colors.grey[800]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Mes Demandes',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[200],
            height: 1,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 16),
            Text(
              'Chargement des demandes...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      )
          : demandes.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: fetchDemandes,
        color: Colors.blue,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: demandes.length,
          itemBuilder: (context, index) {
            final demande = demandes[index];
            return _buildDemandeCard(demande);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune demande trouvée',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos demandes de maintenance\napparaîtront ici',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemandeCard(dynamic demande) {
    final voiture = demande['voiture'];
    final service = demande['service_panne'];
    final techniciens = demande['techniciens'] as List<dynamic>? ?? [];
    final demandeId = demande['id'];
    final meetLink = meetLinks[demandeId];
    final isShared = meetLinkStatus[demandeId] ?? false;
    final status = demande['statut'] ?? 'En attente';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToDetailsPage(context, demande),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec statut
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusBgColor(status),
                        borderRadius: BorderRadius.circular(20),
                      ),

                    ),
                    const Spacer(),
                    if (isShared && meetLink != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.videocam,
                          size: 16,
                          color: Colors.green[600],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Contenu principal
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icône véhicule
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.directions_car,
                        size: 32,
                        color: Colors.blue[600],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Informations
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service?['titre'] ?? 'Service non spécifié',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Icon(
                                Icons.directions_car_outlined,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${voiture?['marque'] ?? ''} ${voiture?['model'] ?? 'Modèle inconnu'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          Row(
                            children: [
                              Icon(
                                Icons.engineering,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  techniciens.isEmpty
                                      ? 'Aucun technicien assigné'
                                      : '${techniciens.length} technicien${techniciens.length > 1 ? 's' : ''} assigné${techniciens.length > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatDateForCard(demande['created_at']),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Bouton Meet si disponible

              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateForCard(String? dateStr) {
    if (dateStr == null) return 'Date non spécifiée';
    try {
      DateTime date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _launchMeetUrl(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        _showSnackBar('Impossible d\'ouvrir le lien de visioconférence', isError: true);
      }
    } catch (e) {
      _showSnackBar('Erreur lors de l\'ouverture du lien', isError: true);
    }
  }
}

class DemandeDetailsPage extends StatelessWidget {
  final dynamic demande;
  final String? meetLink;
  final bool isShared;

  const DemandeDetailsPage({
    super.key,
    required this.demande,
    this.meetLink,
    required this.isShared,
  });

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Non spécifiée';
    try {
      DateTime date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr ?? 'Non spécifiée';
    }
  }

  Future<void> _launchMeetUrl(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      print('Erreur lors de l\'ouverture du lien: $e');
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'terminé':
      case 'completed':
        return Colors.green;
      case 'en cours':
      case 'in_progress':
        return Colors.orange;
      case 'en attente':
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiture = demande['voiture'];
    final service = demande['service_panne'];
    final techniciens = demande['techniciens'] as List<dynamic>? ?? [];
    final status = demande['statut'] ?? 'En attente';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Demande ${demande['id']}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[200],
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            _buildStatusHeader(status),

            const SizedBox(height: 24),

            // Section Service
            _buildSection(
              title: 'Service demandé',
              icon: Icons.build_circle,
              color: Colors.blue,
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.handyman,
                    label: 'Type de service',
                    value: service?['titre'] ?? 'Non spécifié',
                  ),
                  if (service?['description'] != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.description,
                      label: 'Description',
                      value: service['description'],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section Véhicule
            _buildSection(
              title: 'Véhicule',
              icon: Icons.directions_car,
              color: Colors.green,
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.branding_watermark,
                    label: 'Modèle',
                    value: '${voiture?['marque'] ?? ''} ${voiture?['model'] ?? 'Non spécifié'}',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.confirmation_number,
                    label: 'Série',
                    value: voiture?['serie']?.toString() ?? 'Non spécifiée',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section Rendez-vous
            _buildSection(
              title: 'Rendez-vous',
              icon: Icons.calendar_today,
              color: Colors.orange,
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.date_range,
                    label: 'Date',
                    value: _formatDate(demande['date_maintenance']),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.access_time,
                    label: 'Heure',
                    value: demande['heure_maintenance'] ?? 'Non spécifiée',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section Techniciens
            _buildSection(
              title: 'Techniciens assignés',
              icon: Icons.engineering,
              color: Colors.purple,
              child: techniciens.isEmpty
                  ? _buildDetailRow(
                icon: Icons.info_outline,
                label: 'Information',
                value: 'Aucun technicien assigné pour le moment',
              )
                  : Column(
                children: techniciens
                    .map((tech) => _buildTechnicianCard(tech))
                    .toList(),
              ),
            ),

            // Section Visioconférence
            if (isShared && meetLink != null) ...[
              const SizedBox(height: 20),
              _buildVideoConferenceSection(),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.assignment,
              size: 30,
              color: _getStatusColor(status),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statut de la demande',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicianCard(dynamic technician) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.purple[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 24,
              color: Colors.purple[600],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  technician['nom'] ?? 'Technicien',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (technician['specialite'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    technician['specialite'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                if (technician['experience'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Expérience: ${technician['experience']} ans',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.message_outlined,
              color: Colors.purple[600],
            ),
            onPressed: () {
              // Action pour envoyer un message
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVideoConferenceSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal[400]!, Colors.teal[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.video_call,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Visioconférence disponible',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            const Text(
              'Rejoignez la réunion avec votre technicien pour un accompagnement personnalisé.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.video_call, size: 24),
                label: const Text(
                  'Rejoindre maintenant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.teal[600],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _launchMeetUrl(meetLink!),
              ),
            ),

            const SizedBox(height: 12),

            InkWell(
              onTap: () => _launchMeetUrl(meetLink!),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.link,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        meetLink!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.open_in_new,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}