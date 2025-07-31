import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SelectionPiecesPage extends StatefulWidget {
  final int demandeId;

  const SelectionPiecesPage({Key? key, required this.demandeId}) : super(key: key);

  @override
  _SelectionPiecesPageState createState() => _SelectionPiecesPageState();
}

class _SelectionPiecesPageState extends State<SelectionPiecesPage> {
  List<dynamic> _pieces = [];
  bool _isLoading = true;
  String _voitureModel = 'Sélection de pièces';
  int _currentIndex = 0;
  String? _selectedType;
  Map<int, String> _selections = {};

  @override
  void initState() {
    super.initState();
    _fetchPieces();
  }

  Future<void> _fetchPieces() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/demandes/${widget.demandeId}/pieces-choisies'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _pieces = data['pieces'];
          _voitureModel = data['demande']['voiture_model'] ?? 'Modèle inconnu';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Erreur lors du chargement des pièces');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Erreur de connexion: ${e.toString()}');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _nextPiece() {
    if (_selectedType == null) {
      _showSnackBar('Veuillez sélectionner un type de pièce');
      return;
    }

    _selections[_currentIndex] = _selectedType!;

    if (_currentIndex < _pieces.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedType = _selections[_currentIndex];
      });
    } else {
      _showConfirmationDialog();
    }
  }

  void _previousPiece() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _selectedType = _selections[_currentIndex];
      });
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('Confirmation'),
          ],
        ),
        content: Text(
          'Voulez-vous enregistrer vos sélections?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveSelections();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Confirmer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSelections() async {
    try {
      final piecesToSave = [];
      for (var i = 0; i < _pieces.length; i++) {
        if (_selections.containsKey(i)) {
          final piece = _pieces[i];
          piecesToSave.add({
            'piece_id': piece['info']['idPiece'],
            'type': _selections[i],
            'prix': piece[_selections[i]!]['prix'],
          });
        }
      }

      final response = await http.post(
        Uri.parse('http://localhost:8000/api/demandes/${widget.demandeId}/save-selections'),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*' // Add this header
        },
        body: jsonEncode({'pieces': piecesToSave}),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        _showSnackBar('Erreur lors de l\'enregistrement');
      }
    } catch (e) {
      _showSnackBar('Erreur de connexion: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sélection de pièces',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              _voitureModel,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          if (_pieces.isNotEmpty)
            Container(
              margin: EdgeInsets.only(right: 16),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '${_currentIndex + 1}/${_pieces.length}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 16),
            Text('Chargement des pièces...'),
          ],
        ),
      )
          : _pieces.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Aucune pièce disponible',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Progress indicator
          Container(
            margin: EdgeInsets.all(16),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _pieces.length,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),

          // Piece image - Height réduite
          Container(
            height: 250, // Réduit de 200 à 150
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: _pieces[_currentIndex]['info']['photo'] != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                'http://localhost:8000/storage/${_pieces[_currentIndex]['info']['photo']}',
                fit: BoxFit.cover,
                width: double.infinity,
                height: 150, // Ajusté à la nouvelle hauteur
                errorBuilder: (context, error, stackTrace) => Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 50, color: Colors.grey[400]), // Réduit
                      SizedBox(height: 8),
                      Text('Image non disponible', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
            )
                : Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 50, color: Colors.grey[400]), // Réduit
                  SizedBox(height: 8),
                  Text('Aucune image', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          ),

          // Piece name and number
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  _pieces[_currentIndex]['info']['nom'] ?? 'Nom non disponible',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_pieces[_currentIndex]['info']['num_piece'] != null) ...[
                  SizedBox(height: 2),
                  Text(
                    'Réf: ${_pieces[_currentIndex]['info']['num_piece']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Selection options - Avec SingleChildScrollView pour éviter l'overflow
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildPieceColumn(
                      type: 'original',
                      pieceData: _pieces[_currentIndex]['original'],
                      isSelected: _selectedType == 'original',
                      color: Colors.blue,
                    ),
                    SizedBox(width: 10),
                    _buildPieceColumn(
                      type: 'commercial',
                      pieceData: _pieces[_currentIndex]['commercial'],
                      isSelected: _selectedType == 'commercial',
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Navigation buttons
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentIndex > 0 ? _previousPiece : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back, size: 20),
                        SizedBox(width: 8),
                        Text('Précédent', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _nextPiece,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentIndex == _pieces.length - 1
                              ? 'Terminer'
                              : 'Suivant',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          _currentIndex == _pieces.length - 1
                              ? Icons.check
                              : Icons.arrow_forward,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieceColumn({
    required String type,
    required Map<String, dynamic> pieceData,
    required bool isSelected,
    required Color color,
  }) {
    final disponibiliteKey = type == 'original' ? 'disponibiliteOriginal' : 'disponibiliteCommercial';
    final dateKey = type == 'original' ? 'date_disponibilite' : 'date_disponibilite';

    final disponibiliteValue = pieceData[disponibiliteKey];
    final isDisponible = disponibiliteValue == true ||
        disponibiliteValue == 1 ||
        disponibiliteValue == '1' ||
        disponibiliteValue == 'true';

    final prix = pieceData['prix'] is num
        ? (pieceData['prix'] as num).toStringAsFixed(2)
        : pieceData['prix']?.toString() ?? 'N/A';

    final dateDispo = pieceData[dateKey]?.toString() ?? 'Non spécifiée';

    return Expanded(
      child: GestureDetector(
        onTap: isDisponible
            ? () {
          setState(() {
            _selectedType = type;
          });
        }
            : null,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.all(12), // Padding réduit
          decoration: BoxDecoration(
            color: isDisponible
                ? (isSelected ? color.withOpacity(0.1) : Colors.white)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected ? color : (isDisponible ? Colors.grey[300]! : Colors.grey[400]!),
              width: isSelected ? 3 : 1,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ]
                : [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Important pour éviter l'overflow
            children: [
              // Type label
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Padding réduit
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  type == 'original' ? 'Originale' : 'Commercial',
                  style: TextStyle(
                    fontSize: 12, // Taille réduite
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),

              SizedBox(height: 8), // Espacement réduit

              // Price
              Container(
                padding: EdgeInsets.all(12), // Padding réduit
                decoration: BoxDecoration(
                  color: isDisponible ? color.withOpacity(0.1) : Colors.grey[200],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDisponible ? color : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: Text(
                  '$prix DH',
                  style: TextStyle(
                    fontSize: 12, // Taille réduite
                    fontWeight: FontWeight.bold,
                    color: isDisponible ? color : Colors.grey[600],
                  ),
                ),
              ),

              SizedBox(height: 8), // Espacement réduit

              // Availability status
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Padding réduit
                decoration: BoxDecoration(
                  color: isDisponible ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isDisponible ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDisponible ? Icons.check_circle : Icons.cancel,
                      color: isDisponible ? Colors.green : Colors.red,
                      size: 16, // Taille réduite
                    ),
                    SizedBox(width: 4),
                    Text(
                      isDisponible ? 'Disponible' : 'Indisponible',
                      style: TextStyle(
                        fontSize: 10, // Taille réduite
                        color: isDisponible ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              if (isDisponible && dateDispo != 'Non spécifiée') ...[
                SizedBox(height: 4), // Espacement réduit
                Text(
                  'Disponible le:',
                  style: TextStyle(
                    fontSize: 10, // Taille réduite
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  dateDispo,
                  style: TextStyle(
                    fontSize: 10, // Taille réduite
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              if (isSelected) ...[
                SizedBox(height: 8), // Espacement réduit
                Container(
                  padding: EdgeInsets.all(6), // Padding réduit
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18, // Taille réduite
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}