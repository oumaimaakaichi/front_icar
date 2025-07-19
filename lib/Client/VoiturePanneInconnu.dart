import 'package:car_mobile/Client/CategoryPanesPage.dart';
import 'package:car_mobile/Client/CategoryPanne_inconnu.dart';
import 'package:car_mobile/Client/description_probleme.dart';
import 'package:car_mobile/DescriptionPannePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VoiturePanneInconnu extends StatefulWidget {
  const VoiturePanneInconnu({super.key});

  @override
  State<VoiturePanneInconnu> createState() => _MesVoituresPageState();
}

class _MesVoituresPageState extends State<VoiturePanneInconnu>
    with TickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();
  List<dynamic> _voitures = [];
  bool _isLoading = true;
  String _searchQuery = '';
  late AnimationController _animationController;
  late AnimationController _searchController;
  late Animation<double> _fadeAnimation;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _searchController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _fetchVoitures();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchVoitures() async {
    setState(() => _isLoading = true);

    final userDataJsons = await _storage.read(key: 'user_data');
    if (userDataJsons == null) {
      setState(() => _isLoading = false);
      return;
    }

    final userData = jsonDecode(userDataJsons);
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/voitures/${userData["id"]}'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _voitures = jsonDecode(response.body);
          _isLoading = false;
        });
        _animationController.forward();
      } else {
        throw Exception('Failed to load voitures');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  List<dynamic> get _filteredVoitures {
    if (_searchQuery.isEmpty) return _voitures;
    return _voitures.where((voiture) {
      final model = voiture['model']?.toString().toLowerCase() ?? '';
      final company = voiture['company']?.toString().toLowerCase() ?? '';
      return model.contains(_searchQuery.toLowerCase()) ||
          company.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildSearchSection()),
          _isLoading
              ? SliverFillRemaining(child: _buildLoadingIndicator())
              : _filteredVoitures.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState())
              : _buildVoituresGrid(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey.shade800,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Mes Véhicules',
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade50,
                Colors.indigo.shade50,
              ],
            ),
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: () {
              _fetchVoitures();
              HapticFeedback.lightImpact();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Diagnostic Automobile',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionnez le véhicule à diagnostiquer',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Rechercher un véhicule...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(Icons.search,
                      color: Colors.blue.shade600, size: 22),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade400),
                  onPressed: () {
                    setState(() => _searchQuery = '');
                    _searchFocusNode.unfocus();
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 16, horizontal: 20),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          if (_filteredVoitures.isNotEmpty && !_isLoading) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.directions_car,
                    color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_filteredVoitures.length} véhicule${_filteredVoitures.length > 1 ? 's' : ''} disponible${_filteredVoitures.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chargement de vos véhicules...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isEmpty
                    ? Icons.directions_car_outlined
                    : Icons.search_off,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty
                  ? 'Aucun véhicule enregistré'
                  : 'Aucun résultat trouvé',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Ajoutez votre premier véhicule pour commencer'
                  : 'Aucun véhicule ne correspond à "$_searchQuery"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => setState(() => _searchQuery = ''),
                icon: const Icon(Icons.refresh),
                label: const Text('Réinitialiser'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVoituresGrid() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    (index * 0.1).clamp(0.0, 1.0),
                    ((index * 0.1) + 0.4).clamp(0.0, 1.0),
                    curve: Curves.easeOutCubic,
                  ),
                )),
                child: _buildModernVoitureCard(_filteredVoitures[index]),
              ),
            );
          },
          childCount: _filteredVoitures.length,
        ),
      ),
    );
  }

  Widget _buildModernVoitureCard(Map<String, dynamic> voiture) {
    final carColor = _getCarColor(voiture['company']);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
            HapticFeedback.lightImpact();
            _navigateToCarDetail(context, voiture);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        carColor.withOpacity(0.1),
                        carColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: carColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.directions_car_rounded,
                          size: 40,
                          color: carColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: carColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          voiture['company'] ?? 'Marque',
                          style: TextStyle(
                            fontSize: 12,
                            color: carColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        voiture['model'] ?? 'Modèle inconnu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCarColor(String? company) {
    switch (company?.toLowerCase()) {
      case 'toyota':
        return Colors.red.shade600;
      case 'bmw':
        return Colors.blue.shade700;
      case 'mercedes':
        return Colors.blueGrey.shade800;
      case 'audi':
        return Colors.grey.shade700;
      case 'volkswagen':
        return Colors.indigo.shade600;
      case 'ford':
        return Colors.blue.shade800;
      case 'peugeot':
        return Colors.orange.shade600;
      case 'renault':
        return Colors.yellow.shade700;
      case 'nissan':
        return Colors.red.shade700;
      case 'honda':
        return Colors.purple.shade600;
      default:
        return Colors.teal.shade600;
    }
  }

  void _navigateToCarDetail(BuildContext context, Map<String, dynamic> voiture) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProblemDescriptionPage(

              voitureId: voiture['id'],
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }
}