import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../api/api_client.dart';

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
      // Fetch real data from backend API
      final response = await ApiClient.get('/soil/seasonal-recommendations?season=$_selectedSeason&region=ludhiana')
          .timeout(const Duration(seconds: 5), onTimeout: () {
        throw Exception('Connection timeout');
      });
      
      // Process the API response
      setState(() {
        // Use real soil analysis data or fallback to stored data if not provided
        _soilAnalysis = response['soil_analysis'] ?? _getDefaultSoilAnalysis();
        // Use real recommendations from API
        _recommendations = {
          'crops': response['recommendations'] ?? [],
          'fertilizers': response['fertilizer_recommendations'] ?? _getDefaultFertilizers(),
          'improvements': response['improvement_suggestions'] ?? _getDefaultImprovements(),
        };
        _isLoading = false;
      });
      
      _fadeController.forward();
      _slideController.forward();
      _scaleController.forward();
    } catch (e) {
      debugPrint("Error fetching soil data: $e");
      // Fallback to default data if API fails
      setState(() {
        _soilAnalysis = _getDefaultSoilAnalysis();
        _recommendations = _getDefaultRecommendations();
        _isLoading = false;
      });
      
      _fadeController.forward();
      _slideController.forward();
      _scaleController.forward();
    }
  }

  // Default soil analysis data for fallback
  Map<String, dynamic> _getDefaultSoilAnalysis() {
    return {
      'ph_level': 6.8,
      'nitrogen': 250,
      'phosphorus': 20,
      'potassium': 150,
      'organic_matter': 2.0,
      'moisture': 55,
      'ec': 0.5,
      'texture': 'Loamy',
      'health_score': 75,
      'last_tested': DateTime.now().subtract(const Duration(days: 7)),
    };
  }

  // Default recommendations for fallback
  Map<String, dynamic> _getDefaultRecommendations() {
    return {
      'crops': _getDefaultCrops(),
      'fertilizers': _getDefaultFertilizers(),
      'improvements': _getDefaultImprovements(),
    };
  }
  
  // Get default crops based on selected season
  List<Map<String, dynamic>> _getDefaultCrops() {
    if (_selectedSeason == 'rabi') {
      return [
        {'name': 'Wheat', 'suitability': 95, 'yield': '4.5 tons/ha', 'profit': '₹45,000/ha'},
        {'name': 'Mustard', 'suitability': 88, 'yield': '1.8 tons/ha', 'profit': '₹38,000/ha'},
        {'name': 'Gram', 'suitability': 82, 'yield': '2.2 tons/ha', 'profit': '₹42,000/ha'},
      ];
    } else if (_selectedSeason == 'kharif') {
      return [
        {'name': 'Rice', 'suitability': 92, 'yield': '5.5 tons/ha', 'profit': '₹55,000/ha'},
        {'name': 'Cotton', 'suitability': 85, 'yield': '2.5 tons/ha', 'profit': '₹62,000/ha'},
        {'name': 'Maize', 'suitability': 78, 'yield': '6.0 tons/ha', 'profit': '₹48,000/ha'},
      ];
    } else {
      return [
        {'name': 'Watermelon', 'suitability': 90, 'yield': '35 tons/ha', 'profit': '₹85,000/ha'},
        {'name': 'Cucumber', 'suitability': 87, 'yield': '20 tons/ha', 'profit': '₹65,000/ha'},
        {'name': 'Muskmelon', 'suitability': 83, 'yield': '25 tons/ha', 'profit': '₹75,000/ha'},
      ];
    }
  }
  
  // Default fertilizer recommendations
  List<Map<String, dynamic>> _getDefaultFertilizers() {
    return [
      {'type': 'DAP', 'quantity': '100 kg/ha', 'timing': 'At sowing', 'importance': 'high'},
      {'type': 'Urea', 'quantity': '50 kg/ha', 'timing': 'After 30 days', 'importance': 'medium'},
      {'type': 'MOP', 'quantity': '25 kg/ha', 'timing': 'Before flowering', 'importance': 'low'},
    ];
  }
  
  // Default improvement suggestions
  List<String> _getDefaultImprovements() {
    return [
      'Add organic compost to improve soil structure',
      'Consider crop rotation with legumes',
      'Install drip irrigation for water efficiency',
    ];
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
          const Text(
            'Analyzing soil data...',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please wait',
            style: TextStyle(fontSize: 12, color: Colors.grey),
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Opacity(
                      opacity: 0.2,
                      child: Icon(
                        Icons.grass,
                        size: 120,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Soil Analysis',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last updated: Today',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Main Content
        SliverList(
          delegate: SliverChildListDelegate([
            // Soil Health Score
            _buildSoilHealthScore(),
            
            // Nutrient Analysis
            _buildHeader(),
            
            // Crop Recommendations
            _buildCropRecommendations(),
            
            // Fertilizer Recommendations
            _buildFertilizerRecommendations(),
            
            // Improvement Suggestions
            _buildImprovementSuggestions(),
            
            const SizedBox(height: 40),
          ]),
        ),
      ],
    );
  }

  Widget _buildSoilHealthScore() {
    if (_soilAnalysis == null) return const SizedBox.shrink();
    
    final healthScore = _soilAnalysis!['health_score'] as int;
    final healthStatus = healthScore > 80 
        ? 'Excellent' 
        : healthScore > 60 
            ? 'Good' 
            : healthScore > 40 
                ? 'Fair' 
                : 'Poor';
    
    final healthColor = healthScore > 80 
        ? AppTheme.success 
        : healthScore > 60 
            ? AppTheme.primaryGreen 
            : healthScore > 40 
                ? AppTheme.warning 
                : AppTheme.danger;
    
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Soil Health Score',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: healthColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      healthStatus,
                      style: TextStyle(
                        color: healthColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: CircularProgressIndicator(
                      value: healthScore / 100,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '$healthScore',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'out of 100',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSoilInfoItem(
                    'Texture',
                    _soilAnalysis!['texture'] as String,
                    Icons.layers,
                  ),
                  _buildSoilInfoItem(
                    'EC',
                    '${_soilAnalysis!['ec']} dS/m',
                    Icons.bolt,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoilInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryGreen,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    if (_soilAnalysis == null) return const SizedBox.shrink();
    
    final List<Map<String, dynamic>> nutrients = [
      {
        'name': 'pH Level',
        'value': _soilAnalysis!['ph_level'].toString(),
        'unit': '',
        'optimal': '6.5-7.5',
        'icon': Icons.water_drop_outlined,
        'color': Colors.blue,
      },
      {
        'name': 'Nitrogen',
        'value': _soilAnalysis!['nitrogen'].toString(),
        'unit': 'kg/ha',
        'optimal': '280-560',
        'icon': Icons.eco_outlined,
        'color': Colors.green,
      },
      {
        'name': 'Phosphorus',
        'value': _soilAnalysis!['phosphorus'].toString(),
        'unit': 'kg/ha',
        'optimal': '20-40',
        'icon': Icons.science_outlined,
        'color': Colors.orange,
      },
      {
        'name': 'Potassium',
        'value': _soilAnalysis!['potassium'].toString(),
        'unit': 'kg/ha',
        'optimal': '140-280',
        'icon': Icons.grass_outlined,
        'color': Colors.purple,
      },
      {
        'name': 'Organic Matter',
        'value': _soilAnalysis!['organic_matter']?.toStringAsFixed(1),
        'unit': '%',
        'optimal': '3-5',
        'icon': Icons.compost_outlined,
        'color': Colors.brown,
      },
      {
        'name': 'Moisture',
        'value': _soilAnalysis!['moisture'].toString(),
        'unit': '%',
        'optimal': '50-70',
        'icon': Icons.opacity_outlined,
        'color': Colors.lightBlue,
      },
    ];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nutrient Analysis',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: nutrients.map((nutrient) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: (nutrient['color'] as Color).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              nutrient['icon'] as IconData,
                              color: nutrient['color'] as Color,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            nutrient['name'] as String,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            nutrient['value'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              nutrient['unit'] as String,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Optimal: ${nutrient['optimal']}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
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
    
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommended Crops',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'BEST FOR ' + _selectedSeason.toUpperCase(),
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: _seasons.map((season) {
                final isSelected = season['id'] == _selectedSeason;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSeason = season['id'] as String;
                    });
                    _fetchSoilData();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.primaryGreen 
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(season['icon'] as String),
                        const SizedBox(width: 4),
                        Text(
                          season['name'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: isSelected 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ...crops.map<Widget>((crop) {
              final suitability = crop['suitability'] as int;
              final suitabilityColor = suitability > 90 
                  ? AppTheme.success 
                  : suitability > 80 
                      ? AppTheme.primaryGreen 
                      : suitability > 70 
                          ? AppTheme.warning 
                          : AppTheme.danger;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: suitabilityColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$suitability%',
                          style: TextStyle(
                            color: suitabilityColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                            crop['name'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildCropInfoItem(
                                'Yield',
                                crop['yield'] as String,
                                Icons.grass,
                              ),
                              const SizedBox(width: 16),
                              _buildCropInfoItem(
                                'Profit',
                                crop['profit'] as String,
                                Icons.currency_rupee,
                              ),
                            ],
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

  Widget _buildCropInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFertilizerRecommendations() {
    if (_recommendations == null) return const SizedBox.shrink();
    
    final fertilizers = _recommendations!['fertilizers'] as List;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fertilizer Recommendations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...fertilizers.map<Widget>((fertilizer) {
              final importance = fertilizer['importance'] as String;
              final importanceColor = importance == 'high' 
                  ? AppTheme.danger 
                  : importance == 'medium' 
                      ? AppTheme.warning 
                      : AppTheme.success;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: importanceColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.science,
                          color: importanceColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fertilizer['type'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quantity: ${fertilizer['quantity']}',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Apply: ${fertilizer['timing']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: importanceColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        importance.toUpperCase(),
                        style: TextStyle(
                          color: importanceColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
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
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Improvement Suggestions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...improvements.asMap().entries.map<Widget>((entry) {
              final index = entry.key;
              final suggestion = entry.value as String;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
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
}