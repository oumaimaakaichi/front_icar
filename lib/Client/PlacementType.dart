import 'package:car_mobile/Client/homeClient.dart';
import 'package:car_mobile/Client/mobile_maintenance_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class MaintenanceTypePage extends StatefulWidget {
  final int demandeId;

  const MaintenanceTypePage({
    Key? key,
    required this.demandeId,
  }) : super(key: key);

  @override
  _MaintenanceTypePageState createState() => _MaintenanceTypePageState();
}

class _MaintenanceTypePageState extends State<MaintenanceTypePage> {
  bool _showAteliers = false;
  bool _showCalendar = false;
  bool _showTimePicker = false;
  List<dynamic> _ateliers = [];
  bool _isLoadingAteliers = false;
  bool _isUpdating = false;
  bool _isLoadingAvailability = false;
  dynamic _selectedAtelier;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  String? _errorMessage;
  Map<String, List<String>> _availability = {};
  List<String> _availableSlots = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;

  // Variables pour la recherche et pagination
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchAteliers();
    _setupScrollListener();
    _setupSearchListener();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        _loadMoreAteliers();
      }
    });
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      if (_searchController.text != _searchQuery) {
        setState(() {
          _searchQuery = _searchController.text;
        });
        _debounceSearch();
      }
    });
  }

  // Debounce pour éviter trop de requêtes
  void _debounceSearch() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (_searchController.text == _searchQuery && mounted) {
        _fetchAteliers(isNewSearch: true);
      }
    });
  }

  Future<void> _fetchAteliers({bool isNewSearch = false}) async {
    if (isNewSearch) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _ateliers.clear();
        _hasMore = true;
      });
    } else if (_currentPage == 1) {
      setState(() => _isLoading = true);
    }

    try {
      final queryParams = <String, String>{
        'page': _currentPage.toString(),
        'per_page': '10',
      };

      // Ajouter le paramètre de recherche seulement s'il n'est pas vide
      if (_searchQuery.trim().isNotEmpty) {
        queryParams['search'] = _searchQuery.trim();
      }

      final uri = Uri.parse('http://localhost:8000/api/ateliers').replace(
        queryParameters: queryParams,
      );

      print('Fetching ateliers: $uri'); // Debug

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}'); // Debug
      print('Response body: ${response.body}'); // Debug

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
          _isLoadingMore = false;
        });
      } else {
        throw Exception('Failed to load ateliers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching ateliers: $e'); // Debug
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      _showErrorSnackBar('Erreur de chargement: ${e.toString()}');
    }
  }

  Future<void> _loadMoreAteliers() async {
    if (!_hasMore || _isLoadingMore || _isLoading) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final queryParams = <String, String>{
        'page': nextPage.toString(),
        'per_page': '10',
      };

      if (_searchQuery.trim().isNotEmpty) {
        queryParams['search'] = _searchQuery.trim();
      }

      final uri = Uri.parse('http://localhost:8000/api/ateliers').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _ateliers.addAll(data['data'] ?? []);
          _currentPage = nextPage;
          _hasMore = _currentPage < (data['last_page'] ?? 1);
          _isLoadingMore = false;
        });
      } else {
        throw Exception('Failed to load more ateliers');
      }
    } catch (e) {
      setState(() => _isLoadingMore = false);
      _showErrorSnackBar('Erreur de chargement supplémentaire: ${e.toString()}');
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    _fetchAteliers(isNewSearch: true);
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

  Future<void> _fetchAtelierAvailability(int atelierId) async {
    setState(() {
      _isLoadingAvailability = true;
      _availability = {};
      _availableSlots = [];
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/atelier/$atelierId/disponibilite'),
        headers: {
          'Accept': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['availability'] != null) {
          final rawAvailability = data['availability'] as Map<String, dynamic>;

          final parsedAvailability = rawAvailability.map((day, slots) {
            return MapEntry(day, List<String>.from(slots));
          });

          setState(() {
            _availability = parsedAvailability;
            _isLoadingAvailability = false;
          });
        } else {
          throw Exception('Format de disponibilité invalide ou manquant');
        }
      } else {
        throw Exception('Code de statut non 200');
      }

      print('Disponibilité: $_availability');
    } catch (e) {
      print('Erreur: $e');
      setState(() {
        _isLoadingAvailability = false;
        _errorMessage = 'Erreur de chargement des disponibilités';
      });
    }
  }

  void _selectPlacementType(bool isFixed) {
    if (isFixed) {
      setState(() {
        _showAteliers = true;
        _showCalendar = false;
        _showTimePicker = false;
        _selectedAtelier = null;
        _selectedDate = null;
        _selectedTime = null;
        _errorMessage = null;
      });
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MobileMaintenanceFlow(demandeId: widget.demandeId),
        ),
      );
    }
  }

  void _selectAtelier(dynamic atelier) async {
    setState(() {
      _selectedAtelier = atelier;
      _showCalendar = true;
      _showTimePicker = false;
      _errorMessage = null;
    });
    await _fetchAtelierAvailability(atelier['id']);
  }

  bool _isDayAvailable(DateTime day) {
    if (_availability.isEmpty) return false;

    final weekday = day.weekday;
    String dayName;

    switch (weekday) {
      case 1: dayName = 'lundi'; break;
      case 2: dayName = 'mardi'; break;
      case 3: dayName = 'mercredi'; break;
      case 4: dayName = 'jeudi'; break;
      case 5: dayName = 'vendredi'; break;
      case 6: dayName = 'samedi'; break;
      case 7: dayName = 'dimanche'; break;
      default: dayName = '';
    }

    return _availability.containsKey(dayName) &&
        _availability[dayName]!.isNotEmpty;
  }

  void _updateAvailableSlots(DateTime selectedDay) {
    final weekday = selectedDay.weekday;
    String dayName;

    switch (weekday) {
      case 1: dayName = 'lundi'; break;
      case 2: dayName = 'mardi'; break;
      case 3: dayName = 'mercredi'; break;
      case 4: dayName = 'jeudi'; break;
      case 5: dayName = 'vendredi'; break;
      case 6: dayName = 'samedi'; break;
      case 7: dayName = 'dimanche'; break;
      default: dayName = '';
    }

    setState(() {
      _availableSlots = _availability[dayName] ?? [];
    });
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6C63FF),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _updateDemandeInfo() async {
    if (_selectedDate == null) {
      setState(() {
        _errorMessage = 'Veuillez sélectionner une date';
      });
      return;
    }

    if (_selectedTime == null) {
      setState(() {
        _errorMessage = 'Veuillez sélectionner une heure';
      });
      return;
    }

    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final timeStr = _selectedTime!.format(context);

      final response = await http.put(
        Uri.parse('http://localhost:8000/api/demandes/${widget.demandeId}/update-info'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'type_emplacement': 'fixe',
          'date_maintenance': dateStr,
          'heure_maintenance': timeStr,
          'atelier_id': _selectedAtelier['id'],
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ConfirmationPage(
              atelier: _selectedAtelier,
              date: _selectedDate!,
              time: _selectedTime!,
              isFixed: true,
              demandeId: widget.demandeId,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = responseData['message'] ??
              responseData['errors']?.values.first?.first ??
              'Erreur lors de la mise à jour';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Place de Maintenance', style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF6797A2),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF5F7FF)],
          ),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_showAteliers && !_showCalendar && !_showTimePicker) ...[
                // Header Section
                Container(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Text(
                        'Choisissez votre Place de maintenance',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Sélectionnez l\'option qui correspond à vos besoins',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 35),

                // Cards Section
                Row(
                  children: [
                    // Card "En atelier"
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectPlacementType(true),
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF667EEA),
                                Color(0xFF764BA2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF667EEA).withOpacity(0.4),
                                blurRadius: 15,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Decorative circles
                              Positioned(
                                top: -15,
                                right: -15,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -20,
                                left: -20,
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),

                              // Content
                              Padding(
                                padding: EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Icon and arrow
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.home_repair_service,
                                            size: 24,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.white.withOpacity(0.7),
                                          size: 16,
                                        ),
                                      ],
                                    ),

                                    Spacer(),

                                    // Text content
                                    Text(
                                      'En atelier',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Réparation dans notre atelier',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Équipement ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white.withOpacity(0.85),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 20),

                    // Card "À domicile"
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectPlacementType(false),
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF43CEA2),
                                Color(0xFF185A9D),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF43CEA2).withOpacity(0.4),
                                blurRadius: 15,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Decorative circles
                              Positioned(
                                top: -15,
                                right: -15,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -20,
                                left: -20,
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),

                              // Content
                              Padding(
                                padding: EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Icon and arrow
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.directions_car,
                                            size: 24,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.white.withOpacity(0.7),
                                          size: 16,
                                        ),
                                      ],
                                    ),

                                    Spacer(),

                                    // Text content
                                    Text(
                                      'À domicile',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Déplacement de notre technicien',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Service personnalisé',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white.withOpacity(0.85),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 30),

                // Info Card améliorée
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  padding: EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Color(0xFFE5E7EB),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF000000).withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF3B82F6),
                              Color(0xFF1D4ED8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Information importante',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Nos techniciens qualifiés interviennent du lundi au vendredi de 8h à 18h. Pour les interventions à domicile, des frais de déplacement peuvent s\'appliquer selon votre localisation.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_showAteliers && !_showCalendar && !_showTimePicker) ...[
                _buildBackButton(() {
                  setState(() {
                    _showAteliers = false;
                  });
                }),
                SizedBox(height: 20),
                Text(
                  'Sélectionnez un atelier',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Choisissez l\'atelier le plus proche de chez vous',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 20),
                _buildSearchBar(),
                SizedBox(height: 20),
                _buildAteliersList(),
                if (_isLoadingMore)
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                      ),
                    ),
                  ),
              ],

              if (_showCalendar && !_showTimePicker) ...[
                _buildBackButton(() {
                  setState(() {
                    _showCalendar = false;
                  });
                }),
                SizedBox(height: 20),

                // Affichage des disponibilités
                if (_isLoadingAvailability)
                  Center(child: CircularProgressIndicator())
                else if (_availability.isNotEmpty)
                  buildAvailabilityInfo(),

                SizedBox(height: 20),
                _buildCalendarSection(),
                if (_selectedDate != null) ...[
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showTimePicker = true;
                        _showCalendar = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6C63FF),
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Choisir l\'heure',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ],

              if (_showTimePicker) ...[
                _buildBackButton(() {
                  setState(() {
                    _showTimePicker = false;
                    _showCalendar = true;
                  });
                }),
                SizedBox(height: 20),
                _buildTimePickerSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher par ville, nom d\'atelier...',
          prefixIcon: Icon(Icons.search, color: Color(0xFF6C63FF)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: Colors.grey),
            onPressed: _clearSearch,
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildAteliersList() {
    if (_isLoading && _ateliers.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
          ),
        ),
      );
    }

    if (_ateliers.isEmpty && !_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.location_off, size: 60, color: Colors.grey),
              SizedBox(height: 20),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Aucun atelier trouvé pour "${_searchQuery}"'
                    : 'Aucun atelier disponible',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (_searchQuery.isNotEmpty) ...[
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _clearSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6C63FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Effacer la recherche', style: TextStyle(color: Colors.white)),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Info sur les résultats
        if (_searchQuery.isNotEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFF6C63FF).withOpacity(0.2)),
            ),
            child: Text(
              '${_ateliers.length} atelier(s) trouvé(s) pour "${_searchQuery}"',
              style: TextStyle(
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // Liste des ateliers
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _ateliers.length,
          itemBuilder: (context, index) {
            final atelier = _ateliers[index];
            return Container(
              margin: EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.car_repair, size: 24, color: Colors.blueGrey),
                ),
                title: Text(
                  atelier['nom_commercial'] ?? 'Atelier ${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            atelier['ville'] ?? 'Ville non spécifiée',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    if (atelier['adresse'] != null && atelier['adresse'].toString().isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          atelier['adresse'],
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (atelier['telephone'] != null)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.phone, size: 12, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              atelier['telephone'],
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.blueGrey),
                onTap: () => _selectAtelier(atelier),
              ),
            );
          },
        ),

        // Pagination info
        if (_ateliers.isNotEmpty && _totalPages > 1)
          Container(
            margin: EdgeInsets.only(top: 20),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Page $_currentPage sur $_totalPages',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (_hasMore) ...[
                  SizedBox(width: 8),
                  Text(
                    '• Faites défiler pour plus',
                    style: TextStyle(
                      color: Color(0xFF6C63FF),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget buildAvailabilityInfo() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF8F9FF),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6C63FF).withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Color(0xFF6C63FF).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec icône et titre
            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Color(0xFF6C63FF).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.access_time_rounded,
                      color: Color(0xFF6C63FF),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Disponibilités de l\'atelier',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Color(0xFF2D3436),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFF00B894).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Ouvert',
                      style: TextStyle(
                        color: Color(0xFF00B894),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Liste des disponibilités - 2 jours par ligne
            ..._buildAvailabilityRows(),

            SizedBox(height: 16),

            // Note informative
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFFFF3CD).withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(0xFFFFC107).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFFE67E22),
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Les horaires peuvent varier selon les événements spéciaux',
                      style: TextStyle(
                        color: Color(0xFFE67E22),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Fonction pour construire les lignes avec 2 jours par ligne
  Widget _buildAvailabilityInfo() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF8F9FF),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6C63FF).withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Color(0xFF6C63FF).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec icône et titre
            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Color(0xFF6C63FF).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.access_time_rounded,
                      color: Color(0xFF6C63FF),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Disponibilités de l\'atelier',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Color(0xFF2D3436),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFF00B894).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Ouvert',
                      style: TextStyle(
                        color: Color(0xFF00B894),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Liste des disponibilités - 2 jours par ligne
            ..._buildAvailabilityRows(),

            SizedBox(height: 16),

            // Note informative
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFFFF3CD).withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(0xFFFFC107).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFFE67E22),
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Les horaires peuvent varier selon les événements spéciaux',
                      style: TextStyle(
                        color: Color(0xFFE67E22),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Fonction pour construire les lignes avec 2 jours par ligne
  List<Widget> _buildAvailabilityRows() {
    List<Widget> rows = [];
    List<MapEntry<String, List<String>>> entries = _availability.entries
        .map<MapEntry<String, List<String>>>((entry) =>
        MapEntry(entry.key as String, entry.value as List<String>))
        .toList();

    for (int i = 0; i < entries.length; i += 2) {
      List<Widget> rowChildren = [];

      // Premier jour de la ligne
      rowChildren.add(
        Expanded(
          child: _buildDayCard(entries[i]),
        ),
      );

      // Espacement entre les deux cards
      if (i + 1 < entries.length) {
        rowChildren.add(SizedBox(width: 12));

        // Deuxième jour de la ligne
        rowChildren.add(
          Expanded(
            child: _buildDayCard(entries[i + 1]),
          ),
        );
      }

      rows.add(
        Container(
          margin: EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowChildren,
          ),
        ),
      );
    }

    return rows;
  }

