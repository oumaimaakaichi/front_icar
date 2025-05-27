import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OffresPage extends StatefulWidget {
  final int clientId;

  const OffresPage({super.key, required this.clientId});

  @override
  State<OffresPage> createState() => _OffresPageState();
}

class _OffresPageState extends State<OffresPage> {
  List<dynamic> offres = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchOffres();
  }

  Future<void> fetchOffres() async {
    print(widget.clientId);
    final url = Uri.parse('http://192.168.1.17:8000/api/demandes/client/${widget.clientId}/offres');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          offres = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Erreur serveur: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Erreur réseau : $e';
        isLoading = false;
      });
    }
  }

  Future<void> _handleResponse(int demandeId, String action) async {
    try {
      final url = Uri.parse('http://192.168.1.17:8000/api/demandes/$demandeId/${action == 'accept' ? 'accept' : 'reject'}');
      final response = await http.post(url);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Offre ${action == 'accept' ? 'acceptée' : 'refusée'} avec succès')),
        );
        fetchOffres(); // Rafraîchir la liste
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur réseau: $e')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Offres', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.grey[200],
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Offres', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.grey[200],
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Center(child: Text(error!, style: const TextStyle(fontSize: 16))),
      );
    }

    if (offres.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Offres', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.grey[200],
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(
            child: Text('Aucune offre trouvée', style: TextStyle(fontSize: 16))),
      );

    }

    return Scaffold(
    appBar: AppBar(
    title: const Text('Offres', style: TextStyle(color: Colors.black)),
    backgroundColor: Colors.grey[200],
    elevation: 0,
    iconTheme: const IconThemeData(color: Colors.black),
    ),
    body: ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: offres.length,
    itemBuilder: (context, index) {
    final offre = offres[index];
    return Card(
    margin: const EdgeInsets.only(bottom: 16),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    elevation: 2,
    child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    Expanded(
    child: Text(
    offre['service_panne']?['titre'] ?? 'Service inconnu',
    style: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    ),
    ),
    ),
    Chip(
    backgroundColor: Colors.green[50],
    label: Text(
    '${offre['prix_main_oeuvre'] ?? 'N/A'} €',
    style: TextStyle(
    color: Colors.green[800],
    fontWeight: FontWeight.bold,
    ),
    ),
    ),
    ],
    ),
    const SizedBox(height: 8),
    Text(
    'Voiture: ${offre['voiture']?['model'] ?? 'Non spécifiée'}',
    style: TextStyle(color: Colors.grey[600]),
    ),
    const SizedBox(height: 8),
    Text(
    'Date: ${offre['created_at']}',
    style: TextStyle(color: Colors.grey[600]),
    ),
    const SizedBox(height: 16),
    Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
    OutlinedButton(
    style: OutlinedButton.styleFrom(
    side: BorderSide(color: Colors.red[400]!),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    ),
    ),
    onPressed: () => _handleResponse(offre['id'], 'reject'),
    child: Text(
    'Refuser',
    style: TextStyle(color: Colors.red[400]),
    ),
    ),
    const SizedBox(width: 12),
    ElevatedButton(
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green[400],
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    ),
    ),
    onPressed: () => _handleResponse(offre['id'], 'accept'),
    child: const Text(
    'Accepter',
    style: TextStyle(color: Colors.white),
    ),
    ),
    ],
    ),
    ],
    ),
    ),
    );
    },
    ),
    );
  }
}