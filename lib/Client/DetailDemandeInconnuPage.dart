import 'dart:convert';
import 'package:car_mobile/Client/ReviewModel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
class DemandeDetailsIPage extends StatefulWidget {
  final dynamic demande;
  final String? meetLink;
  final bool isShared;
  final bool isOpen;

  const DemandeDetailsIPage({
    super.key,
    required this.demande,
    this.meetLink,
    required this.isShared,
    required this.isOpen,
  });

  @override
  State<DemandeDetailsIPage> createState() => _DemandeDetailsPageState();
}

class _DemandeDetailsPageState extends State<DemandeDetailsIPage> {
  bool _rapportExists = false;
  Map<String, dynamic>? _existingRapport;
  bool _isLoadingRapport = false;
  Map<int, List<ReviewModel>> technicienReviews = {};
  Map<int, bool> showReviewForm = {};
  Map<int, int> selectedRatings = {};
  Map<int, TextEditingController> reviewControllers = {};
  final _storage = const FlutterSecureStorage();

  int? _userId;

  @override
  void initState() {
    super.initState();
    _initializeTechnicienStates();
    _checkRapportExistence();
    _loadUserData();
    _loadTechnicienReviews();
  }

  // Nouvelle méthode pour initialiser les états des techniciens
  void _initializeTechnicienStates() {
    final techniciens = widget.demande['techniciens'] as List<dynamic>? ?? [];
    for (var tech in techniciens) {
      final techId = tech['id'];
      if (techId != null) {
        showReviewForm[techId] = false;
        selectedRatings[techId] = 0;
        reviewControllers[techId] = TextEditingController();
        technicienReviews[techId] = [];
      }
    }
  }

  Future<void> _loadUserData() async {
    final token = await _storage.read(key: 'token');
    final userDataJson = await _storage.read(key: 'user_data');

    if (userDataJson != null) {
      final userData = jsonDecode(userDataJson);
      if (!mounted) return;
      setState(() {
        _userId = userData['id'];
      });
    }
  }

