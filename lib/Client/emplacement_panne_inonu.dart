import 'package:car_mobile/Client/domicile_emplacement_inconnu.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:car_mobile/Client/confirmation_page.dart';

class MaintenanceTypePagee extends StatefulWidget {
  final int voitureId;
  final int clientId;
  final String problemDescription;

  const MaintenanceTypePagee({
    Key? key,
    required this.voitureId,
    required this.clientId,
    required this.problemDescription,
  }) : super(key: key);

  @override
  _MaintenanceTypePageeState createState() => _MaintenanceTypePageeState();
}

class _MaintenanceTypePageeState extends State<MaintenanceTypePagee>
    with TickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isFixed = true;
  dynamic _selectedAtelier;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  bool _isLoadingMore = false;

  List<dynamic> _ateliers = [];
  String _searchQuery = '';
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();

    // Écouter le scroll pour la pagination
    _scrollController.addListener(_onScroll);

    _fetchAteliers();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (_hasMore && !_isLoadingMore) {
        _loadMoreAteliers();
      }
    }
  }

  Future<void> _fetchAteliers({bool isNewSearch = false}) async {
    if (isNewSearch) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _ateliers.clear();
      });
    } else {
      setState(() => _isLoading = true);
    }

    try {
      final uri = Uri.parse('http://localhost:8000/api/ateliers').replace(
        queryParameters: {
          'page': _currentPage.toString(),
          'per_page': '10',
          if (_searchQuery.isNotEmpty) 'ville': _searchQuery,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          if (isNewSearch || _currentPage == 1) {
            _ateliers = data['data'] ?? [];
          } else {
            _ateliers.addAll(data['data'] ?? []);
          }

          _currentPage = data['current_page'] ?? 1;
          _totalPages = data['last_page'] ?? 1;
          _hasMore = _currentPage < _totalPages;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load ateliers');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur de chargement: ${e.toString()}');
    }
  }

  Future<void> _loadMoreAteliers() async {
    if (!_hasMore || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      _currentPage++;
      final uri = Uri.parse('http://localhost:8000/api/ateliers').replace(
        queryParameters: {
          'page': _currentPage.toString(),
          'per_page': '10',
          if (_searchQuery.isNotEmpty) 'ville': _searchQuery,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _ateliers.addAll(data['data'] ?? []);
          _hasMore = _currentPage < (data['last_page'] ?? 1);
          _isLoadingMore = false;
        });
      } else {
        _currentPage--; // Revenir à la page précédente en cas d'erreur
        throw Exception('Failed to load more ateliers');
      }
    } catch (e) {
      setState(() => _isLoadingMore = false);
      _showErrorSnackBar('Erreur de chargement: ${e.toString()}');
    }
  }

  void _onSearchChanged(String value) {
    if (_searchQuery != value) {
      setState(() {
        _searchQuery = value;
        _selectedAtelier = null; // Réinitialiser la sélection lors d'une nouvelle recherche
      });

      // Debounce la recherche
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_searchQuery == value && mounted) {
          _fetchAteliers(isNewSearch: true);
        }
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _submitDemande() async {
    if (_isFixed && (_selectedAtelier == null || _selectedDate == null || _selectedTime == null)) {
      _showErrorSnackBar('Veuillez compléter toutes les informations');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final storage = FlutterSecureStorage();
      final userDataJson = await storage.read(key: 'user_data');
      if (userDataJson == null) {
        throw Exception('Utilisateur non connecté');
      }

      final userData = jsonDecode(userDataJson);
      final clientId = userData['id'];
      if (clientId == null) {
        throw Exception('ID client introuvable');
      }

      // Simuler des coordonnées GPS (à remplacer par les vraies valeurs)
      final latitude = 0.0; // Remplacer par la vraie latitude
      final longitude = 0.0; // Remplacer par la vraie longitude

      final response = await http.post(
        Uri.parse('http://localhost:8000/api/demandes-panne-inconnue'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'voiture_id': widget.voitureId,
          'client_id': clientId,
          'description_probleme': widget.problemDescription,
          'type_emplacement': _isFixed ? 'fixe' : 'domicile',
          'atelier_id': _isFixed ? _selectedAtelier['id'] : null,
          'date_maintenance': _selectedDate != null
              ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
              : null,
          'heure_maintenance': _selectedTime != null
              ? _selectedTime!.format(context)
              : null,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmationPage(
              demande: responseData['data'],
              isFixed: _isFixed,
            ),
          ),
        );
      } else {
        final errorMessage = responseData['message'] ??
            responseData['errors']?.toString() ??
            'Erreur inconnue (${response.statusCode})';
        throw Exception(errorMessage);
      }
    } catch (e) {
      _showErrorSnackBar('Erreur: ${e.toString()}');
      debugPrint('Erreur détaillée: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Type de maintenance',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.green.shade600,
                  size: 20,
                ),
              ),
              onPressed: _isLoading ? null : _submitDemande,
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _isLoading && _ateliers.isEmpty
              ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Chargement...'),
              ],
            ),
          )
              : SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec titre
                Text(
                  'Choisissez votre type de maintenance',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sélectionnez l\'option qui vous convient le mieux',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                // Cards de sélection d'emplacement
                Row(
                  children: [
                    Expanded(
                      child: _buildLocationCard(
                        title: 'En atelier',
                        subtitle: 'Amenez votre véhicule',
                        icon: Icons.store,
                        isSelected: _isFixed,
                        onTap: () => setState(() {
                          _isFixed = true;
                          _selectedDate = null;
                          _selectedTime = null;
                        }),
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade600, Colors.blue.shade800],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildLocationCard(
                        title: 'À domicile',
                        subtitle: 'On vient chez vous',
                        icon: Icons.home,
                        isSelected: !_isFixed,
                        onTap: () {
                          setState(() {
                            _isFixed = false;
                            _selectedAtelier = null;
                            _selectedDate = null;
                            _selectedTime = null;
                          });

                          // Navigation vers une autre page avec les paramètres
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DomicileEmplacementPage(
                                  voitureId: widget.voitureId,
                                  clientId: widget.clientId,
                                  problemDescription: widget.problemDescription
                              ),
                            ),
                          );
                        },
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade600, Colors.orange.shade800],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Contenu dynamique selon le choix
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isFixed ? _buildFixedMaintenanceContent() : _buildMobileMaintenanceContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Gradient gradient,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? gradient.colors.first.withOpacity(0.3) : Colors.grey.shade200,
              blurRadius: isSelected ? 15 : 8,
              offset: Offset(0, isSelected ? 8 : 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedMaintenanceContent() {
    return Column(
      key: const ValueKey('fixed'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sélectionnez un atelier',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),

        // Barre de recherche
        _buildSearchBar(),
        const SizedBox(height: 16),

        _buildAtelierList(),
        if (_selectedAtelier != null) ...[
          const SizedBox(height: 32),
          _buildDateTimeSelection(),
        ],
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Rechercher par ville...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: Colors.grey.shade400),
            onPressed: () {
              _searchController.clear();
              _onSearchChanged('');
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildAtelierList() {
    return Column(
      children: [
        if (_ateliers.isEmpty && !_isLoading)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.car_repair, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Aucun atelier trouvé pour "$_searchQuery"'
                      : 'Aucun atelier disponible',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._ateliers.map((atelier) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedAtelier != null && _selectedAtelier['id'] == atelier['id']
                    ? Colors.blue.shade300
                    : Colors.grey.shade200,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _selectedAtelier != null && _selectedAtelier['id'] == atelier['id']
                      ? Colors.blue.shade100
                      : Colors.grey.shade100,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.car_repair, color: Colors.blue.shade600),
              ),
              title: Text(
                atelier['nom_commercial'] ?? 'Atelier',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (atelier['ville'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_city, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          atelier['ville'],
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (atelier['adresse'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      atelier['adresse'],
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
              trailing: _selectedAtelier != null && _selectedAtelier['id'] == atelier['id']
                  ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.check, color: Colors.green.shade600, size: 20),
              )
                  : null,
              onTap: () => setState(() => _selectedAtelier = atelier),
            ),
          )),

        // Indicateur de chargement pour plus d'éléments
        if (_isLoadingMore)
          Container(
            padding: const EdgeInsets.all(16),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),

        // Indicateur de fin de liste
        if (!_hasMore && _ateliers.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Tous les ateliers ont été chargés',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDateTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Planifiez votre rendez-vous',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              CalendarDatePicker(
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 60)),
                onDateChanged: (date) => setState(() => _selectedDate = date),
              ),
              if (_selectedDate != null) ...[
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.access_time, color: Colors.orange.shade600),
                  ),
                  title: const Text('Heure de maintenance'),
                  subtitle: Text(
                    _selectedTime != null
                        ? _selectedTime!.format(context)
                        : 'Sélectionner une heure',
                    style: TextStyle(
                      color: _selectedTime != null ? Colors.grey.shade800 : Colors.grey.shade500,
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime ?? TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() => _selectedTime = time);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
        if (_selectedDate != null && _selectedTime != null) ...[
          const SizedBox(height: 24),
          _buildSubmitButton(),
        ],
      ],
    );
  }

  Widget _buildMobileMaintenanceContent() {
    return Container(
      key: const ValueKey('mobile'),
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade100, Colors.orange.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.home,
              size: 64,
              color: Colors.orange.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Maintenance à domicile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Un technicien vous contactera pour convenir d\'un rendez-vous à votre domicile',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade300,
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitDemande,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Confirmer la demande',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.send,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}