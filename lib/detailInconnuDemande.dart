import 'package:car_mobile/DescriptionPannePage.dart';
import 'package:car_mobile/rapportInconnuPanne.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

class DemandeDetailsPageInco extends StatefulWidget {
  final int demandeId;

  const DemandeDetailsPageInco({Key? key, required this.demandeId}) : super(key: key);

  @override
  _DemandeDetailsPageState createState() => _DemandeDetailsPageState();
}

class _DemandeDetailsPageState extends State<DemandeDetailsPageInco> with TickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();
  Map<String, dynamic>? _demande;
  bool _isLoading = true;
  String? _errorMessage;
  String? _meetLink;
  String? _meetLinkEntretient;
  int? _idFlux;
  int? _idFluxEntretirnt;
  bool _isGeneratingLink = false;
  bool _isGeneratingLinkEntretient = false;
  bool? _ouvertureMeet;
  bool? _ouvertureMeetEntretient;
  bool? _hasDemandeFlux;
  bool? _hasDemandeFluxEntretient;
  bool _isSharing = false;
  bool? _partageAvecClient;
  bool? _partageAvecClientEntretient;
  bool? _EnvoyerAuClient;
  bool? _EnvoyerAuClientEntretient;
  bool? hasPieces = false;
  bool? hasPanne = false;
  bool? hasCategories = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller first
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    // Call async methods after initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDemandeDetails();
      _fetchMeetLink();
      _fetchMeetLinkEntretient();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _convertToBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      if (value == '1' || value.toLowerCase() == 'true') return true;
      if (value == '0' || value.toLowerCase() == 'false') return false;
    }
    return false;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _fetchDemandeDetails() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/demandes-inconnues/${widget.demandeId}'),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _demande = data['data'];
          final hasPieces = _demande?['pieces_choisies'] != null &&
              (_demande!['pieces_choisies'] as List).isNotEmpty;
          final hasCategories = _demande?['categories'] != null &&
              (_demande!['categories'] as List).isNotEmpty;
          final hasPanne = _demande?['panne'] != null &&
              (_demande!['panne'] as String).isNotEmpty;
          _isLoading = false;
        });

        // Only start animation if the controller is still valid and mounted
        if (mounted && _animationController.status == AnimationStatus.dismissed) {
          _animationController.forward();
        }

        await _fetchMeetLink();
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMeetLink() async {
    if (!mounted) return;

    try {
      print(widget.demandeId);
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/flux-par-demande_inconnu/${widget.demandeId}'),
        headers: {'Accept': 'application/json'},
      );

      if (!mounted) return;

      print(response.statusCode);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data['lien_meet']);
        setState(() {
          _meetLink = data['lien_meet'];
          _ouvertureMeet = data['ouvert'];
          _idFlux = data['id_flux'];
          _hasDemandeFlux = data['has_demande_flux'];
        });

        if (_idFlux != null) {
          await _fetchPartageStatus();
        }

        print(_meetLink);
      }
    } catch (e) {
      debugPrint('Error fetching meet link: $e');
    }
  }

  Future<void> _fetchMeetLinkEntretient() async {
    if (!mounted) return;

    try {
      print(widget.demandeId);
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/flux-par-demande_inconnu-entretient/${widget.demandeId}'),
        headers: {'Accept': 'application/json'},
      );

      if (!mounted) return;

      print(response.statusCode);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data['lien_meet']);
        setState(() {
          _meetLinkEntretient = data['lien_meet'];
          _ouvertureMeetEntretient = data['ouvert'];
          _idFluxEntretirnt = data['id_flux'];
          _hasDemandeFluxEntretient = data['has_demande_flux'];
        });

        if (_idFluxEntretirnt != null) {
          await _fetchPartageStatusEntretient();
        }

        print(_meetLinkEntretient);
      }
    } catch (e) {
      debugPrint('Error fetching meet link: $e');
    }
  }

  Future<void> _fetchPartageStatus() async {
    if (!mounted) return;

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/demande-flux-inconnu/by-flux/$_idFlux'),
      );

      if (!mounted) return;

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
  Future<void> _fetchPartageStatusEntretient() async {
    if (!mounted) return;

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/demande-flux-inconnu/by-flux/$_idFluxEntretirnt'),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _partageAvecClientEntretient = _convertToBool(data['data']['permission']);
          _EnvoyerAuClientEntretient = _convertToBool(data['data']['partage_with_client']);
        });
      }
    } catch (e) {
      debugPrint('Erreur fetchPartageStatus: $e');
    }
  }

  Future<void> _generateOrOpenMeetLink() async {
    if (_isGeneratingLink || !mounted) return;

    if (_meetLink != null && _meetLink!.isNotEmpty && _ouvertureMeet != false) {
      await _launchMeetLink(_meetLink!);
      return;
    }

    setState(() => _isGeneratingLink = true);

    try {
      final userDataJson = await _storage.read(key: 'user_data');
      final userId = jsonDecode(userDataJson!)['id'];

      final generatedLink = 'https://meet.jit.si/icar-${widget.demandeId}';

      final response = await http.post(
        Uri.parse('http://localhost:8000/api/flux-par-demandeInconnu'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'demande_id': widget.demandeId,
          'technicien_id': userId,
          'lien_meet': generatedLink,
          'type_meet' : "Examination"
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _meetLink = data['flux']['lien_meet'];
          _idFlux = data['flux']['id'];
          _ouvertureMeet = true;
        });
        await _launchMeetLink(_meetLink!);
      } else {
        throw Exception('Erreur API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnack('Erreur: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingLink = false);
        await _fetchMeetLink();
      }
    }
  }

  Future<void> _generateOrOpenMeetLinkEntretient() async {
    if (_isGeneratingLinkEntretient || !mounted) return;

    if (_meetLinkEntretient != null && _meetLinkEntretient!.isNotEmpty && _ouvertureMeetEntretient != false) {
      await _launchMeetLink(_meetLinkEntretient!);
      return;
    }

    setState(() => _isGeneratingLinkEntretient = true);

    try {
      final userDataJson = await _storage.read(key: 'user_data');
      final userId = jsonDecode(userDataJson!)['id'];

      final generatedLink = 'https://meet.jit.si/icar-${widget.demandeId}';

      final response = await http.post(
        Uri.parse('http://localhost:8000/api/flux-par-demandeInconnu'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'demande_id': widget.demandeId,
          'technicien_id': userId,
          'lien_meet': generatedLink,
          'type_meet' : "Entretient"
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _meetLinkEntretient = data['flux']['lien_meet'];
          _idFluxEntretirnt = data['flux']['id'];
          _ouvertureMeetEntretient = true;
        });
        await _launchMeetLink(_meetLinkEntretient!);
      } else {
        throw Exception('Erreur API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnack('Erreur: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingLinkEntretient = false);
        await _fetchMeetLinkEntretient();
      }
    }
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      length,
          (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

  Future<void> _demanderFluxAvecClient() async {
    if (_isGeneratingLink || _idFlux == null || !mounted) return;

    setState(() => _isGeneratingLink = true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/demande-flux-inconnu'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_flux': _idFlux,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        _showSuccessSnack('Demande de flux envoyée à l\'expert');
        await _fetchPartageStatus();
      } else {
        _showErrorSnack('Échec de la demande: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnack('Erreur: ${e.toString()}');
      }
      debugPrint('Erreur détaillée: $e');
    } finally {
      if (mounted) {
        setState(() => _isGeneratingLink = false);
      }
    }
  }

  Future<void> _fermerFlux() async {
    if (_idFlux == null || !mounted) return;

    setState(() => _isGeneratingLink = true);

    try {
      final response = await http.put(
        Uri.parse('http://localhost:8000/api/flux-direct-inconnu/$_idFlux/fermer'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSuccessSnack('Flux fermé avec succès');
        await _fetchMeetLink();
      } else {
        _showErrorSnack('Échec de la fermeture du flux');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnack('Erreur: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingLink = false);
      }
    }
  }

  Future<void> _autoriserPartage() async {
    if (!mounted) return;

    try {
      final response = await http.put(
        Uri.parse('http://localhost:8000/api/demande-flux-inconnu/$_idFlux/autoriser-partage'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSuccessSnack('Demande de partage envoyée au client');
        await _fetchPartageStatus();
      } else {
        _showErrorSnack('Échec de l\'autorisation de partage.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnack('Erreur: ${e.toString()}');
      }
    }
  }

  Future<void> _launchMeetLink(String link) async {
    try {
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await Clipboard.setData(ClipboardData(text: link));
        if (mounted) {
          _showErrorSnack('Lien copié dans le presse-papier: $link');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnack('Impossible d\'ouvrir le lien. Erreur: ${e.toString()}');
      }
    }
  }




  Future<void> _demanderFluxAvecClientEntrent() async {
    if (_isGeneratingLinkEntretient || _idFluxEntretirnt == null || !mounted) return;

    setState(() => _isGeneratingLinkEntretient = true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/demande-flux-inconnu'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_flux': _idFluxEntretirnt,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        _showSuccessSnack('Demande de flux envoyée à l\'expert');
        await _fetchPartageStatus();
      } else {
        _showErrorSnack('Échec de la demande: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnack('Erreur: ${e.toString()}');
      }
      debugPrint('Erreur détaillée: $e');
    } finally {
      if (mounted) {
        setState(() => _isGeneratingLinkEntretient = false);
      }
    }
  }

  Future<void> _fermerFluxEntretient() async {
    if (_idFluxEntretirnt == null || !mounted) return;

    setState(() => _isGeneratingLinkEntretient = true);

    try {
      final response = await http.put(
        Uri.parse('http://localhost:8000/api/flux-direct-inconnu/$_idFluxEntretirnt/fermer'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSuccessSnack('Flux fermé avec succès');
        await _fetchMeetLink();
      } else {
        _showErrorSnack('Échec de la fermeture du flux');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnack('Erreur: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingLinkEntretient = false);
      }
    }
  }

  Future<void> _autoriserPartageEntrient() async {
    if (!mounted) return;

    try {
      final response = await http.put(
        Uri.parse('http://localhost:8000/api/demande-flux-inconnu/$_idFluxEntretirnt/autoriser-partage'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSuccessSnack('Demande de partage envoyée au client');
        await _fetchPartageStatus();
      } else {
        _showErrorSnack('Échec de l\'autorisation de partage.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnack('Erreur: ${e.toString()}');
      }
    }
  }

  Future<void> _launchMeetLinkEntrient(String link) async {
    try {
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await Clipboard.setData(ClipboardData(text: link));
        if (mounted) {
          _showErrorSnack('Lien copié dans le presse-papier: $link');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnack('Impossible d\'ouvrir le lien. Erreur: ${e.toString()}');
      }
    }
  }

  void _showSuccessSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFE57373),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.white],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x749DC2B5), Color(0x749DC2B5)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Erreur: $_errorMessage',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_demande == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.white],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Aucune donnée disponible',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final voiture = _demande!['voiture'] ?? {};
    final client = _demande!['client'] ?? {};

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF73B1BD), Color(0xFF73B1BD)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header personnalisé
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Détails',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _meetLink != null && _ouvertureMeet != false
                              ? Icons.videocam
                              : Icons.videocam_off,
                          color: _meetLink != null && _ouvertureMeet != false
                              ? Colors.blue
                              : Colors.red[300],
                        ),
                        onPressed: () {
                          if (_meetLink != null && _ouvertureMeet != false) {
                            _launchMeetLink(_meetLink!);
                          } else {
                            _generateOrOpenMeetLink();
                          }
                        },
                        tooltip: 'Vidéoconférence',
                      ),
                    ),
                  ],
                ),
              ),

              // Contenu principal
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Indicateur visuel
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Section Client
                            _buildModernSection(
                              title: 'Informations Client',
                              icon: Icons.person_outline,
                              color: Color(0x749DC2B5),
                              children: [
                                _buildModernInfoTile(
                                  icon: Icons.account_circle,
                                  label: 'Nom complet',
                                  value: '${client['prenom']} ${client['nom']}',
                                  color: const Color(0xFF667eea),
                                ),
                                _buildModernInfoTile(
                                  icon: Icons.phone,
                                  label: 'Téléphone',
                                  value: client['phone'] ?? 'Non fourni',
                                  color: const Color(0xFF667eea),
                                ),
                                _buildModernInfoTile(
                                  icon: Icons.email,
                                  label: 'Email',
                                  value: client['email'] ?? 'Non fourni',
                                  color: const Color(0xFF667eea),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Section Véhicule
                            _buildModernSection(
                              title: 'Véhicule',
                              icon: Icons.directions_car_outlined,
                              color: Colors.lightBlue ,
                              children: [
                                _buildModernInfoTile(
                                  icon: Icons.car_rental,
                                  label: 'Modèle',
                                  value: voiture['model'] ?? 'Inconnu',
                                  color: const Color(0xFF764ba2),
                                ),
                                _buildModernInfoTile(
                                  icon: Icons.confirmation_number,
                                  label: 'Série',
                                  value: voiture['serie'].toString() ?? 'Inconnue',
                                  color: const Color(0xFF764ba2),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Section Demande
                            _buildModernSection(
                              title: 'Détails de la demande',
                              icon: Icons.description_outlined,
                              color: Colors.lightBlue,
                              children: [
                                _buildModernInfoTile(
                                  icon: Icons.text_snippet,
                                  label: 'Description',
                                  value: _demande!['description_probleme'],
                                  color:Colors.lightBlue,
                                ),
                                _buildModernInfoTile(
                                  icon: Icons.calendar_today,
                                  label: 'Date',
                                  value: _formatDate(_demande!['date_maintenance']),
                                  color: Colors.lightBlue,
                                ),
                                _buildModernInfoTile(
                                  icon: Icons.access_time,
                                  label: 'Heure',
                                  value: _demande!['heure_maintenance'],
                                  color: Colors.lightBlue,
                                ),
                                _buildModernInfoTile(
                                  icon: Icons.location_on,
                                  label: 'Type emplacement',
                                  value: _demande!['type_emplacement'],
                                  color: Colors.lightBlue,
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Section Vidéoconférence
                            _buildVideoConferenceCard(),

                            const SizedBox(height: 20),

                            // Section Partage
                            if (_partageAvecClient == true) _buildSharingCard(),
                            const SizedBox(height: 20),
                            if (_partageAvecClient == true) _buildDescriptionPanneCard(),

                            const SizedBox(height: 20),
                          if(_demande!["pieces_selectionnees"] != null)
                            _buildVideoConferenceCardEntrient(),
                            const SizedBox(height: 20),
                            if (_partageAvecClientEntretient == true) _buildSharingCardEntrient(),
                            if (_ouvertureMeetEntretient == false) _buildRapport(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoConferenceCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667eea).withOpacity(0.1),
            const Color(0xFF764ba2).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF667eea).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.video_call,
                    color: Color(0xFF667eea),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Visioconférence Examination',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

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
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _ouvertureMeet == false
                        ? [Colors.grey.shade300, Colors.grey.shade400]
                        : _meetLink != null
                        ? [const Color(0xFF4CAF50), const Color(0xFF45A049)]
                        : [const Color(0xFF667eea), const Color(0xFF764ba2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_ouvertureMeet == false
                          ? Colors.grey
                          : _meetLink != null
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF667eea))
                          .withOpacity(0.3),
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _isGeneratingLink
                    ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
                    : Icon(
                  _ouvertureMeet == false
                      ? Icons.videocam_off
                      : _meetLink != null
                      ? Icons.videocam
                      : Icons.videocam_off,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (_meetLink != null && _ouvertureMeet != false)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _meetLink!,
                  style: const TextStyle(
                    color: Color(0xFF667eea),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            if (_ouvertureMeet == false)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Flux fermé - Vidéoconférence indisponible',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 20),

            if (_meetLink != null && _hasDemandeFlux == false && _ouvertureMeet != false)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.3),
                      spreadRadius: 0,
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _idFlux == null ? null : _demanderFluxAvecClient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Envoi en cours...",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send, size: 20, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        "Demander flux avec client",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
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


  Widget _buildVideoConferenceCardEntrient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667eea).withOpacity(0.1),
            const Color(0xFF764ba2).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF667eea).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.video_call,
                    color: Color(0xFF667eea),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Visioconférence Entretient',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            GestureDetector(
              onTap: _isGeneratingLinkEntretient
                  ? null
                  : () {
                if (_meetLinkEntretient != null) {
                  _launchMeetLinkEntrient(_meetLinkEntretient!);
                } else {
                  _generateOrOpenMeetLinkEntretient();
                }
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _ouvertureMeetEntretient == false
                        ? [Colors.grey.shade300, Colors.grey.shade400]
                        : _meetLinkEntretient!= null
                        ? [const Color(0xFF4CAF50), const Color(0xFF45A049)]
                        : [const Color(0xFF667eea), const Color(0xFF764ba2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_ouvertureMeetEntretient == false
                          ? Colors.grey
                          : _meetLinkEntretient != null
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF667eea))
                          .withOpacity(0.3),
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _isGeneratingLinkEntretient
                    ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
                    : Icon(
                  _ouvertureMeetEntretient == false
                      ? Icons.videocam_off
                      : _meetLink != null
                      ? Icons.videocam
                      : Icons.videocam_off,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (_meetLinkEntretient != null && _ouvertureMeetEntretient != false)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _meetLinkEntretient!,
                  style: const TextStyle(
                    color: Color(0xFF667eea),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            if (_ouvertureMeetEntretient == false)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Flux fermé - Vidéoconférence indisponible',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 20),

            if (_meetLinkEntretient != null && _hasDemandeFluxEntretient == false && _ouvertureMeetEntretient != false)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.3),
                      spreadRadius: 0,
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _idFluxEntretirnt == null ? null : _demanderFluxAvecClientEntrent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isGeneratingLinkEntretient
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Envoi en cours...",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send, size: 20, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        "Demander flux avec client",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildSharingCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50).withOpacity(0.1),
            const Color(0xFF45A049).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.2),
          width: 1,
        ),
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
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.share,
                    color: Color(0xFF4CAF50),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Partage avec client',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.share_outlined,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Partage avec le client',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _EnvoyerAuClient ?? false,
                      onChanged: (value) {
                        if (value) {
                          _autoriserPartage();
                        }
                      },
                      activeColor: const Color(0xFF4CAF50),
                      activeTrackColor: const Color(0xFF4CAF50).withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),

            if (_EnvoyerAuClient == false) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      spreadRadius: 0,
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _autoriserPartage,
                  icon: const Icon(Icons.share, color: Colors.white, size: 20),
                  label: const Text(
                    'Partager',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

            if (_ouvertureMeet != false) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE57373), Color(0xFFEF5350)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE57373).withOpacity(0.3),
                      spreadRadius: 0,
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _fermerFlux,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Fermeture en cours...",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close, size: 20, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        "Fermer le flux",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  Widget _buildSharingCardEntrient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50).withOpacity(0.1),
            const Color(0xFF45A049).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.2),
          width: 1,
        ),
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
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.share,
                    color: Color(0xFF4CAF50),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Partage avec client',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.share_outlined,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Partage avec le client',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _EnvoyerAuClientEntretient ?? false,
                      onChanged: (value) {
                        if (value) {
                          _autoriserPartageEntrient();
                        }
                      },
                      activeColor: const Color(0xFF4CAF50),
                      activeTrackColor: const Color(0xFF4CAF50).withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),

            if (_EnvoyerAuClientEntretient == false) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      spreadRadius: 0,
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _autoriserPartageEntrient,
                  icon: const Icon(Icons.share, color: Colors.white, size: 20),
                  label: const Text(
                    'Partager',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

            if (_ouvertureMeetEntretient != false) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE57373), Color(0xFFEF5350)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE57373).withOpacity(0.3),
                      spreadRadius: 0,
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _fermerFluxEntretient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isGeneratingLinkEntretient
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Fermeture en cours...",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close, size: 20, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        "Fermer le flux",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  Widget _buildDescriptionPanneCard() {
    // Vérifier si la panne est déjà renseignée
    final panneExist = _demande?['panne'] != null && (_demande!['panne'] as String).isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF73B1BD).withOpacity(0.08),
            const Color(0xFF5A9BA8).withOpacity(0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF73B1BD).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF73B1BD).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec icône et titre
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF73B1BD), Color(0xFF5A9BA8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF73B1BD).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.report_problem_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        panneExist ? 'Description existante' : 'Description de la panne',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      if (panneExist) ...[
                        const SizedBox(height: 4),
                        Text(
                          _demande!['panne'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            if (!panneExist) ...[
              const SizedBox(height: 24),
              // Section d'information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF73B1BD).withOpacity(0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Bouton d'action seulement si panne n'existe pas
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) =>
                                  DescriptionPannePage(demandeId: widget.demandeId),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOutCubic;

                                var tween = Tween(begin: begin, end: end)
                                    .chain(CurveTween(curve: curve));
                                var offsetAnimation = animation.drive(tween);

                                return SlideTransition(
                                  position: offsetAnimation,
                                  child: child,
                                );
                              },
                              transitionDuration: const Duration(milliseconds: 300),
                            ),
                          );
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.edit_note_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        label: const Text(
                          'Ajouter une description',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF73B1BD),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ).copyWith(
                          overlayColor: MaterialStateProperty.all(
                            Colors.white.withOpacity(0.1),
                          ),
                          shadowColor: MaterialStateProperty.all(
                            const Color(0xFF73B1BD).withOpacity(0.3),
                          ),
                          elevation: MaterialStateProperty.resolveWith((states) {
                            if (states.contains(MaterialState.pressed)) {
                              return 8;
                            }
                            return 2;
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Points d'aide rapide (toujours visibles)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF73B1BD).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF73B1BD).withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates_outlined,
                        color: const Color(0xFF73B1BD),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Conseils rapides',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF73B1BD),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...const [
                    'Décrivez les symptômes observés',
                    'Mentionnez quand le problème survient',
                    'Indiquez les bruits ou odeurs inhabituels',
                  ].map((tip) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF73B1BD),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tip,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4A5568),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }Widget _buildRapport() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rapport',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              if (_demande != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RapportMaintenanceInconnuPage(demande: _demande!),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Aucune demande disponible.')),
                );
              }
            },

            icon: const Icon(Icons.description),
            label: const Text('Créer le rapport maintenant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }


}