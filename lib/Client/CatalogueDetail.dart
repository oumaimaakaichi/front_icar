import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:car_mobile/Client/PanierPage.dart';

class CatalogueDetailPage extends StatefulWidget {
  final Map<String, dynamic> piece;
  final String? userId;

  const CatalogueDetailPage({
    Key? key,
    required this.piece,
    this.userId,
  }) : super(key: key);

  @override
  _CatalogueDetailPageState createState() => _CatalogueDetailPageState();
}

class _CatalogueDetailPageState extends State<CatalogueDetailPage> {
  static const String baseUrl = 'http://localhost:8000';
  final _storage = const FlutterSecureStorage();
  int? _userId;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userDataJson = await _storage.read(key: 'user_data');
    if (userDataJson != null) {
      final userData = jsonDecode(userDataJson);
      setState(() {
        _userId = userData['id'];
      });
    }
  }

  // Fonction pour construire l'URL de l'image correctement
  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';

    // Si l'URL est déjà complète
    if (path.startsWith('http')) return path;

    // Si le chemin commence par un slash
    if (path.startsWith('/')) return '$baseUrl$path';

    // Sinon ajouter un slash
    return '$baseUrl/$path';
  }

  Future<void> _addToCart() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vous connecter'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/paniers'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${await _storage.read(key: 'token')}',
        },
        body: jsonEncode({
          'client_id': _userId.toString(),
          'catalogue_id': widget.piece['id'].toString(),
          'quantite': _quantity,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PanierPage(userId: _userId!),
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur inconnue');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final piece = widget.piece;
    final theme = Theme.of(context);
    final imageUrl = _getImageUrl(piece['photo_piece']);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(piece['nom_piece'] ?? 'Détails'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Fonctionnalité de partage
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // Fonctionnalité favoris
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Image
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.white,
              child: Hero(
                tag: 'image-${piece['id']}',
                child: imageUrl.isEmpty
                    ? Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                )
                    : CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blueGrey.withOpacity(0.7),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 100,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),

            // Section Infos
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et type
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          piece['nom_piece'] ?? 'Nom de la pièce',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          piece['type_voiture'] ?? 'Type inconnu',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Prix
                  Text(
                    '${piece['prix']?.toString() ?? 'N/A'} \$',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description
                  _buildSectionTitle('Description'),
                  const SizedBox(height: 8),
                  Text(
                    piece['description'] ??
                        'Aucune description disponible pour cette pièce.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Détails techniques
                  _buildSectionTitle('Détails techniques'),
                  const SizedBox(height: 12),
                  _buildDetailItem(Icons.business, 'Fabricant', piece['entreprise']),
                  _buildDetailItem(Icons.confirmation_number, 'Référence', piece['num_piece']),
                  _buildDetailItem(Icons.flag, 'Origine', piece['paye_fabrication']),
                  _buildDetailItem(Icons.inventory, 'Stock disponible', piece['quantite']?.toString() ?? 'N/A'),
                ],
              ),
            ),
          ],
        ),
      ),

      // Barre inférieure avec quantité et ajout au panier
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Sélecteur de quantité
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 20),
                    onPressed: () {
                      if (_quantity > 1) {
                        setState(() => _quantity--);
                      }
                    },
                  ),
                  Text(
                    '$_quantity',
                    style: const TextStyle(fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () {
                      setState(() => _quantity++);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Bouton Ajouter au panier
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.shopping_cart),
                label: const Text(
                  'AJOUTER AU PANIER',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.blue[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value?.toString() ?? 'Non spécifié',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
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