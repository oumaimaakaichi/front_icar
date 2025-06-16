import 'package:car_mobile/Client/homeClient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DomicileEmplacementPage extends StatefulWidget {
  final int voitureId;
  final int categoryId;
  final int clientId;
  final String problemDescription;

  const DomicileEmplacementPage({
    Key? key,
    required this.voitureId,
    required this.categoryId,
    required this.clientId,
    required this.problemDescription,
  }) : super(key: key);

  @override
  State<DomicileEmplacementPage> createState() => _DomicileEmplacementPageState();
}

class _DomicileEmplacementPageState extends State<DomicileEmplacementPage> {
  int _currentStep = 0;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  LatLng? _selectedLocation;
  String? _selectedLocationType;
  final Map<String, dynamic> _locationDetails = {};
  bool _isLoading = false;
  bool _confirmed = false;

  final List<String> _locationTypes = [
    'maison',
    'quartier_general_prive',
    'en_travail',
    'parking'
  ];

  final Map<String, String> _locationTypeLabels = {
    'maison': 'Maison',
    'quartier_general_prive': 'Bureau',
    'en_travail': 'Lieu de travail',
    'parking': 'Parking'
  };

  final Map<String, IconData> _locationTypeIcons = {
    'maison': Icons.home,
    'quartier_general_prive': Icons.business,
    'en_travail': Icons.work,
    'parking': Icons.local_parking,
  };

