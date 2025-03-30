import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'get_ip.dart';

class TakeTestScreen extends StatefulWidget {
  final int testId;

  const TakeTestScreen({super.key, required this.testId});

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
          'http://$serverIP/get_test_details.php?id=${widget.testId}'));
          
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
          'http://$serverIP/get_questions.php?test_id=${widget.testId}'));
      
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
              ],
            ),
            const SizedBox(height: 8),
            Text(question['name'] ?? ''),
            if (question['description']?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  question['description'],
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              enabled: !isSubmitted,
              decoration: const InputDecoration(
                labelText: 'Your answer',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => userAnswers[question['id']] = value,
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(testDetails?['name'] ?? 'Loading Test...'),
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

class ReviewScreen extends StatelessWidget {
  final Map<String, dynamic> testDetails;
  final List<dynamic> questions;
  final Map<int, String> userAnswers;

  const ReviewScreen({
    super.key,
    required this.testDetails,
    required this.questions,
    required this.userAnswers,
  });

  Widget _buildReviewQuestion(int index) {
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(question['name'] ?? ''),
            if (question['description']?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(question['description']),
              ),
            const SizedBox(height: 12),
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Your answer',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              controller: TextEditingController(
                text: userAnswers[question['id']] ?? 'No answer provided'),
            ),
            const SizedBox(height: 8),
            Text(
              'Correct answer: ${question['answer'] ?? 'No answer provided'}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review: ${testDetails['name']}'),
      ),
      body: ListView.builder(
        itemCount: questions.length,
        itemBuilder: (context, index) => _buildReviewQuestion(index),
      ),
    );
  }
}