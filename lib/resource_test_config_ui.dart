import 'package:flutter/material.dart';
import 'package:knowledgeswap/models/user_info.dart';
import 'package:knowledgeswap/resource_test_generator.dart';
import 'package:knowledgeswap/user_info_provider.dart';
import 'package:provider/provider.dart';

class ResourceTestConfigScreen extends StatefulWidget {
  final int resourceId;
  final String resourceName;
  final int userId;

  const ResourceTestConfigScreen({
    super.key,
    required this.resourceId,
    required this.resourceName,
    required this.userId,
  });

  @override
  State<ResourceTestConfigScreen> createState() => _ResourceTestConfigScreenState();
}

class _ResourceTestConfigScreenState extends State<ResourceTestConfigScreen> {
  final List<Map<String, TextEditingController>> _questions = [];
  final TextEditingController _replaceTopicsController = TextEditingController();
  final TextEditingController _replaceParamsController = TextEditingController();
  bool _isGenerating = false;
  final int _maxQuestions = 20;
  late UserInfo userInfo;

  @override
  void initState() {
    super.initState();
    userInfo = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    _initializeDefaultQuestions();
  }

  void _initializeDefaultQuestions() {
    _questions.clear();

    // Add 5 default questions with resource name as topic
    for (var i = 0; i < 5; i++) {
      _addQuestion(
        topic: widget.resourceName,
        parameters: _getDefaultParameters(i),
      );
    }
  }

  String _getDefaultParameters(int index) {
    switch (index % 5) {
      case 0: return 'Easy, multiple choice';
      case 1: return 'Hard, multiple choice';
      case 2: return 'Easy, true or false';
      case 3: return 'Easy, open-ended';
      case 4: return 'Easy, fill-in-the-blank';
      default: return 'Easy, multiple choice';
    }
  }

  void _addQuestion({String topic = '', String parameters = ''}) {
    if (_questions.length >= _maxQuestions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum of 20 questions reached')),
      );
      return;
    }

    setState(() {
      _questions.add({
        'topic': TextEditingController(text: topic.isNotEmpty ? topic : widget.resourceName),
        'parameters': TextEditingController(text: parameters),
      });
    });
  }

  void _cloneQuestion(int index) {
    if (_questions.length >= _maxQuestions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum of 20 questions reached')),
      );
      return;
    }

    final questionToClone = _questions[index];
    if (questionToClone['topic']!.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot clone a question with empty topic')),
      );
      return;
    }

    setState(() {
      _questions.insert(index + 1, {
        'topic': TextEditingController(text: questionToClone['topic']!.text),
        'parameters': TextEditingController(text: questionToClone['parameters']!.text),
      });
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions[index]['topic']!.dispose();
      _questions[index]['parameters']!.dispose();
      _questions.removeAt(index);
    });
  }

  void _replaceAllTopics() {
    final newTopic = _replaceTopicsController.text.trim();
    if (newTopic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter text to replace topics')),
      );
      return;
    }

    setState(() {
      for (var question in _questions) {
        question['topic']!.text = newTopic;
      }
    });
    _replaceTopicsController.clear();
    FocusScope.of(context).unfocus();
  }

  void _replaceAllParameters() {
    final newParams = _replaceParamsController.text.trim();
    // Parameters can be empty, so no validation here

    setState(() {
      for (var question in _questions) {
        question['parameters']!.text = newParams;
      }
    });
    _replaceParamsController.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _generateTest() async {
    if (_isGenerating) return;
    
    // Validate all topics (parameters can be empty)
    for (var i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      if (question['topic']!.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Question ${i + 1} has an empty topic')),
        );
        return;
      }
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final questions = _questions.map((q) => {
            'topic': q['topic']!.text.trim(),
            'parameters': q['parameters']!.text.trim(), // Can be empty
          }).toList();

      await ResourceTestGenerator.generateTest(
        context: context,
        resourceId: widget.resourceId,
        userId: widget.userId,
        resourceName: widget.resourceName,
        questions: questions,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (var question in _questions) {
      question['topic']!.dispose();
      question['parameters']!.dispose();
    }
    _replaceTopicsController.dispose();
    _replaceParamsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Generate Test for ${widget.resourceName}',
          style: const TextStyle(color: Colors.deepPurple),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Replace Topics Section
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replaceTopicsController,
                    decoration: InputDecoration(
                      labelText: 'Replace all topics with',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _replaceAllTopics,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Replace Parameters Section
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replaceParamsController,
                    decoration: InputDecoration(
                      labelText: 'Replace all parameters with',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _replaceAllParameters,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Question Counter
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_questions.length}/$_maxQuestions',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            
            // Questions List
            ..._questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Question ${index + 1}'),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.content_copy, size: 20),
                            onPressed: () => _cloneQuestion(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () => _removeQuestion(index),
                          ),
                        ],
                      ),
                      TextField(
                        controller: question['topic'],
                        decoration: InputDecoration(
                          labelText: 'Topic*',
                          hintText: 'e.g. ${widget.resourceName}',
                          border: const OutlineInputBorder(),
                          errorText: question['topic']!.text.trim().isEmpty ? 'Required' : null,
                        ),
                        onChanged: (value) {
                          setState(() {}); // Trigger rebuild to show/hide error
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: question['parameters'],
                        decoration: const InputDecoration(
                          labelText: 'Parameters (optional)',
                          hintText: 'e.g. easy multiple choice about verbs',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            
            // Action Buttons
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _addQuestion(
                    topic: widget.resourceName,
                    parameters: '', // Empty parameters by default
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                    side: const BorderSide(color: Colors.deepPurple),
                  ),
                  child: const Text('Add Question'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _generateTest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: _isGenerating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Generate Test'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}