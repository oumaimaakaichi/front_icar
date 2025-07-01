import 'package:flutter/material.dart';
import 'api_service.dart';

class DemandeDetailsPages extends StatefulWidget {
  final int userId;
  final int demandeId;

  const DemandeDetailsPages({
    Key? key,
    required this.userId,
    required this.demandeId,
  }) : super(key: key);

  @override
  _DemandeDetailsPageState createState() => _DemandeDetailsPageState();
}

class _DemandeDetailsPageState extends State<DemandeDetailsPages> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _futureDemande;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _futureDemande = _loadDemandeDetails();
  }

  Future<Map<String, dynamic>> _loadDemandeDetails() async {
    try {
      return await _apiService.getDemandeDetails(widget.userId, widget.demandeId);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      return {};
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de la demande'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : FutureBuilder<Map<String, dynamic>>(
        future: _futureDemande,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final demande = snapshot.data!;
            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    demande['service_panne']['titre'],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                      'Voiture: ${demande['voiture']['marque']} ${demande['voiture']['model']}'),
                  SizedBox(height: 8),
                  Text('Date: ${demande['date_maintenance']}'),
                  SizedBox(height: 8),
                  if (demande['heure_maintenance'] != null)
                    Text('Heure: ${demande['heure_maintenance']}'),
                  SizedBox(height: 16),
                  Text(
                    'Client:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${demande['client']['prenom']} ${demande['client']['nom']}'),
                  Text(demande['client']['email']),
                  Text(demande['client']['phone']),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}