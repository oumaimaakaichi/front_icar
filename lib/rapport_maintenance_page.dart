import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class RapportMaintenancePage extends StatefulWidget {
  final Map<String, dynamic> demande;

  const RapportMaintenancePage({Key? key, required this.demande}) : super(key: key);

  @override
  _RapportMaintenancePageState createState() => _RapportMaintenancePageState();
}

class _RapportMaintenancePageState extends State<RapportMaintenancePage> {
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
        Uri.parse('http://localhost:8000/api/rapport-maintenance/demande/${widget.demande['id']}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
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
          ? 'http://localhost:8000/api/rapport-maintenance/${_existingRapport!['id']}'
          : 'http://localhost:8000/api/rapport-maintenance';

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
      final pdfUrl = 'http://localhost:8000/api/rapport-maintenance/${_existingRapport!['id']}/download';

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
      appBar: AppBar(
        title: Text(
          _rapportExists ? 'Rapport de maintenance' : 'Nouveau Rapport',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor:  Color(0xFF6C5CE7),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_rapportExists && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: _isCheckingRapport
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card with demande info
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.assignment, color: Colors.blueGrey),
                          const SizedBox(width: 10),
                          Text(
                            'Demande #${widget.demande['id']}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.demande['service']?['titre'] ?? 'Service non spécifié',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 5),
                          Text(
                            '${widget.demande['client']['prenom']} ${widget.demande['client']['nom']}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),

              if (_rapportExists && !_isEditing) ...[
                const Text(
                  'Rapport existant',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.green[100]!, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _existingRapport?['description'] ?? '',
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Créé le: ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(_existingRapport?['created_at'] ?? DateTime.now().toString()))}',
                              style: TextStyle(color: Colors.grey[600]),
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
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text(
                      'TÉLÉCHARGER LE RAPPORT PDF',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _downloadRapport,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blueGrey[800],
                      side: BorderSide(color: Colors.blueGrey[800]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],

              if (_isEditing || !_rapportExists) ...[
                const Text(
                  'Description des travaux*',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: 'Décrivez en détail les travaux effectués...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blueGrey),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ce champ est obligatoire';
                    }
                    if (value.length < 20) {
                      return 'La description doit être plus détaillée';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Error/Success messages
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

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
                            foregroundColor: Colors.blueGrey[800],
                            side: BorderSide(color: Colors.blueGrey[800]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'ANNULER',
                            style: TextStyle(fontWeight: FontWeight.bold),
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
                            backgroundColor: Colors.blueGrey[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isSubmitting
                              ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          )
                              : const Text(
                            'ENREGISTRER',
                            style: TextStyle(
                              fontSize: 16,
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