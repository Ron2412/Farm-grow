import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../api/api_client.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Try to fetch from API with sample data for Ludhiana region
      // In a real app, you'd get region and soil data from user preferences
      Map<String, dynamic>? alertsData;
      
      // Option 1: Try API call (uncomment when backend is ready)
      // try {
      //   final requestBody = {
      //     'region': 'ludhiana',
      //     'soil_data': {
      //       'pH': 6.5,
      //       'nitrogen': 280,
      //       'phosphorus': 40,
      //       'potassium': 150,
      //       'organic_carbon': 0.75,
      //       'moisture': 45
      //     }
      //   };
      //   alertsData = await ApiClient.post('/alerts/soil-weather', body: requestBody);
      // } catch (apiError) {
      //   debugPrint('API call failed, using mock data: $apiError');
      //   alertsData = null;
      // }
      
      // Option 2: Use mock data for now (remove when API is ready)
      alertsData = _getMockAlertData();
      
      // Transform the data to a list of alerts
      final alerts = <Map<String, dynamic>>[];
      
      if (alertsData != null) {
        // Add weather alerts
        if (alertsData['weather_alerts'] != null) {
          for (var alert in alertsData['weather_alerts']) {
            alerts.add({
              'type': 'weather',
              'title': alert['title'] ?? 'Weather Alert',
              'description': alert['description'] ?? '',
              'severity': alert['severity'] ?? 'medium',
              'timestamp': DateTime.now().subtract(Duration(hours: alert['hours_ago'] ?? 1)),
              'icon': _getWeatherIcon(alert['title'] ?? ''),
            });
          }
        }

        // Add soil alerts
        if (alertsData['soil_alerts'] != null) {
          for (var alert in alertsData['soil_alerts']) {
            alerts.add({
              'type': 'soil',
              'title': alert['title'] ?? 'Soil Alert',
              'description': alert['description'] ?? '',
              'severity': alert['severity'] ?? 'low',
              'timestamp': DateTime.now().subtract(Duration(days: alert['days_ago'] ?? 1)),
              'icon': Icons.grass,
            });
          }
        }
      }

      // Add some default alerts if none exist
      if (alerts.isEmpty) {
        alerts.addAll(_getDefaultAlerts());
      }

      // Sort alerts by timestamp (newest first)
      alerts.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      // If any error occurs, show default alerts
      setState(() {
        _alerts = _getDefaultAlerts();
        _isLoading = false;
      });
      debugPrint("Error fetching alerts: $e");
    }
  }
  
  // Mock data for testing
  Map<String, dynamic> _getMockAlertData() {
    // Use a Set to track unique alert titles and prevent duplicates
    final Set<String> uniqueAlertTitles = {};
    
    // Create initial alerts list
    final weatherAlerts = [
      {
        'title': 'Heavy Rainfall Expected',
        'description': 'Heavy rainfall expected in next 24 hours. Protect your crops and ensure proper drainage.',
        'severity': 'high',
        'hours_ago': 2,
      },
      {
        'title': 'Temperature Drop',
        'description': 'Temperature expected to drop below 10°C tonight. Take precautions for sensitive crops.',
        'severity': 'medium',
        'hours_ago': 24,
      },
    ];
    
    // Filter out any duplicate weather alerts
    final uniqueWeatherAlerts = weatherAlerts.where((alert) {
      final title = alert['title'] as String;
      if (uniqueAlertTitles.contains(title)) {
        return false;
      }
      uniqueAlertTitles.add(title);
      return true;
    }).toList();
    
    // Add soil alerts, also checking for duplicates
    final soilAlerts = [
      {
        'title': 'Soil Moisture Alert',
        'description': 'Soil moisture levels are optimal for sowing. Consider planting wheat or mustard.',
        'severity': 'info',
        'days_ago': 0,
      },
    ].where((alert) {
      final title = alert['title'] as String;
      if (uniqueAlertTitles.contains(title)) {
        return false;
      }
      uniqueAlertTitles.add(title);
      return true;
    }).toList();
    
    return {
      'weather_alerts': uniqueWeatherAlerts,
      'soil_alerts': soilAlerts,
    };
  }
  
  // Get appropriate weather icon based on alert title
  IconData _getWeatherIcon(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('rain')) {
      return Icons.water_drop;
    } else if (lowerTitle.contains('temperature') || lowerTitle.contains('cold')) {
      return Icons.ac_unit;
    } else if (lowerTitle.contains('sun') || lowerTitle.contains('clear')) {
      return Icons.wb_sunny;
    } else if (lowerTitle.contains('wind')) {
      return Icons.air;
    } else if (lowerTitle.contains('storm')) {
      return Icons.thunderstorm;
    } else {
      return Icons.wb_cloudy;
    }
  }
  
  // Default alerts when API is not available
  List<Map<String, dynamic>> _getDefaultAlerts() {
    return [
      {
        'type': 'weather',
        'title': 'Weather Update',
        'description': 'Clear skies expected for next 3 days. Good time for harvesting.',
        'severity': 'info',
        'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
        'icon': Icons.wb_sunny,
      },
      {
        'type': 'soil',
        'title': 'Fertilizer Reminder',
        'description': 'Time to apply second dose of fertilizer for your wheat crop.',
        'severity': 'medium',
        'timestamp': DateTime.now().subtract(const Duration(hours: 3)),
        'icon': Icons.eco,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🔔 Alerts & Notifications"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAlerts,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchAlerts,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (_alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No alerts at this time",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              "You'll be notified of important updates",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _alerts.length,
      itemBuilder: (context, index) {
        final alert = _alerts[index];
        return _buildAlertCard(alert);
      },
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final color = _getSeverityColor(alert['severity']);
    final icon = _getAlertIcon(alert);
    final timeAgo = _getTimeAgo(alert['timestamp']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => _showAlertDetails(alert),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert['title'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildSeverityChip(alert['severity']),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                alert['description'],
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityChip(String severity) {
    final color = _getSeverityColor(severity);
    final label = severity.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'critical':
        return Colors.red;
      case 'medium':
      case 'warning':
        return Colors.orange;
      case 'low':
        return Colors.yellow[700]!;
      case 'info':
      default:
        return Colors.blue;
    }
  }

  IconData _getAlertIcon(Map<String, dynamic> alert) {
    if (alert['icon'] != null) return alert['icon'];
    
    switch (alert['type']) {
      case 'weather':
        return Icons.cloud_queue;
      case 'soil':
        return Icons.grass;
      default:
        return Icons.notification_important;
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  void _showAlertDetails(Map<String, dynamic> alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final color = _getSeverityColor(alert['severity']);
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getAlertIcon(alert), color: color, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert['title'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getTimeAgo(alert['timestamp']),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSeverityChip(alert['severity']),
                  const SizedBox(height: 20),
                  const Text(
                    "Details",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alert['description'],
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Recommended Actions",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildActionsList(alert),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Got it"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionsList(Map<String, dynamic> alert) {
    List<String> actions = [];
    
    if (alert['type'] == 'weather') {
      if (alert['title'].toLowerCase().contains('rain')) {
        actions = [
          'Ensure proper drainage in fields',
          'Protect harvested crops from moisture',
          'Postpone fertilizer application',
          'Check for pest activity after rain',
        ];
      } else if (alert['title'].toLowerCase().contains('temperature')) {
        actions = [
          'Cover sensitive crops',
          'Adjust irrigation schedule',
          'Monitor crop health closely',
        ];
      } else {
        actions = [
          'Monitor weather updates regularly',
          'Plan field activities accordingly',
        ];
      }
    } else if (alert['type'] == 'soil') {
      actions = [
        'Test soil pH and nutrients',
        'Apply recommended fertilizers',
        'Maintain optimal soil moisture',
        'Consider crop rotation',
      ];
    }

    return Column(
      children: actions.map((action) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  action,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Filter Alerts"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text("Weather Alerts"),
                value: true,
                onChanged: (value) {},
              ),
              CheckboxListTile(
                title: const Text("Soil Alerts"),
                value: true,
                onChanged: (value) {},
              ),
              CheckboxListTile(
                title: const Text("Market Alerts"),
                value: false,
                onChanged: (value) {},
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _fetchAlerts();
              },
              child: const Text("Apply"),
            ),
          ],
        );
      },
    );
  }
}