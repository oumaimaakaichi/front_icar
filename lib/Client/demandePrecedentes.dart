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
  Map<int, String?> meetLinks = {}; // Cache pour stocker les liens Meet par demande_id
  Map<int, bool> meetLinkStatus = {}; // Cache pour stocker l'état de partage

  @override
  void initState() {
    super.initState();
    fetchDemandes();
  }

  Future<void> fetchDemandes() async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors du chargement des demandes')),
      );
    }
  }

  Future<void> checkMeetLinkAvailability(int demandeId) async {
    try {
      final url = Uri.parse('http://192.168.1.17:8000/api/demandes/$demandeId/meet-link');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        meetLinks[demandeId] = data['lien_meet'];

        // Handle both int (0/1) and bool (true/false) cases
        if (data['partage_with_client'] is int) {
          meetLinkStatus[demandeId] = data['partage_with_client'] == 1;
        } else {
          meetLinkStatus[demandeId] = data['partage_with_client'] ?? false;
        }

        setState(() {
          meetLinks[demandeId] = data['lien_meet'];
          meetLinkStatus[demandeId] = data['partage_with_client'] == 1; // or the appropriate conversion
        });
      }
    } catch (e) {
      print('Erreur lors de la récupération du lien Meet: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes avec technicien'),
        backgroundColor: Colors.grey[200],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : demandes.isEmpty
          ? const Center(child: Text('Aucune demande trouvée'))
          : RefreshIndicator(
        onRefresh: fetchDemandes,
        child: ListView.builder(
          itemCount: demandes.length,
          itemBuilder: (context, index) {
            final demande = demandes[index];
            final voiture = demande['voiture'];
            final service = demande['service_panne'];
            final techniciens = demande['techniciens'] as List<dynamic>? ?? [];
            final demandeId = demande['id'];
            final meetLink = meetLinks[demandeId];
            final isShared = meetLinkStatus[demandeId] ?? false;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 4,
              child: InkWell(
                onTap: () => _navigateToDetailsPage(context, demande),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.directions_car, size: 40, color: Colors.lightBlue),
                                const SizedBox(height: 8),
                                Text(
                                  voiture?['model'] ?? 'Modèle inconnu',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service?['titre'] ?? 'Service inconnu',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Technicien(s):',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    if (techniciens.isEmpty)
                                      const Text('Aucun technicien', style: TextStyle(fontSize: 14, color: Colors.black54)),
                                    ...techniciens.map<Widget>((t) => Text(
                                      '- ${t['nom'] ?? 'Nom non spécifié'}',
                                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                                    )),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Date: ${demande['created_at'] ?? ''}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (isShared && meetLink != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.video_call, size: 20),
                            label: const Text('' ,style: TextStyle(fontSize: 15),),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(10, 20),
                            ),
                            onPressed: () => _launchMeetUrl(meetLink),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _launchMeetUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir le lien: $url')),
      );
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

  String _formatDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return '${date.year.toString().padLeft(4, '0')}:${date.month.toString().padLeft(2, '0')}:${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _launchMeetUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Impossible d\'ouvrir le lien: $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiture = demande['voiture'];
    final service = demande['service_panne'];
    final techniciens = demande['techniciens'] as List<dynamic>? ?? [];
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la demande' ,style: TextStyle(color:Colors.white),),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blueGrey,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    isDarkMode ? Colors.blueGrey[700]! : Colors.blue[100]!,
                    isDarkMode ? Colors.blueGrey[600]! : Colors.lightBlue[50]!,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDarkMode ? Colors.blue[300] : Colors.blue[500],
                    ),
                    child: const Icon(Icons.assignment, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Demande #${demande['id'] ?? ''}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Statut: ${demande['statut'] ?? 'En cours'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDarkMode ? Colors.white70 : Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Service Section
            _buildSection(
              context,
              title: 'Services demandés',
              icon: Icons.build_circle_outlined,
              children: [
                _buildDetailItem(
                  context,
                  icon: Icons.handyman,
                  title: 'Type de service',
                  value: service?['titre'] ?? 'Non spécifié',
                ),
                if (service?['description'] != null)
                  _buildDetailItem(
                    context,
                    icon: Icons.description,
                    title: 'Description',
                    value: service?['description'],
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // Vehicle Section
            _buildSection(
              context,
              title: 'Véhicule',

              icon: Icons.directions_car_filled,
              children: [
                _buildDetailItem(
                  context,
                  icon: Icons.branding_watermark,
                  title: 'Modèle',
                  value: '${voiture?['marque'] ?? ''} ${voiture?['model'] ?? ''}',
                ),
                _buildDetailItem(
                  context,
                  icon: Icons.confirmation_number,
                  title: 'Série',
                  value: voiture?['serie'].toString() ?? 'Non spécifiée',
                ),

              ],
            ),

            const SizedBox(height: 24),

            // Appointment Section
            _buildSection(
              context,
              title: 'Rendez-vous',
              icon: Icons.calendar_month,
              children: [
                _buildDetailItem(
                  context,
                  icon: Icons.date_range,
                  title: 'Date',
                  value: demande['date_maintenance'] != null
                      ? _formatDate(demande['date_maintenance'])
                      : 'Non spécifiée',
                ),
                _buildDetailItem(
                  context,
                  icon: Icons.access_time_filled,
                  title: 'Heure',
                  value: demande['heure_maintenance'] ?? 'Non spécifiée',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Technicians Section
            _buildSection(
              context,
              title: 'Techniciens assignés',
              icon: Icons.engineering,
              children: [
                if (techniciens.isEmpty)
                  _buildDetailItem(
                    context,
                    icon: Icons.info,
                    title: 'Information',
                    value: 'Aucun technicien assigné',
                  ),
                ...techniciens.map((tech) => _buildTechnicianCard(context, tech)),
              ],
            ),

            // Video Conference Section
            if (isShared && meetLink != null) ...[
              const SizedBox(height: 24),
              _buildVideoConferenceSection(context),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDarkMode ? Colors.blueGrey[800] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDarkMode ? Colors.blue[300] : Colors.blue[500],
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.blue[900],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color: isDarkMode ? Colors.blue[200] : Colors.blue[600],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDarkMode ? Colors.white70 : Colors.blueGrey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianCard(BuildContext context, dynamic technician) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDarkMode ? Colors.blueGrey[700] : Colors.blue[50],
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDarkMode ? Colors.blue[300] : Colors.blue[100],
          ),
          child: Icon(
            Icons.person,
            size: 30,
            color: isDarkMode ? Colors.white : Colors.blue[600],
          ),
        ),
        title: Text(
          technician['nom'] ?? 'Technicien',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.blue[900],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (technician['specialite'] != null)
              Text(
                technician['specialite'],
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? Colors.white70 : Colors.blueGrey[700],
                ),
              ),
            if (technician['experience'] != null)
              Text(
                'Expérience: ${technician['experience']} ans',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDarkMode ? Colors.white60 : Colors.blueGrey[600],
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.message,
            color: isDarkMode ? Colors.blue[200] : Colors.blue[600],
          ),
          onPressed: () {
            // Handle message action
          },
        ),
      ),
    );
  }

  Widget _buildVideoConferenceSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            isDarkMode ? Colors.teal[800]! : Colors.teal[100]!,
            isDarkMode ? Colors.teal[700]! : Colors.teal[50]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDarkMode ? Colors.teal[300] : Colors.teal[500],
                  ),
                  child: const Icon(Icons.videocam, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  'Visioconférence',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.teal[900],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Rejoignez la réunion en cliquant sur le bouton ci-dessous',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? Colors.white70 : Colors.teal[800],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: () => _launchMeetUrl(meetLink!),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDarkMode ? Colors.teal[600] : Colors.teal[500],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        meetLink!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.video_call),
                label: const Text('Rejoindre maintenant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                onPressed: () => _launchMeetUrl(meetLink!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}