import 'package:car_mobile/Client/ServicesByCategoryPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AllPannesPage extends StatefulWidget {
  final String voitureModel;
  final int voitureId; // Ajout du paramètre voitureId

  const AllPannesPage({
    super.key,
    required this.voitureModel,
    required this.voitureId, // Ajout dans le constructeur
  });


  @override
  State<AllPannesPage> createState() => _AllPannesPageState();
}

class _AllPannesPageState extends State<AllPannesPage> {
  final _storage = const FlutterSecureStorage();
  List<dynamic> _pannes = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAllPannes();
  }

  Future<void> _fetchAllPannes() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.17:8000/api/category-panes'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _pannes = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load pannes');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  List<dynamic> get _filteredPannes {
    if (_searchQuery.isEmpty) return _pannes;
    return _pannes.where((panne) {
      final title = panne['titre']?.toString().toLowerCase() ?? '';
      final description = panne['description']?.toString().toLowerCase() ?? '';
      return title.contains(_searchQuery.toLowerCase()) ||
          description.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catégories de Pannes'),
        backgroundColor: Colors.grey[200],
        elevation: 0,

        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAllPannes,
            color: Colors.teal,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Choisir une catégorie de panne',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueGrey,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator()
                : _filteredPannes.isEmpty
                ? _buildEmptyState()
                : _buildPannesList(),
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
          hintText: 'Rechercher une panne...',
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
          'Chargement des pannes...',
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
        Icon(Icons.handyman, size: 80, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(
          _searchQuery.isEmpty
              ? 'Aucune panne disponible'
              : 'Aucun résultat pour "$_searchQuery"',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_searchQuery.isNotEmpty) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _searchQuery = ''),
            child: const Text('Réinitialiser la recherche'),
          ),
        ],
      ],
    ),
  );

  Widget _buildPannesList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredPannes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final panne = _filteredPannes[index];
        return _buildPanneCard(panne);
      },
    );
  }

  Widget _buildPanneCard(Map<String, dynamic> panne) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServicesByCategoryPage(
                categoryId: panne['id'],
                categoryName: panne['titre'],
                  voitureId: widget.voitureId,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.build,
                  color: Colors.teal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      panne['titre'] ?? 'Titre non disponible',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      panne['description'] ?? 'Description non disponible',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}