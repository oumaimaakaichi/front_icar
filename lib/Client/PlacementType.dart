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
  dynamic _selectedAtelier;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
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
        Uri.parse('http://localhost:8000/api/ateliers'),
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

  void _selectAtelier(dynamic atelier) {
    setState(() {
      _selectedAtelier = atelier;
      _showCalendar = true;
      _showTimePicker = false;
      _errorMessage = null;
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
        Uri.parse('http://192.168.1.11:8000/api/demandes/${widget.demandeId}/update-info'),
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
        title: const Text('Place de Maintenance' , style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF6797A2),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(

          ),
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null)
                Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (!_showAteliers && !_showCalendar && !_showTimePicker) ...[
                Text(
                  'Choisissez votre Place de maintenance',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Sélectionnez l\'option qui correspond à vos besoins',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: _MaintenanceCard(
                        title: 'En atelier',
                        subtitle: 'Réparation dans notre ateliers',
                        icon: Icons.home_repair_service,
                        color: Color(0xFF6C63FF),
                        gradient: LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF4A42E8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () => _selectPlacementType(true),
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: _MaintenanceCard(
                        title: 'À domicile',
                        subtitle: 'Déplacement de notre technicien',
                        icon: Icons.directions_car,
                        color: Color(0xFF46607C),
                        gradient: LinearGradient(
                          colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],

                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () => _selectPlacementType(false),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                _buildInfoCard(),
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
                _isLoadingAteliers
                    ? Center(child: CircularProgressIndicator())
                    : _ateliers.isEmpty
                    ? Center(
                  child: Column(
                    children: [
                      Icon(Icons.location_off, size: 50, color: Colors.grey),
                      SizedBox(height: 10),
                      Text(
                        'Aucun atelier disponible',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
                    : _buildAteliersList(),
              ],

              if (_showCalendar && !_showTimePicker) ...[
                _buildBackButton(() {
                  setState(() {
                    _showCalendar = false;
                  });
                }),
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
      ),],
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

  Widget _buildAteliersList() {
    return ListView.builder(
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
              atelier['nom_commercial'],
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
                    Text(
                      atelier['ville'],
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                if (atelier['adresse'] != null)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      atelier['adresse'],
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
            trailing: Icon(Icons.chevron_right, color: Colors.blueGrey),
            onTap: () => _selectAtelier(atelier),
          ),
        );
      },
    );
  }

  Widget _buildCalendarSection() {
    return Column(
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(10),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(Duration(days: 365)),
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
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blueGrey,
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: TextStyle(color: Colors.red),
                defaultTextStyle: TextStyle(
                  color: Color(0xFF2D3748),
                  fontWeight: FontWeight.w500,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonDecoration: BoxDecoration(
                  color: Color(0xFF6C63FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                formatButtonTextStyle: TextStyle(color: Colors.white),
                titleTextStyle: TextStyle(
                  color: Color(0xFF2D3748),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFF6C63FF)),
                rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFF6C63FF)),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Color(0xFF2D3748)),
                weekendStyle: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
        if (_selectedDate != null) ...[
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xFF6C63FF).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today, size: 18, color: Color(0xFF6C63FF)),
                SizedBox(width: 8),
                Text(
                  'Date: ${DateFormat('EEEE dd MMMM', 'fr_FR').format(_selectedDate!)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimePickerSection() {
    return Column(
      children: [
        Text(
          'Choisissez l\'heure du rendez-vous',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        SizedBox(height: 20),
        Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.access_time, color: Color(0xFF6C63FF)),
                title: Text(
                  _selectedTime == null
                      ? 'Sélectionner une heure'
                      : 'Heure choisie: ${_selectedTime!.format(context)}',
                  style: TextStyle(fontSize: 16),
                ),
                trailing: Icon(Icons.arrow_drop_down, color: Colors.grey),
                onTap: () => _selectTime(context),
              ),
            ],
          ),
        ),
        SizedBox(height: 30),
        if (_selectedTime != null) ...[
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Résumé du rendez-vous',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 12),
                _buildSummaryItem(Icons.business, 'Atelier', _selectedAtelier['nom_commercial']),
                _buildSummaryItem(Icons.location_on, 'Adresse', ' ${_selectedAtelier['ville']}'),
                _buildSummaryItem(
                  Icons.calendar_today,
                  'Date et heure',
                  '${DateFormat('EEEE dd MMMM', 'fr_FR').format(_selectedDate!)} à ${_selectedTime!.format(context)}',
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: _isUpdating
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _updateDemandeInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6C63FF),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Confirmer le rendez-vous',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Color(0xFF6C63FF)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
      Uri.parse('http://192.168.1.11:8000/api/catalogues'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement du catalogue');
    }
  }

  Future<Map<String, dynamic>> _fetchDemandeDetails() async {
    final response = await http.get(
      Uri.parse('http://192.168.1.11:8000/api/$demandeId/confirmation-details'),
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
                  Icon(Icons.error_outline, size: 50, color: Colors.red),
                  SizedBox(height: 20),
                  Text(
                    'Erreur: ${snapshot.error}',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Retour'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6C63FF),
                    ),
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