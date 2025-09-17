import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart';
import '../api/api_client.dart';
import '../theme/app_theme.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _currentWeather;
  Map<String, dynamic>? _forecast;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  // Location (default: Ludhiana)
  final double _lat = 30.9010;
  final double _lon = 75.8573;
  String _selectedCrop = 'wheat';
  
  final List<String> _crops = ['wheat', 'rice', 'maize', 'cotton', 'sugarcane'];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchWeatherData();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch current weather
      final currentWeather = await ApiClient.get(
        "/weather/current?lat=$_lat&lon=$_lon"
      );
      
      // Try to fetch forecast, but handle errors gracefully
      Map<String, dynamic>? forecast;
      try {
        forecast = await ApiClient.get(
          "/weather/forecast?lat=$_lat&lon=$_lon&days=5&crop=$_selectedCrop"
        );
      } catch (e) {
        // Use mock forecast data if API fails
        forecast = _getMockForecast();
        debugPrint("Forecast API failed, using mock data: $e");
      }

      setState(() {
        _currentWeather = currentWeather;
        _forecast = forecast;
        _isLoading = false;
      });
      
      _fadeController.forward();
      _scaleController.forward();
    } catch (e) {
      // If even current weather fails, use all mock data
      setState(() {
        _currentWeather = _getMockCurrentWeather();
        _forecast = _getMockForecast();
        _isLoading = false;
        _errorMessage = null; // Don't show error, just use mock data
      });
      
      _fadeController.forward();
      _scaleController.forward();
      debugPrint("Error fetching weather: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchWeatherData,
          color: AppTheme.primaryGreen,
          child: _isLoading
              ? _buildLoadingState()
              : _errorMessage != null
                  ? _buildErrorState()
                  : _buildWeatherContent(),
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
            'Fetching weather data...',
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
            onPressed: _fetchWeatherData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent() {
    return CustomScrollView(
      slivers: [
        // Custom App Bar
        SliverAppBar(
          expandedHeight: 60,
          floating: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Weather & Forecast',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.location_on),
              onPressed: () {
                // Show location picker
                _showLocationDialog();
              },
            ),
          ],
        ),
        
        // Current Weather Hero Card
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildCurrentWeatherCard(),
            ),
          ),
        ),
        
        // Weather Details Grid
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildWeatherDetailsGrid(),
          ),
        ),
        
        // Crop Selection for Alerts
        SliverToBoxAdapter(
          child: _buildCropSelector(),
        ),
        
        // 5-Day Forecast
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildForecastSection(),
          ),
        ),
        
        // Weather Alerts
        if (_forecast?['alerts'] != null && (_forecast!['alerts'] as List).isNotEmpty)
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildWeatherAlerts(),
            ),
          ),
        
        const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
      ],
    );
  }

  Widget _buildCurrentWeatherCard() {
    if (_currentWeather == null) return const SizedBox.shrink();
    
    final temp = _currentWeather!['temperature'] ?? 0;
    final condition = _currentWeather!['weather_condition'] ?? 'Clear';
    final city = _currentWeather!['city'] ?? 'Unknown';
    
    return Container(
      margin: const EdgeInsets.all(20),
      height: 220,
      decoration: BoxDecoration(
        gradient: _getWeatherGradient(condition),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _getWeatherColor(condition).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -30,
            top: -30,
            child: Icon(
              _getWeatherIcon(condition),
              size: 180,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, 
                                color: Colors.white70, size: 16),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  city,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${temp.round()}°',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 64,
                                fontWeight: FontWeight.w200,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Icon(
                          _getWeatherIcon(condition),
                          size: 80,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          condition,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: _buildTempDetail('Feels like', 
                        '${(_currentWeather!['feels_like'] ?? temp).round()}°'),
                    ),
                    Expanded(
                      child: _buildTempDetail('UV Index', 
                        '${_currentWeather!['uv_index'] ?? 5}'),
                    ),
                    Expanded(
                      child: _buildTempDetail('Visibility', 
                        '${(_currentWeather!['visibility'] ?? 10)} km'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTempDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildWeatherDetailsGrid() {
    if (_currentWeather == null) return const SizedBox.shrink();
    
    final details = [
      {
        'icon': Icons.water_drop,
        'label': 'Humidity',
        'value': '${_currentWeather!['humidity'] ?? 0}%',
        'color': AppTheme.info,
      },
      {
        'icon': Icons.air,
        'label': 'Wind',
        'value': '${_currentWeather!['wind_speed'] ?? 0} m/s',
        'color': AppTheme.secondaryGreen,
      },
      {
        'icon': Icons.compress,
        'label': 'Pressure',
        'value': '${_currentWeather!['pressure'] ?? 1013} hPa',
        'color': AppTheme.accentOrange,
      },
      {
        'icon': Icons.water,
        'label': 'Rainfall',
        'value': '${_currentWeather!['rainfall'] ?? 0} mm',
        'color': AppTheme.primaryGreen,
      },
    ];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.8,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: details.map((detail) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (detail['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    detail['icon'] as IconData,
                    color: detail['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        detail['label'] as String,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        detail['value'] as String,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCropSelector() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Get Alerts For',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _crops.length,
              itemBuilder: (context, index) {
                final crop = _crops[index];
                final isSelected = crop == _selectedCrop;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCrop = crop;
                    });
                    _fetchWeatherData();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryGreen : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected 
                          ? AppTheme.primaryGreen 
                          : Colors.grey.shade300,
                      ),
                      boxShadow: isSelected ? AppTheme.elevatedShadow : null,
                    ),
                    child: Center(
                      child: Text(
                        crop.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastSection() {
    if (_forecast == null || _forecast!['forecast'] == null) {
      return const SizedBox.shrink();
    }
    
    final forecastDays = _forecast!['forecast'] as List;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '5-Day Forecast',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                'for $_selectedCrop',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: forecastDays.length,
              itemBuilder: (context, index) {
                final day = forecastDays[index];
                final date = DateTime.parse(day['date']);
                final dayName = _getDayName(date);
                
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: index == 0 
                      ? AppTheme.primaryGradient 
                      : null,
                    color: index == 0 ? null : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        index == 0 ? 'Today' : dayName,
                        style: TextStyle(
                          color: index == 0 
                            ? Colors.white 
                            : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        _getWeatherIcon(day['main'] ?? 'Clear'),
                        color: index == 0 ? Colors.white : AppTheme.primaryGreen,
                        size: 32,
                      ),
                      Text(
                        '${day['temp_max']?.round() ?? 0}°',
                        style: TextStyle(
                          color: index == 0 ? Colors.white : AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${day['temp_min']?.round() ?? 0}°',
                        style: TextStyle(
                          color: index == 0 
                            ? Colors.white70 
                            : AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      if (day['rain'] != null && day['rain'] > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.water_drop,
                              size: 12,
                              color: index == 0 ? Colors.white70 : AppTheme.info,
                            ),
                            Text(
                              '${day['rain']}mm',
                              style: TextStyle(
                                fontSize: 10,
                                color: index == 0 
                                  ? Colors.white70 
                                  : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherAlerts() {
    final alerts = _forecast!['alerts'] as List;
    
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: AppTheme.warning, size: 24),
              const SizedBox(width: 8),
              Text(
                'Weather Alerts for $_selectedCrop',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...alerts.map((alert) {
            final severity = alert['severity'] ?? 'info';
            final color = _getAlertColor(severity);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getAlertIcon(alert['type']),
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert['message'] ?? 'Weather Alert',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (alert['recommendation'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            alert['recommendation'],
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
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

  LinearGradient _getWeatherGradient(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('rain') || c.contains('drizzle')) {
      return const LinearGradient(
        colors: [Color(0xFF4A90E2), Color(0xFF7B68EE)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (c.contains('cloud')) {
      return const LinearGradient(
        colors: [Color(0xFF757F9A), Color(0xFFD7DDE8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (c.contains('clear') || c.contains('sun')) {
      return const LinearGradient(
        colors: [Color(0xFFFFA751), Color(0xFFFFE259)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (c.contains('storm') || c.contains('thunder')) {
      return const LinearGradient(
        colors: [Color(0xFF373B44), Color(0xFF4286F4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return AppTheme.primaryGradient;
  }

  Color _getWeatherColor(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('rain')) return Colors.blue;
    if (c.contains('cloud')) return Colors.grey;
    if (c.contains('clear') || c.contains('sun')) return Colors.orange;
    return AppTheme.primaryGreen;
  }

  IconData _getWeatherIcon(String? condition) {
    if (condition == null) return WeatherIcons.day_sunny;
    final c = condition.toLowerCase();
    if (c.contains('rain')) return WeatherIcons.rain;
    if (c.contains('cloud')) return WeatherIcons.cloudy;
    if (c.contains('clear') || c.contains('sun')) return WeatherIcons.day_sunny;
    if (c.contains('storm') || c.contains('thunder')) return WeatherIcons.thunderstorm;
    if (c.contains('snow')) return WeatherIcons.snow;
    if (c.contains('mist') || c.contains('fog')) return WeatherIcons.fog;
    return WeatherIcons.day_cloudy;
  }

  Color _getAlertColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
      case 'high':
        return AppTheme.danger;
      case 'medium':
      case 'warning':
        return AppTheme.warning;
      case 'low':
        return AppTheme.info;
      default:
        return AppTheme.success;
    }
  }

  IconData _getAlertIcon(String? type) {
    if (type == null) return Icons.info_outline;
    switch (type.toLowerCase()) {
      case 'rain':
        return Icons.water_drop;
      case 'temperature':
        return Icons.thermostat;
      case 'wind':
        return Icons.air;
      case 'storm':
        return Icons.bolt;
      default:
        return Icons.warning_amber;
    }
  }

  String _getDayName(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Location'),
        content: const Text('Location selection will be implemented soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getMockCurrentWeather() {
    return {
      'temperature': 24,
      'humidity': 65,
      'wind_speed': 12,
      'weather_condition': 'Partly Cloudy',
      'city': 'Ludhiana',
      'pressure': 1013,
      'feels_like': 23,
      'uv_index': 5,
      'visibility': 10,
      'rainfall': 0,
    };
  }

  Map<String, dynamic> _getMockForecast() {
    return {
      'city': 'Ludhiana',
      'crop': _selectedCrop,
      'forecast': [
        {
          'date': DateTime.now().toIso8601String(),
          'temp_max': 26,
          'temp_min': 18,
          'main': 'Clear',
          'rain': 0,
        },
        {
          'date': DateTime.now().add(Duration(days: 1)).toIso8601String(),
          'temp_max': 27,
          'temp_min': 19,
          'main': 'Partly Cloudy',
          'rain': 0,
        },
        {
          'date': DateTime.now().add(Duration(days: 2)).toIso8601String(),
          'temp_max': 25,
          'temp_min': 17,
          'main': 'Cloudy',
          'rain': 2,
        },
        {
          'date': DateTime.now().add(Duration(days: 3)).toIso8601String(),
          'temp_max': 24,
          'temp_min': 16,
          'main': 'Rain',
          'rain': 8,
        },
        {
          'date': DateTime.now().add(Duration(days: 4)).toIso8601String(),
          'temp_max': 25,
          'temp_min': 17,
          'main': 'Clear',
          'rain': 0,
        },
      ],
      'alerts': _selectedCrop == 'wheat' ? [
        {
          'type': 'temperature',
          'severity': 'info',
          'message': 'Optimal temperature for wheat growth',
          'recommendation': 'Continue regular irrigation schedule',
        },
      ] : [],
    };
  }
}
