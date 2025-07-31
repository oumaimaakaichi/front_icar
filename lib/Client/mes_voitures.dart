import 'package:car_mobile/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MesVoituresPage extends StatefulWidget {
  const MesVoituresPage({super.key});

  @override
  State<MesVoituresPage> createState() => _MesVoituresPageState();
}

class Entreprise {
  final int id;
  final String nom;
  final String? logo;
  final List<String> voitures;

  Entreprise({
    required this.id,
    required this.nom,
    this.logo,
    required this.voitures,
  });

  factory Entreprise.fromJson(Map<String, dynamic> json) {
    return Entreprise(
      id: json['id'],
      nom: json['entreprise'],
      logo: json['logo'],
      voitures: List<String>.from(json['voitures'] ?? []),
    );
  }
}

class Couleur {
  final int id;
  final String nom;

  Couleur({required this.id, required this.nom});

  factory Couleur.fromJson(Map<String, dynamic> json) {
    return Couleur(
      id: json['id'],
      nom: json['nom_couleur'],
    );
  }

  @override
  String toString() => nom;
}

class _MesVoituresPageState extends State<MesVoituresPage> with TickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();
  String? _userId;
  List<dynamic> _voitures = [];
  bool _isLoading = true;
  String? _token;
  List<Couleur> _couleurs = [];
  Couleur? _selectedCouleur;
  bool _isLoadingCouleurs = false;
  List<Entreprise> _entreprises = [];
  Entreprise? _selectedEntreprise;
  String? _selectedModele;
  bool _isLoadingEntreprises = false;
  String _searchQuery = '';
  int _currentPage = 1;
  int _itemsPerPage = 6;
  int _totalItems = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadUserData();
    _fetchVoitures();
    _loadCouleurs();
    _loadEntreprises();
    _animationController.forward();
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

  Future<void> _loadCouleurs() async {
    setState(() {
      _isLoadingCouleurs = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/couleur'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _couleurs = data.map((json) => Couleur.fromJson(json)).toList();
          _isLoadingCouleurs = false;
        });
      } else {
        throw Exception('Failed to load couleurs');
      }
    } catch (e) {
      setState(() {
        _isLoadingCouleurs = false;
      });
      _showSnackBar('Erreur lors du chargement des couleurs: ${e.toString()}',
          isError: true);
    }
  }

  Future<void> _loadEntreprises() async {
    setState(() {
      _isLoadingEntreprises = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/entreprises-with-voitures'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'];
        setState(() {
          _entreprises = data.map((json) => Entreprise.fromJson(json)).toList();
          _isLoadingEntreprises = false;
        });
      } else {
        throw Exception('Failed to load entreprises');
      }
    } catch (e) {
      setState(() {
        _isLoadingEntreprises = false;
      });
      _showSnackBar(
          'Erreur lors du chargement des entreprises: ${e.toString()}',
          isError: true);
    }
  }

  Future<void> _fetchVoitures({int page = 1}) async {
    setState(() {
      _isLoading = true;
    });
    final userDataJsons = await _storage.read(key: 'user_data');

    if (userDataJsons == null) {
      print("No user data found");
      return;
    }

    final userData = jsonDecode(userDataJsons);
    try {
      final response = await http.get(
        Uri.parse(
            'http://localhost:8000/api/voiture/${userData["id"]}?page=$page'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _voitures = responseData['data'];
          _totalItems = responseData['total'];
          _currentPage = page;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load voitures');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Erreur: ${e.toString()}', isError: true);
    }
  }

  Future<void> _addVoiture(Map<String, dynamic> voitureData) async {
    try {
      final userDataJson = await _storage.read(key: 'user_data');
      if (userDataJson != null) {
        final userData = jsonDecode(userDataJson);
        voitureData['client_id'] = userData['id'];
        voitureData['company'] = voitureData['company'] ?? '';
      }

      if (voitureData['couleur'] is Couleur) {
        voitureData['couleur'] = voitureData['couleur'].nom;
      }

      voitureData['numero_chassis'] = voitureData['numero_chassis'].toString();

      final response = await http.post(
        Uri.parse('http://localhost:8000/api/voitures'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(voitureData),
      );

      if (response.statusCode == 201) {
        _fetchVoitures();
        _showSnackBar('Voiture ajoutée avec succès', isError: false);
      } else {
        final errorResponse = jsonDecode(response.body);
        if (errorResponse['errors'] != null) {
          final errors = errorResponse['errors'] as Map<String, dynamic>;
          final errorMessages = errors.values.expand((e) => e).join('\n');
          _showSnackBar('Erreurs: $errorMessages', isError: true);
        }
        throw Exception('Failed to add voiture: ${response.body}');
      }
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}', isError: true);
    }
  }

  Future<void> _updateVoiture(int id, Map<String, dynamic> voitureData) async {
    try {
      if (voitureData['couleur'] is Couleur) {
        voitureData['couleur'] = voitureData['couleur'].nom;
      }

      final response = await http.put(
        Uri.parse('http://localhost:8000/api/voitures/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(voitureData),
      );

      if (response.statusCode == 200) {
        _fetchVoitures();
        _showSnackBar('Voiture modifiée avec succès', isError: false);
      } else {
        throw Exception('Failed to update voiture');
      }
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}', isError: true);
    }
  }

  Future<void> _deleteVoiture(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:8000/api/voitures/$id'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        _fetchVoitures();
        _showSnackBar('Voiture supprimée avec succès', isError: false);
      } else {
        throw Exception('Failed to delete voiture');
      }
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
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

  void _showAddVoitureDialog() {
    final formKey = GlobalKey<FormState>();
    final serieController = TextEditingController();
    final numeroChassisController = TextEditingController();
    DateTime? dateFabrication;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(
                    maxWidth: 400, maxHeight: 600),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header avec gradient
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF007896),
                            const Color(0xFF00A3C4)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius
                            .circular(24)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                                Icons.directions_car, color: Colors.white,
                                size: 28),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Ajouter une voiture',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    // Contenu du formulaire
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: formKey,
                          child: Column(
                            children: [
                              _buildModernTextField(
                                controller: serieController,
                                label: 'Série',
                                icon: Icons.confirmation_number_outlined,
                                isNumber: true,
                                validator: (value) =>
                                value == null || value.isEmpty
                                    ? 'Veuillez entrer la série'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              _buildModernDropdown<Entreprise>(
                                value: _selectedEntreprise,
                                hint: 'Sélectionner entreprise',
                                icon: Icons.business,
                                items: _entreprises.map((e) =>
                                    DropdownMenuItem(
                                      value: e,
                                      child: Row(
                                        children: [
                                          if (e.logo != null)
                                            ClipRRect(
                                              borderRadius: BorderRadius
                                                  .circular(4),
                                              child: Image.network(
                                                e.logo!,
                                                width: 24,
                                                height: 24,
                                                errorBuilder: (context, error,
                                                    stackTrace) =>
                                                const Icon(
                                                    Icons.business, size: 24),
                                              ),
                                            ),
                                          if (e.logo != null) const SizedBox(
                                              width: 8),
                                          Text(e.nom),
                                        ],
                                      ),
                                    )).toList(),
                                onChanged: (value) {
                                  setStateDialog(() {
                                    _selectedEntreprise = value;
                                    _selectedModele = null;
                                  });
                                },
                                validator: (value) =>
                                value == null
                                    ? 'Veuillez choisir une entreprise'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              if (_selectedEntreprise != null)
                                _buildModernDropdown<String>(
                                  value: _selectedModele,
                                  hint: 'Sélectionner un modèle',
                                  icon: Icons.directions_car,
                                  items: _selectedEntreprise!.voitures.map((
                                      model) =>
                                      DropdownMenuItem(
                                        value: model,
                                        child: Text(model),
                                      )).toList(),
                                  onChanged: (value) {
                                    setStateDialog(() {
                                      _selectedModele = value;
                                    });
                                  },
                                  validator: (value) =>
                                  value == null
                                      ? 'Veuillez choisir un modèle'
                                      : null,
                                ),
                              if (_selectedEntreprise != null) const SizedBox(
                                  height: 20),
                              _buildModernDropdown<Couleur>(
                                value: _selectedCouleur,
                                hint: 'Sélectionner une couleur',
                                icon: Icons.palette,
                                items: _couleurs.map((c) =>
                                    DropdownMenuItem(
                                      value: c,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color: _getColorFromName(c.nom),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: Colors.grey.shade300),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(c.nom),
                                        ],
                                      ),
                                    )).toList(),
                                onChanged: (value) {
                                  setStateDialog(() {
                                    _selectedCouleur = value;
                                  });
                                },
                                validator: (value) =>
                                value == null
                                    ? 'Veuillez choisir une couleur'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              _buildModernTextField(
                                controller: numeroChassisController,
                                label: 'Numéro de chassis',
                                icon: Icons.credit_card_outlined,
                                isNumber: true,
                                validator: (value) =>
                                value == null || value.isEmpty
                                    ? 'Veuillez entrer le numéro de chassis'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              _buildDatePicker(
                                date: dateFabrication,
                                onDateSelected: (date) {
                                  setStateDialog(() {
                                    dateFabrication = date;
                                  });
                                },
                              ),
                              const SizedBox(height: 32),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              12),
                                        ),
                                        side: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                      child: const Text(
                                          'Annuler', style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      )),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (formKey.currentState!.validate() &&
                                            dateFabrication != null) {
                                          _addVoiture({
                                            'serie': int.parse(
                                                serieController.text),
                                            'model': _selectedModele,
                                            'couleur': _selectedCouleur,
                                            'company': _selectedEntreprise?.nom,
                                            'numero_chassis': numeroChassisController
                                                .text,
                                            'date_fabrication': dateFabrication!
                                                .toIso8601String(),
                                          });
                                          Navigator.pop(context);
                                        } else if (dateFabrication == null) {
                                          _showSnackBar(
                                              'Veuillez sélectionner une date de fabrication',
                                              isError: true);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                            0xFF007896),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              12),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                          'Ajouter', style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      )),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
      },
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF007896).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF007896), size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF007896), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildModernDropdown<T>({
    required T? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required String? Function(T?) validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      hint: Text(hint),
      items: items,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF007896).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF007896), size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF007896), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildDatePicker({
    required DateTime? date,
    required void Function(DateTime) onDateSelected,
  }) {
    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF007896),
                  onPrimary: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            );
          },
        );
        if (selectedDate != null) {
          onDateSelected(selectedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF007896).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                  Icons.calendar_today, color: Color(0xFF007896), size: 20),
            ),
            Expanded(
              child: Text(
                date != null
                    ? '${date.day}/${date.month}/${date.year}'
                    : 'Date de fabrication',
                style: TextStyle(
                  color: date != null ? Colors.black : Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'rouge':
        return Colors.red;
      case 'bleu':
        return Colors.blue;
      case 'vert':
        return Colors.green;
      case 'jaune':
        return Colors.yellow;
      case 'noir':
        return Colors.black;
      case 'blanc':
        return Colors.white;
      case 'gris':
        return Colors.grey;
      case 'orange':
        return Colors.orange;
      case 'violet':
        return Colors.purple;
      case 'rose':
        return Colors.pink;
      default:
        return Colors.grey;
    }
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
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007896)),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement...',
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF007896).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_car,
                size: 80,
                color: Color(0xFF007896),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucune voiture enregistrée',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez par ajouter votre première voiture',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddVoitureDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Ajouter une voiture',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007896),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher une voiture...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF007896).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.search, color: Color(0xFF007896), size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              vertical: 16, horizontal: 8),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildVoitureCard(Map<String, dynamic> voiture) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showEditVoitureDialog(voiture),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getCarColor(voiture['company']).withOpacity(0.1),
                          _getCarColor(voiture['company']).withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Hero(
                            tag: 'car_${voiture['id']}',
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _getCarColor(voiture['company'])
                                    .withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.directions_car,
                                size: 48,
                                color: _getCarColor(voiture['company']),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: PopupMenuButton<String>(
                              icon: Icon(
                                  Icons.more_vert, color: Colors.grey.shade600,
                                  size: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              itemBuilder: (context) =>
                              [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                              6),
                                        ),
                                        child: const Icon(
                                            Icons.edit, color: Colors.blue,
                                            size: 16),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('Modifier'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                              6),
                                        ),
                                        child: const Icon(
                                            Icons.delete, color: Colors.red,
                                            size: 16),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('Supprimer'),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditVoitureDialog(voiture);
                                } else if (value == 'delete') {
                                  _showDeleteConfirmationDialog(voiture['id']);
                                }
                              },
                            ),
                          ),
                        ),
                        // Badge de couleur
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getColorFromName(
                                  voiture['couleur'] ?? ''),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              voiture['couleur'] ?? '',
                              style: TextStyle(
                                color: _getColorFromName(
                                    voiture['couleur'] ?? '') == Colors.white ||
                                    _getColorFromName(
                                        voiture['couleur'] ?? '') ==
                                        Colors.yellow
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
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
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              voiture['model'] ?? 'Modèle inconnu',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),

                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8,
                              vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007896).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Série: ${voiture['serie'] ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF007896),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCarColor(String? company) {
    switch (company?.toLowerCase()) {
      case 'toyota':
        return Colors.red;
      case 'bmw':
        return Colors.blue;
      case 'mercedes':
        return Colors.black;
      case 'audi':
        return Colors.grey;
      case 'volkswagen':
        return Colors.indigo;
      case 'peugeot':
        return Colors.orange;
      case 'renault':
        return Colors.yellow.shade700;
      case 'ford':
        return Colors.blue.shade800;
      default:
        return const Color(0xFF007896);
    }
  }

  void _showDeleteConfirmationDialog(int id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning, color: Colors.red),
              ),
              const SizedBox(width: 12),
              const Text('Confirmer suppression'),
            ],
          ),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer cette voiture ? Cette action est irréversible.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Annuler',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteVoiture(id);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Supprimer',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditVoitureDialog(Map<String, dynamic> voiture) {
    final formKey = GlobalKey<FormState>();
    final serieController = TextEditingController(
        text: voiture['serie'].toString());
    final modelController = TextEditingController(text: voiture['model']);
    final companyController = TextEditingController(text: voiture['company']);
    final numeroChassisController = TextEditingController(
        text: voiture['numero_chassis'].toString());
    DateTime dateFabrication = DateTime.parse(voiture['date_fabrication']);

    Couleur? selectedCouleur = _couleurs.firstWhere(
          (c) => c.nom == voiture['couleur'],
      orElse: () => Couleur(id: -1, nom: voiture['couleur']),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(
                    maxWidth: 400, maxHeight: 600),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade600, Colors.blue.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius
                            .circular(24)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                                Icons.edit, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Modifier la voiture',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    // Contenu
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: formKey,
                          child: Column(
                            children: [
                              _buildModernTextField(
                                controller: serieController,
                                label: 'Série',
                                icon: Icons.confirmation_number_outlined,
                                isNumber: true,
                                validator: (value) =>
                                value == null || value.isEmpty
                                    ? 'Veuillez entrer la série'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              _buildModernTextField(
                                controller: modelController,
                                label: 'Modèle',
                                icon: Icons.directions_car_outlined,
                                validator: (value) =>
                                value == null || value.isEmpty
                                    ? 'Veuillez entrer le modèle'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              _buildModernDropdown<Couleur>(
                                value: selectedCouleur,
                                hint: 'Sélectionner une couleur',
                                icon: Icons.palette,
                                items: _couleurs.map((c) =>
                                    DropdownMenuItem(
                                      value: c,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color: _getColorFromName(c.nom),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: Colors.grey.shade300),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(c.nom),
                                        ],
                                      ),
                                    )).toList(),
                                onChanged: (value) {
                                  setStateDialog(() {
                                    selectedCouleur = value;
                                  });
                                },
                                validator: (value) =>
                                value == null
                                    ? 'Veuillez choisir une couleur'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              _buildModernTextField(
                                controller: companyController,
                                label: 'Marque',
                                icon: Icons.branding_watermark_outlined,
                                validator: (value) =>
                                value == null || value.isEmpty
                                    ? 'Veuillez entrer la marque'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              _buildModernTextField(
                                controller: numeroChassisController,
                                label: 'Numéro de chassis',
                                icon: Icons.credit_card_outlined,
                                isNumber: true,
                                validator: (value) =>
                                value == null || value.isEmpty
                                    ? 'Veuillez entrer le numéro de chassis'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              _buildDatePicker(
                                date: dateFabrication,
                                onDateSelected: (date) {
                                  setStateDialog(() {
                                    dateFabrication = date;
                                  });
                                },
                              ),
                              const SizedBox(height: 32),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              12),
                                        ),
                                        side: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                      child: const Text(
                                          'Annuler', style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      )),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (formKey.currentState!.validate()) {
                                          _updateVoiture(voiture['id'], {
                                            'serie': int.parse(
                                                serieController.text),
                                            'model': modelController.text,
                                            'couleur': selectedCouleur,
                                            'company': companyController.text,
                                            'numero_chassis': numeroChassisController
                                                .text,
                                            'date_fabrication': dateFabrication
                                                .toIso8601String(),
                                          });
                                          Navigator.pop(context);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade600,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              12),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                          'Enregistrer', style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      )),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
      },
    );
  }

  Widget _buildPaginationControls() {
    final totalPages = (_totalItems / _itemsPerPage).ceil();

    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: _currentPage > 1
                ? () => _fetchVoitures(page: _currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left, size: 18),
            label: const Text('Précédent'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentPage > 1
                  ? const Color(0xFF007896)
                  : Colors.grey.shade300,
              foregroundColor: _currentPage > 1 ? Colors.white : Colors.grey
                  .shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF007896).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Page $_currentPage / $totalPages',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF007896),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _currentPage < totalPages
                ? () => _fetchVoitures(page: _currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right, size: 18),
            label: const Text('Suivant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentPage < totalPages ? const Color(
                  0xFF007896) : Colors.grey.shade300,
              foregroundColor: _currentPage < totalPages ? Colors.white : Colors
                  .grey.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Mes Voitures',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF007896),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF007896), Color(0xFF00A3C4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchVoitures,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVoitureDialog,
        backgroundColor: const Color(0xFF007896),
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.add),
        label: const Text(
          'Ajouter',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator()
                : _filteredVoitures.isEmpty
                ? _buildEmptyState()
                : FadeTransition(
              opacity: _fadeAnimation,
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: _filteredVoitures.length,
                itemBuilder: (context, index) {
                  final voiture = _filteredVoitures[index];
                  return _buildVoitureCard(voiture);
                },
              ),
            ),
          ),
          _buildPaginationControls(),
        ],
      ),
    );
  }
}