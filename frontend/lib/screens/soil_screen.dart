import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;

class SoilScreen extends StatefulWidget {
  const SoilScreen({Key? key}) : super(key: key);

  @override
  State<SoilScreen> createState() => _SoilScreenState();
}

class _SoilScreenState extends State<SoilScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _soilAnalysis;
  Map<String, dynamic>? _recommendations;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  // Filters
  String _selectedSeason = 'rabi';
  
  final List<Map<String, dynamic>> _seasons = [
    {'id': 'rabi', 'name': 'Rabi', 'icon': '❄️', 'months': 'Oct-Mar'},
    {'id': 'kharif', 'name': 'Kharif', 'icon': '☀️', 'months': 'Apr-Sep'},
    {'id': 'zaid', 'name': 'Zaid', 'icon': '🌱', 'months': 'Apr-Jun'},
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchSoilData();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _fetchSoilData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Generate mock data based on selected filters
      setState(() {
        _soilAnalysis = _generateMockSoilAnalysis();
        _recommendations = _generateMockRecommendations();
        _isLoading = false;
      });
      
      _fadeController.forward();
      _slideController.forward();
      _scaleController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load soil data";
        _isLoading = false;
      });
      debugPrint("Error fetching soil data: $e");
    }
  }

  Map<String, dynamic> _generateMockSoilAnalysis() {
    return {
      'ph_level': 6.8 + math.Random().nextDouble() * 0.5,
      'nitrogen': 250 + math.Random().nextInt(50),
      'phosphorus': 20 + math.Random().nextInt(15),
      'potassium': 150 + math.Random().nextInt(50),
      'organic_matter': 2.0 + math.Random().nextDouble() * 1.5,
      'moisture': 55 + math.Random().nextInt(20),
      'ec': 0.5 + math.Random().nextDouble() * 0.3,
      'texture': 'Loamy',
      'health_score': 75 + math.Random().nextInt(20),
      'last_tested': DateTime.now().subtract(Duration(days: math.Random().nextInt(30))),
    };
  }

  Map<String, dynamic> _generateMockRecommendations() {
    final crops = _selectedSeason == 'rabi'
        ? [
            {'name': 'Wheat', 'suitability': 95, 'yield': '4.5 tons/ha', 'profit': '₹45,000/ha'},
            {'name': 'Mustard', 'suitability': 88, 'yield': '1.8 tons/ha', 'profit': '₹38,000/ha'},
            {'name': 'Gram', 'suitability': 82, 'yield': '2.2 tons/ha', 'profit': '₹42,000/ha'},
          ]
        : _selectedSeason == 'kharif'
        ? [
            {'name': 'Rice', 'suitability': 92, 'yield': '5.5 tons/ha', 'profit': '₹55,000/ha'},
            {'name': 'Cotton', 'suitability': 85, 'yield': '2.5 tons/ha', 'profit': '₹62,000/ha'},
            {'name': 'Maize', 'suitability': 78, 'yield': '6.0 tons/ha', 'profit': '₹48,000/ha'},
          ]
        : [
            {'name': 'Watermelon', 'suitability': 90, 'yield': '35 tons/ha', 'profit': '₹85,000/ha'},
            {'name': 'Cucumber', 'suitability': 87, 'yield': '20 tons/ha', 'profit': '₹65,000/ha'},
            {'name': 'Muskmelon', 'suitability': 83, 'yield': '25 tons/ha', 'profit': '₹75,000/ha'},
          ];
    
    return {
      'crops': crops,
      'fertilizers': [
        {'type': 'DAP', 'quantity': '100 kg/ha', 'timing': 'At sowing', 'importance': 'high'},
        {'type': 'Urea', 'quantity': '50 kg/ha', 'timing': 'After 30 days', 'importance': 'medium'},
        {'type': 'MOP', 'quantity': '25 kg/ha', 'timing': 'Before flowering', 'importance': 'low'},
      ],
      'improvements': [
        'Add organic compost to improve soil structure',
        'Consider crop rotation with legumes',
        'Install drip irrigation for water efficiency',
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchSoilData,
          color: AppTheme.primaryGreen,
          child: _isLoading
              ? _buildLoadingState()
              : _errorMessage != null
                  ? _buildErrorState()
                  : _buildSoilContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: AppTheme.cardShadow,
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Analyzing soil data...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.danger.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.danger,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchSoilData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoilContent() {
    return CustomScrollView(
      slivers: [
        // Custom App Bar
        SliverAppBar(
          expandedHeight: 120,
          floating: true,
          backgroundColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Soil Analysis',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Monitor your soil health',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Content
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildFilters(),
              _buildSoilHealthCard(),
              _buildNutrientCards(),
              _buildCropRecommendations(),
              _buildFertilizerRecommendations(),
              _buildImprovementSuggestions(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Select Season & Region',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Season Selector
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _seasons.length,
                      itemBuilder: (context, index) {
                        final season = _seasons[index];
                        final isSelected = season['id'] == _selectedSeason;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSeason = season['id'];
                            });
                            _fetchSoilData();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: isSelected 
                                ? AppTheme.primaryGreen 
                                : Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isSelected 
                                  ? AppTheme.primaryGreen 
                                  : Colors.grey.shade300,
                                width: 2,
                              ),
                              boxShadow: isSelected 
                                ? AppTheme.elevatedShadow 
                                : null,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  season['icon'],
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      season['name'],
                                      style: TextStyle(
                                        color: isSelected 
                                          ? Colors.white 
                                          : AppTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      season['months'],
                                      style: TextStyle(
                                        color: isSelected 
                                          ? Colors.white70 
                                          : AppTheme.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoilHealthCard() {
    if (_soilAnalysis == null) return const SizedBox.shrink();
    
    final healthScore = _soilAnalysis!['health_score'];
    final healthColor = healthScore > 80 
      ? AppTheme.success 
      : healthScore > 60 
        ? AppTheme.warning 
        : AppTheme.danger;
    
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [healthColor, healthColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: healthColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Soil Health Score',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          healthScore.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 4),
                          child: Text(
                            '/100',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: healthScore / 100,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 8,
                      ),
                      Icon(
                        healthScore > 80 
                          ? Icons.check_circle 
                          : healthScore > 60 
                            ? Icons.info 
                            : Icons.warning,
                        color: Colors.white,
                        size: 32,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.landscape,
                    color: Colors.white.withOpacity(0.9),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _soilAnalysis!['texture'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientCards() {
    if (_soilAnalysis == null) return const SizedBox.shrink();
    
    final nutrients = [
      {
        'name': 'pH',
        'value': _soilAnalysis!['ph_level']?.toStringAsFixed(1),
        'unit': '',
        'optimal': '6.5-7.5',
        'icon': Icons.science,
        'color': AppTheme.info,
      },
      {
        'name': 'Nitrogen',
        'value': _soilAnalysis!['nitrogen'].toString(),
        'unit': 'kg/ha',
        'optimal': '250-300',
        'icon': Icons.grass,
        'color': AppTheme.success,
      },
      {
        'name': 'Phosphorus',
        'value': _soilAnalysis!['phosphorus'].toString(),
        'unit': 'kg/ha',
        'optimal': '20-35',
        'icon': Icons.bubble_chart,
        'color': AppTheme.accentOrange,
      },
      {
        'name': 'Potassium',
        'value': _soilAnalysis!['potassium'].toString(),
        'unit': 'kg/ha',
        'optimal': '150-200',
        'icon': Icons.grain,
        'color': AppTheme.warning,
      },
      {
        'name': 'Organic Matter',
        'value': _soilAnalysis!['organic_matter']?.toStringAsFixed(1),
        'unit': '%',
        'optimal': '2-4%',
        'icon': Icons.eco,
        'color': AppTheme.primaryGreen,
      },
      {
        'name': 'Moisture',
        'value': _soilAnalysis!['moisture'].toString(),
        'unit': '%',
        'optimal': '60-70%',
        'icon': Icons.water_drop,
        'color': Colors.blue,
      },
    ];
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutrient Analysis',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: nutrients.map((nutrient) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (nutrient['color'] as Color).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              nutrient['icon'] as IconData,
                              color: nutrient['color'] as Color,
                              size: 20,
                            ),
                          ),
                          Text(
                            nutrient['optimal'] as String,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nutrient['name'] as String,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                nutrient['value'] as String,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  nutrient['unit'] as String,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropRecommendations() {
    if (_recommendations == null) return const SizedBox.shrink();
    
    final crops = _recommendations!['crops'] as List;
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recommended Crops',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _selectedSeason.toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...crops.map((crop) {
              final suitability = crop['suitability'];
              final suitabilityColor = suitability > 90 
                ? AppTheme.success 
                : suitability > 80 
                  ? AppTheme.warning 
                  : AppTheme.info;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      // Show crop details
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  suitabilityColor,
                                  suitabilityColor.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '$suitability%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  crop['name'],
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.agriculture,
                                      size: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      crop['yield'],
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.attach_money,
                                      size: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      crop['profit'],
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFertilizerRecommendations() {
    if (_recommendations == null) return const SizedBox.shrink();
    
    final fertilizers = _recommendations!['fertilizers'] as List;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.elevatedShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.science,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Fertilizer Schedule',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...fertilizers.map((fertilizer) {
              final importance = fertilizer['importance'];
              final importanceColor = importance == 'high'
                ? Colors.red
                : importance == 'medium'
                  ? Colors.orange
                  : Colors.green;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: importanceColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                fertilizer['type'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  fertilizer['quantity'],
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fertilizer['timing'],
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovementSuggestions() {
    if (_recommendations == null) return const SizedBox.shrink();
    
    final improvements = _recommendations!['improvements'] as List;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.info.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tips_and_updates,
                color: AppTheme.info,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Improvement Tips',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...improvements.map((tip) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.info,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}