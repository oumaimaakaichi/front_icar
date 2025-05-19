import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForfaitsByServicePage extends StatefulWidget {
  final int serviceId;
  final String serviceTitre;
  final int voitureId;

  const ForfaitsByServicePage({
    super.key,
    required this.serviceId,
    required this.serviceTitre,
    required this.voitureId,
  });

  @override
  State<ForfaitsByServicePage> createState() => _ForfaitsByServicePageState();
}

class _ForfaitsByServicePageState extends State<ForfaitsByServicePage> {
  List<dynamic> _forfaits = [];
  bool _isLoading = true;
  String? _error;
  int? _selectedForfaitId;

  @override
  void initState() {
    super.initState();
    _fetchForfaits();
  }

  Future<void> _fetchForfaits() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.17:8000/api/forfaits/service/${widget.serviceId}'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _forfaits = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _envoyerDemande(int forfaitId) async {
    final url = Uri.parse('http://192.168.1.17:8000/api/demandes');
    try {
      final response = await http.post(
        url,
        headers: {'Accept': 'application/json'},
        body: {
          'forfait_service_id': forfaitId.toString(),
          'service_panne_id': widget.serviceId.toString(),
          'voiture_id': widget.voitureId.toString(),
        },
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Votre demande a été envoyée. S\'il vous plaît, attendez. Les prix vous seront envoyés prochainement.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'envoi de la demande: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceTitre),
        backgroundColor: Colors.grey[200],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Sélectionnez un forfait :',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _forfaits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final forfait = _forfaits[index];
                final isSelected = _selectedForfaitId == forfait['id'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedForfaitId = forfait['id'];
                    });
                  },
                  child: Card(
                    color: isSelected ? Colors.teal[50] : Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? Colors.teal : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            forfait['titre'] ?? 'Sans titre',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(forfait['description'] ?? 'Pas de description'),
                          const SizedBox(height: 8),

                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _selectedForfaitId == null
                ? null
                : () => _envoyerDemande(_selectedForfaitId!),
            icon: const Icon(Icons.assignment_turned_in),
            label: const Text(
              'Passer une demande',
              style: TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
