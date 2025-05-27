import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:car_mobile/Client/homeClient.dart';


class MobileMaintenanceFlow extends StatefulWidget {
  final int demandeId;

  const MobileMaintenanceFlow({Key? key, required this.demandeId}) : super(key: key);

  @override
  _MobileMaintenanceFlowState createState() => _MobileMaintenanceFlowState();
}

class _MobileMaintenanceFlowState extends State<MobileMaintenanceFlow> {
  int _currentStep = 0;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  LatLng? _selectedLocation;
  bool _isLoading = false;
  String? _errorMessage;
  bool _confirmed = false;
  String? _selectedLocationType;
  final Map<String, dynamic> _locationDetails = {};

  final List<String> _locationTypes = [
    'Maison',
    'Quartier général privé',
    'En travail',
    'Parking'
  ];

  @override
  Widget build(BuildContext context) {
    if (_confirmed) {
      return MaintenanceConfirmationPage(
        date: _selectedDate,
        time: _selectedTime,
        demandeId: widget.demandeId,
        location: _selectedLocation,
        locationType: _selectedLocationType,
        locationDetails: _locationDetails,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Maintenance Mobile',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0C2B4B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1A4B8C),
          ),
        ),
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _continue,
          onStepCancel: _cancel,
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep != 0)
                    OutlinedButton(
                      onPressed: details.onStepCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: const BorderSide(color: Color(0xFF1A4B8C)),
                      ),
                      child: const Text(
                        'Retour',
                        style: TextStyle(color: Color(0xFF1A4B8C)),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A4B8C),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      _currentStep == 3 ? 'Confirmer' : 'Suivant',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
          steps: _buildSteps(),
        ),
      ),
    );

  }

  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text('Date et heure', style: TextStyle(fontWeight: FontWeight.bold)),
        content: _buildDateTimeSelection(),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Type d\'emplacement', style: TextStyle(fontWeight: FontWeight.bold)),
        content: _buildLocationTypeSelection(),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Détails', style: TextStyle(fontWeight: FontWeight.bold)),
        content: _buildLocationDetails(),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Confirmation', style: TextStyle(fontWeight: FontWeight.bold)),
        content: _buildConfirmation(),
        isActive: _currentStep >= 3,
      ),
    ];
  }

  Widget _buildDateTimeSelection() {
    return Column(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Text('Sélectionnez une date',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _selectedDate ?? DateTime.now(),
                  selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDate = selectedDay;
                      _errorMessage = null;
                    });
                  },
                  calendarStyle: const CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: Color(0xFF1A4B8C),
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Color(0xFF3A7BDB),
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    leftChevronIcon: const Icon(Icons.chevron_left, color: Color(0xFF1A4B8C)),
                    rightChevronIcon: const Icon(Icons.chevron_right, color: Color(0xFF1A4B8C)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Text('Sélectionnez une heure',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.access_time, color: Color(0xFF1A4B8C)),
                  title: Text(
                    _selectedTime == null
                        ? 'Choisir une heure'
                        : _selectedTime!.format(context),
                    style: const TextStyle(fontSize: 16),
                  ),
                  trailing: const Icon(Icons.arrow_drop_down),
                  onTap: () => _selectTime(context),
                ),
              ],
            ),
          ),
        ),
        if (_selectedDate != null && _selectedTime != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF1A4B8C), size: 20),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('EEEE dd MMMM', 'fr_FR').format(_selectedDate!)} à ${_selectedTime!.format(context)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
        if (_errorMessage != null && _currentStep == 0)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A4B8C),
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
        _errorMessage = null;
      });
    }
  }

  Widget _buildLocationTypeSelection() {
    return Column(
      children: [
        const Text('Où souhaitez-vous effectuer la maintenance ?',
            style: TextStyle(fontSize: 16, color: Colors.black54)),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.2,
          children: _locationTypes.map((type) {
            return _buildLocationTypeCard(type);
          }).toList(),
        ),
        if (_errorMessage != null && _currentStep == 1)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationTypeCard(String type) {
    final isSelected = _selectedLocationType == type;
    IconData icon;
    Color color;

    switch (type) {
      case 'Maison':
        icon = Icons.home;
        color = const Color(0xFF4CAF50);
        break;
      case 'Quartier général privé':
        icon = Icons.business;
        color = const Color(0xFF2196F3);
        break;
      case 'En travail':
        icon = Icons.work;
        color = const Color(0xFFFF9800);
        break;
      case 'Parking':
        icon = Icons.local_parking;
        color = const Color(0xFF9C27B0);
        break;
      default:
        icon = Icons.location_on;
        color = const Color(0xFF607D8B);
    }

    return InkWell(
      onTap: () {
        setState(() {
          _selectedLocationType = type;
          _errorMessage = null;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              type,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected ? color : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDetails() {
    if (_selectedLocationType == null) {
      return const Center(child: Text('Veuillez sélectionner un type d\'emplacement'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Position sur la carte',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        const Text('Appuyez sur la carte pour sélectionner l\'emplacement',
            style: TextStyle(fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 15),
        SizedBox(
          height: 250,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              options: MapOptions(
                center: _selectedLocation ??  LatLng(24.713552, 46.675296),
                zoom: 13.0,
                onTap: (tapPosition, latLng) {
                  setState(() {
                    _selectedLocation = latLng;
                    _errorMessage = null;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                if (_selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation!,
                        builder: (ctx) => const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (_selectedLocation != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F0FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF1A4B8C), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                      'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        ..._buildSpecificLocationFields(),
        if (_errorMessage != null && _currentStep == 2)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildSpecificLocationFields() {
    switch (_selectedLocationType) {
      case 'Maison':
      case 'Quartier général privé':
        return [
          _buildNumberField(
            label: _selectedLocationType == 'Maison'
                ? 'Surface de la maison (m²)'
                : 'Surface du bureau (m²)',
            onChanged: (value) => _locationDetails['surface'] = double.tryParse(value),
          ),
          const SizedBox(height: 15),
          _buildNumberField(
            label: 'Hauteur du plafond (m)',
            onChanged: (value) => _locationDetails['hauteur_plafond'] = double.tryParse(value),
          ),
          const SizedBox(height: 15),
          const Text('Dimensions du portail',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  label: 'Hauteur (m)',
                  onChanged: (value) => _locationDetails['porte_hauteur'] = double.tryParse(value),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildNumberField(
                  label: 'Largeur (m)',
                  onChanged: (value) => _locationDetails['porte_largeur'] = double.tryParse(value),
                ),
              ),
            ],
          ),
        ];
      case 'En travail':
        return [
          _buildNumberField(
            label: 'Surface parking travail (m²)',
            onChanged: (value) => _locationDetails['surface'] = double.tryParse(value),
          ),
          const SizedBox(height: 15),
          const Text('Dimensions du portail',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  label: 'Hauteur (m)',
                  onChanged: (value) => _locationDetails['porte_hauteur'] = double.tryParse(value),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildNumberField(
                  label: 'Largeur (m)',
                  onChanged: (value) => _locationDetails['porte_largeur'] = double.tryParse(value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SwitchListTile(
            title: const Text('Autorisation d\'entrée'),
            value: _locationDetails['autorisation_entree'] ?? false,
            onChanged: (bool value) {
              setState(() {
                _locationDetails['autorisation_entree'] = value;
              });
            },
            activeColor: const Color(0xFF1A4B8C),
          ),
        ];
      case 'Parking':
        return [
          const SizedBox(height: 15),
          SwitchListTile(
            title: const Text('Proximité parking public'),
            value: _locationDetails['proximite_parking_public'] ?? true,
            onChanged: (bool value) {
              setState(() {
                _locationDetails['proximite_parking_public'] = value;
              });
            },
            activeColor: const Color(0xFF1A4B8C),
          ),
        ];
      default:
        return [];
    }
  }

  Widget _buildNumberField({required String label, required Function(String) onChanged}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }

  Widget _buildConfirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                const Text(
                  'Récapitulatif',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.build, 'Service:', 'Maintenance mobile'),
                _buildInfoRow(Icons.calendar_today, 'Date:',
                    _selectedDate != null && _selectedTime != null
                        ? '${DateFormat('EEEE dd MMMM', 'fr_FR').format(_selectedDate!)} à ${_selectedTime!.format(context)}'
                        : 'Non définie'),
                _buildInfoRow(Icons.location_on, 'Type:', _selectedLocationType ?? 'Non défini'),
                if (_selectedLocation != null)
                  _buildInfoRow(Icons.map, 'Position:',
                      'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}\n'
                          'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}'),
                ..._buildSpecificInfoRows(),
              ],
            ),
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_errorMessage != null && _currentStep == 3)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildSpecificInfoRows() {
    switch (_selectedLocationType) {
      case 'Maison':
      case 'Quartier général privé':
        return [
          _buildInfoRow(Icons.square_foot, 'Surface:',
              '${_locationDetails['surface']?.toStringAsFixed(2) ?? '--'} m²'),
          _buildInfoRow(Icons.height, 'Hauteur plafond:',
              '${_locationDetails['hauteur_plafond']?.toStringAsFixed(2) ?? '--'} m'),
          _buildInfoRow(Icons.door_back_door, 'Portail:',
              'H: ${_locationDetails['porte_hauteur']?.toStringAsFixed(2) ?? '--'} m, '
                  'L: ${_locationDetails['porte_largeur']?.toStringAsFixed(2) ?? '--'} m'),
        ];
      case 'En travail':
        return [
          _buildInfoRow(Icons.square_foot, 'Surface parking:',
              '${_locationDetails['surface']?.toStringAsFixed(2) ?? '--'} m²'),
          _buildInfoRow(Icons.door_back_door, 'Portail:',
              'H: ${_locationDetails['porte_hauteur']?.toStringAsFixed(2) ?? '--'} m, '
                  'L: ${_locationDetails['porte_largeur']?.toStringAsFixed(2) ?? '--'} m'),
          _buildInfoRow(Icons.verified_user, 'Autorisation:',
              (_locationDetails['autorisation_entree'] ?? false) ? 'Oui' : 'Non'),
        ];
      case 'Parking':
        return [
          _buildInfoRow(Icons.local_parking, 'Proximité parking public:',
              (_locationDetails['proximite_parking_public'] ?? true) ? 'Oui' : 'Non'),
        ];
      default:
        return [];
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1A4B8C)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _cancel() {
    setState(() {
      _errorMessage = null;
      if (_currentStep > 0) {
        _currentStep -= 1;
      }
    });
  }

  void _continue() {
    if (_currentStep == 0) {
      if (_selectedDate == null) {
        setState(() => _errorMessage = 'Veuillez sélectionner une date');
        return;
      }
      if (_selectedTime == null) {
        setState(() => _errorMessage = 'Veuillez sélectionner une heure');
        return;
      }
    }

    if (_currentStep == 1 && _selectedLocationType == null) {
      setState(() => _errorMessage = 'Veuillez sélectionner un type d\'emplacement');
      return;
    }

    if (_currentStep == 2) {
      if (_selectedLocation == null) {
        setState(() => _errorMessage = 'Veuillez sélectionner un emplacement sur la carte');
        return;
      }

      switch (_selectedLocationType) {
        case 'Maison':
          if (_locationDetails['surface'] == null) {
            setState(() => _errorMessage = 'Veuillez entrer la surface');
            return;
          }
          if (_locationDetails['hauteur_plafond'] == null) {
            setState(() => _errorMessage = 'Veuillez entrer la hauteur du plafond');
            return;
          }
          if (_locationDetails['porte_hauteur'] == null || _locationDetails['porte_largeur'] == null) {
            setState(() => _errorMessage = 'Veuillez entrer les dimensions du portail');
            return;
          }
          break;
        case 'Quartier général privé':
          if (_locationDetails['surface'] == null) {
            setState(() => _errorMessage = 'Veuillez entrer la surface');
            return;
          }
          if (_locationDetails['hauteur_plafond'] == null) {
            setState(() => _errorMessage = 'Veuillez entrer la hauteur du plafond');
            return;
          }
          if (_locationDetails['porte_hauteur'] == null || _locationDetails['porte_largeur'] == null) {
            setState(() => _errorMessage = 'Veuillez entrer les dimensions du portail');
            return;
          }
          break;
        case 'En travail':
          if (_locationDetails['surface'] == null) {
            setState(() => _errorMessage = 'Veuillez entrer la surface');
            return;
          }
          if (_locationDetails['porte_hauteur'] == null || _locationDetails['porte_largeur'] == null) {
            setState(() => _errorMessage = 'Veuillez entrer les dimensions du portail');
            return;
          }
          break;
      }
    }

    if (_currentStep == 3) {
      _confirmMaintenance();
      return;
    }

    setState(() {
      _errorMessage = null;
      _currentStep += 1;
    });
  }

  Future<void> _confirmMaintenance() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Map<String, dynamic> requestData = {
        'date_maintenance': _selectedDate!.toIso8601String(),
        'heure_maintenance': _selectedTime!.format(context),
        'type_emplacement': _selectedLocationType!.toLowerCase().replaceAll(' ', '_'),
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
      };

      switch (_selectedLocationType) {
        case 'Maison':
          requestData.addAll({
            'surface_maison': _locationDetails['surface'],
            'hauteur_plafond_maison': _locationDetails['hauteur_plafond'],
            'porte_garage_maison': {
              'hauteur': _locationDetails['porte_hauteur'],
              'largeur': _locationDetails['porte_largeur'],
            },
          });
          break;
        case 'Quartier général privé':
          requestData.addAll({
            'surface_bureau': _locationDetails['surface'],
            'hauteur_plafond_bureau': _locationDetails['hauteur_plafond'],
            'porte_garage_bureau': {
              'hauteur': _locationDetails['porte_hauteur'],
              'largeur': _locationDetails['porte_largeur'],
            },
          });
          break;
        case 'En travail':
          requestData.addAll({
            'surface_parking_travail': _locationDetails['surface'],
            'porte_travail': {
              'hauteur': _locationDetails['porte_hauteur'],
              'largeur': _locationDetails['porte_largeur'],
            },
            'autorisation_entree_travail': _locationDetails['autorisation_entree'] ?? false,
          });
          break;
        case 'Parking':
          requestData.addAll({
            'proximite_parking_public': _locationDetails['proximite_parking_public'] ?? true,
          });
          break;
      }

      final response = await http.put(
        Uri.parse('http://192.168.1.17:8000/api/demandes/${widget.demandeId}/update-location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      if (response.statusCode != 200) {
        throw Exception('Échec de la requête: ${response.statusCode}');
      }

      setState(() => _confirmed = true);
    } catch (e) {
      setState(() => _errorMessage = 'Erreur: ${e.toString()}');
    } finally {
      if (!_confirmed) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class MaintenanceConfirmationPage extends StatelessWidget {
  final DateTime? date;
  final TimeOfDay? time;
  final int demandeId;
  final LatLng? location;
  final String? locationType;
  final Map<String, dynamic> locationDetails;

  const MaintenanceConfirmationPage({
    Key? key,
    required this.date,
    required this.time,
    required this.demandeId,
    this.location,
    this.locationType,
    this.locationDetails = const {},
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate = date != null && time != null
        ? '${DateFormat('EEEE dd MMMM', 'fr_FR').format(date!)} à ${time!.format(context)}'
        : 'Non définie';

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF006D77), Color(0xFF83C5BE)],



              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 60,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Demande confirmée !',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Votre demande a été enregistrée avec succès',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Détails de la demande',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0C2B4B),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildDetailRow(Icons.build, 'Service:', 'Maintenance mobile'),
                          _buildDetailRow(Icons.calendar_today, 'Date:', formattedDate),
                          _buildDetailRow(Icons.location_on, 'Type:', locationType ?? 'Non défini'),
                          if (location != null)
                            _buildDetailRow(Icons.map, 'Position:',
                                'Lat: ${location!.latitude.toStringAsFixed(6)}\n'
                                    'Lng: ${location!.longitude.toStringAsFixed(6)}'),
                          ..._buildSpecificDetails(),
                        ],
                      ),
                    ),
                  ),
                ),
                if (location != null) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: SizedBox(
                          height: 200,
                          child: FlutterMap(
                            options: MapOptions(
                              center: location ??  LatLng(24.713552, 46.675296),
                              zoom: 15.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                subdomains: const ['a', 'b', 'c'],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: location!,
                                    builder: (ctx) => const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const ClientHomePage()),
                              (Route<dynamic> route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0C2B4B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Retour à l\'accueil',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSpecificDetails() {
    switch (locationType) {
      case 'Maison':
      case 'Quartier général privé':
        return [
          _buildDetailRow(Icons.square_foot, 'Surface:',
              '${locationDetails['surface']?.toStringAsFixed(2) ?? '--'} m²'),
          _buildDetailRow(Icons.height, 'Hauteur plafond:',
              '${locationDetails['hauteur_plafond']?.toStringAsFixed(2) ?? '--'} m'),
          _buildDetailRow(Icons.door_back_door, 'Portail:',
              'H: ${locationDetails['porte_hauteur']?.toStringAsFixed(2) ?? '--'} m\n'
                  'L: ${locationDetails['porte_largeur']?.toStringAsFixed(2) ?? '--'} m'),
        ];
      case 'En travail':
        return [
          _buildDetailRow(Icons.square_foot, 'Surface parking:',
              '${locationDetails['surface']?.toStringAsFixed(2) ?? '--'} m²'),
          _buildDetailRow(Icons.door_back_door, 'Portail:',
              'H: ${locationDetails['porte_hauteur']?.toStringAsFixed(2) ?? '--'} m\n'
                  'L: ${locationDetails['porte_largeur']?.toStringAsFixed(2) ?? '--'} m'),
          _buildDetailRow(Icons.verified_user, 'Autorisation:',
              (locationDetails['autorisation_entree'] ?? false) ? 'Oui' : 'Non'),
        ];
      case 'Parking':
        return [
          _buildDetailRow(Icons.local_parking, 'Proximité parking public:',
              (locationDetails['proximite_parking_public'] ?? true) ? 'Oui' : 'Non'),
        ];
      default:
        return [];
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}