// Fonction pour construire une card de jour
  Widget _buildDayCard(MapEntry<String, List<String>> entry) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            spreadRadius: 0,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Jour avec indicateur coloré
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: _getDayColor(entry.key),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF2D3436),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // Horaires
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: entry.value.map((time) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFF6C63FF).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Color(0xFF6C63FF).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 12,
                      color: Color(0xFF6C63FF),
                    ),
                    SizedBox(width: 3),
                    Text(
                      time,
                      style: TextStyle(
                        color: Color(0xFF6C63FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

// Fonction helper pour obtenir la couleur selon le jour
  Color _getDayColor(String day) {
    switch (day.toLowerCase()) {
      case 'lundi':
        return Color(0xFF6C63FF);
      case 'mardi':
        return Color(0xFF00B894);
      case 'mercredi':
        return Color(0xFFE17055);
      case 'jeudi':
        return Color(0xFFFFB142);
      case 'vendredi':
        return Color(0xFFE84393);
      case 'samedi':
        return Color(0xFF00CEC9);
      case 'dimanche':
        return Color(0xFFFF7675);
      default:
        return Color(0xFF6C63FF);
    }
  }
  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFF6C63FF), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nos ateliers sont équipés des dernières technologies pour un service optimal',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back, color: Colors.black),
            SizedBox(width: 8),
            Text(
              _showTimePicker
                  ? 'Choisir l\'heure'
                  : _showCalendar
                  ? '${_selectedAtelier['nom_commercial']}'
                  : 'Sélectionner un atelier',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Choisir une date',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: TableCalendar<dynamic>(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _selectedDate ?? DateTime.now(),
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              onDaySelected: (selectedDay, focusedDay) {
                if (_isDayAvailable(selectedDay)) {
                  setState(() {
                    _selectedDate = selectedDay;
                    _updateAvailableSlots(selectedDay);
                  });
                }
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              availableCalendarFormats: const {
                CalendarFormat.month: 'Mois',
                CalendarFormat.week: 'Semaine',
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF764ba2)],
                  ),
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: const TextStyle(color: Colors.red),
                defaultTextStyle: const TextStyle(
                  color: Color(0xFF2D3748),
                  fontWeight: FontWeight.w500,
                ),
                outsideDaysVisible: false,
                markersMaxCount: 3,
                disabledTextStyle: TextStyle(color: Colors.grey[300]),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonDecoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                formatButtonTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                titleTextStyle: const TextStyle(
                  color: Color(0xFF2D3748),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                leftChevronIcon: const Icon(
                  Icons.chevron_left_rounded,
                  color: Color(0xFF6C63FF),
                ),
                rightChevronIcon: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF6C63FF),
                ),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: Color(0xFF2D3748),
                  fontWeight: FontWeight.w500,
                ),
                weekendStyle: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              enabledDayPredicate: (day) {
                return _isDayAvailable(day);
              },
            ),
          ),
          if (_selectedDate != null) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6C63FF).withOpacity(0.1),
                    const Color(0xFF764ba2).withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.today_rounded,
                      size: 20,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Date: ${DateFormat('EEEE dd MMMM', 'fr_FR').format(_selectedDate!)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimePickerSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 0,
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.schedule_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Choisissez l\'heure ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _selectTime(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF6C63FF).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: const Color(0xFF6C63FF),
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _selectedTime == null
                                  ? 'Sélectionner une heure'
                                  : 'Heure choisie: ${_selectedTime!.format(context)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.grey[400],
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_selectedTime != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF0F4FF), Color(0xFFE8F2FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.summarize_rounded,
                          color: Color(0xFF6C63FF),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Résumé',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSummaryItem(Icons.business_rounded, 'Atelier', _selectedAtelier['nom_commercial']),
                  _buildSummaryItem(Icons.location_on_rounded, 'Adresse', _selectedAtelier['ville']),
                  _buildSummaryItem(
                    Icons.event_rounded,
                    'Date et heure',
                    '${DateFormat('EEEE dd MMMM', 'fr_FR').format(_selectedDate!)} à ${_selectedTime!.format(context)}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: _isUpdating
                  ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                ),
              )
                  : ElevatedButton(
                onPressed: _updateDemandeInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ).copyWith(
                  backgroundColor: MaterialStateProperty.all(Colors.transparent),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF764ba2)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    alignment: Alignment.center,
                    child: const Text(
                      'Confirmer le rendez-vous',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: const Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
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
}

