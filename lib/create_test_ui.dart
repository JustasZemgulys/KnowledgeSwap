import 'package:flutter/material.dart';
import 'package:knowledgeswap/profile_details_ui.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'get_ip.dart';
import 'package:file_picker/file_picker.dart';

class CreateTestScreen extends StatefulWidget {
  final Map<String, dynamic>? initialTestData;

  const CreateTestScreen({super.key, this.initialTestData});

  @override
  State<CreateTestScreen> createState() => _CreateTestScreenState();
}


class _CreateTestScreenState extends State<CreateTestScreen> {
  late UserInfo user_info;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _parametersController = TextEditingController();
  //final TextEditingController _amountController = TextEditingController();
  int _titleCharCount = 0;
  int _descriptionCharCount = 0;
  final int _maxTitleLength = 255;
  final int _maxDescriptionLength = 255;
  List<String> _questions = [];
  PlatformFile? _selectedFile;

  // List to hold the question forms
  List<_QuestionFormData> _questionFormData = [];

  @override
  void initState() {
    super.initState();
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    _titleController.addListener(_updateTitleCharCount);
    _descriptionController.addListener(_updateDescriptionCharCount);

    // Load existing test data if editing
    if (widget.initialTestData != null) {
      _titleController.text = widget.initialTestData!['name'] ?? '';
      _descriptionController.text = widget.initialTestData!['description'] ?? '';
      _loadExistingQuestions();
    }
  }

