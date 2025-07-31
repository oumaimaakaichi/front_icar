import 'dart:convert';
import 'package:car_mobile/Client/DetailDemandeInconnuPage.dart';
import 'package:car_mobile/Client/SelectionPiecesPage.dart';// Ajoutez cette import
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MesDemandesPageInconnu extends StatefulWidget {
  @override
  _MesDemandesPageState createState() => _MesDemandesPageState();
}

class _MesDemandesPageState extends State<MesDemandesPageInconnu>
    with SingleTickerProviderStateMixin {
  final _storage = FlutterSecureStorage();
  String? _token;
  int? _userId;
  bool _isLoading = true;
  List<dynamic> _demandes = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Map<int, String?> meetLinks = {};
  Map<int, bool> meetLinkStatus = {};
  Map<int, bool> meetOpening = {};
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadUserData().then((_) => _fetchDemandes());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final token = await _storage.read(key: 'token');
    final userDataJson = await _storage.read(key: 'user_data');

    if (userDataJson != null) {
      final userData = jsonDecode(userDataJson);
      if (!mounted) return;
      setState(() {
        _token = token;
        _userId = userData['id'];
      });
    }
  }
  Future<void> checkMeetLinkAvailability(int demandeId) async {
    try {
      final url = Uri.parse('http://localhost:8000/api/demandes/$demandeId/meet-link-inconnu');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          meetLinks[demandeId] = data['lien_meet'];
          meetLinkStatus[demandeId] = data['partage_with_client'] == 1 ||
              data['partage_with_client'] == true;
          meetOpening[demandeId] = data['ouvert'] == 1 ||
              data['ouvert'] == true;
        });

        print(meetOpening[demandeId]);
      }

    } catch (e) {
      print('Erreur lors de la récupération du lien Meet: $e');
    }
  }

  Future<void> _fetchDemandes() async {
    if (_userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/demandes/client/$_userId'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _demandes = data['data'];
            _isLoading = false;
          });
          _animationController.forward();
          for (var demande in _demandes) {
            await checkMeetLinkAvailability(demande['id']);
          }
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des demandes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _hasPiecesDisponibles(dynamic demande) {
    // Vérifie que disponibilite_pieces existe et n'est pas vide
    final disponibilitePieces = demande['disponibilite_pieces'];
    final hasDisponibilite = disponibilitePieces != null &&
        !(disponibilitePieces is String &&
            (disponibilitePieces.isEmpty ||
                disponibilitePieces == '[]' ||
                disponibilitePieces == '{}'));

    // Vérifie que pieces_selectionnees est null ou vide
    final piecesSelectionnees = demande['pieces_selectionnees'];
    final hasNoSelection = piecesSelectionnees == null ||
        (piecesSelectionnees is String &&
            (piecesSelectionnees.isEmpty ||
                piecesSelectionnees == '[]' ||
                piecesSelectionnees == '{}')) ||
        (piecesSelectionnees is List && piecesSelectionnees.isEmpty) ||
        (piecesSelectionnees is Map && piecesSelectionnees.isEmpty);

    return hasDisponibilite && hasNoSelection;
  }

  bool _shouldShowPrixButton(dynamic demande) {
    final disponibilitePieces = demande['disponibilite_pieces'];
    final piecesSelectionnees = demande['pieces_selectionnees'];

    // Vérifier si disponibilite_pieces existe et n'est pas vide
    bool hasDisponibilite = disponibilitePieces != null;
    if (disponibilitePieces is String) {
      hasDisponibilite = disponibilitePieces.isNotEmpty &&
          disponibilitePieces != '[]' &&
          disponibilitePieces != '{}';
    } else if (disponibilitePieces is List) {
      hasDisponibilite = disponibilitePieces.isNotEmpty;
    } else if (disponibilitePieces is Map) {
      hasDisponibilite = disponibilitePieces.isNotEmpty;
    }

    // Vérifier si pieces_selectionnees est null ou vide (pas encore sélectionnées)
    bool hasNoSelection = piecesSelectionnees == null;
    if (piecesSelectionnees is String) {
      hasNoSelection = piecesSelectionnees.isEmpty ||
          piecesSelectionnees == '[]' ||
          piecesSelectionnees == '{}';
    } else if (piecesSelectionnees is List) {
      hasNoSelection = piecesSelectionnees.isEmpty;
    } else if (piecesSelectionnees is Map) {
      hasNoSelection = piecesSelectionnees.isEmpty;
    }

    return hasDisponibilite && hasNoSelection;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'nouvelle_demande':
        return Color(0xFF667EEA);
      case 'assignée':
        return Color(0xFF48BB78);
      case 'refuse':
      case 'refusée':
        return Color(0xFFED64A6);
      case 'en_cours':
        return Color(0xFFECC94B);
      case 'termine':
      case 'terminée':
        return Color(0xFF9F7AEA);
      default:
        return Color(0xFF718096);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x749DC2B5),
              Color(0x749DC2B5),
              Color(0xFFF093FB),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildGradientAppBar(),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: _isLoading
                        ? _buildModernLoadingState()
                        : _demandes.isEmpty
                        ? _buildModernEmptyState()
                        : _buildModernDemandesList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientAppBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 30),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Mes Demandes',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Suivi en temps réel de vos maintenances',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _fetchDemandes,
                    child: Container(
                      padding: EdgeInsets.all(16),
                      child: Icon(
                        Icons.refresh_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.car_repair_rounded,
                  color: Colors.black,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  '${_demandes.length} demande(s)',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernLoadingState() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(40),
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Color(0xA3ADD9FF).withOpacity(0.2),
              blurRadius: 30,
              offset: Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF667EEA).withOpacity(0.3),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.directions_car_rounded,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
                Positioned.fill(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            Text(
              'Chargement en cours...',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Récupération de vos demandes',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernEmptyState() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(40),
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF667EEA).withOpacity(0.1),
              blurRadius: 30,
              offset: Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.car_repair_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 30),
            Text(
              "Aucune demande",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 15),
            Text(
              "Vous n'avez pas encore créé\nde demandes de maintenance",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
                height: 1.6,
              ),
            ),
            SizedBox(height: 30),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF667EEA).withOpacity(0.4),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: () {
                    // Navigation vers création de demande
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text(
                          "Créer une demande",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDemandesList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _fetchDemandes,
        color: Color(0xFF667EEA),
        backgroundColor: Colors.white,
        child: ListView.builder(
          padding: EdgeInsets.all(25),
          itemCount: _demandes.length,
          itemBuilder: (context, index) {
            final demande = _demandes[index];
            final hasPieces = _hasPiecesDisponibles(demande);

            return TweenAnimationBuilder(
              duration: Duration(milliseconds: 600 + (index * 150)),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, double value, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: _buildModernDemandeCard(demande, hasPieces, index),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernDemandeCard(dynamic demande, bool hasPieces, int index) {
    final colors = [
      [Color(0x749DC2B5), Color(0x749DC2B5)],
      [Color(0xFF48BB78), Color(0xFF38A169)],
      [Color(0x749DC2B5), Color(0x749DC2B5)],
      [Colors.blueGrey, Colors.blueGrey],
    ];
    final cardColors = colors[index % colors.length];

    return Container(
      margin: EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: cardColors[0].withOpacity(0.15),
            blurRadius: 25,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildModernCardHeader(demande, cardColors),
          _buildModernCardBody(demande),
          _buildModernCardFooter(demande, cardColors),
        ],
      ),
    );
  }

  Widget _buildModernCardHeader(dynamic demande, List<Color> colors) {
    return Container(
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Icon(
              Icons.directions_car_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  demande['voiture_model'] ?? 'Modèle inconnu',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 5),
                // Ajout du statut si disponible
                if (demande['statut'] != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      demande['statut'].toString().toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCardBody(dynamic demande) {
    return Padding(
      padding: EdgeInsets.all(25),
      child: Column(
        children: [
          _buildModernInfoRow(
            Icons.event_rounded,
            'Date de maintenance',
            demande['date_maintenance'] ?? 'Non spécifiée',
            Color(0xFF48BB78),
          ),
          if (demande['atelier'] != null) ...[
            SizedBox(height: 20),
            _buildModernInfoRow(
              Icons.build_circle_rounded,
              'Atelier assigné',
              demande['atelier'],
              Color(0xFF9F7AEA),
            ),
          ],
          if (demande['categorie'] != null) ...[
            SizedBox(height: 20),
            _buildModernInfoRow(
              Icons.category_rounded,
              'Type de maintenance',
              demande['categorie'],
              Color(0xFFED64A6),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernCardFooter(dynamic demande, List<Color> colors) {
    final shouldShowButton = _shouldShowPrixButton(demande);

    return Container(
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFF1F5F9),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: shouldShowButton
                        ? [Color(0xFF48BB78), Color(0xFF38A169)]
                        : [Color(0xFF9CA3AF), Color(0xFF6B7280)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: shouldShowButton
                          ? Color(0xFF48BB78).withOpacity(0.3)
                          : Color(0xFF9CA3AF).withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  shouldShowButton ? Icons.monetization_on_rounded : Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shouldShowButton ? 'Prix disponible' : 'Statut de la demande',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      shouldShowButton
                          ? 'Pièces et tarifs proposés'
                          : 'En attente de traitement',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              if (shouldShowButton)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colors[0].withOpacity(0.4),
                        blurRadius: 15,
                        offset: Offset(0, 8),
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
                            builder: (context) => SelectionPiecesPage(demandeId: demande['id']),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility_rounded, size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Voir prix',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 15),
          // Bouton Détails ajouté ici
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF667EEA).withOpacity(0.3),
                  blurRadius: 15,
                  offset: Offset(0, 8),
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
                      builder: (context) => DemandeDetailsIPage(
                        demande: demande,
                        meetLink: meetLinks[demande['id']],
                        isShared: meetLinkStatus[demande['id']] ?? false,
                        isOpen: meetOpening[demande['id']] ?? false,
                      ),
                    ),
                  );

                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_rounded, size: 18, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Voir les détails',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: iconColor.withOpacity(0.2)),
          ),
          child: Icon(
            icon,
            size: 20,
            color: iconColor,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}