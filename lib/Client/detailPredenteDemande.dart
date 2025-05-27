import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DemandeDetailsPagee extends StatelessWidget {
  final dynamic demande;
  final int userId;

  const DemandeDetailsPagee({
    super.key,
    required this.demande,
    required this.userId,
  });

  Future<void> _launchMeetUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Impossible d\'ouvrir le lien: $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiture = demande['voiture'];
    final service = demande['service_panne'];
    final techniciens = demande['techniciens'] as List<dynamic>? ?? [];
    final flux = demande['flux_direct'];
    final demandeFlux = flux != null ? flux['demande_flux'] : null;
    final isShared = demandeFlux != null && demandeFlux['partage_with_client'] == true;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Détails Intervention',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue[50],
                    ),
                    child: Icon(
                      Icons.car_repair,
                      color: Colors.blue[600],
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Intervention en cours',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Demande #${demande['id'] ?? '000'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Active',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.green[400],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Main Content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Vehicle Card
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.directions_car, color: Colors.blue[600]),
                            SizedBox(width: 8),
                            Text(
                              'Véhicule',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildDetailItem(
                          'Modèle',
                          '${voiture?['marque'] ?? ''} ${voiture?['model'] ?? ''}',
                        ),
                        _buildDetailItem(
                          'Immatriculation',
                          voiture?['immatriculation'] ?? 'Non spécifiée',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Service Card
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.build, color: Colors.orange[600]),
                            SizedBox(width: 8),
                            Text(
                              'Service',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildDetailItem(
                          'Type de service',
                          service?['titre'] ?? 'Non spécifié',
                        ),
                        _buildDetailItem(
                          'Description',
                          service?['description'] ?? 'Aucune description',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Appointment Card
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.purple[600]),
                            SizedBox(width: 8),
                            Text(
                              'Rendez-vous',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildDetailItem(
                          'Date',
                          demande['date_maintenance'] ?? 'Non spécifiée',
                        ),
                        _buildDetailItem(
                          'Heure',
                          demande['heure_maintenance'] ?? 'Non spécifiée',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Technicians Card
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.engineering, color: Colors.red[600]),
                            SizedBox(width: 8),
                            Text(
                              'Techniciens',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        if (techniciens.isEmpty)
                          _buildDetailItem(
                            'Assignation',
                            'Aucun technicien assigné',
                          ),
                        ...techniciens.map((t) => _buildDetailItem(
                          t['nom'] ?? 'Nom non spécifié',
                          t['specialite'] ?? 'Spécialité non spécifiée',
                        )),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Video Conference
                  if (isShared) ...[
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Colors.blue[600]!, Colors.blue[400]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.videocam, color: Colors.white),
                              SizedBox(width: 12),
                              Text(
                                'Visioconférence',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.link, color: Colors.white),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    flux['lien_meet'],
                                    style: TextStyle(
                                      color: Colors.white,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue[600],
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () => _launchMeetUrl(flux['lien_meet']),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.video_call),
                                SizedBox(width: 8),
                                Text(
                                  'Rejoindre maintenant',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: child,
    );
  }

  Widget _buildDetailItem(String title, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}