class _MaintenanceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Gradient? gradient;
  final VoidCallback onTap;

  const _MaintenanceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: Colors.white),
            ),
            SizedBox(height: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ConfirmationPage extends StatelessWidget {
  final dynamic atelier;
  final DateTime? date;
  final TimeOfDay? time;
  final bool isFixed;
  final int demandeId;

  const ConfirmationPage({
    Key? key,
    required this.atelier,
    required this.date,
    required this.time,
    required this.isFixed,
    required this.demandeId,
  }) : super(key: key);

  Future<List<dynamic>> _fetchCataloguePieces() async {
    final response = await http.get(
      Uri.parse('http://localhost:8000/api/catalogues'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement du catalogue');
    }
  }

  Future<Map<String, dynamic>> _fetchDemandeDetails() async {
    final response = await http.get(
      Uri.parse('http://localhost:8000/api/$demandeId/confirmation-details'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load demande details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchDemandeDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final details = snapshot.data!;
          final piecesChoisies = details['pieces_choisies'] as List<dynamic>;
          final totalPieces = details['total_pieces'] ?? 0;
          final totalMainOeuvre = details['total_main_oeuvre'] ?? 0;
          final totalTTC = totalPieces + totalMainOeuvre;

          DateTime? dateTimeMaintenance;
          if (date != null && time != null) {
            dateTimeMaintenance = DateTime(
              date!.year,
              date!.month,
              date!.day,
              time!.hour,
              time!.minute,
            );
          }

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF006D77), Color(0xFF83C5BE)],
                  ),
                ),
              ),
              SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    SizedBox(height: 40),
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Color(0xFF4CAF50),
                        size: 60,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Rendez-vous confirmé!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Votre demande a été enregistrée avec succès',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    SizedBox(height: 40),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Détails de la demande',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          SizedBox(height: 20),
                          _buildDetailItem(
                            Icons.build,
                            'Service',
                            details['service_titre'] ?? 'Non spécifié',
                          ),
                          _buildDetailItem(
                            Icons.directions_car,
                            'Voiture',
                            details['voiture_model'] ?? 'Non spécifié',
                          ),
                          _buildDetailItem(
                            Icons.shopping_cart,
                            'Total pièces',
                            '$totalPieces €',
                            isPrice: true,
                          ),
                          Divider(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total TTC',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$totalTTC €',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF83C5BE),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          if (piecesChoisies.isNotEmpty)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  _showPiecesDialog(context, piecesChoisies);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFF0F4FF),
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.list, size: 20),
                                    SizedBox(width: 8),
                                    Text('Voir les pièces choisies'),
                                  ],
                                ),
                              ),
                            ),
                          SizedBox(height: 20),
                          Divider(height: 30),
                          if (isFixed) ...[
                            _buildDetailItem(
                              Icons.business,
                              'Atelier',
                              atelier['nom_commercial'],
                            ),
                            _buildDetailItem(
                              Icons.location_on,
                              'Adresse',
                              '${atelier['ville'] ?? ''}',
                            ),
                            if (dateTimeMaintenance != null)
                              _buildDetailItem(
                                Icons.calendar_today,
                                'Date et heure',
                                DateFormat('EEEE dd MMMM yyyy - HH:mm', 'fr_FR')
                                    .format(dateTimeMaintenance),
                              ),
                          ] else ...[
                            _buildDetailItem(
                              Icons.directions_car,
                              'Type de service',
                              'Maintenance à domicile',
                            ),
                            _buildDetailItem(
                              Icons.info,
                              'Information',
                              'Un technicien vous contactera pour convenir d\'un rendez-vous',
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => ClientHomePage()),
                                (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Payer maintenant',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => ClientHomePage()),
                              (route) => false,
                        );
                      },
                      child: Text(
                        'Retour à l\'accueil',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value,
      {bool isPrice = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color: Color(0xFF83C5BE),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
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
                    fontWeight: isPrice ? FontWeight.bold : FontWeight.normal,
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

  Future<void> _showPiecesDialog(BuildContext context, List<dynamic> pieces) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/catalogues'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors du chargement du catalogue');
      }

      final catalogues = jsonDecode(response.body);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pièces choisies'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: pieces.length,
              itemBuilder: (context, index) {
                final piece = pieces[index];

                final catalogueMatch = catalogues.firstWhere(
                      (c) => c['id'] == piece['piece_id'],
                  orElse: () => null,
                );

                final nomPiece = catalogueMatch != null
                    ? catalogueMatch['nom_piece']
                    : piece['nom_piece'] ?? 'Pièce ${index + 1}';

                return ListTile(
                  title: Text(nomPiece),
                  subtitle: Text('Type: ${piece['type'] ?? 'Inconnu'}'),
                  trailing: Text('${piece['prix'] ?? '0'} €'),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erreur'),
          content: Text('Impossible de charger les pièces :\n${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}