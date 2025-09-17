import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart';
import '../api/api_client.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _weatherData;
  Map<String, dynamic>? _marketData;
  bool _isLoading = true;
  String? _errorMessage;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // For AI Chat
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, dynamic>> _chatMessages = [];
  bool _isSendingMessage = false;

  // Dashboard settings
  bool _isTranslationEnabled = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchDashboardData();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
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
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch weather data
      final weatherData = await ApiClient.get("/weather/current?lat=30.9010&lon=75.8573");
      
      // Mock market data for now
      final marketData = {
        'wheat_price': 2125,
        'rice_price': 3200,
        'trend': 'up',
        'change': 2.5,
      };

      setState(() {
        _weatherData = weatherData;
        _marketData = marketData;
        _isLoading = false;
      });
      
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      // Use mock data if API fails
      setState(() {
        _weatherData = {
          'temperature': 24,
          'humidity': 65,
          'wind_speed': 12,
          'weather_condition': 'Partly Cloudy',
          'city': 'Ludhiana',
          'pressure': 1013,
        };
        _marketData = {
          'wheat_price': 2125,
          'rice_price': 3200,
          'trend': 'up',
          'change': 2.5,
        };
        _isLoading = false;
      });
      
      _fadeController.forward();
      _slideController.forward();
      debugPrint("Error fetching dashboard data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchDashboardData,
          color: AppTheme.primaryGreen,
          child: _isLoading
              ? _buildLoadingState()
              : _errorMessage != null
                  ? _buildErrorState()
                  : _buildDashboard(size),
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
            'Loading your dashboard...',
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
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.danger,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchDashboardData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(Size size) {
    return CustomScrollView(
      slivers: [
        // Custom App Bar with Greeting
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildHeader(),
          ),
        ),
        
        // Quick Stats Cards
        SliverToBoxAdapter(
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildQuickStats(),
          ),
        ),
        
        // Weather Card
        SliverToBoxAdapter(
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildWeatherCard(),
          ),
        ),
        
        // Quick Actions
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildQuickActions(),
          ),
        ),
        
        // Market Prices
        SliverToBoxAdapter(
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildMarketPrices(),
          ),
        ),
        
        // Recent Activities
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildRecentActivities(),
          ),
        ),
        
        const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
      ],
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    IconData greetingIcon = Icons.wb_sunny;
    
    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.wb_sunny;
    } else if (hour >= 17) {
      greeting = 'Good Evening';
      greetingIcon = Icons.nights_stay;
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(greetingIcon, color: AppTheme.accentOrange, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        greeting,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome back, Farmer!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryGreen,
                child: const Icon(Icons.person, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: _buildTranslationCard(),
    );
  }
  
  Widget _buildTranslationCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.translate, color: AppTheme.primaryGreen, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isTranslationEnabled ? 'Translation Enabled' : 'Enable Translation',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Make app accessible in your language',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isTranslationEnabled,
            activeColor: AppTheme.primaryGreen,
            onChanged: (value) {
              setState(() {
                _isTranslationEnabled = value;
                _applyTranslation(value);
              });
            },
          ),
        ],
      ),
    );
  }
  
  void _applyTranslation(bool enabled) {
    // This would connect to a translation service in a real implementation
    // For now, we'll just show a snackbar to indicate the change
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(enabled 
          ? 'Translation enabled - App language changed' 
          : 'Translation disabled - Using default language'),
        backgroundColor: AppTheme.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildWeatherCard() {
    if (_weatherData == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                    '${_weatherData!['city'] ?? 'Ludhiana'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_weatherData!['temperature']}°C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _weatherData!['weather_condition'] ?? 'Clear',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Icon(
                _getWeatherIcon(_weatherData!['weather_condition']),
                color: Colors.white,
                size: 80,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherDetail(
                Icons.water_drop,
                '${_weatherData!['humidity']}%',
                'Humidity',
              ),
              _buildWeatherDetail(
                Icons.air,
                '${_weatherData!['wind_speed']} m/s',
                'Wind',
              ),
              _buildWeatherDetail(
                Icons.compress,
                '${_weatherData!['pressure']} hPa',
                'Pressure',
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String? condition) {
    if (condition == null) return WeatherIcons.day_sunny;
    final c = condition.toLowerCase();
    if (c.contains('cloud')) return WeatherIcons.cloudy;
    if (c.contains('rain')) return WeatherIcons.rain;
    if (c.contains('clear')) return WeatherIcons.day_sunny;
    return WeatherIcons.day_cloudy;
  }

  Widget _buildWeatherDetail(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildActionCard(
                'AI Chat',
                Icons.chat_outlined,
                AppTheme.primaryGreen,
                () => _showChatDialog(context),
              ),
              _buildActionCard(
                'Soil Test',
                Icons.science,
                AppTheme.accentOrange,
                () => Navigator.pushNamed(context, '/soil'),
              ),
              _buildActionCard(
                'Market',
                Icons.store,
                AppTheme.info,
                () => Navigator.pushNamed(context, '/market'),
              ),
              _buildActionCard(
                'Pest Detection',
                Icons.camera_alt_outlined,
                AppTheme.warning,
                () => Navigator.pushNamed(context, '/pest-detection'),
              ),
              _buildActionCard(
                'Alerts',
                Icons.notifications,
                AppTheme.danger,
                () => Navigator.pushNamed(context, '/alerts'),
              ),
              _buildActionCard(
                'Chatbot',
                Icons.help_outline,
                AppTheme.secondaryGreen,
                () => Navigator.pushNamed(context, '/chatbot'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Chat dialog implementation
  void _showChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AI Farming Assistant',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: _chatMessages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: AppTheme.primaryGreen.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Ask me anything about farming!',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _chatMessages.length,
                            itemBuilder: (context, index) {
                              final message = _chatMessages[index];
                              return _buildChatMessage(
                                message['text'],
                                message['isUser'],
                                message['timestamp'],
                              );
                            },
                          ),
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          decoration: InputDecoration(
                            hintText: 'Type your question...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          onSubmitted: (_) => _sendChatMessage(setState),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: _isSendingMessage
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send, color: Colors.white),
                          onPressed: _isSendingMessage ? null : () => _sendChatMessage(setState),
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
    );
  }

  Widget _buildChatMessage(String text, bool isUser, DateTime timestamp) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primaryGreen : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: isUser ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendChatMessage(StateSetter setState) {
    if (_chatController.text.trim().isEmpty) return;

    final userMessage = _chatController.text.trim();
    setState(() {
      _chatMessages.add({
        'text': userMessage,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
      _isSendingMessage = true;
      _chatController.clear();
    });

    // Simulate AI response after a delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _chatMessages.add({
          'text': _getAIResponse(userMessage),
          'isUser': false,
          'timestamp': DateTime.now(),
        });
        _isSendingMessage = false;
      });
    });
  }

  String _getAIResponse(String userMessage) {
    // Mock AI responses based on keywords in user message
    final lowerCaseMessage = userMessage.toLowerCase();
    
    if (lowerCaseMessage.contains('weather')) {
      return 'Based on the current forecast, expect ${_weatherData?['weather_condition'] ?? 'clear skies'} with temperatures around ${_weatherData?['temperature'] ?? '25'}°C. This is good weather for field work.';
    } else if (lowerCaseMessage.contains('crop') || lowerCaseMessage.contains('plant')) {
      return 'For your soil type and current season, I recommend planting wheat, rice, or maize. Would you like specific details about any of these crops?';
    } else if (lowerCaseMessage.contains('pest') || lowerCaseMessage.contains('disease')) {
      return 'To identify pests or diseases, please use the image detector feature on the dashboard. You can upload a photo of the affected plant, and I\'ll analyze it for you.';
    } else if (lowerCaseMessage.contains('market') || lowerCaseMessage.contains('price')) {
      return 'Current market prices: Wheat - ₹${_marketData?['wheat_price'] ?? '2100'}/quintal, Rice - ₹${_marketData?['rice_price'] ?? '3200'}/quintal. Prices have ${_marketData?['trend'] == 'up' ? 'increased' : 'decreased'} by ${_marketData?['change'] ?? '2.5'}% this week.';
    } else if (lowerCaseMessage.contains('fertilizer') || lowerCaseMessage.contains('nutrient')) {
      return 'Based on typical soil conditions in your area, I recommend using a balanced NPK fertilizer (10-10-10) at 250kg/hectare. For more specific recommendations, please use the soil testing feature.';
    } else {
      return 'I\'m your farming assistant. I can help with weather forecasts, crop recommendations, pest identification, market prices, and more. What specific information do you need?';
    }
  }

  // Image detector section
  void _showImageDetector() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pest & Disease Detector',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 80,
                      color: AppTheme.primaryGreen.withOpacity(0.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Take a photo of your plant to identify pests and diseases',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => _mockImageDetection(context),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => _mockImageDetection(context),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Choose from Gallery'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mockImageDetection(BuildContext context) {
    // Close the current dialog
    Navigator.pop(context);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Analyzing image...'),
            ],
          ),
        ),
      ),
    );
    
    // Simulate processing delay
    Future.delayed(const Duration(seconds: 2), () {
      // Close loading dialog
      Navigator.pop(context);
      
      // Show results dialog
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bug_report,
                  size: 48,
                  color: AppTheme.danger,
                ),
                const SizedBox(height: 16),
                Text(
                  'Pest Detected: Aphids',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aphids are small sap-sucking insects that can cause significant damage to crops by transmitting plant viruses.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Recommended Action:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Apply neem oil spray (15ml per liter of water)\n'
                  '2. Introduce ladybugs as natural predators\n'
                  '3. Remove heavily infested plant parts\n'
                  '4. Apply insecticidal soap for severe infestations',
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketPrices() {
    if (_marketData == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Market Prices',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/market'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPriceCard(
                  'Wheat',
                  _marketData!['wheat_price'],
                  _marketData!['trend'] == 'up',
                  _marketData!['change'],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPriceCard(
                  'Rice',
                  _marketData!['rice_price'],
                  false,
                  -1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(
    String crop,
    int price,
    bool isUp,
    double change,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            crop,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '₹$price/q',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isUp ? Icons.trending_up : Icons.trending_down,
                color: isUp ? AppTheme.success : AppTheme.danger,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${change.abs()}%',
                style: TextStyle(
                  color: isUp ? AppTheme.success : AppTheme.danger,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    final activities = [
      {'icon': Icons.water_drop, 'title': 'Irrigation completed', 'time': '2 hours ago'},
      {'icon': Icons.eco, 'title': 'Fertilizer applied', 'time': '1 day ago'},
      {'icon': Icons.grass, 'title': 'Wheat harvested', 'time': '3 days ago'},
    ];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activities',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: activities.map((activity) {
                final isLast = activities.last == activity;
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      activity['icon'] as IconData,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                  ),
                  title: Text(activity['title'] as String),
                  subtitle: Text(activity['time'] as String),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  shape: !isLast
                      ? Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        )
                      : null,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}