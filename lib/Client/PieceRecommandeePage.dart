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

class _PieceRecommandeePageState extends State<PieceRecommandeePage>
    with TickerProviderStateMixin {
  List<dynamic> _pieces = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _selectedPieceType;
  Map<int, Map<String, dynamic>> _selectedPieces = {};

  // Make these nullable and check before using
  AnimationController? _slideController;
  AnimationController? _fadeController;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _fadeAnimation;

  bool get _isLastPiece => _pieces.isNotEmpty && _currentIndex == _pieces.length - 1;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchPieceRecommandee();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController!,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController!,
      curve: Curves.easeIn,
    ));

    _slideController!.forward();
    _fadeController!.forward();
  }

  @override
  void dispose() {
    _slideController?.dispose();
    _fadeController?.dispose();
    super.dispose();
  }

  Future<void> _fetchPieceRecommandee() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.17:8000/api/piece-recommandee/${widget.demandeId}'),
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
        _showSnackBar('Aucune pièce recommandée trouvée', isError: true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Erreur de connexion: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _nextPiece() {
    if (_selectedPieceType == null) {
      _showSnackBar('Veuillez sélectionner une pièce avant de continuer', isError: true);
      return;
    }

    _saveCurrentSelection();

    if (_currentIndex < _pieces.length - 1) {
      _slideController?.reset();
      setState(() {
        _currentIndex++;
        _selectedPieceType = _getPreselectedTypeForCurrentIndex();
      });
      _slideController?.forward();
    } else {
      _showSnackBar('Vous avez vu toutes les pièces recommandées');
    }
  }

  void _previousPiece() {
    if (_currentIndex > 0) {
      _slideController?.reset();
      setState(() {
        _currentIndex--;
        _selectedPieceType = _getPreselectedTypeForCurrentIndex();
      });
      _slideController?.forward();
    }
  }

  void _saveCurrentSelection() {
    if (_selectedPieceType == null) return;

    final currentPiece = _pieces[_currentIndex];
    final pieceInfo = currentPiece['info'];
    final selectedPiece = currentPiece[_selectedPieceType!];

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
      _showSnackBar('Veuillez sélectionner une pièce avant de confirmer', isError: true);
      return;
    }

    _saveCurrentSelection();
    final piecesToSend = _selectedPieces.values.toList();

    try {
      final response = await http.put(
        Uri.parse('http://192.168.1.17:8000/api/demandes/${widget.demandeId}/pieces-choisies'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'pieces': piecesToSend,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MaintenanceTypePage(demandeId: widget.demandeId)),
        );
      } else {
        final errorData = jsonDecode(response.body);
        _showSnackBar(errorData['message'] ?? 'Erreur lors de l\'enregistrement', isError: true);
      }
    } catch (e) {
      _showSnackBar('Erreur de connexion: ${e.toString()}', isError: true);
    }
  }

  void _cancelSelection() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[50]!,
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingView()
                    : _pieces.isEmpty
                    ? _buildEmptyView()
                    : _buildPieceView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pièces Recommandées',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (!_isLoading && _pieces.isNotEmpty)
                  Text(
                    'Étape ${_currentIndex + 1} sur ${_pieces.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          if (!_isLoading && _pieces.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF007896),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentIndex + 1}/${_pieces.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007896)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chargement des pièces...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune pièce recommandée',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'pour cette demande',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieceView() {
    // Check if animations are initialized before using them
    if (_slideAnimation == null || _fadeAnimation == null || _pieces.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentPiece = _pieces[_currentIndex];
    final originalPiece = currentPiece['original'];
    final commercialPiece = currentPiece['commercial'];

    return SlideTransition(
      position: _slideAnimation!,
      child: FadeTransition(
        opacity: _fadeAnimation!,
        child: Column(
          children: [
            _buildPieceHeader(currentPiece),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    children: [
                      _buildPieceOption(
                        title: 'Originale',
                        pieceData: originalPiece,
                        type: 'original',
                        color: const Color(0xFF4A90E2),
                        accentColor: const Color(0xFF357ABD),
                      ),
                      Container(
                        width: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.grey[300]!,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      _buildPieceOption(
                        title: 'Commerciale',
                        pieceData: commercialPiece,
                        type: 'commercial',
                        color: const Color(0xFF50C878),
                        accentColor: const Color(0xFF45B26B),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildNavigationFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildPieceHeader(Map<String, dynamic> currentPiece) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF007896).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.build_circle,
                  color: Color(0xFF007896),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  currentPiece['info']['nom'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Réf: ${currentPiece['info']['num_piece']}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieceOption({
    required String title,
    required Map<String, dynamic> pieceData,
    required String type,
    required Color color,
    required Color accentColor,
  }) {
    final isSelected = _selectedPieceType == type;
    final disponibiliteField = type == 'original' ? 'disponibiliteOriginal' : 'disponibilitCommercial';
    final disponibiliteValue = pieceData[disponibiliteField];
    final bool isDisponible = disponibiliteValue == null
        ? true
        : disponibiliteValue is bool
        ? disponibiliteValue
        : disponibiliteValue.toString().toLowerCase() == 'true';

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPieceType = type;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            border: isSelected
                ? Border.all(color: color, width: 2)
                : null,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: color, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Sélectionnée',
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Image
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: pieceData['photo'] != null
                        ? Image.network(
                      'http://192.168.1.17:8000/storage/${pieceData['photo']}',
                      fit: BoxFit.contain,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildImagePlaceholder(),
                    )
                        : _buildImagePlaceholder(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Prix:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${pieceData['prix']?.toString() ?? 'N/A'} €',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Replace the problematic Row widget around line 694 with this fixed version:

                    Row(
                      children: [
                        Icon(
                          isDisponible ? Icons.check_circle : Icons.cancel,
                          color: isDisponible ? Colors.green[600] : Colors.red[600],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(  // Changed from direct Text to Flexible wrapper
                          child: Text(
                            isDisponible ? 'Disponible' : 'Indisponible',
                            style: TextStyle(
                              color: isDisponible ? Colors.green[700] : Colors.red[700],
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,  // Add ellipsis for very long text
                          ),
                        ),
                      ],
                    ),
                    if (isDisponible && pieceData['date_disponibilite'] != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: Colors.grey[600],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${pieceData['date_disponibilite']}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Image non disponible',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationFooter() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: _isLastPiece ? _buildConfirmButtons() : _buildNavigationButtons(),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _currentIndex > 0 ? _previousPiece : null,
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            label: const Text('Précédent'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[100],
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _nextPiece,
            icon: const Icon(Icons.arrow_forward_ios, size: 18),
            label: const Text('Suivant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007896),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _cancelSelection,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Annuler'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[100],
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _confirmSelection,
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Confirmer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }
}