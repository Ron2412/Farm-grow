import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

class PestDetectionScreen extends StatefulWidget {
  const PestDetectionScreen({Key? key}) : super(key: key);

  @override
  State<PestDetectionScreen> createState() => _PestDetectionScreenState();
}

class _PestDetectionScreenState extends State<PestDetectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _hasImage = false;
  bool _hasResult = false;
  String _selectedCrop = 'Wheat';
  Map<String, dynamic>? _detectionResult;

  final List<String> _crops = [
    'Wheat',
    'Rice',
    'Maize',
    'Cotton',
    'Sugarcane',
    'Potato',
    'Tomato',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _mockDetectPest() async {
    if (!_hasImage) return;

    setState(() {
      _isLoading = true;
      _hasResult = false;
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Mock API call with timeout handling
      final response = await http.post(
        Uri.parse('http://localhost:8000/pest/detect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'crop_type': _selectedCrop,
          'image_base64': 'mock_image_data',
        }),
      ).timeout(const Duration(seconds: 5), onTimeout: () {
        throw Exception('Connection timeout');
      });

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _detectionResult = result;
          _hasResult = true;
          _isLoading = false;
        });
      } else {
        // If server returns an error
        _showErrorSnackbar('Server error: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // Generate mock data if API fails
      _generateMockResult();
    }
  }

  void _generateMockResult() {
    final random = Random();
    final pestTypes = [
      'Aphids',
      'Whiteflies',
      'Stem Borer',
      'Leaf Spot',
      'Powdery Mildew',
      'Rust',
    ];
    
    final selectedPest = pestTypes[random.nextInt(pestTypes.length)];
    final confidence = (random.nextDouble() * 30 + 70).toStringAsFixed(1);
    
    final treatments = [
      'Apply neem oil solution (15ml per liter of water) for organic control',
      'Use recommended insecticide at proper dosage',
      'Remove and destroy infected plant parts',
      'Ensure proper spacing between plants for better air circulation',
      'Apply copper-based fungicide for control',
    ];
    
    final selectedTreatments = <String>[];
    final numTreatments = random.nextInt(3) + 1;
    for (int i = 0; i < numTreatments; i++) {
      final treatment = treatments[random.nextInt(treatments.length)];
      if (!selectedTreatments.contains(treatment)) {
        selectedTreatments.add(treatment);
      }
    }
    
    setState(() {
      _detectionResult = {
        'pest_name': selectedPest,
        'confidence': double.parse(confidence),
        'crop_type': _selectedCrop,
        'severity': random.nextInt(3) + 1,
        'treatments': selectedTreatments,
        'description': 'This pest commonly affects ${_selectedCrop.toLowerCase()} crops and can cause significant yield loss if not treated promptly.',
      };
      _hasResult = true;
      _isLoading = false;
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _pickImage() {
    // In a real app, this would use image_picker package
    setState(() {
      _hasImage = true;
      _hasResult = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 60,
          floating: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Pest Detection',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        
        // Main Content
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInstructions(),
                  const SizedBox(height: 20),
                  _buildCropSelector(),
                  const SizedBox(height: 20),
                  _buildImageUploadSection(),
                  const SizedBox(height: 20),
                  if (_hasResult) _buildResultSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  'How to use',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '1. Select your crop type',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '2. Take a clear photo of the affected plant part',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '3. Upload the image for analysis',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '4. Get pest identification and treatment recommendations',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Crop Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _crops.length,
            itemBuilder: (context, index) {
              final crop = _crops[index];
              final isSelected = crop == _selectedCrop;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(crop),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCrop = crop;
                      });
                    }
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primaryGreen : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Upload Image',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hasImage ? AppTheme.primaryGreen : Colors.grey,
                  width: 2,
                ),
              ),
              child: _hasImage
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        // This would be the actual image in a real app
                        Image.network(
                          'https://via.placeholder.com/400x300/EEFFEE/008800?text=Plant+Image',
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _hasImage = false;
                                _hasResult = false;
                              });
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    )
                  : InkWell(
                      onTap: _pickImage,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 64,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to upload an image',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _hasImage && !_isLoading ? _mockDetectPest : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Analyze Image',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    if (_detectionResult == null) return const SizedBox.shrink();
    
    final result = _detectionResult!;
    final pestName = result['pest_name'] as String;
    final confidence = result['confidence'] as double;
    final severity = result['severity'] as int;
    final description = result['description'] as String;
    final treatments = result['treatments'] as List<dynamic>;
    
    return SlideTransition(
      position: _slideAnimation,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bug_report, color: AppTheme.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Detection Result',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.danger,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Pest name and confidence
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Identified Pest:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Expanded(
                    child: Text(
                      pestName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Confidence bar
              Row(
                children: [
                  Text(
                    'Confidence:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: confidence / 100,
                        backgroundColor: Colors.grey[300],
                        color: _getConfidenceColor(confidence),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${confidence.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Severity
              Row(
                children: [
                  Text(
                    'Severity:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  ...List.generate(3, (index) {
                    return Icon(
                      Icons.circle,
                      size: 16,
                      color: index < severity
                          ? _getSeverityColor(severity)
                          : Colors.grey[300],
                    );
                  }),
                  const SizedBox(width: 8),
                  Text(
                    _getSeverityText(severity),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _getSeverityColor(severity),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Description
              Text(
                'Description:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              
              // Treatment recommendations
              Text(
                'Recommended Treatments:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...treatments.map<Widget>((treatment) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          treatment as String,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              
              const SizedBox(height: 16),
              
              // Expert consultation button
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to chatbot or expert consultation
                  Navigator.pushNamed(context, '/chatbot');
                },
                icon: const Icon(Icons.support_agent),
                label: const Text('Ask Expert for Advice'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  side: BorderSide(color: AppTheme.primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 85) return AppTheme.primaryGreen;
    if (confidence >= 70) return Colors.amber;
    return AppTheme.danger;
  }

  Color _getSeverityColor(int severity) {
    switch (severity) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.orange;
      case 3:
        return AppTheme.danger;
      default:
        return Colors.grey;
    }
  }

  String _getSeverityText(int severity) {
    switch (severity) {
      case 1:
        return 'Low';
      case 2:
        return 'Medium';
      case 3:
        return 'High';
      default:
        return 'Unknown';
    }
  }
}