  @override
  Widget build(BuildContext context) {
    if (_confirmed) {
      return MaintenanceConfirmationPage(
        date: _selectedDate,
        time: _selectedTime,
        location: _selectedLocation,
        locationType: _selectedLocationType,
        locationDetails: _locationDetails,
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1A4B8C),
          secondary: Color(0xFF1A4B8C),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Maintenance à Domicile',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blueGrey,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Stack(
          children: [
            Stepper(
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
                          child: const Text('Retour',
                              style: TextStyle(color: Color(0xFF1A4B8C))),
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
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A4B8C)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text('Date et heure', style: TextStyle(fontSize: 16)),
        content: _buildDateTimeSelection(),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Type d\'emplacement', style: TextStyle(fontSize: 16)),
        content: _buildLocationTypeSelection(),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Détails', style: TextStyle(fontSize: 16)),
        content: _buildLocationDetails(),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Confirmation', style: TextStyle(fontSize: 16)),
        content: _buildConfirmation(),
        isActive: _currentStep >= 3,
        state: _currentStep == 3 ? StepState.editing : StepState.indexed,
      ),
    ];
  }

  Widget _buildDateTimeSelection() {
    return Column(
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('Sélectionnez une date',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A4B8C))),
                const SizedBox(height: 12),
                TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _selectedDate ?? DateTime.now(),
                  selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                  onDaySelected: (selectedDay, _) =>
                      setState(() => _selectedDate = selectedDay),
                  locale: 'fr_FR',
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                        color: Color(0xFF1A4B8C),
                        fontWeight: FontWeight.w600),
                  ),
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: const Color(0xFF1A4B8C),
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFF1A4B8C).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: const Icon(Icons.access_time, color: Color(0xFF1A4B8C)),
            title: Text(
              _selectedTime == null
                  ? 'Choisir une heure'
                  : _selectedTime!.format(context),
              style: const TextStyle(fontSize: 16),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _selectedTime ?? TimeOfDay.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF1A4B8C),
                        onSurface: Colors.black,
                      ),
                      timePickerTheme: TimePickerThemeData(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) setState(() => _selectedTime = picked);
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Où souhaitez-vous effectuer la maintenance ?',
              style: TextStyle(fontSize: 16, color: Colors.black87)),
        ),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: _locationTypes.map(_buildLocationTypeCard).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationTypeCard(String type) {
    final isSelected = _selectedLocationType == type;
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF1A4B8C) : Colors.grey.shade200,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selectedLocationType = type),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _locationTypeIcons[type],
                size: 32,
                color: isSelected ?  Colors.orange : Colors.green,
              ),
              const SizedBox(height: 8),
              Text(
                _locationTypeLabels[type] ?? type,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ?  Colors.orange : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationDetails() {
    if (_selectedLocationType == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Veuillez sélectionner un type d\'emplacement',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Position sur la carte',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A4B8C),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                options: MapOptions(
                  center: _selectedLocation ??  LatLng(24.713552, 46.675296),
                  zoom: 13,
                  onTap: (_, latLng) => setState(() => _selectedLocation = latLng),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.example.app',
                  ),
                  if (_selectedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation!,
                          builder: (_) => const Icon(
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
          const SizedBox(height: 20),
          ..._buildSpecificLocationFields(),
        ],
      ),
    );
  }

  List<Widget> _buildSpecificLocationFields() {
    switch (_selectedLocationType) {
      case 'maison':
        return [
          _numberField(
            label: 'Surface (m²)',
            icon: Icons.square_foot,
            onChanged: (v) => _locationDetails['surface_maison'] = double.tryParse(v),
          ),
          _numberField(
            label: 'Hauteur plafond (m)',
            icon: Icons.height,
            onChanged: (v) => _locationDetails['hauteur_plafond_maison'] = double.tryParse(v),
          ),
          _multiSelectField(
            label: 'Porte garage',
            icon: Icons.garage,
            options: const ['simple', 'double', 'battante', 'sectionnelle'],
            selectedOptions:
            List<String>.from(_locationDetails['porte_garage_maison'] ?? []),
            onChanged: (selected) => _locationDetails['porte_garage_maison'] = selected,
          ),
          if ((_locationDetails['porte_garage_maison'] as List?)?.isNotEmpty ?? false) ...[
            _numberField(
              label: 'Hauteur porte (m)',
              icon: Icons.straighten,
              onChanged: (v) => _locationDetails['porte_hauteur_maison'] = double.tryParse(v),
            ),
            _numberField(
              label: 'Largeur porte (m)',
              icon: Icons.straighten,
              onChanged: (v) => _locationDetails['porte_largeur_maison'] = double.tryParse(v),
            ),
          ],
        ];
      case 'quartier_general_prive':
        return [
          _numberField(
            label: 'Surface (m²)',
            icon: Icons.square_foot,
            onChanged: (v) => _locationDetails['surface_bureau'] = double.tryParse(v),
          ),
          _multiSelectField(
            label: 'Porte garage',
            icon: Icons.garage,
            options: const ['simple', 'double', 'battante', 'sectionnelle'],
            selectedOptions:
            List<String>.from(_locationDetails['porte_garage_bureau'] ?? []),
            onChanged: (selected) => _locationDetails['porte_garage_bureau'] = selected,
          ),
          if ((_locationDetails['porte_garage_bureau'] as List?)?.isNotEmpty ?? false) ...[
            _numberField(
              label: 'Hauteur porte (m)',
              icon: Icons.straighten,
              onChanged: (v) => _locationDetails['porte_hauteur_bureau'] = double.tryParse(v),
            ),
            _numberField(
              label: 'Largeur porte (m)',
              icon: Icons.straighten,
              onChanged: (v) => _locationDetails['porte_largeur_bureau'] = double.tryParse(v),
            ),
          ],
        ];
      case 'en_travail':
        return [
          _numberField(
            label: 'Surface parking (m²)',
            icon: Icons.square_foot,
            onChanged: (v) => _locationDetails['surface_parking_travail'] = double.tryParse(v),
          ),
          _multiSelectField(
            label: 'Type de porte',
            icon: Icons.garage,
            options: const ['simple', 'double', 'battante', 'sectionnelle'],
            selectedOptions: List<String>.from(_locationDetails['porte_travail'] ?? []),
            onChanged: (selected) => _locationDetails['porte_travail'] = selected,
          ),
          if ((_locationDetails['porte_travail'] as List?)?.isNotEmpty ?? false) ...[
            _numberField(
              label: 'Hauteur porte (m)',
              icon: Icons.straighten,
              onChanged: (v) => _locationDetails['porte_hauteur_travail'] = double.tryParse(v),
            ),
            _numberField(
              label: 'Largeur porte (m)',
              icon: Icons.straighten,
              onChanged: (v) => _locationDetails['porte_largeur_travail'] = double.tryParse(v),
            ),
          ],
          SwitchListTile(
            title: const Text('Autorisation d\'entrée'),
            subtitle: const Text('Avez-vous l\'autorisation d\'accéder à ce lieu ?'),
            value: _locationDetails['autorisation_entree_travail'] ?? false,
            activeColor: const Color(0xFF1A4B8C),
            onChanged: (val) => setState(
                    () => _locationDetails['autorisation_entree_travail'] = val),
          ),
        ];
      case 'parking':
        return [
          SwitchListTile(
            title: const Text('Proximité parking public'),
            subtitle: const Text('Le parking est-il proche d\'un espace public ?'),
            value: _locationDetails['proximite_parking_public'] ?? true,
            activeColor: const Color(0xFF1A4B8C),
            onChanged: (val) =>
                setState(() => _locationDetails['proximite_parking_public'] = val),
          ),
        ];
      default:
        return [];
    }
  }

  Widget _numberField({
    required String label,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1A4B8C)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1A4B8C), width: 2),
          ),
        ),
        keyboardType: TextInputType.number,
        onChanged: onChanged,
      ),
    );
  }

  Widget _multiSelectField({
    required String label,
    required IconData icon,
    required List<String> options,
    required List<String> selectedOptions,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF1A4B8C)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = selectedOptions.contains(option);
              return ChoiceChip(
                label: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  final newSelection = [...selectedOptions];
                  isSelected ? newSelection.remove(option) : newSelection.add(option);
                  onChanged(newSelection);
                  setState(() {});
                },
                selectedColor: const Color(0xFF1A4B8C),
                backgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A4B8C)),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedDate != null && _selectedTime != null)
                    _confirmationItem(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value:
                      '${DateFormat('dd/MM/yyyy').format(_selectedDate!)} à ${_selectedTime!.format(context)}',
                    ),
                  if (_selectedLocationType != null)
                    _confirmationItem(
                      icon: Icons.location_on,
                      label: 'Type',
                      value: _locationTypeLabels[_selectedLocationType],
                    ),
                  if (_selectedLocation != null)
                    _confirmationItem(
                      icon: Icons.location_on,
                      label: 'Position',
                      value:
                      '${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._buildSpecificConfirmationDetails(),
        ],
      ),
    );
  }

  Widget _confirmationItem(
      {required IconData icon, required String label, required String? value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1A4B8C)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value ?? 'Non spécifié',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSpecificConfirmationDetails() {
    switch (_selectedLocationType) {
      case 'maison':
        return [
          if (_locationDetails['surface_maison'] != null)
            _confirmationDetailItem(
                'Surface', '${_locationDetails['surface_maison']} m²'),
          if (_locationDetails['hauteur_plafond_maison'] != null)
            _confirmationDetailItem('Hauteur plafond',
                '${_locationDetails['hauteur_plafond_maison']} m'),
          if ((_locationDetails['porte_garage_maison'] as List?)?.isNotEmpty ?? false) ...[
            _confirmationDetailItem('Porte garage',
                (_locationDetails['porte_garage_maison'] as List).join(', ')),
            if (_locationDetails['porte_hauteur_maison'] != null)
              _confirmationDetailItem('Hauteur porte',
                  '${_locationDetails['porte_hauteur_maison']} m'),
            if (_locationDetails['porte_largeur_maison'] != null)
              _confirmationDetailItem('Largeur porte',
                  '${_locationDetails['porte_largeur_maison']} m'),
          ],
        ];
      case 'quartier_general_prive':
        return [
          if (_locationDetails['surface_bureau'] != null)
            _confirmationDetailItem(
                'Surface', '${_locationDetails['surface_bureau']} m²'),
          if ((_locationDetails['porte_garage_bureau'] as List?)?.isNotEmpty ?? false) ...[
            _confirmationDetailItem('Porte garage',
                (_locationDetails['porte_garage_bureau'] as List).join(', ')),
            if (_locationDetails['porte_hauteur_bureau'] != null)
              _confirmationDetailItem('Hauteur porte',
                  '${_locationDetails['porte_hauteur_bureau']} m'),
            if (_locationDetails['porte_largeur_bureau'] != null)
              _confirmationDetailItem('Largeur porte',
                  '${_locationDetails['porte_largeur_bureau']} m'),
          ],
        ];
      case 'en_travail':
        return [
          if (_locationDetails['surface_parking_travail'] != null)
            _confirmationDetailItem('Surface parking',
                '${_locationDetails['surface_parking_travail']} m²'),
          if ((_locationDetails['porte_travail'] as List?)?.isNotEmpty ?? false) ...[
            _confirmationDetailItem('Porte',
                (_locationDetails['porte_travail'] as List).join(', ')),
            if (_locationDetails['porte_hauteur_travail'] != null)
              _confirmationDetailItem('Hauteur porte',
                  '${_locationDetails['porte_hauteur_travail']} m'),
            if (_locationDetails['porte_largeur_travail'] != null)
              _confirmationDetailItem('Largeur porte',
                  '${_locationDetails['porte_largeur_travail']} m'),
          ],
          _confirmationDetailItem(
              'Autorisation',
              (_locationDetails['autorisation_entree_travail'] ?? false)
                  ? 'Oui'
                  : 'Non'),
        ];
      case 'parking':
        return [
          _confirmationDetailItem(
              'Proximité parking public',
              (_locationDetails['proximite_parking_public'] ?? true)
                  ? 'Oui'
                  : 'Non'),
        ];
      default:
        return [];
    }
  }

  Widget _confirmationDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const SizedBox(width: 32),
          Text('$label : ',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  void _cancel() {
    if (_currentStep > 0) setState(() => _currentStep -= 1);
  }

  void _continue() {
    if (_currentStep == 0 && (_selectedDate == null || _selectedTime == null)) {
      _showSnackBar('Veuillez sélectionner une date et une heure');
      return;
    }
    if (_currentStep == 1 && _selectedLocationType == null) {
      _showSnackBar('Veuillez sélectionner un type d\'emplacement');
      return;
    }
    if (_currentStep == 2 && _selectedLocation == null) {
      _showSnackBar('Veuillez sélectionner un emplacement sur la carte');
      return;
    }
    if (_currentStep == 3) {
      _submitDemande();
      return;
    }
    setState(() => _currentStep += 1);
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: const Color(0xFF1A4B8C),
      ),
    );
  }

  Future<void> _submitDemande() async {
    setState(() => _isLoading = true);
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

    try {
      if (_selectedDate == null ||
          _selectedTime == null ||
          _selectedLocation == null ||
          _selectedLocationType == null) {
        throw Exception('Tous les champs requis ne sont pas remplis');
      }

      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final formattedTime = _selectedTime!.format(context);
      print(widget.problemDescription);

      final body = {
        'voiture_id': widget.voitureId,
        'client_id': clientId,
        'category_id': widget.categoryId,
        'description_probleme': widget.problemDescription,
        'type_emplacement': _selectedLocationType,
        'date_maintenance': formattedDate,
        'heure_maintenance': formattedTime,
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        ..._getLocationSpecificData(),
      }..removeWhere((_, value) => value == null);

      final response = await http
          .post(
        Uri.parse('http://192.168.1.17:8000/api/demandes-panne-inconnue'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 30));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        setState(() => _confirmed = true);
      } else {
        throw Exception(
            responseData['message'] ?? 'Erreur (${response.statusCode})');
      }
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _getLocationSpecificData() {
    switch (_selectedLocationType) {
      case 'maison':
        return {
          'surface_maison': _locationDetails['surface_maison'],
          'hauteur_plafond_maison': _locationDetails['hauteur_plafond_maison'],
          'porte_garage_maison': (_locationDetails['porte_garage_maison'] as List?)?.isNotEmpty ?? false
              ? {

            'hauteur': _locationDetails['porte_hauteur_maison'],
            'largeur': _locationDetails['porte_largeur_maison'],
          }
              : null,
        };
      case 'quartier_general_prive':
        return {
          'surface_bureau': _locationDetails['surface_bureau'],
          'porte_garage_bureau': (_locationDetails['porte_garage_bureau'] as List?)?.isNotEmpty ?? false
              ? {

            'hauteur': _locationDetails['porte_hauteur_bureau'],
            'largeur': _locationDetails['porte_largeur_bureau'],
          }
              : null,
        };
      case 'en_travail':
        return {
          'surface_parking_travail': _locationDetails['surface_parking_travail'],
          'porte_travail': (_locationDetails['porte_travail'] as List?)?.isNotEmpty ?? false
              ? {

            'hauteur': _locationDetails['porte_hauteur_travail'],
            'largeur': _locationDetails['porte_largeur_travail'],
          }
              : null,
          'autorisation_entree_travail': _locationDetails['autorisation_entree_travail'],
        };
      case 'parking':
        return {
          'proximite_parking_public': _locationDetails['proximite_parking_public'],
        };
      default:
        return {};
    }
  }
}

class MaintenanceConfirmationPage extends StatelessWidget {
  final DateTime? date;
  final TimeOfDay? time;
  final LatLng? location;
  final String? locationType;
  final Map<String, dynamic> locationDetails;

  const MaintenanceConfirmationPage({
    Key? key,
    required this.date,
    required this.time,
    required this.location,
    required this.locationType,
    required this.locationDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A4B8C).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Color(0xFF1A4B8C),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Demande confirmée !',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A4B8C),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Votre demande de maintenance à domicile a été enregistrée avec succès.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              if (date != null && time != null)
                Text(
                  '${DateFormat('dd/MM/yyyy').format(date!)} à ${time!.format(context)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ClientHomePage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A4B8C),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Retour à l\'accueil',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}