  Future<void> _checkRapportExistence() async {
    setState(() {
      _isLoadingRapport = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/rapport-maintenance-inconnu/demande/${widget.demande['id']}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _rapportExists = true;
          _existingRapport = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Erreur lors de la vérification du rapport: $e');
    } finally {
      setState(() {
        _isLoadingRapport = false;
      });
    }
  }

  Future<void> _downloadRapport() async {
    if (!_rapportExists) return;

    try {
      final pdfUrl = 'http://localhost:8000/api/rapport-maintenance-inconnu/${_existingRapport!['id']}/download';

      if (await canLaunchUrl(Uri.parse(pdfUrl))) {
        await launchUrl(
          Uri.parse(pdfUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Impossible d\'ouvrir l\'URL';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du téléchargement: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Non spécifiée';
    try {
      DateTime date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _launchMeetUrl(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ouverture du lien: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'terminé':
      case 'completed':
        return Colors.green;
      case 'en cours':
      case 'in_progress':
        return Colors.orange;
      case 'en attente':
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _loadTechnicienReviews() async {
    try {
      final techniciens = widget.demande['techniciens'] as List<dynamic>? ?? [];

      for (var tech in techniciens) {
        final techId = tech['id'];
        if (techId != null) {
          // Charger les reviews pour ce technicien sur cette demande spécifique
          final response = await http.get(
            Uri.parse('http://localhost:8000/api/reviews2/demande/${widget.demande['id']}/technicienI/$techId'),
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body) as List;
            if (mounted) {
              setState(() {
                technicienReviews[techId] =
                    data.map((item) => ReviewModel.fromJson(item)).toList();
                // Ensure all states are properly initialized
                showReviewForm[techId] = showReviewForm[techId] ?? false;
                selectedRatings[techId] = selectedRatings[techId] ?? 0;
                reviewControllers[techId] = reviewControllers[techId] ?? TextEditingController();
              });
            }
          } else if (response.statusCode == 404) {
            // Pas de reviews pour ce technicien, initialiser avec une liste vide
            if (mounted) {
              setState(() {
                technicienReviews[techId] = [];
                showReviewForm[techId] = showReviewForm[techId] ?? false;
                selectedRatings[techId] = selectedRatings[techId] ?? 0;
                reviewControllers[techId] = reviewControllers[techId] ?? TextEditingController();
              });
            }
          }
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des reviews: $e');
    }
  }

  Future<void> _submitReview(int technicienId) async {
    final rating = selectedRatings[technicienId] ?? 0;
    if (rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner une note'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: utilisateur non identifié'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('Rating: $rating');
    print('TechnicienId: $technicienId');
    print('UserId: ${_existingRapport!['id']}');

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/reviewsStore'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'nbr_etoile': rating,
          'commentaire': reviewControllers[technicienId]?.text ?? '',
          'client_id': _userId,
          'technicien_id': technicienId,
          'demande_inconnu_id':widget.demande['id'],
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Avis soumis avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadTechnicienReviews();
        setState(() {
          showReviewForm[technicienId] = false;
        });
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de la soumission: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la soumission de l\'avis'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Ajoutez cette méthode pour vérifier si l'utilisateur a déjà donné un avis
  bool _hasUserAlreadyReviewed(int technicienId) {
    final reviews = technicienReviews[technicienId] ?? [];
    return reviews.any((review) => review.clientId == _userId);
  }

// Méthode pour obtenir la review de l'utilisateur actuel
  ReviewModel? _getUserReview(int technicienId) {
    final reviews = technicienReviews[technicienId] ?? [];
    try {
      return reviews.firstWhere((review) => review.clientId == _userId);
    } catch (e) {
      return null;
    }
  }

// Modifiez la méthode _buildReviewSection
  Widget _buildReviewSection(int technicienId) {
    final reviews = technicienReviews[technicienId] ?? [];
    final averageRating = reviews.isNotEmpty
        ? (reviews.map((r) => r.nbrEtoile).reduce((a, b) => a + b) / reviews.length).toDouble()
        : 0.0;

    // Vérification de sécurité pour showReviewForm
    final isShowingForm = showReviewForm[technicienId] ?? false;
    final hasUserReviewed = _hasUserAlreadyReviewed(technicienId);
    final userReview = _getUserReview(technicienId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Avis clients',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),

        if (reviews.isNotEmpty) ...[
          Row(
            children: [
              _buildRatingStars(averageRating, size: 20),
              const SizedBox(width: 8),
              Text(
                averageRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${reviews.length} avis)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Afficher la review de l'utilisateur en premier si elle existe
          if (hasUserReviewed && userReview != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.blue[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Votre avis',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[600],
                        ),
                      ),
                      const Spacer(),
                      _buildRatingStars(userReview.nbrEtoile.toDouble(), size: 16),
                      const SizedBox(width: 8),

                    ],
                  ),
                  if (userReview.commentaire != null && userReview.commentaire!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      userReview.commentaire!,
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Afficher les autres reviews (exclure celle de l'utilisateur actuel)
          ...reviews
              .where((review) => review.clientId != _userId)
              .map((review) => _buildReviewItem(review))
              .toList(),
        ] else ...[
          Text(
            'Aucun avis pour le moment',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Afficher le bouton ou le formulaire seulement si l'utilisateur n'a pas encore donné d'avis
        if (!hasUserReviewed) ...[
          if (!isShowingForm) ...[
            ElevatedButton(
              onPressed: () {
                setState(() {
                  showReviewForm[technicienId] = true;
                });
              },
              child: Text('Donner votre avis'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ] else ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notez ce technicien',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedRatings[technicienId] = index + 1;
                        });
                      },
                      child: Icon(
                        index < (selectedRatings[technicienId] ?? 0)
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reviewControllers[technicienId],
                  decoration: InputDecoration(
                    labelText: 'Commentaire (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _submitReview(technicienId),
                      child: Text('Envoyer'),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          showReviewForm[technicienId] = false;
                        });
                      },
                      child: Text('Annuler'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ] else ...[
          // Message informatif si l'utilisateur a déjà donné son avis
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border.all(color: Colors.green[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Avis déja ajoutée',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewItem(ReviewModel review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                review.clientId.toString(), // Vous pouvez remplacer par le nom du client si disponible
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              _buildRatingStars(review.nbrEtoile.toDouble(), size: 16),
              const SizedBox(width: 8),
              Text(
                _formatDate(review.createdAt.toString()),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          if (review.commentaire != null && review.commentaire!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.commentaire!,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ],
          const Divider(height: 24),
        ],
      ),
    );
  }

  Widget _buildRatingStars(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star
              : (index < rating ? Icons.star_half : Icons.star_border),
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }

  @override
  void dispose() {
    // Nettoyer les contrôleurs pour éviter les fuites mémoire
    for (var controller in reviewControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiture = widget.demande['voiture'];

    final techniciens = widget.demande['techniciens'] as List<dynamic>? ?? [];
    final status = widget.demande['statut'] ?? 'En attente';
    final description = widget.demande['description_probleme'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Détails Demande #${widget.demande['id']}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[200],
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            _buildStatusHeader(status),

            const SizedBox(height: 24),

            // Section Description
            if (description != null && description.isNotEmpty)
              _buildSection(
                title: 'Description du problème',
                icon: Icons.description,
                color: Colors.blueGrey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ),

            if (description != null && description.isNotEmpty)
              const SizedBox(height: 20),

            // Section Service

            const SizedBox(height: 20),

            // Section Véhicule
            _buildSection(
              title: 'Véhicule',
              icon: Icons.directions_car,
              color: Colors.green,
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.branding_watermark,
                    label: 'Marque',
                    value: voiture?['company'] ?? 'Non spécifiée',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.directions_car,
                    label: 'Modèle',
                    value: voiture?['model'] ?? 'Non spécifié',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.confirmation_number,
                    label: 'Numéro de série',
                    value: voiture?['serie']?.toString() ?? 'Non spécifié',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.calendar_today,
                    label: 'Année',
                    value: voiture?['date_fabrication']?.toString() ?? 'Non spécifiée',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section Rendez-vous
            _buildSection(
              title: 'Rendez-vous',
              icon: Icons.calendar_today,
              color: Colors.orange,
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.date_range,
                    label: 'Date prévue',
                    value: _formatDate(widget.demande['date_maintenance']),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.access_time,
                    label: 'Heure prévue',
                    value: widget.demande['heure_maintenance'] ?? 'Non spécifiée',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.location_on,
                    label: 'Lieu',
                    value: widget.demande['lieu'] ?? 'Non spécifié',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section Techniciens
            _buildSection(
              title: 'Techniciens assignéssss',
              icon: Icons.engineering,
              color: Colors.purple,
              child: techniciens.isEmpty
                  ? _buildDetailRow(
                icon: Icons.info_outline,
                label: 'Information',
                value: 'Aucun technicien assigné pour le moment',
              )
                  : Column(
                children: techniciens
                    .where((tech) => tech != null && tech['id'] != null)
                    .map((tech) => _buildTechnicianCard(tech))
                    .toList(),
              ),
            ),

            // Section Rapport
            if (_isLoadingRapport)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_rapportExists)
              _buildRapportSection(),

            // Section Visioconférence
            if (widget.meetLink != null && widget.isShared)
              Column(
                children: [
                  const SizedBox(height: 20),
                  _buildVideoConferenceSection(),
                ],
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.assignment,
              size: 30,
              color: _getStatusColor(status),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statut de la demande',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Créée le ${_formatDate(widget.demande['created_at'])}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
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
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicianCard(dynamic technician) {
    final technicienId = technician['id'];
    if (technicienId == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  size: 24,
                  color: Colors.purple[600],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${technician['prenom'] ?? ''} ${technician['nom'] ?? 'Technicien'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (technician['specialite'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        technician['specialite'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    if (technician['experience'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Expérience: ${technician['experience']} ans',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.message_outlined,
                  color: Colors.purple[600],
                ),
                onPressed: () {
                  // Action pour envoyer un message
                },
              ),
            ],
          ),
          // Ajout de la section review
          if (_rapportExists)
            _buildReviewSection(technicienId),
        ],
      ),
    );
  }
  Widget _buildRapportSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.description,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Rapport de maintenance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Le rapport de maintenance est disponible en téléchargement.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Télécharger le rapport'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _downloadRapport,
                ),
                if (_existingRapport?['created_at'] != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Généré le ${_formatDate(_existingRapport!['created_at'])}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                if (_existingRapport?['notes'] != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Notes supplémentaires:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _existingRapport!['notes'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoConferenceSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isOpen
              ? [Colors.teal[400]!, Colors.teal[600]!]
              : [Colors.grey[400]!, Colors.grey[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.isOpen ? Colors.teal.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.video_call,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.isOpen
                      ? 'Visioconférence disponible'
                      : 'Visioconférence fermée',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              widget.isOpen
                  ? 'Rejoignez la réunion avec votre technicien pour un accompagnement personnalisé.'
                  : 'Cette visioconférence est actuellement indisponible.',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: Icon(
                  widget.isOpen ? Icons.video_call : Icons.lock_outline,
                  size: 24,
                  color: widget.isOpen ? Colors.teal[600] : Colors.white,
                ),
                label: Text(
                  widget.isOpen
                      ? 'Rejoindre maintenant'
                      : 'Fermée',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: widget.isOpen ? Colors.teal : Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: widget.isOpen ? Colors.teal[600] : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: widget.isOpen
                    ? () => _launchMeetUrl(widget.meetLink!)
                    : null,
              ),
            ),

            if (!widget.isOpen) const SizedBox(height: 12),

            if (widget.isOpen) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _launchMeetUrl(widget.meetLink!),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.link,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.meetLink!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.open_in_new,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}