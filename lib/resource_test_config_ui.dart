import 'package:flutter/material.dart';
import 'package:knowledgeswap/resource_test_generator.dart';

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
  bool _isGenerating = false;
  final int _maxQuestions = 20;

  @override
  void initState() {
    super.initState();
    _initializeDefaultQuestions();
  }

  void _initializeDefaultQuestions() {
    _questions.clear();
    // Add 5 default questions
    for (var i = 0; i < 5; i++) {
      _addQuestion(
        topic: 'Grammar',
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
        SnackBar(content: Text('Maximum of $_maxQuestions questions reached')),
      );
      return;
    }

    setState(() {
      _questions.add({
        'topic': TextEditingController(text: topic),
        'parameters': TextEditingController(text: parameters),
      });
    });
  }

  void _cloneQuestion(int index) {
    if (_questions.length >= _maxQuestions) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum of $_maxQuestions questions reached')),
      );
      return;
    }

    setState(() {
      final questionToClone = _questions[index];
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

  Future<void> _generateTest() async {
    if (_isGenerating) return;
    
    setState(() {
      _isGenerating = true;
    });

    try {
      final questions = _questions
          .where((q) => q['topic']!.text.isNotEmpty && q['parameters']!.text.isNotEmpty)
          .map((q) => {
                'topic': q['topic']!.text,
                'parameters': q['parameters']!.text,
              })
          .toList();

      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one valid question')),
        );
        return;
      }

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Generate Test for ${widget.resourceName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Questions: ${_questions.length}/$_maxQuestions',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
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
                        decoration: const InputDecoration(
                          labelText: 'Topic',
                          hintText: 'e.g. Grammar, Vocabulary',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: question['parameters'],
                        decoration: const InputDecoration(
                          labelText: 'Parameters',
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
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _addQuestion(
                    topic: 'Grammar',
                    parameters: 'multiple choice',
                  ),
                  child: const Text('Add Question'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _generateTest,
                  child: _isGenerating
                      ? const CircularProgressIndicator()
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