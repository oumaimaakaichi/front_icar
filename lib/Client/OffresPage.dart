import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OffresPage extends StatefulWidget {
  final int clientId;

  const OffresPage({super.key, required this.clientId});

  @override
  State<OffresPage> createState() => _OffresPageState();
}

class _OffresPageState extends State<OffresPage> with TickerProviderStateMixin {
  List<dynamic> offres = [];
  bool isLoading = true;
  String? error;
  AnimationController? _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    fetchOffres();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> fetchOffres() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    print(widget.clientId);
    final url = Uri.parse('http://192.168.1.11:8000/api/demandes/client/${widget.clientId}/offres');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          offres = json.decode(response.body);
          isLoading = false;
        });
        _animationController?.forward();
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
    // Afficher un dialog de confirmation
    bool? shouldProceed = await _showConfirmationDialog(action);
    if (shouldProceed != true) return;

    // Afficher le loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Traitement en cours...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final url = Uri.parse('http://192.168.1.11:8000/api/demandes/$demandeId/${action == 'accept' ? 'accept' : 'reject'}');
      final response = await http.post(url);

      Navigator.of(context).pop(); // Fermer le dialog de loading

      if (response.statusCode == 200) {
        _showSuccessSnackBar(action == 'accept' ? 'acceptée' : 'refusée');
        fetchOffres(); // Rafraîchir la liste
      } else {
        _showErrorSnackBar('Erreur: ${response.body}');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Fermer le dialog de loading
      _showErrorSnackBar('Erreur réseau: $e');
    }
  }

  Future<bool?> _showConfirmationDialog(String action) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                action == 'accept' ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: action == 'accept' ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text('Confirmation'),
            ],
          ),
          content: Text(
            'Êtes-vous sûr de vouloir ${action == 'accept' ? 'accepter' : 'refuser'} cette offre ?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: action == 'accept' ? Colors.green : Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                action == 'accept' ? 'Accepter' : 'Refuser',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Offre $message avec succès'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Date inconnue';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Mes Offres',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor:Color(0xFF6797A2),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchOffres,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return _buildLoadingWidget();
    }

    if (error != null) {
      return _buildErrorWidget();
    }

    if (offres.isEmpty) {
      return _buildEmptyWidget();
    }

    return RefreshIndicator(
      onRefresh: fetchOffres,
      child: _animationController != null
          ? AnimatedBuilder(
        animation: _animationController!,
        builder: (context, child) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: offres.length,
            itemBuilder: (context, index) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController!,
                  curve: Interval(
                    index * 0.1,
                    1.0,
                    curve: Curves.easeOutCubic,
                  ),
                )),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _animationController!,
                    curve: Interval(
                      index * 0.1,
                      1.0,
                      curve: Curves.easeIn,
                    ),
                  ),
                  child: _buildOffreCard(offres[index], index),
                ),
              );
            },
          );
        },
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: offres.length,
        itemBuilder: (context, index) {
          return _buildOffreCard(offres[index], index);
        },
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
          ),
          SizedBox(height: 16),
          Text(
            'Chargement des offres...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Une erreur est survenue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fetchOffres,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune offre disponible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos offres apparaîtront ici dès qu\'elles seront disponibles.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fetchOffres,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffreCard(dynamic offre, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 3,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(offre),
                const SizedBox(height: 16),
                _buildCardDetails(offre),
                const SizedBox(height: 20),
                _buildActionButtons(offre),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(dynamic offre) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.indigo[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.build_circle_outlined,
            color: Colors.indigo[700],
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offre['service_panne']?['titre'] ?? 'Service inconnu',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Text(
                  '${offre['prix_main_oeuvre'] ?? 'N/A'} €',
                  style: TextStyle(
                    color: Colors.green[800],
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardDetails(dynamic offre) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.directions_car,
            'Véhicule',
            offre['voiture']?['model'] ?? 'Non spécifiée',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.calendar_today,
            'Date',
            _formatDate(offre['created_at']),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(dynamic offre) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleResponse(offre['id'], 'reject'),
            icon: const Icon(Icons.close),
            label: const Text('Refuser'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red[600],
              side: BorderSide(color: Colors.red[300]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleResponse(offre['id'], 'accept'),
            icon: const Icon(Icons.check),
            label: const Text('Accepter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}