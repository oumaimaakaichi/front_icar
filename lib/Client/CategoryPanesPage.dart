import 'package:car_mobile/Client/ServicesByCategoryPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AllPannesPage extends StatefulWidget {
  final String voitureModel;
  final int voitureId;

  const AllPannesPage({
    super.key,
    required this.voitureModel,
    required this.voitureId,
  });

  @override
  State<AllPannesPage> createState() => _AllPannesPageState();
}

class _AllPannesPageState extends State<AllPannesPage> with TickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();
  List<dynamic> _allPannes = [];
  List<dynamic> _currentPagePannes = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Pagination variables
  int _currentPage = 1;
  int _itemsPerPage = 6;
  int _totalPages = 1;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchAllPannes();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
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
          _allPannes = jsonDecode(response.body);
          _isLoading = false;
          _currentPage = 1;
          _updatePagination();
        });

        _fadeController.forward();
        _slideController.forward();
      } else {
        throw Exception('Failed to load pannes');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  List<dynamic> get _filteredPannes {
    if (_searchQuery.isEmpty) return _allPannes;
    return _allPannes.where((panne) {
      final title = panne['titre']?.toString().toLowerCase() ?? '';
      final description = panne['description']?.toString().toLowerCase() ?? '';
      return title.contains(_searchQuery.toLowerCase()) ||
          description.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _updatePagination() {
    final filteredList = _filteredPannes;
    _totalPages = (filteredList.length / _itemsPerPage).ceil();
    if (_totalPages == 0) _totalPages = 1;

    if (_currentPage > _totalPages) {
      _currentPage = _totalPages;
    }

    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, filteredList.length);

    _currentPagePannes = filteredList.sublist(
      startIndex,
      endIndex,
    );
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _currentPage = 1;
      _updatePagination();
    });
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages && page != _currentPage) {
      setState(() {
        _currentPage = page;
        _updatePagination();
      });

      // Reset and replay animations
      _fadeController.reset();
      _slideController.reset();
      _fadeController.forward();
      _slideController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildHeader()),
          _isLoading
              ? SliverFillRemaining(child: _buildLoadingIndicator())
              : _filteredPannes.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState())
              : SliverToBoxAdapter(child: _buildPannesContent()),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.1),
      surfaceTintColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1E293B)),
            onPressed: _fetchAllPannes,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Catégories de Pannes',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Color(0xFFF1F5F9),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Rechercher une catégorie de panne...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.search_rounded,
                color: Colors.grey[400],
                size: 24,
              ),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear_rounded, color: Colors.grey[400]),
              onPressed: () => _onSearchChanged(''),
            )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onChanged: _onSearchChanged,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Choisir une catégorie de panne',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!_isLoading && _filteredPannes.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_filteredPannes.length} catégories',
                style: const TextStyle(
                  color: Color(0xFF3B82F6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chargement des catégories...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.build_circle_outlined,
                size: 64,
                color: const Color(0xFF3B82F6).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty
                  ? 'Aucune catégorie disponible'
                  : 'Aucun résultat trouvé',
              style: const TextStyle(
                fontSize: 22,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Les catégories de pannes seront affichées ici'
                  : 'Aucune catégorie ne correspond à "$_searchQuery"',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _onSearchChanged(''),
                icon: const Icon(Icons.clear_rounded),
                label: const Text('Effacer la recherche'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPannesContent() {
    return Column(
      children: [
        FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildPannesList(),
          ),
        ),
        if (_totalPages > 1) ...[
          const SizedBox(height: 20),
          _buildPaginationControls(),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildPannesList() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _currentPagePannes.asMap().entries.map((entry) {
          final index = entry.key;
          final panne = entry.value;
          return Container(
            margin: EdgeInsets.only(bottom: index == _currentPagePannes.length - 1 ? 0 : 16),
            child: _buildPanneCard(panne, index),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPanneCard(Map<String, dynamic> panne, int index) {
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];
    final cardColor = colors[index % colors.length];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) {
                  return ServicesByCategoryPage(
                    categoryId: panne['id'],
                    categoryName: panne['titre'],
                    voitureId: widget.voitureId,
                  );
                },
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubic,
                    )),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 400),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Hero(
                  tag: 'panne_${panne['id']}',
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cardColor.withOpacity(0.8),
                          cardColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getPanneIcon(panne['titre']),
                      color: Colors.white,
                      size: 28,
                    ),
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
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        panne['description'] ?? 'Description non disponible',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: cardColor,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          _buildPaginationButton(
            onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
            child: const Icon(Icons.chevron_left_rounded),
          ),
          const SizedBox(width: 12),

          // Page numbers
          ...List.generate(_totalPages, (index) {
            final pageNum = index + 1;
            final isCurrentPage = pageNum == _currentPage;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildPaginationButton(
                onPressed: () => _goToPage(pageNum),
                isSelected: isCurrentPage,
                child: Text(
                  pageNum.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isCurrentPage ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(width: 12),
          // Next button
          _buildPaginationButton(
            onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
            child: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required VoidCallback? onPressed,
    required Widget child,
    bool isSelected = false,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF3B82F6)
            : onPressed != null
            ? Colors.white
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        boxShadow: onPressed != null ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Center(
            child: IconTheme(
              data: IconThemeData(
                color: isSelected
                    ? Colors.white
                    : onPressed != null
                    ? const Color(0xFF1E293B)
                    : Colors.grey[400],
                size: 20,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getPanneIcon(String? title) {
    final titleLower = title?.toLowerCase() ?? '';

    if (titleLower.contains('moteur')) return Icons.settings_rounded;
    if (titleLower.contains('frein')) return Icons.stop_circle_outlined;
    if (titleLower.contains('électrique') || titleLower.contains('batterie')) return Icons.electrical_services_rounded;
    if (titleLower.contains('transmission')) return Icons.sync_rounded;
    if (titleLower.contains('suspension')) return Icons.linear_scale_rounded;
    if (titleLower.contains('climatisation')) return Icons.ac_unit_rounded;
    if (titleLower.contains('carburant')) return Icons.local_gas_station_rounded;
    if (titleLower.contains('pneu') || titleLower.contains('roue')) return Icons.tire_repair_rounded;

    return Icons.build_circle_rounded;
  }
}