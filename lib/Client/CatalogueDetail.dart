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
  static const String baseUrl = 'http://192.168.1.17:8000';
  final _storage = const FlutterSecureStorage();
  int? _userId;
  int _quantity = 1;
  bool _isFavorite = false;
  bool _isAddingToCart = false;
  final Color _primaryColor = const Color(0xFF2A364E);
  final Color _accentColor = const Color(0xFF4E7D96);

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
        _userId = userData['id'] != null ? int.tryParse(userData['id'].toString()) : null;
      });
    }
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    if (path.startsWith('/')) return '$baseUrl$path';
    return '$baseUrl/$path';
  }

  Future<void> _addToCart() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vous connecter pour ajouter au panier'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isAddingToCart = true);

    try {
      final token = await _storage.read(key: 'token');
      final response = await http.post(
        Uri.parse('$baseUrl/api/paniers'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',

        },
        body: jsonEncode({
          'client_id': _userId.toString(),
          'catalogue_id': widget.piece['id'].toString(),
          'quantite': _quantity,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PanierPage(userId: _userId!),
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de l\'ajout au panier');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString().replaceAll("Exception: ", "")}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final piece = widget.piece;
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final imageUrl = _getImageUrl(piece['photo_piece']);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(

            expandedHeight: mediaQuery.size.height * 0.35,
            floating: false,
            pinned: true,

            flexibleSpace: FlexibleSpaceBar(


              background: Hero(
                tag: 'image-${piece['id']}',
                child: imageUrl.isEmpty
                    ? Container(
                  margin: const EdgeInsets.only(top: 26),
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                  ),
                )

                    : CachedNetworkImage(

                  imageUrl: imageUrl,
                  width: 100,
                  height: 50,

                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _primaryColor,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.black,
                ),
                onPressed: () {
                  setState(() => _isFavorite = !_isFavorite);
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          piece['nom_piece'] ?? 'Pièce automobile',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                      ),
                      Text(
                        '${piece['prix']?.toString() ?? '--'} €',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      piece['type_voiture'] ?? 'Type inconnu',
                      style: TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Description',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    piece['description'] ??
                        'Cette pièce automobile est de haute qualité, conçue pour offrir une performance optimale.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Détails techniques',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailCard(
                    context,
                    items: [
                      _buildDetailItem(
                        Icons.business_outlined,
                        'Fabricant',
                        piece['entreprise'] ?? 'Non spécifié',
                      ),
                      _buildDetailItem(
                        Icons.confirmation_number_outlined,
                        'Référence',
                        piece['num_piece'].toString() ?? '--',
                      ),
                      _buildDetailItem(
                        Icons.flag_outlined,
                        'Origine',
                        piece['paye_fabrication'] ?? 'Non spécifié',
                      ),
                      _buildDetailItem(
                        Icons.inventory_2_outlined,
                        'Stock',
                        piece['quantite']?.toString() ?? '0',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildDetailCard(BuildContext context, {required List<Widget> items}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: items,
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: _accentColor),
          const SizedBox(width: 16),
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
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Sélecteur de quantité
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 20),
                  onPressed: _isAddingToCart
                      ? null
                      : () {
                    if (_quantity > 1) {
                      setState(() => _quantity--);
                    }
                  },
                ),
                Text(
                  '$_quantity',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: _isAddingToCart
                      ? null
                      : () {
                    setState(() => _quantity++);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isAddingToCart ? null : _addToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isAddingToCart
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.shopping_cart_outlined, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'AJOUTER AU PANIER',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}