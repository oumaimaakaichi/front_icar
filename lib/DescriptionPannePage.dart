import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DescriptionPannePage extends StatefulWidget {
  final int demandeId;

  const DescriptionPannePage({Key? key, required this.demandeId}) : super(key: key);

  @override
  State<DescriptionPannePage> createState() => _DescriptionPannePageState();
}

class _DescriptionPannePageState extends State<DescriptionPannePage>
    with TickerProviderStateMixin {
  final TextEditingController _panneController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  bool _isLoadingCategories = false;
  bool _isLoadingCatalogues = false;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  List<dynamic> _categories = [];
  List<int> _selectedCategories = [];

  List<dynamic> _catalogues = [];
  List<int> _selectedCatalogues = [];

  final String baseUrl = 'http://192.168.1.11:8000';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    if (_animationController != null) {
      _fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeInOut,
      ));

      _slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeOutCubic,
      ));

      _animationController!.forward();
    }

    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadCategories(),
      _loadCatalogues(),
    ]);
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/category-panes'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _categories = jsonDecode(response.body);
        });
      }
    } catch (e) {
      _showCustomSnackBar('Erreur de chargement des catégories', isError: true);
    } finally {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _loadCatalogues() async {
    setState(() => _isLoadingCatalogues = true);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/catalogues'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _catalogues = jsonDecode(response.body);
        });
      }
    } catch (e) {
      _showCustomSnackBar('Erreur de chargement des catalogues', isError: true);
    } finally {
      setState(() => _isLoadingCatalogues = false);
    }
  }

  @override
  void dispose() {
    _panneController.dispose();
    _focusNode.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_panneController.text.trim().isEmpty) {
      _showCustomSnackBar('Veuillez décrire la panne', isError: true);
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/demande-panne/${widget.demandeId}/update-panne'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'panne': _panneController.text.trim(),
          'categories': _selectedCategories,
          'catalogues': _selectedCatalogues,
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        HapticFeedback.mediumImpact();
        _showCustomSnackBar('Panne, catégories et pièces enregistrées avec succès !', isError: false);

        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) Navigator.pop(context, true);
      } else {
        _showCustomSnackBar('Erreur lors de l\'enregistrement', isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showCustomSnackBar('Erreur de connexion', isError: true);
    }
  }

  void _showCustomSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? Colors.red.shade600
            : const Color(0xFF73B1BD),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: Duration(milliseconds: isError ? 3000 : 2000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF73B1BD), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: const Text(
        'Décrire la panne',
        style: TextStyle(
          color: Color(0xFF2D3748),
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFB), Color(0xFFEDF2F7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _fadeAnimation != null && _slideAnimation != null
            ? FadeTransition(
          opacity: _fadeAnimation!,
          child: SlideTransition(
            position: _slideAnimation!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(),
                const SizedBox(height: 32),
                _buildFormSection(),
                const SizedBox(height: 24),
                _buildCataloguesSection(),
                const SizedBox(height: 24),
                _buildCategoriesSection(),
                const SizedBox(height: 24),
                _buildSubmitButton(),
                const SizedBox(height: 24),
                _buildTipsSection(),
              ],
            ),
          ),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 32),
            _buildFormSection(),
            const SizedBox(height: 24),
            _buildCataloguesSection(),
            const SizedBox(height: 24),
            _buildCategoriesSection(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
            const SizedBox(height: 24),
            _buildTipsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCataloguesSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: const Color(0xFF73B1BD),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Pièces concernées',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingCatalogues)
            const Center(child: CircularProgressIndicator())
          else if (_catalogues.isEmpty)
            const Text(
              'Aucune pièce disponible',
              style: TextStyle(color: Colors.grey),
            )
          else
            Column(
              children: _catalogues.map((catalogue) {
                final catalogueId = catalogue['id'] as int;
                final isSelected = _selectedCatalogues.contains(catalogueId);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF73B1BD)
                          : Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                  color: isSelected
                      ? const Color(0xFF73B1BD).withOpacity(0.1)
                      : Colors.white,
                  child: CheckboxListTile(
                    title: Text(
                      catalogue['nom_piece'] ?? 'Pièce sans nom',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF73B1BD)
                            : const Color(0xFF2D3748),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (catalogue['num_piece'] != null)
                          Text(
                            'Réf: ${catalogue['num_piece']}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        if (catalogue['type_voiture'] != null)
                          Text(
                            'Pour: ${catalogue['type_voiture']}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                    value: isSelected,
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedCatalogues.add(catalogueId);
                        } else {
                          _selectedCatalogues.remove(catalogueId);
                        }
                      });
                    },
                    activeColor: const Color(0xFF73B1BD),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.category_outlined,
                color: const Color(0xFF73B1BD),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Catégories de panne',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingCategories)
            const Center(child: CircularProgressIndicator())
          else if (_categories.isEmpty)
            const Text(
              'Aucune catégorie disponible',
              style: TextStyle(color: Colors.grey),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final categoryId = category['id'] as int;
                final isSelected = _selectedCategories.contains(categoryId);

                return FilterChip(
                  label: Text(category['titre'] ?? 'Sans titre'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(categoryId);
                      } else {
                        _selectedCategories.remove(categoryId);
                      }
                    });
                  },
                  selectedColor: const Color(0xFF73B1BD).withOpacity(0.2),
                  backgroundColor: Colors.grey.shade100,
                  checkmarkColor: const Color(0xFF73B1BD),
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFF73B1BD) : Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF73B1BD)
                          : Colors.grey.shade300,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF73B1BD), Color(0xFF5A9BA8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF73B1BD).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.build_circle_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description requise',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Décrivez précisément le problème rencontré',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_outlined,
                color: const Color(0xFF73B1BD),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Description de la panne',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _focusNode.hasFocus
                    ? const Color(0xFF73B1BD)
                    : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: TextField(
              controller: _panneController,
              focusNode: _focusNode,
              maxLines: 8,
              maxLength: 500,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Color(0xFF2D3748),
              ),
              decoration: InputDecoration(
                hintText: 'Exemple :\n• Bruit étrange lors du démarrage\n• Fuite visible sous l\'équipement\n• Voyant d\'erreur allumé\n• Performance réduite...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                  height: 1.4,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
                counterStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF73B1BD),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: Colors.grey.shade300,
        ).copyWith(
          overlayColor: MaterialStateProperty.all(
            Colors.white.withOpacity(0.1),
          ),
        ),
        child: _isLoading
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Enregistrement...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.save_outlined, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Enregistrer la description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF73B1BD).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF73B1BD).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: const Color(0xFF73B1BD),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Conseils pour une bonne description',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF73B1BD),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...const [
            '• Décrivez les symptômes observés',
            '• Indiquez quand le problème survient',
            '• Mentionnez les bruits ou odeurs anormales',
            '• Précisez si c\'est un problème récurrent',
          ].map((tip) => Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 16,
                color: Color(0xFF73B1BD),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  tip,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4A5568),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          )).toList(),
        ],
      ),
    );
  }
}