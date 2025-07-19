import 'dart:convert';
import 'package:car_mobile/Client/SelectionPiecesPage.dart';
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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
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

  Future<void> _fetchDemandes() async {
    if (_userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/demandes/client/$_userId'),
        headers: {
          'Authorization': 'Bearer $_token',
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
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _hasPiecesDisponibles(dynamic demande) {
    if (demande['disponibilite_pieces'] == null) return false;

    if (demande['disponibilite_pieces'] is List) {
      return (demande['disponibilite_pieces'] as List).isNotEmpty;
    }

    if (demande['disponibilite_pieces'] is String) {
      return demande['disponibilite_pieces'].toString().trim().isNotEmpty;
    }

    return true;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'nouvelle_demande':
        return Color(0xFF3B82F6);
      case 'assignée':
        return Color(0xFF10B981);
      case 'refuse':
      case 'refusée':
        return Color(0xFFEF4444);
      case 'en_cours':
        return Color(0xFFF59E0B);
      case 'termine':
      case 'terminée':
        return Color(0xFF8B5CF6);
      default:
        return Color(0xFF6B7280);
    }
  }

  LinearGradient _getStatusGradient(String status) {
    switch (status.toLowerCase()) {
      case 'nouvelle_demande':
        return LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'assignée':
        return LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'refuse':
      case 'refusée':
        return LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'en_cours':
        return LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'termine':
      case 'terminée':
        return LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'nouvelle_demande':
        return 'Nouvelle demande';
      case 'assignée':
        return 'Assignée';
      case 'refuse':
        return 'Refusée';
      case 'en_cours':
        return 'En cours';
      case 'termine':
        return 'Terminée';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'nouvelle_demande':
        return Icons.schedule_rounded;
      case 'assignée':
        return Icons.check_circle_rounded;
      case 'refuse':
      case 'refusée':
        return Icons.cancel_rounded;
      case 'en_cours':
        return Icons.settings_rounded;
      case 'termine':
      case 'terminée':
        return Icons.task_alt_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildModernAppBar(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _demandes.isEmpty
                  ? _buildEmptyState()
                  : _buildDemandesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Color(0xFF6797A2),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mes Demandes',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Suivi de vos demandes de maintenance',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _fetchDemandes,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 32),
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Color(0xFF6797A2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                  Icon(
                    Icons.car_repair_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Chargement des demandes...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Veuillez patienter un moment',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 32),
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFF6797A2),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.car_repair_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24),
            Text(
              "Aucune demande trouvée",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Vous n'avez pas encore de demandes\nde maintenance",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFF6797A2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "Créer une demande",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemandesList() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
        ),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _fetchDemandes,
          color: Color(0xFF6797A2),
          child: ListView.builder(
            padding: EdgeInsets.all(24),
            itemCount: _demandes.length,
            itemBuilder: (context, index) {
              final demande = _demandes[index];
              final hasPieces = _hasPiecesDisponibles(demande);

              return TweenAnimationBuilder(
                duration: Duration(milliseconds: 400 + (index * 100)),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                builder: (context, double value, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: _buildEnhancedDemandeCard(demande, hasPieces),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedDemandeCard(dynamic demande, bool hasPieces) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildEnhancedCardHeader(demande),
          _buildEnhancedCardBody(demande),
          if (hasPieces) _buildEnhancedCardFooter(demande),
        ],
      ),
    );
  }

  Widget _buildEnhancedCardHeader(dynamic demande) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xA1DAEEFF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.directions_car_rounded,
              color: Color(0xFF6797A2),
              size: 20,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  demande['voiture_model'] ?? 'Modèle inconnu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedCardBody(dynamic demande) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [

          _buildEnhancedInfoRow(
            Icons.calendar_today_rounded,
            'Date maintenance',
            demande['date_maintenance'] ?? 'Non spécifiée',
            Color(0xFF10B981),
          ),
          if (demande['atelier'] != null) ...[
            SizedBox(height: 20),
            _buildEnhancedInfoRow(
              Icons.store_rounded,
              'Atelier',
              demande['atelier'],
              Color(0xFF8B5CF6),
            ),
          ],
          if (demande['categorie'] != null) ...[
            SizedBox(height: 20),
            _buildEnhancedInfoRow(
              Icons.category_rounded,
              'Catégorie',
              demande['categorie'],
              Color(0xFFF59E0B),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnhancedCardFooter(dynamic demande) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.monetization_on_rounded,
              color: Color(0xFF10B981),
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prix disponible',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                Text(
                  'Consultez les prix des pièces',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SelectionPiecesPage(demandeId: demande['id']),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_rounded, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Voir prix',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}