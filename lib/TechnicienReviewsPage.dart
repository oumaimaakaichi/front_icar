import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TechnicienReviewsPage extends StatefulWidget {
  final int? technicienId;

  const TechnicienReviewsPage({Key? key, this.technicienId}) : super(key: key);

  @override
  _TechnicienReviewsPageState createState() => _TechnicienReviewsPageState();
}

class _TechnicienReviewsPageState extends State<TechnicienReviewsPage> {
  List<dynamic> reviews = [];
  bool isLoading = true;
  String errorMessage = '';
  double averageRating = 0.0;
  int totalReviews = 0;

  @override
  void initState() {
    super.initState();
    loadReviews();
  }

  Future<void> loadReviews() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Remplacez par votre URL d'API
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/reviews/technicien/${widget.technicienId}'),
        headers: {
          'Content-Type': 'application/json',
          // Ajoutez votre token d'authentification si nécessaire
          // 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          reviews = data['reviews'] ?? [];
          totalReviews = data['total_reviews'] ?? 0;
          averageRating = calculateAverageRating();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Erreur lors du chargement des reviews';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur de connexion: $e';
        isLoading = false;
      });
    }
  }

  double calculateAverageRating() {
    if (reviews.isEmpty) return 0.0;
    double sum = reviews.fold(0.0, (sum, review) => sum + (review['nbr_etoile'] ?? 0));
    return sum / reviews.length;
  }

  Widget buildStarRating(int rating, {double size = 20}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }

  Widget buildReviewCard(dynamic review) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec client et étoiles
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF73B1BD),
                  radius: 20,
                  child: Text(
                    (review['client']?['prenom']?.toString().substring(0, 1).toUpperCase() ??
                        review['client']?['nom']?.toString().substring(0, 1).toUpperCase() ??
                        'C'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${review['client']?['prenom'] ?? ''} ${review['client']?['nom'] ?? 'Client anonyme'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 4),
                      buildStarRating(review['nbr_etoile'] ?? 0),
                    ],
                  ),
                ),
                Text(
                  _formatDate(review['created_at']),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Commentaire
            if (review['commentaire'] != null && review['commentaire'].toString().isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  review['commentaire'],
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),

            // Informations sur la demande (si disponible)
            if (review['demande'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Demande #${review['demande']['id'] ?? ''}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }

  Widget buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF73B1BD), Color(0xFF5A9BA8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                buildStarRating(averageRating.round(), size: 16),
                const SizedBox(height: 4),
                Text(
                  'Note moyenne',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  totalReviews.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  totalReviews <= 1 ? 'Avis' : 'Avis',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Mes Reviews',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF73B1BD),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadReviews,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF73B1BD)),
        ),
      )
          : errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loadReviews,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF73B1BD),
                foregroundColor: Colors.white,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      )
          : reviews.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            Text(
              'Aucun avis pour le moment',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les avis de vos clients apparaîtront ici',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          buildStatsCard(),
          Expanded(
            child: ListView.builder(
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                return buildReviewCard(reviews[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}