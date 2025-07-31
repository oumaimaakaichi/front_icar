import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class RapportMaintenanceInconnuPage extends StatefulWidget {
  final Map<String, dynamic> demande;

  const RapportMaintenanceInconnuPage({Key? key, required this.demande}) : super(key: key);

  @override
  _RapportMaintenanceInconnuPageState createState() => _RapportMaintenanceInconnuPageState();
}

class _RapportMaintenanceInconnuPageState extends State<RapportMaintenanceInconnuPage> {
  final _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  bool _isCheckingRapport = false;
  String? _errorMessage;
  String? _successMessage;
  Map<String, dynamic>? _existingRapport;
  bool _rapportExists = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _checkForExistingRapport();
  }

  Future<void> _checkForExistingRapport() async {
    setState(() {
      _isCheckingRapport = true;
      _errorMessage = null;
    });

    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/rapport-maintenance-inconnu/demande/${widget.demande['id']}'),
        headers: {
          'Accept': 'application/json',

        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _existingRapport = data;
          _rapportExists = data != null;
          if (_rapportExists) {
            _descriptionController.text = data['description'] ?? '';
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la vérification du rapport';
      });
    } finally {
      setState(() {
        _isCheckingRapport = false;
      });
    }
  }

  Future<void> _submitRapport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final token = await _storage.read(key: 'auth_token');
      final userDataJson = await _storage.read(key: 'user_data');
      final userData = jsonDecode(userDataJson!);
      final technicienId = userData['id'];

      final url = _rapportExists
          ? 'http://localhost:8000/api/rapport-maintenance-inconnu/${_existingRapport!['id']}'
          : 'http://localhost:8000/api/rapport-maintenance-inconnu';

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        'id_technicien': technicienId,
        'id_demande': widget.demande['id'],
        'description': _descriptionController.text,
      });

      late http.Response response;

      if (_rapportExists) {
        response = await http.put(Uri.parse(url), headers: headers, body: body);
      } else {
        response = await http.post(Uri.parse(url), headers: headers, body: body);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _successMessage = _rapportExists
              ? 'Rapport mis à jour avec succès!'
              : 'Rapport enregistré avec succès!';
          _isEditing = false;
        });

        await _checkForExistingRapport();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de l\'enregistrement');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _downloadRapport() async {
    if (!_rapportExists) return;

    try {
      final token = await _storage.read(key: 'auth_token');
      final pdfUrl = 'http://localhost:8000/api/rapport-maintenance-inconnu/${_existingRapport!['id']}/download';

      if (await canLaunch(pdfUrl)) {
        await launch(
          pdfUrl,
          headers: {'Authorization': 'Bearer $token'},
        );
      } else {
        throw 'Impossible d\'ouvrir l\'URL';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du téléchargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _rapportExists ? 'Rapport de maintenance' : 'Nouveau Rapport',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blueGrey,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          if (_rapportExists && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, size: 24),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: _isCheckingRapport
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Color(0xFF4A6BFF)),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card with demande info
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 3,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A6BFF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.assignment,
                            color: Color(0xFF4A6BFF),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Demande #${widget.demande['id']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.demande['service']?['titre'] ?? 'Service non spécifié',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Divider(height: 1, color: Colors.grey[200]),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 20, color: Colors.grey[600]),
                        const SizedBox(width: 10),
                        Text(
                          'Client: ${widget.demande['client']['prenom']} ${widget.demande['client']['nom']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                  ],
                ),
              ),
              const SizedBox(height: 30),

              if (_rapportExists && !_isEditing) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Text(
                    'Rapport existant',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _existingRapport?['description'] ?? '',
                          style: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Créé le: ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(_existingRapport?['created_at'] ?? DateTime.now().toString()))}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download, size: 20),
                    label: const Text(
                      'TÉLÉCHARGER LE RAPPORT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    onPressed: _downloadRapport,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blueGrey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],

              if (_isEditing || !_rapportExists) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Text(
                    'Description des travaux',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Text(
                    'Décrivez en détail les travaux effectués',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _descriptionController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: 'Ex: Remplacement du composant X, vérification du système Y...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(15),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez saisir une description';
                      }
                      if (value.length < 20) {
                        return 'La description doit être plus détaillée (min. 20 caractères)';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4A6BFF).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: const Color(0xFF4A6BFF), size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Conseil: Soyez précis en mentionnant les pièces utilisées, problèmes rencontrés et solutions apportées.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],

              // Error/Success messages
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_isEditing || !_rapportExists) ...[
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                              if (_rapportExists) {
                                _descriptionController.text = _existingRapport?['description'] ?? '';
                              }
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4A6BFF),
                            side: const BorderSide(color: Color(0xFF4A6BFF)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'ANNULER',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitRapport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A6BFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                              : const Text(
                            'ENREGISTRER',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}