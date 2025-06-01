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

class _ServicesByCategoryPageState extends State<ServicesByCategoryPage> with SingleTickerProviderStateMixin {
  List<dynamic> _services = [];
  List<dynamic> _forfaits = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  late TabController _tabController;
  int _currentTabIndex = 0;
  int? _selectedServiceId;
  int? _selectedForfaitId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch services
      final servicesResponse = await http.get(
        Uri.parse('http://localhost:8000/api/panne/category/${widget.categoryId}'),
        headers: {'Accept': 'application/json'},
      );

      // Fetch forfaits
      final forfaitsResponse = await http.get(
        Uri.parse('http://localhost:8000/api/forfaits'),
        headers: {'Accept': 'application/json'},
      );

      if (servicesResponse.statusCode == 200 && forfaitsResponse.statusCode == 200) {
        setState(() {
          _services = jsonDecode(servicesResponse.body);
          _forfaits = jsonDecode(forfaitsResponse.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Échec du chargement: Services: ${servicesResponse.statusCode}, Forfaits: ${forfaitsResponse.statusCode}');
      }
    } catch (e) {
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(forfait['nomForfait'] ?? 'Détails du forfait'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Prix: ${forfait['prixForfait']} DT', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Remise: ${forfait['rival']}%', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Text('Services inclus:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ...services.map<Widget>((service) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('- ${service['titre']}', style: TextStyle(fontWeight: FontWeight.bold)),
                        if (service['description'] != null)
                          Text('  ${service['description']}', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Fermer', style: TextStyle(color: Colors.teal)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _envoyerDemande() async {
    if (_selectedServiceId == null || _selectedForfaitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un service ET un forfait'),
          backgroundColor: Colors.red,
        ),
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

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Votre demande a été envoyée avec succès. Vous recevrez bientôt les prix.',
            ),
            backgroundColor: Colors.green,
          ),

        );
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>  MesDemandesPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
        // Reset selections after successful submission
        setState(() {
          _selectedServiceId = null;
          _selectedForfaitId = null;
        });
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'envoi de la demande: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: Colors.grey[200],
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
            color: Colors.teal,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Services', icon: Icon(Icons.build)),
            Tab(text: 'Packs', icon: Icon(Icons.assignment)),
          ],
          indicatorColor: Colors.teal,
          labelColor: Colors.teal,
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSelectionIndicators(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Services Tab
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text(
                        'Choisir un service',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildServicesContent(),
                    ),
                  ],
                ),
                // Forfaits Tab
                _buildForfaitsContent(),
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

  Widget _buildSelectionIndicators() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          if (_selectedServiceId != null)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.teal[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Service sélectionné',
                  style: TextStyle(
                    color: Colors.teal[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (_selectedServiceId != null && _selectedForfaitId != null)
            const SizedBox(width: 8),
          if (_selectedForfaitId != null)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Pack sélectionné',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _envoyerDemande,
          icon: const Icon(Icons.send),
          label: const Text(
            'Envoyer la demande',
            style: TextStyle(fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: _currentTabIndex == 0
              ? 'Rechercher un service...'
              : 'Rechercher un Pack...',
          prefixIcon: const Icon(Icons.search, color: Colors.teal),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildServicesContent() {
    if (_isLoading && _currentTabIndex == 0) {
      return _buildLoadingIndicator();
    }

    if (_errorMessage != null && _currentTabIndex == 0) {
      return _buildErrorState();
    }

    if (_filteredServices.isEmpty && _currentTabIndex == 0) {
      return _buildEmptyState(isServices: true);
    }

    return _buildServicesList();
  }

  Widget _buildForfaitsContent() {
    if (_isLoading && _currentTabIndex == 1) {
      return _buildLoadingIndicator();
    }

    if (_errorMessage != null && _currentTabIndex == 1) {
      return _buildErrorState();
    }

    if (_filteredForfaits.isEmpty && _currentTabIndex == 1) {
      return _buildEmptyState(isServices: false);
    }

    return _buildForfaitsList();
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement en cours...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              'Une erreur est survenue',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: _fetchData,
              child: const Text(
                'Réessayer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required bool isServices}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isServices ? Icons.handyman : Icons.assignment,
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? isServices
                ? 'Aucun service disponible'
                : 'Aucun Pack disponible'
                : 'Aucun résultat trouvé',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? isServices
                ? 'Aucun service trouvé pour cette catégorie'
                : 'Aucun Pack trouvé'
                : 'Aucun ${isServices ? 'service' : 'Pack'} ne correspond à "$_searchQuery"',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _searchQuery = ''),
              child: const Text('Réinitialiser la recherche'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServicesList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredServices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final service = _filteredServices[index];
        final isSelected = _selectedServiceId == service['id'];
        return _buildServiceCard(service, isSelected);
      },
    );
  }

  Widget _buildForfaitsList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredForfaits.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final forfait = _filteredForfaits[index];
        final isSelected = _selectedForfaitId == forfait['id'];
        return _buildForfaitCard(forfait, isSelected);
      },
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, bool isSelected) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isSelected ? Colors.teal[50] : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedServiceId = isSelected ? null : service['id'];
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service['titre'] ?? 'Service sans nom',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
              ),
              const SizedBox(height: 8),
              if (service['description'] != null)
                Text(
                  service['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              if (isSelected)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Chip(
                      label: const Text('Sélectionné'),
                      backgroundColor: Colors.teal,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForfaitCard(Map<String, dynamic> forfait, bool isSelected) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isSelected ? Colors.blue[50] : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedForfaitId = isSelected ? null : forfait['id'];
          });
        },
        onLongPress: () => _showForfaitDetails(context, forfait),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                forfait['nomForfait'] ?? 'Nom inconnu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Prix: ${forfait['prixForfait']} DT',
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Remise: ${forfait['rival']}%',
                    style: TextStyle(
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              if (isSelected)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Chip(
                      label: const Text('Sélectionné'),
                      backgroundColor: Colors.blue,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}