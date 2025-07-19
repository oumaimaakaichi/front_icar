import 'package:car_mobile/Client/MesDemandesPage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ServicesByCategoryPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final int voitureId;

  const ServicesByCategoryPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.voitureId,
  });

  @override
  State<ServicesByCategoryPage> createState() => _ServicesByCategoryPageState();
}

class _ServicesByCategoryPageState extends State<ServicesByCategoryPage>
    with TickerProviderStateMixin {
  List<dynamic> _services = [];
  List<dynamic> _forfaits = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  late TabController _tabController;
  int _currentTabIndex = 0;
  int? _selectedServiceId;
  int? _selectedForfaitId;
  late AnimationController _animationController;
  Animation<double>? _fadeAnimation; // Changed to nullable

  @override

  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);

    // Only create one AnimationController
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fetchData();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return; // Check if widget is still mounted

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final servicesResponse = await http.get(
        Uri.parse('http://localhost:8000/api/panne/category/${widget.categoryId}'),
        headers: {'Accept': 'application/json'},
      );

      final forfaitsResponse = await http.get(
        Uri.parse('http://localhost:8000/api/forfaits'),
        headers: {'Accept': 'application/json'},
      );

      if (!mounted) return; // Check again after async operations

      if (servicesResponse.statusCode == 200 && forfaitsResponse.statusCode == 200) {
        setState(() {
          _services = jsonDecode(servicesResponse.body);
          _forfaits = jsonDecode(forfaitsResponse.body);
          _isLoading = false;
        });
        // Only forward animation if widget is still mounted and animation is initialized
        if (mounted && _fadeAnimation != null) {
          _animationController.forward();
        }
      } else {
        throw Exception('Échec du chargement: Services: ${servicesResponse.statusCode}, Forfaits: ${forfaitsResponse.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  List<dynamic> get _filteredServices {
    if (_searchQuery.isEmpty) return _services;
    return _services.where((service) {
      final title = service['titre']?.toString().toLowerCase() ?? '';
      final description = service['description']?.toString().toLowerCase() ?? '';
      return title.contains(_searchQuery.toLowerCase()) ||
          description.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<dynamic> get _filteredForfaits {
    if (_searchQuery.isEmpty) return _forfaits;
    return _forfaits.where((forfait) {
      final nom = forfait['nomForfait']?.toString().toLowerCase() ?? '';
      return nom.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showForfaitDetails(BuildContext context, dynamic forfait) {
    final services = forfait['service_pannes'] ?? [];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 20,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.blue.shade50],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade400],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.assignment, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          forfait['nomForfait'] ?? 'Détails du forfait',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                '${forfait['prixForfait']} DT',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                'Remise ${forfait['rival']}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Services inclus:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...services.map<Widget>((service) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),

                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service['titre'] ?? 'Service',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (service['description'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    service['description'],
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Fermer',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _envoyerDemande() async {
    if (_selectedServiceId == null || _selectedForfaitId == null) {
      _showCustomSnackBar(
        'Veuillez sélectionner un service ET un forfait',
        Colors.red.shade400,
        Icons.warning,
      );
      return;
    }

    final url = Uri.parse('http://localhost:8000/api/demandes');
    try {
      final response = await http.post(
        url,
        headers: {'Accept': 'application/json'},
        body: {
          'forfait_id': _selectedForfaitId.toString(),
          'service_panne_id': _selectedServiceId.toString(),
          'voiture_id': widget.voitureId.toString(),
        },
      );

      if (!mounted) return; // Check if widget is still mounted

      if (response.statusCode == 201) {
        _showCustomSnackBar(
          'Votre demande a été envoyée avec succès!',
          Colors.green.shade400,
          Icons.check_circle,
        );

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => MesDemandesPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: animation.drive(
                  Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeInOut)),
                ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );

        setState(() {
          _selectedServiceId = null;
          _selectedForfaitId = null;
        });
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      _showCustomSnackBar(
        'Erreur lors de l\'envoi: ${e.toString()}',
        Colors.red.shade400,
        Icons.error,
      );
    }
  }

  void _showCustomSnackBar(String message, Color backgroundColor, IconData icon) {
    if (!mounted) return; // Check if widget is still mounted
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
        shadowColor: Colors.transparent,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _fetchData,
              color: Colors.teal.shade600,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.build_rounded, size: 20),
                      const SizedBox(width: 8),
                      const Text('Services', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_rounded, size: 20),
                      const SizedBox(width: 8),
                      const Text('Packs', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
              indicatorColor: Colors.teal.shade600,
              indicatorWeight: 3,
              labelColor: Colors.teal.shade600,
              unselectedLabelColor: Colors.grey.shade600,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSelectionIndicators(),
          Expanded(
            child: _fadeAnimation != null // Null check for animation
                ? FadeTransition(
              opacity: _fadeAnimation!,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildServicesTab(),
                  _buildForfaitsTab(),
                ],
              ),
            )
                : TabBarView( // Fallback without animation
              controller: _tabController,
              children: [
                _buildServicesTab(),
                _buildForfaitsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedServiceId != null && _selectedForfaitId != null
          ? _buildBottomActionBar()
          : null,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: _currentTabIndex == 0
                ? 'Rechercher un service...'
                : 'Rechercher un Pack...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.teal.shade600),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
    );
  }

  Widget _buildSelectionIndicators() {
    if (_selectedServiceId == null && _selectedForfaitId == null) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),

    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade400, Colors.teal.shade600],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _envoyerDemande,
            icon: const Icon(Icons.send_rounded, size: 24),
            label: const Text(
              'Envoyer la demande',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServicesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.build_rounded, color: Colors.teal.shade700, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Choisir un service',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildServicesContent()),
      ],
    );
  }

  Widget _buildForfaitsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.assignment_rounded, color: Colors.blue.shade700, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Choisir un pack',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildForfaitsContent()),
      ],
    );
  }

  Widget _buildServicesContent() {
    if (_isLoading) return _buildLoadingIndicator();
    if (_errorMessage != null) return _buildErrorState();
    if (_filteredServices.isEmpty) return _buildEmptyState(isServices: true);
    return _buildServicesList();
  }

  Widget _buildForfaitsContent() {
    if (_isLoading) return _buildLoadingIndicator();
    if (_errorMessage != null) return _buildErrorState();
    if (_filteredForfaits.isEmpty) return _buildEmptyState(isServices: false);
    return _buildForfaitsList();
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
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade600),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chargement en cours...',
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

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Une erreur est survenue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Impossible de charger les données',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required bool isServices}) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isServices ? Icons.handyman_rounded : Icons.assignment_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? isServices ? 'Aucun service disponible' : 'Aucun Pack disponible'
                  : 'Aucun résultat trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? isServices ? 'Aucun service trouvé pour cette catégorie' : 'Aucun Pack trouvé'
                  : 'Aucun ${isServices ? 'service' : 'Pack'} ne correspond à "$_searchQuery"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => setState(() => _searchQuery = ''),
                icon: const Icon(Icons.clear_rounded),
                label: const Text('Réinitialiser la recherche'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.teal.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServicesList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredServices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final service = _filteredServices[index];
        final isSelected = _selectedServiceId == service['id'];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: _buildServiceCard(service, isSelected),
        );
      },
    );
  }

  Widget _buildForfaitsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredForfaits.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final forfait = _filteredForfaits[index];
        final isSelected = _selectedForfaitId == forfait['id'];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: _buildForfaitCard(forfait, isSelected),
        );
      },
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
          colors: [Colors.teal.shade50, Colors.teal.shade100],
        )
            : null,
        color: isSelected ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: Colors.teal.shade300, width: 2)
            : Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? Colors.teal.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: isSelected ? 12 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _selectedServiceId = isSelected ? null : service['id'];
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.teal.shade600 : Colors.teal.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.build_rounded,
                        color: isSelected ? Colors.white : Colors.teal.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        service['titre'] ?? 'Service sans nom',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.teal.shade800 : Colors.grey.shade800,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade600,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                  ],
                ),
                if (service['description'] != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    service['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
                if (isSelected) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Sélectionné',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForfaitCard(Map<String, dynamic> forfait, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
        )
            : null,
        color: isSelected ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: Colors.blue.shade300, width: 2)
            : Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? Colors.blue.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: isSelected ? 12 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _selectedForfaitId = isSelected ? null : forfait['id'];
            });
          },
          onLongPress: () => _showForfaitDetails(context, forfait),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade600 : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.assignment_rounded,
                        color: isSelected ? Colors.white : Colors.blue.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        forfait['nomForfait'] ?? 'Pack sans nom',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.blue.shade800 : Colors.grey.shade800,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.attach_money_rounded,
                              color: Colors.green.shade700, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${forfait['prixForfait']} DT',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_offer_rounded,
                              color: Colors.orange.shade700, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${forfait['rival']}%',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: Colors.grey.shade500, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Appui long pour voir les détails',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                if (isSelected) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Sélectionné',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}