  Future<void> _loadExistingQuestions() async {
    if (widget.initialTestData == null) return;

    try {
      final userIP = await getUserIP();
      final url = 'http://$userIP/get_questions.php?test_id=${widget.initialTestData!['id']}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> questions = responseData['questions'] ?? [];
          
          // Sort questions by their index before creating form data
          questions.sort((a, b) => (a['index'] ?? 0).compareTo(b['index'] ?? 0));
          
          setState(() {
            _questionFormData = questions.map((q) {
              return _QuestionFormData(index: q['index'] ?? (_questionFormData.length + 1))
                ..questionId = q['id']
                ..questionTitleController.text = q['name'] ?? ''
                ..questionDescriptionController.text = q['description'] ?? ''
                ..questionAnswerController.text = q['answer'] ?? '';
            }).toList();
          });
        }
      }
    } catch (e) {
      print('Error loading questions: $e');
    }
  }

  Future<void> _fetchQuestionsFromAI() async {
    final String topic = _topicController.text;
    final String parameters = _parametersController.text;

    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a topic")),
      );
      return;
    }

    String userIP = await getUserIP();
    final String url = 'http://$userIP/ai_create_question.php';

    bool retry = false;

    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        var responseData = await _sendRequest(url, topic, parameters);

        if (responseData != null) {
          bool success = _processResponse(responseData);
          if (success) return; // Exit if successful
          retry = true; // Retry if unsuccessful
        } else {
          retry = true; // Retry if response is null
        }
      } catch (e) {
        print('Error: $e');
        retry = true; // Retry if an exception occurs
      }

      if (!retry) break; // Exit the loop if no retry is needed
    }

    // Show an error message if all attempts fail
    if (retry) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong. Please try again.")),
      );
    }
  }

  /// Sends a request to the server and returns the response data.
  Future<Map<String, dynamic>?> _sendRequest(String url, String topic, String parameters) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Add text fields
      request.fields['topic'] = topic;
      request.fields['parameters'] = parameters;

      // Add file if selected
      if (_selectedFile != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _selectedFile!.bytes!,
            filename: _selectedFile!.name,
          ),
        );
      }

      var response = await request.send();

      // Log status code and headers
      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        print('Raw Response: $responseData'); // Log the raw response
        return json.decode(responseData);
      } else {
        print('Server Response: ${response.statusCode}');
        var responseData = await response.stream.bytesToString();
        print('Body: $responseData');
        return null;
      }
    } catch (e, stackTrace) {
      print("Error in _sendRequest: $e");
      print("Stack Trace: $stackTrace");
      return null;
    }
  }

  /// Processes the response and creates a question form if successful.
  bool _processResponse(Map<String, dynamic> responseData) {
    if (responseData['success'] == true) {
      String content = responseData['full_response']['choices'][0]['message']['content'];

      // Extract question, options, and answer
      String question = _extractQuestion(content);
      String options = _extractOptions(content);
      String answer = _extractAnswer(content);

      // Validate extracted data
      if (question.isEmpty || answer.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to generate valid question - missing title or answer")),
        );
        return false;
      }

      // Create a new question form with the extracted data
      setState(() {
        _questionFormData.add(_QuestionFormData(index: _questionFormData.length + 1)
          ..questionTitleController.text = question
          ..questionDescriptionController.text = options
          ..questionAnswerController.text = answer);
      });
      return true;
    }
    return false;
  }

  /// Extracts the question from the response content.
  String _extractQuestion(String content) {
    RegExp questionRegex = RegExp(r'Question:\s*(.+)');
    if (questionRegex.hasMatch(content)) {
      return questionRegex.firstMatch(content)!.group(1)!.trim();
    }
    return '';
  }

  /// Extracts the options from the response content.
  String _extractOptions(String content) {
    RegExp optionsRegex = RegExp(r'Options:\s*([\s\S]+?)Answer:');
    if (optionsRegex.hasMatch(content)) {
      return optionsRegex.firstMatch(content)!.group(1)!.trim();
    }
    return '';
  }

  /// Extracts the answer from the response content.
  String _extractAnswer(String content) {
    RegExp answerRegex = RegExp(r'Answer:\s*(.+)');
    if (answerRegex.hasMatch(content)) {
      return answerRegex.firstMatch(content)!.group(1)!.trim();
    }
    return '';
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateTitleCharCount() {
    setState(() {
      _titleCharCount = _titleController.text.length;
    });
  }

  void _updateDescriptionCharCount() {
    setState(() {
      _descriptionCharCount = _descriptionController.text.length;
    });
  }

  void _addQuestionForm() {
    setState(() {
      _questionFormData.add(_QuestionFormData(index: _questionFormData.length + 1));
    });
  }

  void _removeQuestionForm(int index) {
    setState(() {
      _questionFormData.removeAt(index);
      _updateQuestionIndexes(); // Update indexes
    });
  }

  void _moveQuestionUp(int index) {
  if (index > 0) {
    setState(() {
      final question = _questionFormData.removeAt(index);
      _questionFormData.insert(index - 1, question);
      _updateQuestionIndexes();
    });
  }
}

void _moveQuestionDown(int index) {
  if (index < _questionFormData.length - 1) {
    setState(() {
      final question = _questionFormData.removeAt(index);
      _questionFormData.insert(index + 1, question);
      _updateQuestionIndexes();
    });
  }
}

void _updateQuestionIndexes() {
  for (int i = 0; i < _questionFormData.length; i++) {
    _questionFormData[i].index = i + 1; // Update to 1-based index
  }
}

void _saveTest() async {
  // Validate test name
  if (_titleController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please enter a test title")),
    );
    return;
  }

  // Validate at least one question
  if (_questionFormData.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please add at least one question")),
    );
    return;
  }

  // Validate each question has title and answer
  for (int i = 0; i < _questionFormData.length; i++) {
    final question = _questionFormData[i];
    if (question.questionTitleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Question ${i + 1} is missing a title")),
      );
      return;
    }
    if (question.questionAnswerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Question ${i + 1} is missing an answer")),
      );
      return;
    }
  }

  // Get user info
  final userInfoProvider = Provider.of<UserInfoProvider>(context, listen: false);
  final userInfo = userInfoProvider.userInfo;

  if (userInfo == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("User not logged in")),
    );
    return;
  }

  // Prepare test data
  final testData = {
    'name': _titleController.text,
    'description': _descriptionController.text,
    'questions': _questionFormData.map((question) => {
      'title': question.questionTitleController.text,
      'description': question.questionDescriptionController.text,
      'answer': question.questionAnswerController.text,
      'index': question.index,
      'id': question.questionId, // Include question ID if editing
    }).toList(),
    'userId': userInfo.id,
  };

  // If editing, include test ID
  if (widget.initialTestData != null) {
    testData['testId'] = widget.initialTestData!['id'];
  }

  // Send data to the server
  final userIP = await getUserIP();
  final url = widget.initialTestData != null 
      ? 'http://$userIP/update_test.php'
      : 'http://$userIP/save_test.php';

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(testData),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.initialTestData != null 
              ? "Test updated successfully" 
              : "Test saved successfully")),
        );
        Navigator.pop(context, true);
      } else {
        print('Operation failed: $responseData');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? "Operation failed")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save test. Status code: ${response.statusCode}")),
      );
    }
  } catch (e) {
    print('Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialTestData != null ? "Edit Test" : "Test Creation"),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          const SizedBox(width: 1),
          IconButton(
            icon: Image.asset("assets/usericon.jpg"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ProfileDetailsScreen()),
              );
            },
          ),
        ],
        elevation: 0,
        backgroundColor: const Color(0x00000000),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              maxLength: _maxTitleLength,
              decoration: InputDecoration(
                labelText: "Test Title",
                hintText: "Enter the test title here",
                border: const OutlineInputBorder(),
                counterText: "$_titleCharCount/$_maxTitleLength",
                counterStyle: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              maxLength: _maxDescriptionLength,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: "Test Description",
                hintText: "Enter the test description here",
                border: const OutlineInputBorder(),
                counterText: "$_descriptionCharCount/$_maxDescriptionLength",
                counterStyle: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addQuestionForm,
              child: const Text("Create Question"),
            ),
            const SizedBox(height: 20),
            // Display the question forms here
            Column(
              children: [
                for (int i = 0; i < _questionFormData.length; i++)
                  _QuestionForm(
                      key: ObjectKey(_questionFormData[i]),
                      questionFormData: _questionFormData[i],
                      onRemove: () => _removeQuestionForm(i),
                      onMoveUp: () => _moveQuestionUp(i),
                      onMoveDown: () => _moveQuestionDown(i)),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                labelText: "Topic",
                hintText: "Enter topic for quiz questions",
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _parametersController,
              decoration: InputDecoration(
                labelText: "Parameters",
                hintText: "Enter parameters for the question (e.g., 'multiple choice, difficulty: hard')",
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text("Upload PDF/JPG"),
            ),
            const SizedBox(height: 20),
            if (_selectedFile != null)
              Text("Selected File: ${_selectedFile!.name}"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchQuestionsFromAI,
              child: const Text("Generate Questions"),
            ),
            const SizedBox(height: 20),
            // Display fetched questions
            if (_questions.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < _questions.length; i++)
                    Text("${i + 1}. ${_questions[i]}"),
                ],
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveTest,
              child: const Text("Save Test"),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionFormData {
  TextEditingController questionTitleController = TextEditingController();
  TextEditingController questionDescriptionController = TextEditingController();
  TextEditingController questionAnswerController = TextEditingController();
  int questionTitleCharCount = 0;
  int questionDescriptionCharCount = 0;
  int questionAnswerCharCount = 0;
  final int maxQuestionTitleLength = 255;
  final int maxQuestionDescriptionLength = 255;
  final int maxQuestionAnswerLength = 255;
  int index; // This will track the question order
  int? questionId; // Add this to track existing question IDs

  _QuestionFormData({required this.index, this.questionId}) {
    questionTitleController.addListener(() {
      questionTitleCharCount = questionTitleController.text.length;
    });
    questionDescriptionController.addListener(() {
      questionDescriptionCharCount = questionDescriptionController.text.length;
    });
    questionAnswerController.addListener(() {
      questionAnswerCharCount = questionAnswerController.text.length;
    });
  }
}

class _QuestionForm extends StatefulWidget {
  final VoidCallback onRemove;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final _QuestionFormData questionFormData;

  const _QuestionForm({
    required this.questionFormData,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
    Key? key,
  }) : super(key: key);

  @override
  State<_QuestionForm> createState() => _QuestionFormState();
}

class _QuestionFormState extends State<_QuestionForm> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final question = widget.questionFormData;
    final hasTitleError = question.questionTitleController.text.isEmpty;
    final hasAnswerError = question.questionAnswerController.text.isEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
          color: (hasTitleError || hasAnswerError) ? Colors.red : Colors.grey,
          width: (hasTitleError || hasAnswerError) ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          // Header row with question number and action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Show number only when expanded, number + title when compressed
              _isExpanded
                  ? Text("Question ${question.index}")
                  : Expanded(
                      child: Row(
                        children: [
                          Text("Question ${question.index}: "),
                          Expanded(
                            child: Text(
                              question.questionTitleController.text.isEmpty
                                  ? "Untitled question"
                                  : question.questionTitleController.text,
                              style: TextStyle(
                                fontStyle: question.questionTitleController.text.isEmpty
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: widget.onMoveUp,
                    tooltip: 'Move up',
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward),
                    onPressed: widget.onMoveDown,
                    tooltip: 'Move down',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: widget.onRemove,
                    tooltip: 'Delete question',
                  ),
                  IconButton(
                    icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    tooltip: _isExpanded ? 'Collapse question' : 'Expand question',
                  ),
                ],
              ),
            ],
          ),
          // The question content that can be collapsed
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _isExpanded
                ? Column(
                    children: [
                      const SizedBox(height: 10),
                      TextField(
                        controller: question.questionTitleController,
                        maxLength: question.maxQuestionTitleLength,
                        decoration: InputDecoration(
                          labelText: "Question Title*",
                          hintText: "Enter the question title here",
                          border: const OutlineInputBorder(),
                          errorText: hasTitleError ? "Title is required" : null,
                          counterText:
                              "${question.questionTitleCharCount}/${question.maxQuestionTitleLength}",
                          counterStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: question.questionDescriptionController,
                        maxLength: question.maxQuestionDescriptionLength,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: "Question Description",
                          hintText: "Enter the question description here",
                          border: const OutlineInputBorder(),
                          counterText:
                              "${question.questionDescriptionCharCount}/${question.maxQuestionDescriptionLength}",
                          counterStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: question.questionAnswerController,
                        maxLength: question.maxQuestionAnswerLength,
                        decoration: InputDecoration(
                          labelText: "Answer*",
                          hintText: "Enter the answer here",
                          border: const OutlineInputBorder(),
                          errorText: hasAnswerError ? "Answer is required" : null,
                          counterText:
                              "${question.questionAnswerCharCount}/${question.maxQuestionAnswerLength}",
                          counterStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(), // No extra content when compressed
          ),
        ],
      ),
    );
  }
}