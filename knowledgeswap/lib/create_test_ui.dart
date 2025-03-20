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
  final TextEditingController _amountController = TextEditingController();
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
    final String amount = _amountController.text;

    if (topic.isEmpty || amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter both topic and amount")),
      );
      return;
    }

    String userIP = await getUserIP();
    final String url = 'http://$userIP/ai_create_question.php';

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Add text fields
      request.fields['topic'] = topic;
      request.fields['question_amount'] = amount;

      // Add file if selected
      if (_selectedFile != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file', // Field name for the file
            _selectedFile!.bytes!, // Use the bytes property
            filename: _selectedFile!.name, // File name
          ),
        );
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);
        print('Server Response: ${response.statusCode}');
        print('Body: $jsonResponse');
        // Process the response and update the UI accordingly
      } else {
        print('Server Response: ${response.statusCode}');
        var responseData = await response.stream.bytesToString();
        print('Body: $responseData');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch questions: $responseData")),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    }
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

  // Method to add a new question form
  void _addQuestionForm() {
    setState(() {
      _questionFormData.add(_QuestionFormData());
    });
  }

  void _removeQuestionForm(int index) {
    setState(() {
      _questionFormData.removeAt(index);
      _updateQuestionIndexes(); //update indexes
    });
  }

  // Helper method to update question indexes after removing or moving
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
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Number of Questions",
                hintText: "Enter the number of questions",
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
  int index = 0; // New index

  _QuestionFormData() {
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