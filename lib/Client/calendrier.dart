import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class CalendrierDemandesPage extends StatefulWidget {
  @override
  _CalendrierDemandesPageState createState() => _CalendrierDemandesPageState();
}

class _CalendrierDemandesPageState extends State<CalendrierDemandesPage>
    with TickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<dynamic> _demandes = [];
  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoading = true;
  int? _userId;
  AnimationController? _fadeController;
  AnimationController? _slideController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _selectedDay = _focusedDay;
    _loadUserData().then((_) => _fetchDemandes());
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController!, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController!, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    _slideController?.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final userDataJson = await _storage.read(key: 'user_data');
    if (userDataJson != null) {
      final userData = jsonDecode(userDataJson);
      if (!mounted) return;
      setState(() {
        _userId = userData['id'] != null ? int.tryParse(userData['id'].toString()) : null;
      });
    }
  }

  Future<void> _fetchDemandes() async {
    if (_userId == null) return;
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/demandes/user/$_userId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _demandes = data is List ? data : [];
          _isLoading = false;
          _organizeEventsByDate();
        });
        _fadeController?.forward();
        _slideController?.forward();
      } else {
        throw Exception('Failed to load demandes');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des demandes: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _organizeEventsByDate() {
    _events.clear();
    for (var demande in _demandes) {
      // Organiser uniquement par date de maintenance
      if (demande['date_maintenance'] != null && demande['date_maintenance'].toString().isNotEmpty) {
        final maintenanceDate = DateTime.tryParse(demande['date_maintenance']);
        if (maintenanceDate != null) {
          final dateKey = DateTime(maintenanceDate.year, maintenanceDate.month, maintenanceDate.day);
          _events[dateKey] ??= [];
          _events[dateKey]!.add(demande);
        }
      }
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _showDemandeDetails(dynamic demande) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDemandeDetailsSheet(demande),
    );
  }

  Widget _buildDemandeDetailsSheet(dynamic demande) {
    final voiture = demande['voiture'] ?? {};
    final service = demande['service_panne'] ?? {};
    final techniciens = demande['techniciens'] as List<dynamic>? ?? [];
    final status = demande['statut'] ?? 'En attente';

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.assignment, color: Colors.blue[600], size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Demande #${demande['id']}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _formatDate(demande['date_maintenance']),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(status),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection(
                        'Service demandé',
                        Icons.build_circle,
                        Colors.blue,
                        [
                          _buildDetailRow('Type', service['titre'] ?? 'Non spécifié'),
                          if (service['description'] != null)
                            _buildDetailRow('Description', service['description']),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildDetailSection(
                        'Véhicule',
                        Icons.directions_car,
                        Colors.green,
                        [
                          _buildDetailRow('Modèle', '${voiture['marque'] ?? ''} ${voiture['model'] ?? 'Non spécifié'}'),
                          _buildDetailRow('Série', voiture['serie']?.toString() ?? 'Non spécifiée'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildDetailSection(
                        'Rendez-vous',
                        Icons.schedule,
                        Colors.orange,
                        [
                          _buildDetailRow('Date', _formatDate(demande['date_maintenance'])),
                          _buildDetailRow('Heure', demande['heure_maintenance'] ?? 'Non spécifiée'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildDetailSection(
                        'Techniciens',
                        Icons.engineering,
                        Colors.purple,
                        techniciens.isEmpty
                            ? [_buildDetailRow('Statut', 'Aucun technicien assigné')]
                            : techniciens.map((tech) => _buildTechnicianRow(tech)).toList(),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'terminé':
      case 'completed':
        color = Colors.green;
        break;
      case 'en cours':
      case 'in_progress':
        color = Colors.orange;
        break;
      case 'en attente':
      case 'pending':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianRow(dynamic technician) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.purple[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: Colors.purple[600], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  technician['nom'] ?? 'Technicien',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (technician['specialite'] != null)
                  Text(
                    technician['specialite'],
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Non spécifiée';
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  int _getMaintenanceCount() {
    return _demandes.where((d) =>
    d['date_maintenance'] != null &&
        d['date_maintenance'].toString().isNotEmpty
    ).length;
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.height < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Calendrier des Maintenances',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF6797A2),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6797A2), Color(0xFF5A8A96)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchDemandes,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: _buildLoadingIndicator())
          : _fadeAnimation != null
          ? FadeTransition(opacity: _fadeAnimation!, child: _buildMainContent(isSmallScreen))
          : _buildMainContent(isSmallScreen),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(32),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6797A2)),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement du calendrier...',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isSmallScreen) {
    return Column(
      children: [
        _buildStatsHeader(),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildCalendarHeader(),
                Expanded(
                  child: _buildCalendar(isSmallScreen),
                ),
              ],
            ),
          ),
        ),
        if (_selectedDay != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _buildEventsList(),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6797A2), Color(0xFF5A8A96)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6797A2).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(Icons.assignment_outlined, 'Total', '${_demandes.length}', 'demandes'),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildStatCard(Icons.build_outlined, 'Maintenances', '${_getMaintenanceCount()}', 'programmées'),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildStatCard(Icons.today_outlined, 'Aujourd\'hui', '${_getEventsForDay(DateTime.now()).length}', 'rendez-vous'),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value, String subtitle) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined, color: const Color(0xFF6797A2), size: 20),
          const SizedBox(width: 8),
          Text(
            DateFormat('MMMM yyyy', 'fr_FR').format(_focusedDay),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              setState(() {
                _calendarFormat = _calendarFormat == CalendarFormat.month
                    ? CalendarFormat.twoWeeks
                    : CalendarFormat.month;
              });
            },
            icon: Icon(
              _calendarFormat == CalendarFormat.month
                  ? Icons.calendar_view_week
                  : Icons.calendar_view_month,
              color: const Color(0xFF6797A2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar<dynamic>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        availableCalendarFormats: const {
          CalendarFormat.month: 'Mois',
          CalendarFormat.twoWeeks: '2 semaines',
        },
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) => setState(() => _calendarFormat = format),
        onPageChanged: (focusedDay) => _focusedDay = focusedDay,
        eventLoader: _getEventsForDay,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: false,
          leftChevronIcon: const Icon(Icons.chevron_left, color: Color(0xFF6797A2), size: 20), // Reduced size
          rightChevronIcon: const Icon(Icons.chevron_right, color: Color(0xFF6797A2), size: 20), // Reduced size
          headerPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), // Reduced padding
          formatButtonShowsNext: false,
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF6797A2),
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: const Color(0xFF6797A2).withOpacity(0.7),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          markerSize:8,// Reduced from 7
          cellPadding: EdgeInsets.zero,
          cellMargin: const EdgeInsets.all(0), // Add small margin
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekendStyle: const TextStyle(color: Colors.red, fontSize: 8),
          dowTextFormatter: (date, locale) => DateFormat.E(locale).format(date)[0].toUpperCase(),
        ),
        rowHeight: 27,
        daysOfWeekHeight: 25, // Reduced from 30
      ),
    );
  }
  Widget _buildEventsList() {
    final events = _getEventsForDay(_selectedDay!);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6797A2).withOpacity(0.1),
                  const Color(0xFF5A8A96).withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.build_outlined, color: const Color(0xFF6797A2), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Maintenances du ${DateFormat('dd MMMM yyyy', 'fr_FR').format(_selectedDay!)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6797A2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${events.length}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: events.isEmpty
                ? _buildEmptyEvents()
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: events.length,
              itemBuilder: (context, index) => _buildEventCard(events[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyEvents() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build_outlined, size: 32, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Aucune maintenance prévue',
            style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(dynamic event) {
    final servicePanne = event['service_panne'] ?? {};
    final voiture = event['voiture'] ?? {};
    final status = event['statut'] ?? 'En attente';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.build_circle_outlined,
            color: Colors.green.shade600,
            size: 20,
          ),
        ),
        title: Text(
          servicePanne['titre'] ?? 'Maintenance',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.green.shade700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Véhicule: ${voiture['marque'] ?? ''} ${voiture['model'] ?? 'Inconnu'}',
              style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF2D3748)),
            ),
            Text(
              'Heure: ${event['heure_maintenance'] ?? 'Non spécifiée'}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: _buildStatusChip(status),
        onTap: () => _showDemandeDetails(event),
      ),
    );
  }
}