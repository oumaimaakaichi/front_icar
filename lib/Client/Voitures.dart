import 'package:car_mobile/Client/CategoryPanesPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Voiture extends StatefulWidget {
  const Voiture({super.key});

  @override
  State<Voiture> createState() => _MesVoituresPageState();
}

class _MesVoituresPageState extends State<Voiture> {
  final _storage = const FlutterSecureStorage();
  List<dynamic> _voitures = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchVoitures();
  }

  Future<void> _fetchVoitures() async {
    setState(() => _isLoading = true);

    final userDataJsons = await _storage.read(key: 'user_data');
    if (userDataJsons == null) return;

    final userData = jsonDecode(userDataJsons);
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.17:8000/api/voitures/${userData["id"]}'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _voitures = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load voitures');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  List<dynamic> get _filteredVoitures {
    if (_searchQuery.isEmpty) return _voitures;
    return _voitures.where((voiture) {
      final model = voiture['model']?.toString().toLowerCase() ?? '';
      final company = voiture['company']?.toString().toLowerCase() ?? '';
      return model.contains(_searchQuery.toLowerCase()) ||
          company.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Voitures', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.grey[200],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchVoitures,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator()
                : _filteredVoitures.isEmpty
                ? _buildEmptyState()
                : _buildVoituresList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher une voiture...',
          prefixIcon: const Icon(Icons.search, color: Colors.teal),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildLoadingIndicator() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
        ),
        const SizedBox(height: 16),
        Text(
          'Chargement de vos voitures...',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      ],
    ),
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.directions_car_outlined,
          size: 80,
          color: Colors.grey[300],
        ),
        const SizedBox(height: 16),
        Text(
          _searchQuery.isEmpty
              ? 'Aucune voiture enregistrée'
              : 'Aucun résultat trouvé',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _searchQuery.isEmpty
              ? 'Ajoutez une voiture pour commencer'
              : 'Aucune voiture ne correspond à "$_searchQuery"',
          style: TextStyle(
            color: Colors.grey[500],
          ),
        ),
        if (_searchQuery.isNotEmpty) ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() => _searchQuery = ''),
            child: const Text('Réinitialiser la recherche'),
          ),
        ],
      ],
    ),
  );

  Widget _buildVoituresList() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            'Sélectionnez une voiture à diagnostiquer',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blueGrey,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemCount: _filteredVoitures.length,
            itemBuilder: (context, index) {
              final voiture = _filteredVoitures[index];
              return _buildVoitureCard(voiture);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVoitureCard(Map<String, dynamic> voiture) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToCarDetail(context, voiture),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_car,
                      size: 60,
                      color: _getCarColor(voiture['company']),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      voiture['company'] ?? 'Marque inconnue',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.center,

                    child: Text(
                      voiture['model'] ?? 'Modèle inconnu',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),


                  if (voiture['year'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Année: ${voiture['year']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCarColor(String? company) {
    switch (company?.toLowerCase()) {
      case 'toyota': return Colors.red;
      case 'bmw': return Colors.blue;
      case 'mercedes': return Colors.black;
      case 'audi': return Colors.grey;
      default: return Colors.teal;
    }
  }

  void _navigateToCarDetail(BuildContext context, Map<String, dynamic> voiture) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllPannesPage(
          voitureModel: voiture['model'],
          voitureId: voiture['id'], // Ajout de l'ID de la voiture
        ),
      ),
    );
  }
}