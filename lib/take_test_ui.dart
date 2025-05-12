import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'get_ip.dart';

class TakeTestScreen extends StatefulWidget {
  final int testId;
  final int? groupId;
  final int? assignmentId;

  const TakeTestScreen({
    super.key, 
    required this.testId,
    this.groupId,
    this.assignmentId,
  });

  @override
  State<TakeTestScreen> createState() => _TakeTestScreenState();
}

class _TakeTestScreenState extends State<TakeTestScreen> {
  late UserInfo userInfo;
  String? serverIP;
  Map<String, dynamic>? testDetails;
  List<dynamic> questions = [];
  Map<int, String> userAnswers = {};
  bool isLoading = true;
  bool isSubmitted = false;

  @override
  void initState() {
    super.initState();
    userInfo = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    _initializeServerIP();
  }

  Future<void> _initializeServerIP() async {
    try {
      serverIP = await getUserIP();
      await _fetchTestDetails();
      await _fetchQuestions();
    } catch (e) {
      _showError('Connection error: $e');
    }
  }

  Future<void> _fetchTestDetails() async {
    try {
      final response = await http.get(Uri.parse(
          '$serverIP/get_test_details.php?id=${widget.testId}'));
          
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => testDetails = data['test']);
      }
    } catch (e) {
      _showError('Failed to load test details');
    }
  }

  Future<void> _fetchQuestions() async {
    try {
      final response = await http.get(Uri.parse(
          '$serverIP/get_questions.php?test_id=${widget.testId}'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Sort questions by their index before displaying
          List<dynamic> loadedQuestions = List<dynamic>.from(data['questions']);
          loadedQuestions.sort((a, b) => (a['index'] ?? 0).compareTo(b['index'] ?? 0));
          
          setState(() {
            questions = loadedQuestions;
            isLoading = false;
          });
        } else {
          _showError(data['message'] ?? 'Failed to load questions');
        }
      }
    } catch (e) {
      _showError('Failed to load questions: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3))
    );
  }

  Widget _buildQuestionCard(int index) {
    final question = questions[index];
    final questionNumber = question['index'] ?? index + 1;
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Question $questionNumber',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if ((question['ai_made'] ?? 0) == 1)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Tooltip(
                      message: 'AI Generated',
                      child: Text(
                        'AI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Make question content scrollable if too long
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(question['name'] ?? ''),
            ),
            if (question['description']?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    question['description'],
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 60, // Minimum height for answer field
              ),
              child: TextField(
                enabled: !isSubmitted,
                maxLines: null, // Allow multiple lines
                decoration: const InputDecoration(
                  labelText: 'Your answer',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => userAnswers[question['id']] = value,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitTest() async {
    setState(() => isSubmitted = true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          testDetails: testDetails!,
          questions: questions,
          userAnswers: userAnswers,
          groupId: widget.groupId,
          assignmentId: widget.assignmentId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          testDetails?['name'] ?? 'Loading Test...',
          style: TextStyle(color: Colors.deepPurple),
        ),
        iconTheme: IconThemeData(color: Colors.deepPurple),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (testDetails?['description']?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(testDetails!['description']),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: questions.length,
                    itemBuilder: (context, index) => _buildQuestionCard(index),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: isSubmitted ? null : _submitTest,
                    child: const Text('Complete Test'),
                  ),
                ),
              ],
            ),
    );
  }
}

class ReviewScreen extends StatefulWidget {
  final Map<String, dynamic> testDetails;
  final List<dynamic> questions;
  final Map<int, String> userAnswers;
  final int? groupId;
  final int? assignmentId;

  const ReviewScreen({
    super.key,
    required this.testDetails,
    required this.questions,
    required this.userAnswers,
    this.groupId,
    this.assignmentId, 
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  bool _isSharing = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _serverIP;

  @override
  void initState() {
    super.initState();
    _initializeServerIP().then((_) {
      if (widget.groupId != null) {
        _shareTestAutomatically();
      }
    });
  }

  Future<void> _initializeServerIP() async {
    _serverIP = await getUserIP();
  }

  Future<void> _shareTestAutomatically() async {
  if (_serverIP == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Server connection not available')),
    );
    return;
  }
  
  try {
    final userInfo = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    final response = await http.post(
      Uri.parse('$_serverIP/share_test.php'),
      body: jsonEncode({
        'title': '${userInfo.name}\'s answers',
        'description': '',
        'original_test_id': widget.testDetails['id'],
        'fk_user': userInfo.id,
        'fk_group': widget.groupId,
        'assignment_id': widget.assignmentId,
        'answers': widget.userAnswers.entries.map((e) => {
          'question_id': e.key,
          'answer': e.value,
        }).toList(),
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test results shared with group')),
        );
      } else {
        throw Exception(responseData['message'] ?? 'Failed to share test');
      }
    } else {
      throw Exception('Server returned status code ${response.statusCode}');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error sharing test: $e')),
    );
  }
}

  Future<void> _shareTest() async {
    if (!_isSharing) {
      setState(() => _isSharing = true);
      return;
    }

    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    try {
      final userInfo = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
      final response = await http.post(
        Uri.parse('$_serverIP/share_test.php'),
        body: jsonEncode({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'original_test_id': widget.testDetails['id'],
          'fk_user': userInfo.id,
          'answers': widget.userAnswers.entries.map((e) => {
            'question_id': e.key,
            'answer': e.value,
          }).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test shared successfully!')),
        );
        setState(() => _isSharing = false);
      } else {
        throw Exception(responseData['message'] ?? 'Failed to share test');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing test: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Review: ${widget.testDetails['name']}',
          style: TextStyle(color: Colors.deepPurple),
        ),
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          // Show share button only if not part of a group assignment
          if (widget.groupId == null) 
            IconButton(
              icon: const Icon(Icons.share, color: Colors.deepPurple),
              onPressed: _shareTest,
              tooltip: 'Share this test',
            ),
          // Always show done button
          IconButton(
            icon: const Icon(Icons.done, color: Colors.deepPurple),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
        ),
      body: Column(
        children: [
          if (_isSharing) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _shareTest,
                    child: const Text('Shared Test'),
                  ),
                ],
              ),
            ),
            const Divider(),
          ],
          Expanded(
            child: ListView.builder(
              itemCount: widget.questions.length,
              itemBuilder: (context, index) => _buildReviewQuestion(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewQuestion(int index) {
    final question = widget.questions[index];
    final questionNumber = question['index'] ?? index + 1;
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Question $questionNumber',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if ((question['ai_made'] ?? 0) == 1)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Tooltip(
                      message: 'AI Generated',
                      child: Text(
                        'AI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(question['name'] ?? ''),
            ),
            if (question['description']?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(question['description']),
                ),
              ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 60,
              ),
              child: TextField(
                enabled: false,
                maxLines: null,
                decoration: InputDecoration(
                  labelText: 'Your answer',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                controller: TextEditingController(
                  text: widget.userAnswers[question['id']] ?? 'No answer provided'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: Text(
                'Correct answer: ${question['answer'] ?? 'No answer provided'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}