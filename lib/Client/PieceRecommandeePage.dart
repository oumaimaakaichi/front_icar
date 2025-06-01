import 'package:car_mobile/Client/PlacementType.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PieceRecommandeePage extends StatefulWidget {
  final int demandeId;

  const PieceRecommandeePage({Key? key, required this.demandeId}) : super(key: key);

  @override
  _PieceRecommandeePageState createState() => _PieceRecommandeePageState();
}

class _PieceRecommandeePageState extends State<PieceRecommandeePage> {
  List<dynamic> _pieces = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _selectedPieceType; // 'original' ou 'commercial'
  Map<int, Map<String, dynamic>> _selectedPieces = {}; // Pour stocker toutes les sélections

  bool get _isLastPiece => _currentIndex == _pieces.length - 1;

  @override
  void initState() {
    super.initState();
    _fetchPieceRecommandee();
  }

  Future<void> _fetchPieceRecommandee() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/piece-recommandee/${widget.demandeId}'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _pieces = data['pieces'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune pièce recommandée trouvée')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion: ${e.toString()}')),
      );
    }
  }

  void _nextPiece() {
    if (_selectedPieceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une pièce avant de continuer')),
      );
      return;
    }

    // Enregistrer la sélection actuelle
    _saveCurrentSelection();

    if (_currentIndex < _pieces.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedPieceType = _getPreselectedTypeForCurrentIndex();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous avez vu toutes les pièces recommandées')),
      );
    }
  }

  void _previousPiece() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _selectedPieceType = _getPreselectedTypeForCurrentIndex();
      });
    }
  }

  void _saveCurrentSelection() {
    if (_selectedPieceType == null) return;

    final currentPiece = _pieces[_currentIndex];
    final pieceInfo = currentPiece['info'];
    final selectedPiece = currentPiece[_selectedPieceType!];
print(pieceInfo);
    _selectedPieces[_currentIndex] = {
      'piece_id': pieceInfo['idPiece'],
      'type': _selectedPieceType!,
      'prix': selectedPiece['prix'],
      'nom': pieceInfo['nom'],
      'num_piece': pieceInfo['num_piece'],
    };
  }

  String? _getPreselectedTypeForCurrentIndex() {
    if (_selectedPieces.containsKey(_currentIndex)) {
      return _selectedPieces[_currentIndex]!['type'];
    }
    return null;
  }

  Future<void> _confirmSelection() async {
    if (_selectedPieceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une pièce avant de confirmer')),
      );
      return;
    }

    // Sauvegarder la dernière sélection
    _saveCurrentSelection();

    // Préparer les données pour l'API
    final piecesToSend = _selectedPieces.values.toList();

    try {
      final response = await http.put(
        Uri.parse('http://localhost:8000/api/demandes/${widget.demandeId}/pieces-choisies'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'pieces': piecesToSend,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) =>  MaintenanceTypePage(demandeId:widget.demandeId)),
        );// Retour avec un indicateur de succès
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['message'] ?? 'Erreur lors de l\'enregistrement')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion: ${e.toString()}')),
      );
    }
  }

  void _cancelSelection() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pièces Recommandées',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey[200],
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pieces.isEmpty
          ? const Center(child: Text('Aucune pièce recommandée pour cette demande'))
          : _buildPieceView(),
    );
  }

  Widget _buildPieceView() {
    final currentPiece = _pieces[_currentIndex];
    final originalPiece = currentPiece['original'];
    final commercialPiece = currentPiece['commercial'];

    return Column(
      children: [
        // En-tête avec informations sur la pièce
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentPiece['info']['nom'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Réf: ${currentPiece['info']['num_piece']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Pièce ${_currentIndex + 1}/${_pieces.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Contenu principal avec les deux parties
        Expanded(
          child: Row(
            children: [
              // Partie Pièce Originale
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPieceType = 'original';
                    });
                  },
                  child: _buildPieceSection(
                    title: 'Originale',
                    pieceData: originalPiece,
                    color: _selectedPieceType == 'original'
                        ? const Color(0xFFE1E1E1)
                        : const Color(0xF2E8E8F6),
                    isSelected: _selectedPieceType == 'original',
                  ),
                ),
              ),

              // Diviseur vertical
              Container(
                width: 1,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(vertical: 16),
              ),

              // Partie Pièce Commerciale
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPieceType = 'commercial';
                    });
                  },
                  child: _buildPieceSection(
                    title: 'Commerciale',
                    pieceData: commercialPiece,
                    color: _selectedPieceType == 'commercial'
                        ? const Color(0xFFE0E0E0)
                        : const Color(0xFFEEEEEE),
                    isSelected: _selectedPieceType == 'commercial',
                  ),
                ),
              ),
            ],
          ),
        ),

        // Pied de page avec prix main d'oeuvre et navigation
        Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -3),
              ),
            ],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [

              const SizedBox(height: 16),
              if (_isLastPiece)
              // Boutons Confirmer/Annuler pour la dernière pièce
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _cancelSelection,
                      icon: const Icon(Icons.cancel, size: 20),
                      label: const Text('Annuler'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: _confirmSelection,
                      icon: const Icon(Icons.check_circle, size: 20),
                      label: const Text('Confirmer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                )
              else
              // Boutons Précédent/Suivant pour les autres pièces
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _previousPiece,
                      icon: const Icon(Icons.arrow_back, size: 20),
                      label: const Text('Précédent'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: _nextPiece,
                      icon: const Icon(Icons.arrow_forward, size: 20),
                      label: const Text('Suivant'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007896),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPieceSection({
    required String title,
    required Map<String, dynamic> pieceData,
    required Color color,
    bool isSelected = false,
  }) {
    final disponibiliteField = title == 'Originale' ? 'disponibiliteOriginal' : 'disponibilitCommercial';
    final disponibiliteValue = pieceData[disponibiliteField];
    final bool isDisponible = disponibiliteValue == null
        ? true
        : disponibiliteValue is bool
        ? disponibiliteValue
        : disponibiliteValue.toString().toLowerCase() == 'true';

    return Container(
      decoration: BoxDecoration(
        color: color,
        border: isSelected
            ? Border.all(color: const Color(0xFF007896), width: 2)
            : null,
      ),
      padding: const EdgeInsets.all(9),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: title == 'Originale' ? Colors.blueGrey[800] : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          if (pieceData['photo'] != null)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    'http://localhost:8000/storage/${pieceData['photo']}',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: const Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Prix:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    Text(
                      '${pieceData['prix']?.toString() ?? 'N/A'} €',
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blueGrey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isDisponible ? 'Disponible' : 'Non disponible',
                      style: TextStyle(
                          color: isDisponible ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (isDisponible && pieceData['date_disponibilite'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Dispo:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      Text(
                        pieceData['date_disponibilite'],
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ],

              ],
            ),
          ),
        ],
      ),
    );
  }
}