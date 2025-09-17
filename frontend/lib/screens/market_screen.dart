import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../theme/app_theme.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({Key? key}) : super(key: key);

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _allPrices;
  Map<String, dynamic>? _selectedCropData;
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCrop = 'wheat';
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final List<Map<String, dynamic>> _cropOptions = [
    {'name': 'wheat', 'icon': '🌾', 'color': Color(0xFFF4A460)},
    {'name': 'rice', 'icon': '🌾', 'color': Color(0xFF8B7355)},
    {'name': 'maize', 'icon': '🌽', 'color': Color(0xFFFFD700)},
    {'name': 'cotton', 'icon': '☁️', 'color': Color(0xFFF0F0F0)},
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchMarketData();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchMarketData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch all market prices
      final allPrices = await ApiClient.get("/market/all");
      
      // Fetch selected crop details
      final cropData = await ApiClient.get("/market/price?crop=$_selectedCrop");

      setState(() {
        _allPrices = allPrices;
        _selectedCropData = cropData;
        _isLoading = false;
      });
      
      _fadeController.forward();
    } catch (e) {
      setState(() {
        // Use mock data if API fails
        _allPrices = {
          'prices': [
            {'crop': 'wheat', 'price': 2125, 'msp': 2125, 'change': 2.5},
            {'crop': 'rice', 'price': 3200, 'msp': 2903, 'change': -1.2},
            {'crop': 'maize', 'price': 2090, 'msp': 2090, 'change': 0.8},
            {'crop': 'cotton', 'price': 6620, 'msp': 6620, 'change': 3.1},
          ]
        };
        _selectedCropData = {
          'crop': _selectedCrop,
          'current_price': 2125,
          'min_price': 1800,
          'max_price': 2200,
          'msp': 2125,
        };
        _isLoading = false;
      });
      _fadeController.forward();
      debugPrint("Error fetching market data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchMarketData,
          color: AppTheme.primaryGreen,
          child: _isLoading
              ? _buildLoadingState()
              : _errorMessage != null
                  ? _buildErrorState()
                  : _buildMarketContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
          ),
          const SizedBox(height: 16),
          Text(
            'Fetching market prices...',
            style: Theme.of(context).textTheme.bodyMedium,
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
          Icon(Icons.error_outline, size: 64, color: AppTheme.danger),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchMarketData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketContent() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 60,
          floating: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Market Prices',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildCropSelector(),
                _buildSelectedCropCard(),
                _buildPriceRangeCard(),
                _buildAllPricesSection(),
                _buildMarketTips(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCropSelector() {
    return Container(
      height: 100,
      margin: const EdgeInsets.all(20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _cropOptions.length,
        itemBuilder: (context, index) {
          final crop = _cropOptions[index];
          final isSelected = crop['name'] == _selectedCrop;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCrop = crop['name'];
              });
              _fetchMarketData();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected 
                    ? AppTheme.primaryGreen 
                    : Colors.grey.shade300,
                  width: 2,
                ),
                boxShadow: isSelected ? AppTheme.elevatedShadow : AppTheme.cardShadow,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    crop['icon'],
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    crop['name'].toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedCropCard() {
    if (_selectedCropData == null) return const SizedBox.shrink();
    
    final currentPrice = _selectedCropData!['current_price'] ?? 0;
    final msp = _selectedCropData!['msp'] ?? 0;
    final priceAboveMsp = currentPrice > msp;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: priceAboveMsp
            ? [AppTheme.success, AppTheme.success.withOpacity(0.8)]
            : [AppTheme.warning, AppTheme.warning.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (priceAboveMsp ? AppTheme.success : AppTheme.warning)
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCrop.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹$currentPrice',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'per quintal',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      priceAboveMsp ? Icons.trending_up : Icons.trending_down,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      priceAboveMsp ? 'Above MSP' : 'Below MSP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPriceInfo('MSP', '₹$msp'),
                _buildPriceInfo('Market', '₹$currentPrice'),
                _buildPriceInfo('Difference', 
                  '${priceAboveMsp ? '+' : ''}₹${(currentPrice - msp).abs()}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRangeCard() {
    if (_selectedCropData == null) return const SizedBox.shrink();
    
    final minPrice = _selectedCropData!['min_price'] ?? 0;
    final maxPrice = _selectedCropData!['max_price'] ?? 0;
    final currentPrice = _selectedCropData!['current_price'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Range (Today)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₹$minPrice', style: Theme.of(context).textTheme.bodySmall),
              Text('₹$maxPrice', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (currentPrice - minPrice) / (maxPrice - minPrice),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Current: ₹$currentPrice',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllPricesSection() {
    if (_allPrices == null) return const SizedBox.shrink();
    
    final prices = _allPrices!['prices'] ?? [];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Crop Prices',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ...prices.map((price) {
            final isPositive = (price['change'] ?? 0) > 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        price['crop'].toString().toUpperCase(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'MSP: ₹${price['msp']}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${price['price']}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                                size: 14,
                                color: isPositive ? AppTheme.success : AppTheme.danger,
                              ),
                              Text(
                                '${price['change'].abs()}%',
                                style: TextStyle(
                                  color: isPositive ? AppTheme.success : AppTheme.danger,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMarketTips() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Market Tips',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Best time to sell wheat is when prices are above MSP\n'
            '• Store your produce properly to get better prices\n'
            '• Check nearby market prices before selling',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}