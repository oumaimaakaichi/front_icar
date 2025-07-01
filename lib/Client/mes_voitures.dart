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

class _MesVoituresPageState extends State<MesVoituresPage> {
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchVoitures();
    _loadCouleurs();
    _loadEntreprises();
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
        Uri.parse('http://192.168.1.11:8000/api/couleur'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading couleurs: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadEntreprises() async {
    setState(() {
      _isLoadingEntreprises = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.11:8000/api/entreprises-with-voitures'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading entreprises: ${e.toString()}')),
      );
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
        Uri.parse('http://192.168.1.11:8000/api/voiture/${userData["id"]}?page=$page'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
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
        Uri.parse('http://192.168.1.11:8000/api/voitures'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(voitureData),
      );

      if (response.statusCode == 201) {
        _fetchVoitures();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voiture ajoutée avec succès')),
        );
      } else {
        final errorResponse = jsonDecode(response.body);
        if (errorResponse['errors'] != null) {
          final errors = errorResponse['errors'] as Map<String, dynamic>;
          final errorMessages = errors.values.expand((e) => e).join('\n');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreurs: $errorMessages')),
          );
        }
        throw Exception('Failed to add voiture: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateVoiture(int id, Map<String, dynamic> voitureData) async {
    try {
      if (voitureData['couleur'] is Couleur) {
        voitureData['couleur'] = voitureData['couleur'].nom;
      }

      final response = await http.put(
        Uri.parse('http://192.168.1.11:8000/api/voitures/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(voitureData),
      );

      if (response.statusCode == 200) {
        _fetchVoitures();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voiture modifiée avec succès')),
        );
      } else {
        throw Exception('Failed to update voiture');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteVoiture(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://192.168.1.11:8000/api/voitures/$id'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        _fetchVoitures();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voiture supprimée avec succès')),
        );
      } else {
        throw Exception('Failed to delete voiture');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
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
    final modelController = TextEditingController();
    final companyController = TextEditingController();
    final numeroChassisController = TextEditingController();
    DateTime? dateFabrication;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              elevation: 5,
              title: const Center(
                child: Text(
                  'Ajouter une voiture',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                    fontSize: 22,
                  ),
                ),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStyledTextField(
                        controller: serieController,
                        label: 'Série',
                        icon: Icons.confirmation_number_outlined,
                        isNumber: true,
                        validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer la série' : null,
                      ),
                      const SizedBox(height: 12),
                      _isLoadingEntreprises
                          ? const CircularProgressIndicator()
                          : DropdownButtonFormField<Entreprise>(
                        value: _selectedEntreprise,
                        hint: const Text('Sélectionner entreprise'),
                        items: _entreprises.map((Entreprise e) {
                          return DropdownMenuItem<Entreprise>(
                            value: e,
                            child: Row(
                              children: [
                                if (e.logo != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: Image.network(
                                      e.logo!,
                                      width: 24,
                                      height: 24,
                                      errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.business, size: 24),
                                    ),
                                  ),
                                Text(e.nom),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (Entreprise? newValue) {
                          setStateDialog(() {
                            _selectedEntreprise = newValue;
                            _selectedModele = null;
                          });
                        },
                        validator: (value) => value == null ? 'Veuillez choisir une entreprise' : null,
                        decoration: InputDecoration(
                          labelText: 'Entreprise',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_selectedEntreprise != null)
                        DropdownButtonFormField<String>(
                          value: _selectedModele,
                          hint: const Text('Sélectionner un modèle'),
                          items: _selectedEntreprise!.voitures.map((String model) {
                            return DropdownMenuItem<String>(
                              value: model,
                              child: Text(model),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setStateDialog(() {
                              _selectedModele = newValue;
                            });
                          },
                          validator: (value) => value == null ? 'Veuillez choisir un modèle' : null,
                          decoration: InputDecoration(
                            labelText: 'Modèle',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      _isLoadingCouleurs
                          ? const CircularProgressIndicator()
                          : DropdownButtonFormField<Couleur>(
                        value: _selectedCouleur,
                        hint: const Text('Sélectionner une couleur'),
                        items: _couleurs.map((Couleur c) {
                          return DropdownMenuItem<Couleur>(
                            value: c,
                            child: Text(c.nom),
                          );
                        }).toList(),
                        onChanged: (Couleur? newValue) {
                          setStateDialog(() {
                            _selectedCouleur = newValue;
                          });
                        },
                        validator: (value) => value == null ? 'Veuillez choisir une couleur' : null,
                        decoration: InputDecoration(
                          labelText: 'Couleur',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStyledTextField(
                        controller: numeroChassisController,
                        label: 'Numéro de chassis',
                        icon: Icons.credit_card_outlined,
                        isNumber: true,
                        validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer le numéro de chassis' : null,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
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
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Color(0xFF007896),
                                    ),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (selectedDate != null) {
                            setStateDialog(() {
                              dateFabrication = selectedDate;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date de fabrication',
                            labelStyle: const TextStyle(color: Color(0xFF007896)),
                            prefixIcon: const Icon(Icons.calendar_today_outlined, color: Color(0xFF007896)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF007896)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF007896)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF007896), width: 2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dateFabrication != null
                                    ? '${dateFabrication!.day}/${dateFabrication!.month}/${dateFabrication!.year}'
                                    : 'Sélectionner une date',
                                style: TextStyle(
                                  color: dateFabrication != null ? Colors.black : Colors.grey[600],
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('ANNULER', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate() && dateFabrication != null) {
                      _addVoiture({
                        'serie': int.parse(serieController.text),
                        'model': _selectedModele,
                        'couleur': _selectedCouleur,
                        'company': _selectedEntreprise?.nom,
                        'numero_chassis': numeroChassisController.text,
                        'date_fabrication': dateFabrication!.toIso8601String(),
                      });
                      Navigator.pop(context);
                    } else if (dateFabrication == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Veuillez sélectionner une date de fabrication'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: Colors.red[400],
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF007896),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                  ),
                  child: const Text('AJOUTER', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditVoitureDialog(Map<String, dynamic> voiture) {
    final formKey = GlobalKey<FormState>();
    final serieController = TextEditingController(text: voiture['serie'].toString());
    final modelController = TextEditingController(text: voiture['model']);
    final companyController = TextEditingController(text: voiture['company']);
    final numeroChassisController = TextEditingController(text: voiture['numero_chassis'].toString());
    DateTime dateFabrication = DateTime.parse(voiture['date_fabrication']);

    Couleur? selectedCouleur = _couleurs.firstWhere(
          (c) => c.nom == voiture['couleur'],
      orElse: () => Couleur(id: -1, nom: voiture['couleur']),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier la voiture'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStyledTextField(
                    controller: serieController,
                    label: 'Série',
                    icon: Icons.confirmation_number_outlined,
                    isNumber: true,
                    validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer la série' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildStyledTextField(
                    controller: modelController,
                    label: 'Modèle',
                    icon: Icons.directions_car_outlined,
                    validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer le modèle' : null,
                  ),
                  const SizedBox(height: 12),
                  _isLoadingCouleurs
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<Couleur>(
                    value: selectedCouleur,
                    hint: const Text('Sélectionner une couleur'),
                    items: _couleurs.map((Couleur c) {
                      return DropdownMenuItem<Couleur>(
                        value: c,
                        child: Text(c.nom),
                      );
                    }).toList(),
                    onChanged: (Couleur? newValue) {
                      selectedCouleur = newValue;
                    },
                    validator: (value) => value == null ? 'Veuillez choisir une couleur' : null,
                    decoration: InputDecoration(
                      labelText: 'Couleur',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStyledTextField(
                    controller: companyController,
                    label: 'Marque',
                    icon: Icons.branding_watermark_outlined,
                    validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer la marque' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildStyledTextField(
                    controller: numeroChassisController,
                    label: 'Numéro de chassis',
                    icon: Icons.credit_card_outlined,
                    isNumber: true,
                    validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer le numéro de chassis' : null,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: dateFabrication,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (selectedDate != null) {
                        dateFabrication = selectedDate;
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date de fabrication',
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${dateFabrication.day}/${dateFabrication.month}/${dateFabrication.year}',
                          ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              )),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF007896),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
                shadowColor: Color(0xFF007896).withOpacity(0.5),
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  if (dateFabrication == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Veuillez sélectionner une date de fabrication'),
                        backgroundColor: Colors.red[400],
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                    return;
                  }

                  _updateVoiture(voiture['id'], {
                    'serie': int.parse(serieController.text),
                    'model': modelController.text,
                    'couleur': selectedCouleur,
                    'company': companyController.text,
                    'numero_chassis': numeroChassisController.text,
                    'date_fabrication': dateFabrication.toIso8601String(),
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'ENREGISTRER',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStyledTextField({
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
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.blueGrey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueGrey, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007896)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            'Aucune voiture enregistrée',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Commencez par ajouter votre première voiture',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF007896),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: _showAddVoitureDialog,
            child: const Text(
              'Ajouter une voiture',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(int id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const Text('Êtes-vous sûr de vouloir supprimer cette voiture ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              )),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                _deleteVoiture(id);
                Navigator.pop(context);
              },
              child: const Text('Supprimer', style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              )),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher une voiture...',
          prefixIcon: const Icon(Icons.search, color: Colors.teal),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor:  Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildVoitureCard(Map<String, dynamic> voiture) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showEditVoitureDialog(voiture),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.directions_car,
                        size: 60,
                        color: _getCarColor(voiture['company']),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.teal),
                                SizedBox(width: 8),
                                Text('Modifier'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Supprimer'),
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
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.center,
                    child: Text(
                      voiture['model'] ?? 'Modèle inconnu',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Marque: ${voiture['company'] ?? 'Inconnue'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Série: ${voiture['serie'] ?? 'Inconnue'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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

  Color _getCarColor(String? company) {
    switch (company?.toLowerCase()) {
      case 'toyota': return Colors.red;
      case 'bmw': return Colors.blue;
      case 'mercedes': return Colors.black;
      case 'audi': return Colors.grey;
      default: return Colors.teal;
    }
  }

  Widget _buildPaginationControls() {
    final totalPages = (_totalItems / _itemsPerPage).ceil();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () => _fetchVoitures(page: _currentPage - 1)
                : null,
          ),
          Text('Page $_currentPage / $totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages
                ? () => _fetchVoitures(page: _currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Mes Voitures',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF007896),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchVoitures,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF007896),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _showAddVoitureDialog,
      ),
      body: Column(
        children: [
          _buildSearchBar(),

          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator()
                : _filteredVoitures.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,

                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemCount: _filteredVoitures.length,
              itemBuilder: (context, index) {
                final voiture = _filteredVoitures[index];
                return _buildVoitureCard(voiture);
              },
            ),
          ),
          _buildPaginationControls(),
        ],
      ),
    );
  }
}