import 'package:car_mobile/Client/homeClient.dart';
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
  List<dynamic> _ateliers = [];
  bool _isLoadingAteliers = false;
  bool _isUpdating = false;
  dynamic _selectedAtelier;
  DateTime? _selectedDate;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAteliers();
  }

  Future<void> _fetchAteliers() async {
    setState(() {
      _isLoadingAteliers = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.17:8000/api/ateliers'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _ateliers = jsonDecode(response.body);
          _isLoadingAteliers = false;
        });
      } else {
        throw Exception('Failed to load ateliers');
      }
    } catch (e) {
      setState(() {
        _isLoadingAteliers = false;
        _errorMessage = 'Erreur de chargement des ateliers';
      });
    }
  }

  void _selectPlacementType(bool isFixed) {
    setState(() {
      _showAteliers = isFixed;
      _showCalendar = false;
      _selectedAtelier = null;
      _selectedDate = null;
      _errorMessage = null;
    });
  }

  void _selectAtelier(dynamic atelier) {
    setState(() {
      _selectedAtelier = atelier;
      _showCalendar = true;
      _errorMessage = null;
    });
  }

  Future<void> _updateDemandeInfo() async {
    if (_selectedDate == null) {
      setState(() {
        _errorMessage = 'Veuillez sélectionner une date';
      });
      return;
    }

    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      final response = await http.put(
        Uri.parse('http://192.168.1.17:8000/api/demandes/${widget.demandeId}/update-info'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'type_emplacement': 'fixe',
          'date_maintenance': _selectedDate?.toIso8601String(),

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

  Future<void> _confirmMobileMaintenance() async {
    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      final response = await http.put(
        Uri.parse('http://192.168.1.17:8000/api/demandes/${widget.demandeId}/update-info'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'type_emplacement': 'mobile',
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ConfirmationPage(
              atelier: null,
              date: null,
              isFixed: false,
              demandeId: widget.demandeId,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = responseData['message'] ??
              responseData['errors']?.values.first?.first ??
              'Erreur lors de la confirmation';
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
        title: const Text('Type de Maintenance'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            if (!_showAteliers && !_showCalendar) ...[
              const Text(
                'Choisir le type de maintenance',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: _MaintenanceCard(
                      title: 'En atelier',
                      subtitle: 'Réparation dans notre centre',
                      icon: Icons.location_on,
                      color: Colors.blue[800]!,
                      onTap: () => _selectPlacementType(true),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _MaintenanceCard(
                      title: 'À domicile',
                      subtitle: 'Déplacement de notre technicien',
                      icon: Icons.directions_car,
                      color: Colors.green[700]!,
                      onTap: () {
                        _selectPlacementType(false);
                        _confirmMobileMaintenance();
                      },
                    ),
                  ),
                ],
              ),
            ],

            if (_showAteliers && !_showCalendar) ...[
              _buildBackButton(() {
                setState(() {
                  _showAteliers = false;
                });
              }),
              const SizedBox(height: 20),
              _isLoadingAteliers
                  ? const Center(child: CircularProgressIndicator())
                  : _ateliers.isEmpty
                  ? const Center(child: Text('Aucun atelier disponible'))
                  : _buildAteliersList(),
            ],

            if (_showCalendar) ...[
              _buildBackButton(() {
                setState(() {
                  _showCalendar = false;
                });
              }),
              const SizedBox(height: 20),
              _buildCalendarSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(VoidCallback onPressed) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onPressed,
        ),
        const SizedBox(width: 10),
        Text(
          _showCalendar
              ? '${_selectedAtelier['nom_commercial']} - ${_selectedAtelier['ville']}'
              : 'Sélectionner un atelier',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAteliersList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _ateliers.length,
      itemBuilder: (context, index) {
        final atelier = _ateliers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const Icon(Icons.car_repair, size: 40),
            title: Text(
              atelier['nom_commercial'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(atelier['ville']),
                if (atelier['adresse'] != null) Text(atelier['adresse']),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectAtelier(atelier),
            selected: _selectedAtelier != null &&
                _selectedAtelier['id'] == atelier['id'],
            selectedTileColor: Colors.blue[50],
          ),
        );
      },
    );
  }

  Widget _buildCalendarSection() {
    return Column(
      children: [
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _selectedDate ?? DateTime.now(),
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDate = selectedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonDecoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                ),
                formatButtonTextStyle: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_selectedDate != null) ...[
          Text(
            'Date sélectionnée: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: _isUpdating
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _updateDemandeInfo,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Confirmer le rendez-vous',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MaintenanceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
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
  final bool isFixed;
  final int demandeId;

  const ConfirmationPage({
    Key? key,
    required this.atelier,
    required this.date,
    required this.isFixed,
    required this.demandeId,
  }) : super(key: key);
  Future<List<dynamic>> _fetchCataloguePieces() async {
    final response = await http.get(
      Uri.parse('http://192.168.1.17:8000/api/catalogues'), // Remplacez par votre URL
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement du catalogue');
    }
  }
  Future<Map<String, dynamic>> _fetchDemandeDetails() async {
    final response = await http.get(
      Uri.parse('http://192.168.1.17:8000/api/$demandeId/confirmation-details'),
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
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final details = snapshot.data!;
          final piecesChoisies = details['pieces_choisies'] as List<dynamic>;
          final totalPieces = details['total_pieces'] ?? 0;
          final totalMainOeuvre = details['total_main_oeuvre'] ?? 0;
          final dateMaintenance = details['date_maintenance'] != null
              ? DateTime.parse(details['date_maintenance'])
              : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  const Icon(Icons.check_circle, color: Colors.green, size: 80),
                  const SizedBox(height: 10),
                  const Text(
                    'Rendez-vous confirmé!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Informations sur le service
                          ListTile(
                            leading: const Icon(Icons.build),
                            title: const Text('Service'),
                            subtitle: Text(details['service_titre'] ?? 'Non spécifié'),
                          ),

                          // Informations sur la voiture
                          ListTile(
                            leading: const Icon(Icons.directions_car),
                            title: const Text('Voiture'),
                            subtitle: Text(details['voiture_model'] ?? 'Non spécifié'),
                          ),

                          // Total des pièces
                          ListTile(
                            leading: const Icon(Icons.shopping_cart),
                            title: const Text('Total pièces'),
                            trailing: Text('$totalPieces €'),
                          ),

                          // Total main d'œuvre


                          // Bouton pour voir les pièces choisies
                          if (piecesChoisies.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.list),
                                label: const Text('Voir les pièces choisies'),
                                onPressed: () {
                                  _showPiecesDialog(context, piecesChoisies);
                                },
                              ),
                            ),

                          if (isFixed) ...[
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.business),
                              title: const Text('Atelier'),
                              subtitle: Text(atelier['nom_commercial']),
                            ),
                            ListTile(
                              leading: const Icon(Icons.location_on),
                              title: const Text('Adresse'),
                              subtitle: Text(
                                  '${atelier['adresse'] ?? ''}\n${atelier['ville'] ?? ''}'),
                            ),
                            if (dateMaintenance != null)
                              ListTile(
                                leading: const Icon(Icons.calendar_today),
                                title: const Text('Date et heure'),
                                subtitle: Text(
                                  DateFormat('EEEE dd MMMM yyyy - HH:mm', 'fr_FR')
                                      .format(dateMaintenance),
                                ),
                              ),
                          ] else ...[
                            const Divider(),
                            const ListTile(
                              leading: Icon(Icons.directions_car),
                              title: Text('Type de service'),
                              subtitle: Text('Maintenance à domicile'),
                            ),
                            const ListTile(
                              leading: Icon(Icons.info),
                              title: Text('Information'),
                              subtitle: Text(
                                  'Un technicien vous contactera pour convenir d\'un rendez-vous'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => ClientHomePage()),
                        (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blue,
                ),
                child: const Text('Payer', style: TextStyle(color: Colors.white)),
              )

              ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showPiecesDialog(BuildContext context, List<dynamic> pieces) async {
    try {
      // Étape 1 : récupérer les catalogues
      final response = await http.get(
        Uri.parse('http://192.168.1.17:8000/api/catalogues'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors du chargement du catalogue');
      }

      final catalogues = jsonDecode(response.body);

      // Étape 2 : afficher les pièces avec nom_piece du catalogue si possible
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

                // 🔍 on suppose que piece contient une clé "id_piece"
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