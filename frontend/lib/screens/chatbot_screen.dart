import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  // Suggested queries for quick access
  final List<String> _suggestions = [
    'What crops should I plant this season?',
    'How\'s the weather forecast for this week?',
    'How do I identify and treat common crop diseases?',
    'What fertilizers are best for my soil type?',
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

    _animationController.forward();
    
    // Add welcome message
    _addBotMessage(
      'Hello! I\'m your AgroSmart assistant. How can I help you today?',
      suggestions: _suggestions,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSubmit(String text) {
    if (text.trim().isEmpty) return;
    
    _messageController.clear();
    
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
      ));
      _isTyping = true;
    });
    
    _scrollToBottom();
    _mockSendMessage(text);
  }

  Future<void> _mockSendMessage(String message) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    try {
      // Mock API call
      final response = await http.post(
        Uri.parse('http://localhost:8000/chatbot/query'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        setState(() {
          _isTyping = false;
          _addBotMessage(
            result['response'],
            suggestions: List<String>.from(result['suggestions']),
            followUpQuestions: List<String>.from(result['follow_up_questions']),
          );
        });
      } else {
        // If server returns an error
        _showErrorSnackbar('Server error: ${response.statusCode}');
        _generateMockResponse(message);
      }
    } catch (e) {
      // Generate mock data if API fails
      _generateMockResponse(message);
    }
  }

  void _generateMockResponse(String message) {
    final random = Random();
    
    // Categories of responses
    final Map<String, List<String>> responses = {
      'weather': [
        'Based on the current forecast, expect clear skies with temperatures around 25°C. This is good weather for field work.',
        'The weather forecast shows a chance of rain in the next 48 hours. Consider completing any harvesting activities today.',
        'Temperatures are expected to rise to 32°C this week. Ensure your crops have adequate irrigation.'
      ],
      'crop': [
        'For your soil type and current season, I recommend planting wheat, rice, or maize. Would you like specific details about any of these crops?',
        'Based on your region, rice cultivation would be optimal now. The ideal sowing time is approaching.',
        'Your soil appears suitable for multiple crops. Consider crop rotation with legumes to improve soil nitrogen content.'
      ],
      'pest': [
        'To identify pests or diseases, please use the image detector feature. You can upload a photo of the affected plant for analysis.',
        'Common pests this season include aphids and whiteflies. Monitor your crops regularly and consider preventive measures.',
        'For organic pest control, neem oil solution (15ml per liter of water) is effective against many common pests.'
      ],
      'general': [
        'I\'m here to help with any farming questions. Feel free to ask about crops, weather, pests, or market prices.',
        'For more detailed assistance, try providing specific information about your farm location, crop type, and current growth stage.',
        'Consider joining the local farmer producer organization for collective bargaining and knowledge sharing.'
      ]
    };
    
    // Determine category based on keywords
    String category = 'general';
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('weather') || 
        lowerMessage.contains('rain') || 
        lowerMessage.contains('forecast')) {
      category = 'weather';
    } else if (lowerMessage.contains('crop') || 
               lowerMessage.contains('plant') || 
               lowerMessage.contains('grow')) {
      category = 'crop';
    } else if (lowerMessage.contains('pest') || 
               lowerMessage.contains('disease') || 
               lowerMessage.contains('insect')) {
      category = 'pest';
    }
    
    // Get a random response from the appropriate category
    final responseList = responses[category]!;
    final response = responseList[random.nextInt(responseList.length)];
    
    // Generate suggestions based on category
    List<String> suggestions = [];
    if (category == 'weather') {
      suggestions = ['Show me weather forecast', 'Weather alerts for my crops'];
    } else if (category == 'crop') {
      suggestions = ['Best crops for this season', 'How to increase yield'];
    } else if (category == 'pest') {
      suggestions = ['Identify pest in my crop', 'Organic pest control methods'];
    } else {
      suggestions = ['Crop recommendations', 'Weather forecast', 'Pest control advice'];
    }
    
    // Generate follow-up questions
    List<String> followUpQuestions = [];
    if (category == 'weather') {
      followUpQuestions = ['Would you like to see the 7-day forecast?', 'Do you need crop-specific weather advice?'];
    } else if (category == 'crop') {
      followUpQuestions = ['Would you like detailed cultivation practices?', 'Do you need information about seed varieties?'];
    } else if (category == 'pest') {
      followUpQuestions = ['Would you like to know about preventive measures?', 'Do you need organic alternatives for pest control?'];
    } else {
      followUpQuestions = ['Would you like information about government schemes for farmers?', 'Are you interested in learning about sustainable farming practices?'];
    }
    
    setState(() {
      _isTyping = false;
      _addBotMessage(
        response,
        suggestions: suggestions,
        followUpQuestions: followUpQuestions,
      );
    });
  }

  void _addBotMessage(String text, {List<String>? suggestions, List<String>? followUpQuestions}) {
    _messages.add(ChatMessage(
      text: text,
      isUser: false,
      suggestions: suggestions,
      followUpQuestions: followUpQuestions,
    ));
    _scrollToBottom();
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgroSmart Assistant'),
        backgroundColor: AppTheme.primaryGreen,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showInfoDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessage(_messages[index]);
                  },
                ),
              ),
            ),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) _buildAvatar(),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isUser ? AppTheme.primaryGreen : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                if (!message.isUser && message.followUpQuestions != null && message.followUpQuestions!.isNotEmpty)
                  _buildFollowUpQuestions(message.followUpQuestions!),
                if (!message.isUser && message.suggestions != null && message.suggestions!.isNotEmpty)
                  _buildSuggestions(message.suggestions!),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (message.isUser) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Icon(
          Icons.smart_toy_outlined,
          size: 20,
          color: AppTheme.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          size: 20,
          color: AppTheme.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildFollowUpQuestions(List<String> questions) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Follow-up questions:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: questions.map((question) {
              return InkWell(
                onTap: () {
                  _handleSubmit(question);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.5)),
                  ),
                  child: Text(
                    question,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(List<String> suggestions) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggestions:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((suggestion) {
              return InkWell(
                onTap: () {
                  _handleSubmit(suggestion);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 16),
          _buildAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _buildDot(0),
                _buildDot(1),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(4),
      ),
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(milliseconds: 300 + (index * 200)),
        builder: (context, double value, child) {
          return Opacity(
            opacity: value,
            child: child,
          );
        },
        child: Container(),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.photo_camera),
            color: Colors.grey[600],
            onPressed: () {
              Navigator.pushNamed(context, '/pest-detection');
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: _handleSubmit,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send),
              color: Colors.white,
              onPressed: () => _handleSubmit(_messageController.text),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            const Text('About AgroSmart Assistant'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This AI assistant can help you with:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildInfoItem('Weather forecasts and alerts'),
            _buildInfoItem('Crop recommendations and cultivation advice'),
            _buildInfoItem('Pest and disease identification'),
            _buildInfoItem('Market prices and trends'),
            _buildInfoItem('Fertilizer and irrigation guidance'),
            const SizedBox(height: 16),
            Text(
              'For pest identification with images, use the camera button to access the Pest Detection feature.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final List<String>? suggestions;
  final List<String>? followUpQuestions;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.suggestions,
    this.followUpQuestions,
  });
}