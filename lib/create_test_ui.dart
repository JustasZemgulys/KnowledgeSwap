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
  const CreateTestScreen({super.key});

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
  }

  Future<void> _fetchQuestionsFromAI() async {
    final String topic = _topicController.text;
    //final String amount = _amountController.text;
    final String parameters = _parametersController.text;

    if (topic.isEmpty){//|| amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter both topic")),
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

      print('------------------------Start');
      print('body: $responseData');
      print('question: $question');
      print('options: $options');
      print('answer: $answer');
      print('------------------------End');

      if (options.isEmpty){
          options = "";
      }

      // Check if question, options, and answer are valid
      if (question.isNotEmpty && answer.isNotEmpty) {
        // Create a new question form with the extracted data
        setState(() {
          _questionFormData.add(_QuestionFormData(index: _questionFormData.length + 1)
            ..questionTitleController.text = question
            ..questionDescriptionController.text = options
            ..questionAnswerController.text = answer);
        });
        return true; // Success
      }
    }
    return false; // Failure
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

  void _updateQuestionIndexes() {
    for (int i = 0; i < _questionFormData.length; i++) {
      _questionFormData[i].index = i + 1;
    }
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

  void _saveTest() async {
    // Validate test name
    if (_titleController.text.isEmpty) {
      print("Error: Please enter a test title");
      return;
    }

    // Validate at least one question
    if (_questionFormData.isEmpty) {
      print("Error: Please add at least one question");
      return;
    }

    // Get user info
    final userInfoProvider = Provider.of<UserInfoProvider>(context, listen: false);
    final userInfo = userInfoProvider.userInfo;

    if (userInfo == null) {
      print("Error: User not logged in");
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
      }).toList(),
      'userId': userInfo.id,
    };

    // Send data to the server
    final userIP = await getUserIP();
    final url = 'http://$userIP/save_test.php';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(testData),
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          print("Test saved successfully");
        } else {
          print("Error: ${responseData['message']}");
        }
      } else {
        print("Failed to save test. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Test Creation"),
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
  int index; // New index

  _QuestionFormData({required this.index}) {
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

  const _QuestionForm(
      {required this.questionFormData,
      required this.onRemove,
      required this.onMoveUp,
      required this.onMoveDown,
      Key? key})
      : super(key: key);

  @override
  State<_QuestionForm> createState() => _QuestionFormState();
}

class _QuestionFormState extends State<_QuestionForm> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20), // Add spacing between forms
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey), // Add the outline
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Question ${widget.questionFormData.index}"),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: widget.onMoveUp,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward),
                    onPressed: widget.onMoveDown,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: widget.onRemove,
                  ),
                ],
              )
            ],
          ),
          TextField(
            controller: widget.questionFormData.questionTitleController,
            maxLength: widget.questionFormData.maxQuestionTitleLength,
            decoration: InputDecoration(
              labelText: "Question Title",
              hintText: "Enter the question title here",
              border: const OutlineInputBorder(),
              counterText:
                  "${widget.questionFormData.questionTitleCharCount}/${widget.questionFormData.maxQuestionTitleLength}",
              counterStyle: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.questionFormData.questionDescriptionController,
            maxLength: widget.questionFormData.maxQuestionDescriptionLength,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: "Question Description",
              hintText: "Enter the question description here",
              border: const OutlineInputBorder(),
              counterText:
                  "${widget.questionFormData.questionDescriptionCharCount}/${widget.questionFormData.maxQuestionDescriptionLength}",
              counterStyle: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.questionFormData.questionAnswerController,
            maxLength: widget.questionFormData.maxQuestionAnswerLength,
            decoration: InputDecoration(
              labelText: "Answer",
              hintText: "Enter the answer here",
              border: const OutlineInputBorder(),
              counterText:
                  "${widget.questionFormData.questionAnswerCharCount}/${widget.questionFormData.maxQuestionAnswerLength}",
              counterStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}