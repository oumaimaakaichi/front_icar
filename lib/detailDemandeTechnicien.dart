import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class DemandeDetailPage extends StatefulWidget {
  final Map<String, dynamic> demande;

  const DemandeDetailPage({Key? key, required this.demande}) : super(key: key);

  @override
  _DemandeDetailPageState createState() => _DemandeDetailPageState();
}

class _DemandeDetailPageState extends State<DemandeDetailPage> {
  final _storage = const FlutterSecureStorage();
  String? _meetLink;
  int? _idFlux;
  bool _isGeneratingLink = false;
  bool _fluxDemandeEnvoye = false;
  bool? _partageAvecClient;
  bool? _ouvertureMeet;
  bool? _EnvoyerAuClient;
  bool? _hasDemandeFlux;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMeetLink();
  }
  bool _convertToBool(dynamic value) {
    if (value == null) return false;

    if (value is bool) return value;

    if (value is int) return value == 1;

    if (value is String) {
      if (value == '1' || value.toLowerCase() == 'true') return true;
      if (value == '0' || value.toLowerCase() == 'false') return false;
    }

    return false; // Par défaut, si le format n'est pas reconnu
  }
  Future<void> _fetchMeetLink() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.17:8000/api/flux-par-demande/${widget.demande['id']}'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _meetLink = data['lien_meet'];
          _ouvertureMeet = data['ouvert'];
          _idFlux = data['id_flux'];
          _hasDemandeFlux = data['has_demande_flux'];
        });

        if (_idFlux != null) {
          await _fetchPartageStatus();
        }
      }
    } catch (e) {
      debugPrint('Error fetching meet link: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  Future<void> _fermerFlux() async {
    if (_idFlux == null) return;

    setState(() => _isGeneratingLink = true);

    try {
      final response = await http.put(
        Uri.parse('http://192.168.1.17:8000/api/flux-direct/$_idFlux/fermer'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _showSuccessSnack('Flux fermé avec succès');
        setState(() {
          // Mettez à jour l'état local si nécessaire
        });
        await _fetchMeetLink(); // Rafraîchir les données
      } else {
        _showErrorSnack('Échec de la fermeture du flux');
      }
    } catch (e) {
      _showErrorSnack('Erreur: ${e.toString()}');
    } finally {
      setState(() => _isGeneratingLink = false);
    }
  }
  Future<void> _fetchPartageStatus() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.17:8000/api/demande-flux/by-flux/$_idFlux'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _partageAvecClient = _convertToBool(data['data']['permission']);
          _EnvoyerAuClient = _convertToBool(data['data']['partage_with_client']);
        });
      }
    } catch (e) {
      debugPrint('Erreur fetchPartageStatus: $e');
    }
  }



  Future<void> _autoriserPartage() async {
    try {
      print(_idFlux);
      final response = await http.put(
        Uri.parse('http://192.168.1.17:8000/api/autoriser-partage/$_idFlux'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _showSuccessSnack('demande de partage envoyé au client');
        await _fetchPartageStatus();
      } else {
        _showErrorSnack('Échec de l\'autorisation de partage.');
      }
    } catch (e) {
      _showErrorSnack('Erreur: ${e.toString()}');
    }
  }

  Future<void> _generateOrOpenMeetLink() async {
    if (_isGeneratingLink) return;

    if (_meetLink != null && _meetLink!.isNotEmpty) {
      await _launchMeetLink(_meetLink!);
      return;
    }

    setState(() => _isGeneratingLink = true);

    try {
      final userDataJson = await _storage.read(key: 'user_data');
      final userId = jsonDecode(userDataJson!)['id'];

      final generatedLink = 'https://meet.jit.si/icar-${widget.demande['id']}';

      final response = await http.post(
        Uri.parse('http://192.168.1.17:8000/api/flux-direct'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'demande_id': widget.demande['id'],
          'technicien_id': userId,
          'lien_meet': generatedLink,
        }),
      );

      if (response.statusCode == 201) {
        setState(() {
          _meetLink = generatedLink;
        });
        await _launchMeetLink(generatedLink);
      } else {
        throw Exception('Erreur API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showErrorSnack('Erreur: ${e.toString()}');
    } finally {
      setState(() => _isGeneratingLink = false);
    }
  }

  Future<void> _demanderFluxAvecClient() async {
    if (_isGeneratingLink || _idFlux == null) return;

    setState(() => _isGeneratingLink = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.17:8000/api/demande-flux/'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_flux': _idFlux,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        setState(() {
          _fluxDemandeEnvoye = true;
        });
        _showSuccessSnack('Demande de flux envoyée a expert');
        await _fetchPartageStatus();
      } else {
        _showErrorSnack('Échec de la demande: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnack('Erreur: ${e.toString()}');
      debugPrint('Erreur détaillée: $e');
    } finally {
      setState(() => _isGeneratingLink = false);
    }
  }

  Future<void> _launchMeetLink(String link) async {
    try {
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await Clipboard.setData(ClipboardData(text: link));
        _showErrorSnack('Lien copié dans le presse-papier: $link');
      }
    } catch (e) {
      _showErrorSnack('Impossible d\'ouvrir le lien. Erreur: ${e.toString()}');
    }
  }

  void _showSuccessSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        )
    );
    }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final demande = widget.demande;
    final dateFormat = DateFormat('dd/MM/yyyy');
    DateTime? dateMaintenance = demande['date_maintenance'] != null
        ? DateTime.parse(demande['date_maintenance'])
        : null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Détails de la demande', style: TextStyle(color: Colors.white)),
        backgroundColor:  Color(0xFF6C5CE7),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,

      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with service title and status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),

              child: Row(

                children: [

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text(
                          demande['service']['titre'] ?? 'Service',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),

                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(demande['status']).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(demande['status']),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      demande['status'] ?? '',
                      style: TextStyle(
                        color: _getStatusColor(demande['status']),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Client Information Section
            _buildSectionTitle('Informations du client'),
            _buildInfoCard(
              children: [
                _buildInfoRow(
                  icon: Icons.person_outline,
                  title: 'Client',
                  value: '${demande['client']['prenom']} ${demande['client']['nom']}',
                ),
                _buildDivider(),
                _buildInfoRow(
                  icon: Icons.phone_android_outlined,
                  title: 'Téléphone',
                  value: demande['client']['phone'],
                ),
                _buildDivider(),
                _buildInfoRow(
                  icon: Icons.email_outlined,
                  title: 'phone',
                  value: demande['client']['phone'] ?? 'Non spécifié',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Vehicle Information Section
            _buildSectionTitle('Informations du véhicule'),
            _buildInfoCard(
              children: [
                _buildInfoRow(
                  icon: Icons.directions_car_outlined,
                  title: 'Marque & Modèle',
                  value: '${demande['voiture']['company']} ${demande['voiture']['model']}',
                ),
                _buildDivider(),
                _buildInfoRow(
                  icon: Icons.confirmation_number_outlined,
                  title: 'Numéro de série',
                  value: demande['voiture']['serie'].toString(),
                ),
                _buildDivider(),
                _buildInfoRow(
                  icon: Icons.date_range_outlined,
                  title: 'Année',
                  value: demande['voiture']['year'] ?? 'Non spécifiée',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Intervention Details
            _buildSectionTitle('Détails de l\'intervention'),
            _buildInfoCard(
              children: [
                if (dateMaintenance != null)
                  Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.calendar_today_outlined,
                        title: 'Date',
                        value: dateFormat.format(dateMaintenance),
                      ),
                      _buildDivider(),
                      _buildInfoRow(
                        icon: Icons.access_time_outlined,
                        title: 'Heure',
                        value: demande['heure_maintenance'] ?? 'Non spécifiée',
                      ),
                      _buildDivider(),
                    ],
                  ),
                _buildInfoRow(
                  icon: Icons.location_on_outlined,
                  title: 'Emplacement',
                  value: demande['type_emplacement'] ?? 'Non spécifié',
                ),
                if (demande['description'] != null) ...[
                  _buildDivider(),
                  _buildInfoRow(
                    icon: Icons.description_outlined,
                    title: 'Description',
                    value: demande['description'],
                    isMultiLine: true,
                  ),
                ],
              ],
            ),

            const SizedBox(height: 20),

            // Video Conference Section
            _buildSectionTitle('Visioconférence'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Flux direct avec client et expert',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_meetLink != null)
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.red.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.red,
                            ),
                          ),
                          onPressed: () {
                            // Ajoutez ici la logique pour fermer le flux

                          },
                          tooltip: 'Fermer le flux',
                          splashRadius: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _isGeneratingLink
                        ? null
                        : () {
                      if (_meetLink != null) {
                        _launchMeetLink(_meetLink!);
                      } else {
                        _generateOrOpenMeetLink();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _meetLink != null
                            ? Colors.green.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                        border: Border.all(
                          color: _meetLink != null ? Colors.green : Colors.blue,
                          width: 2,
                        ),
                      ),
                      child: _isGeneratingLink
                          ? const CircularProgressIndicator()
                          : Icon(
                        _meetLink != null ? Icons.videocam : Icons.videocam_off,
                        size: 40,
                        color: _meetLink != null ? Colors.green : Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_meetLink != null)
                    Text(
                      _meetLink!,
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 16),
                  if (_meetLink != null && _hasDemandeFlux == false)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _idFlux == null ? null : _demanderFluxAvecClient,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: _isGeneratingLink
                            ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text("Envoi en cours..."),
                          ],
                        )
                            : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, size: 18 , color:Colors.white),
                            SizedBox(width: 8),
                            Text("Demander flux avec client" , style:TextStyle(color:Colors.white)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Partage Section
            if (_partageAvecClient == true)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Partage avec client',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.share,
                          color: Colors.blue[800],
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Partage avec le client',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        Switch(
                          value: _EnvoyerAuClient ?? false,
                          onChanged: (value) {
                            if (value) {
                              _autoriserPartage();
                            }
                          },
                          activeColor: Colors.blue[800],
                        ),
                      ],
                    ),
                    if (_EnvoyerAuClient == false)
                      ElevatedButton.icon(
                        onPressed: _autoriserPartage,
                        icon: const Icon(Icons.share, color: Colors.white),
                        label: const Text('Partager', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),



                    if (_partageAvecClient == true && _ouvertureMeet == true)
                      const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _fermerFlux,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: _isGeneratingLink
                            ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text("Fermeture en cours..."),
                          ],
                        )
                            : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close, size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text("Fermer le flux", style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    bool isMultiLine = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blue[800], size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey[200],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'en cours':
        return Colors.orange;
      case 'assignée':
        return Colors.green;
      case 'annulé':
        return Colors.red;
      case 'en attente':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}