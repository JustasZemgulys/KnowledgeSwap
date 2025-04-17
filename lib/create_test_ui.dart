import 'package:flutter/material.dart';
import 'package:knowledgeswap/profile_details_ui.dart';
import 'package:knowledgeswap/resource_search_screen.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
  int _titleCharCount = 0;
  int _descriptionCharCount = 0;
  final int _maxTitleLength = 255;
  final int _maxDescriptionLength = 255;
  List<String> _questions = [];
  PlatformFile? _selectedFile;
  int? _selectedResourceId;
  String? _selectedResourcePath;
  bool _isResourceAttached = false;
  int _visibility = 1;
  String serverIP = '';
  List<_QuestionFormData> _questionFormData = [];  // List to hold the question forms

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
      if (widget.initialTestData!['visibility'] is bool) {
      _visibility = widget.initialTestData!['visibility'] ? 1 : 0;
      } else {
        _visibility = widget.initialTestData!['visibility'] as int;
      }
      if (widget.initialTestData!['fk_resource'] != null) {
        _selectedResourceId = widget.initialTestData!['fk_resource'];
        _isResourceAttached = true;
        // Initialize with the data we already have
        _selectedResourcePath = widget.initialTestData!['resource_link'];
      }
      _loadExistingQuestions();
    }
  }

  Future<void> _loadExistingQuestions() async {
    if (widget.initialTestData == null) return;

    try {
      final url = 'https://juszem1-1.stud.if.ktu.lt/get_questions.php?test_id=${widget.initialTestData!['id']}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> questions = responseData['questions'] ?? [];
          
          // Sort questions by their index before creating form data
          questions.sort((a, b) => (a['index'] ?? 0).compareTo(b['index'] ?? 0));
          
          setState(() {
            _questionFormData = questions.map((q) {
              // Convert database value to proper boolean
              // Assuming ai_made is 1 for true and 0 for false in the database
              final bool isAiMade = (q['ai_made'] ?? 0) == 1;
              
              return _QuestionFormData(
                index: q['index'] ?? (_questionFormData.length + 1),
                aiMade: isAiMade,
              )
                ..questionId = q['id']
                ..initializeWithExistingData(
                  q['name'] ?? '',
                  q['description'] ?? '',
                  q['answer'] ?? '',
                  isAiMade,
                );
            }).toList();
          });
        }
      }
    } catch (e) {
      //print('Error loading questions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load questions: $e')),
      );
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

    final String url = 'https://juszem1-1.stud.if.ktu.lt/ai_create_question.php';

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
        //print('Error: $e');
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

  Future<void> _selectExistingResource() async {
    try {
      final selectedResource = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => const ResourceSearchScreen(),
        ),
      );

      if (selectedResource != null && mounted) {
        setState(() {
          _selectedResourceId = selectedResource['id'];
          //_selectedResourceName = selectedResource['name'];
          _selectedResourcePath = selectedResource['resource_link'];
          _isResourceAttached = true;
          // No need to fetch details - we already have them from the search
          //_resourceDetailsFuture = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select resource: $e')),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _fetchResourceDetails(int resourceId) async {
    try {
      final url = 'https://juszem1-1.stud.if.ktu.lt/get_resource_details.php?resource_id=$resourceId';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['resource'] != null) {
          return responseData['resource'];
        }
      }
      throw Exception('Failed to load resource details');
    } catch (e) {
      debugPrint('Error fetching resource details: $e');
      rethrow;
    }
  }

  void _removeAttachedResource() {
    setState(() {
      _selectedResourceId = null;
      //_selectedResourceName = null;
      _selectedResourcePath = null;
      _isResourceAttached = false;
      //_resourceDetailsFuture = null; // Clear the cached future
    });
  }

  Future<PlatformFile?> _getFileFromPath(String path) async {
    try {
      
      // Clean the path by removing leading slashes and encoding special characters
      final cleanPath = path.replaceAll(RegExp(r'^/+'), '').replaceAll(' ', '%20');
      final fullUrl = 'https://juszem1-1.stud.if.ktu.lt/$cleanPath';
      
      print('Attempting to fetch file from: $fullUrl'); // Debug logging

      // First check if the file exists by making a HEAD request
      final headResponse = await http.head(Uri.parse(fullUrl));
      if (headResponse.statusCode != 200) {
        print('File not found or inaccessible (HTTP ${headResponse.statusCode})');
        return null;
      }

      // Now make the GET request to fetch the file
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Accept': 'application/octet-stream',
          'Origin': 'https://juszem1-1.stud.if.ktu.lt', // Match your server's CORS policy
        },
      );

      if (response.statusCode == 200) {
        // Get filename from path
        final filename = cleanPath.split('/').last;
        
        // Get content type from headers
        //final contentType = response.headers['content-type'] ?? 'application/octet-stream';
        
        return PlatformFile(
          name: filename,
          bytes: response.bodyBytes,
          size: response.bodyBytes.length,
        );
      } else {
        print('Server returned status code ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching file: $e');
      return null;
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
      PlatformFile? fileToUpload = _selectedFile;
      if (fileToUpload == null && _selectedResourcePath != null) {
        fileToUpload = await _getFileFromPath(_selectedResourcePath!);
      }

      // Add file if available
      if (fileToUpload != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileToUpload.bytes!,
            filename: fileToUpload.name,
          ),
        );
      }

      var response = await request.send();

      // Log status code and headers
      //print('Status Code: ${response.statusCode}');
      //print('Headers: ${response.headers}');

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        //print('Raw Response: $responseData'); // Log the raw response
        return json.decode(responseData);
      } else {
        //print('Server Response: ${response.statusCode}');
        //var responseData = await response.stream.bytesToString();
        //print('Body: $responseData');
        return null;
      }
    } catch (e) {
      //print("Error in _sendRequest: $e");
      //print("Stack Trace: $stackTrace");
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

      if (question.isEmpty || answer.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to generate valid question - missing title or answer")),
        );
        return false;
      }

      // Create a new question form with the extracted data
      setState(() {
        final newQuestion = _QuestionFormData(
          index: _questionFormData.length + 1,
          aiMade: true,
        )..initializeWithExistingData(question, options, answer, true);
        
        
        _questionFormData.add(newQuestion);
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

    bool isTestAiMade = _questionFormData.isNotEmpty && 
      _questionFormData.every((q) => q.aiMade);

    try {
      //print('Visibility value being sent: $_visibility'); 
      final testData = {
        'name': _titleController.text,
        'description': _descriptionController.text,
        'questions': _questionFormData.map((question) {
          return {
            'title': question.questionTitleController.text,
            'description': question.questionDescriptionController.text,
            'answer': question.questionAnswerController.text,
            'index': question.index,
            'id': question.questionId,
            'ai_made': question.aiMade ? 1 : 0,
          };
        }).toList(),
        'userId': userInfo.id,
        'ai_made': isTestAiMade ? 1 : 0,
        'fk_resource': _selectedResourceId,
        'visibility': _visibility,
      };

      if (widget.initialTestData != null) {
        testData['testId'] = widget.initialTestData!['id'];
        testData['ai_made'] = widget.initialTestData!['ai_made'] ?? (isTestAiMade ? 1 : 0);
      }

      final url = widget.initialTestData != null 
          ? 'https://juszem1-1.stud.if.ktu.lt/update_test.php'
          : 'https://juszem1-1.stud.if.ktu.lt/save_test.php';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(testData),
      );

      // Handle response
      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(widget.initialTestData != null 
                  ? "Test updated successfully" 
                  : "Test saved successfully")),
            );
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(responseData['message'] ?? "Operation failed")),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Invalid server response")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  Widget _buildResourceAttachmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "Attach Resource:",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _selectExistingResource,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search),
              SizedBox(width: 8),
              Text("Search and Select Resource"),
            ],
          ),
        ),
        if (_isResourceAttached && _selectedResourceId != null) ...[
          const SizedBox(height: 10),
          FutureBuilder<Map<String, dynamic>>(
            future: _fetchResourceDetails(_selectedResourceId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Text('Error loading resource: ${snapshot.error}');
              }
              
              if (snapshot.hasData) {
                final resource = snapshot.data!;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: _buildResourcePreview(resource),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resource['name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                resource['resource_photo_link'] ?? resource['resource_link'] ?? '',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          onPressed: _removeAttachedResource,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const Text('Loading resource details...');
            },
          ),
        ],
      ],
    );
  }

  Widget _buildResourcePreview(Map<String, dynamic> resource) {
    final iconPath = resource['resource_photo_link'] ?? '';
    final filePath = resource['resource_link'] ?? '';
    final displayName = resource['name'] ?? '';

    // Clean paths by removing leading slashes and encoding special characters
    final cleanIconPath = iconPath.replaceAll(RegExp(r'^/+'), '').replaceAll(' ', '%20');
    final cleanFilePath = filePath.replaceAll(RegExp(r'^/+'), '').replaceAll(' ', '%20');

    // 1. First try to show icon image if available (resource_photo_link)
    if (cleanIconPath.isNotEmpty) {
      final iconUrl = 'https://juszem1-1.stud.if.ktu.lt/$cleanIconPath';
      return Image.network(
        iconUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // If icon fails, try showing the actual file if it's an image
          return _getFilePreview(cleanFilePath, displayName);
        },
      );
    }
    
    // 2. No icon available - try showing the file itself if it's an image
    return _getFilePreview(cleanFilePath, displayName);
  }

  Widget _getFilePreview(String filePath, String displayName) {
    if (filePath.isEmpty) {
      return _getFileTypeIcon(null, displayName);
    }

    // Check common image extensions
    final isImage = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].any(
      (ext) => filePath.toLowerCase().endsWith(ext)
    );

    if (isImage) {
      final imageUrl = 'https://juszem1-1.stud.if.ktu.lt/$filePath';
      return Image.network(
        imageUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _getFileTypeIcon(filePath, displayName);
        },
      );
    }

    return _getFileTypeIcon(filePath, displayName);
  }

  Widget _getFileTypeIcon(String? filePath, String displayName) {
    if (filePath == null) {
      return Tooltip(
        message: displayName,
        child: const Icon(Icons.insert_drive_file, size: 40),
      );
    }

    if (filePath.toLowerCase().endsWith('.pdf')) {
      return Tooltip(
        message: displayName,
        child: const Icon(Icons.picture_as_pdf, size: 40, color: Colors.red),
      );
    }

    return Tooltip(
      message: displayName,
      child: const Icon(Icons.insert_drive_file, size: 40),
    );
  }

  Widget _buildVisibilitySwitch() {
    return SwitchListTile(
      title: const Text('Make this test private'),
      subtitle: const Text('Private tests are only visible to you'),
      value: _visibility == 0, // True when private (0), false when public (1)
      onChanged: (bool newValue) {
        setState(() {
          // Toggle between 0 and 1
          _visibility = newValue ? 0 : 1;
          //print('Visibility toggled to: $_visibility (${newValue ? 'Private' : 'Public'})');
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialTestData != null ? "Edit Test" : "Test Creation",
          style: TextStyle(color: Colors.deepPurple),
        ),
        iconTheme: const IconThemeData(color: Colors.deepPurple),
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
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(//Title
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
            TextField(//Description
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
            ElevatedButton(//Create Question
              onPressed: _addQuestionForm,
              child: const Text("Create Question"),
            ),
            const SizedBox(height: 20),
            Column(// Displays the question forms here
              children: [
                for (int i = 0; i < _questionFormData.length; i++)
                  _QuestionForm(
                    key: ObjectKey(_questionFormData[i]),
                    questionFormData: _questionFormData[i],
                    onRemove: () => _removeQuestionForm(i),
                    onMoveUp: () => _moveQuestionUp(i),
                    onMoveDown: () => _moveQuestionDown(i),
                    showAIBadge: _questionFormData[i].aiMade && !_questionFormData[i]._hasBeenEdited,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(//Topic
              controller: _topicController,
              decoration: InputDecoration(
                labelText: "Topic",
                hintText: "Enter topic for quiz questions",
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(//Parameters
              controller: _parametersController,
              decoration: InputDecoration(
                labelText: "Parameters",
                hintText: "Enter parameters for the question (e.g., 'multiple choice, difficulty: hard')",
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
             _buildResourceAttachmentSection(),
            //ElevatedButton(
            //  onPressed: _pickFile,
            //  child: const Text("Upload PDF/JPG"),
            //),
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
            _buildVisibilitySwitch(),
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
  int index;
  int? questionId;
  bool aiMade;
  bool _hasBeenEdited = false;
  String? _initialTitle;
  String? _initialDescription;
  String? _initialAnswer;
  VoidCallback? onEdit;

  _QuestionFormData({
    required this.index, 
    this.aiMade = false
  }) {
    _initialTitle = questionTitleController.text;
    _initialDescription = questionDescriptionController.text;
    _initialAnswer = questionAnswerController.text;

    // Setup listeners for character counting and edit detection
    _setupListeners();
  }

  void _setupListeners() {
    questionTitleController.addListener(_updateTitleState);
    questionDescriptionController.addListener(_updateDescriptionState);
    questionAnswerController.addListener(_updateAnswerState);
  }

  void _updateTitleState() {
    questionTitleCharCount = questionTitleController.text.length;
    _checkForEdits();
  }

  void _updateDescriptionState() {
    questionDescriptionCharCount = questionDescriptionController.text.length;
    _checkForEdits();
  }

  void _updateAnswerState() {
    questionAnswerCharCount = questionAnswerController.text.length;
    _checkForEdits();
  }

  void _checkForEdits() {
    if (!_hasBeenEdited && aiMade) {
      final currentTitle = questionTitleController.text;
      final currentDescription = questionDescriptionController.text;
      final currentAnswer = questionAnswerController.text;

      if (currentTitle != _initialTitle || 
          currentDescription != _initialDescription || 
          currentAnswer != _initialAnswer) {
        _markAsEdited();
      }
    }
  }

  void _markAsEdited() {
    if (!_hasBeenEdited) {  // Only update if not already marked
      _hasBeenEdited = true;
      aiMade = false;  // Remove AI status when edited
      if (onEdit != null) {
        onEdit!();  // Notify parent to rebuild
      }
    }
  }

  void initializeWithExistingData(
    String title, 
    String description, 
    String answer, 
    bool isAiMade,
  ) {
    // Remove listeners temporarily to avoid triggering edit detection
    questionTitleController.removeListener(_updateTitleState);
    questionDescriptionController.removeListener(_updateDescriptionState);
    questionAnswerController.removeListener(_updateAnswerState);

    // Set initial values
    _initialTitle = title;
    _initialDescription = description;
    _initialAnswer = answer;
    
    // Update controllers
    questionTitleController.text = title;
    questionDescriptionController.text = description;
    questionAnswerController.text = answer;
    
    // Update character counts
    questionTitleCharCount = title.length;
    questionDescriptionCharCount = description.length;
    questionAnswerCharCount = answer.length;
    
    // Set AI status
    aiMade = isAiMade;
    _hasBeenEdited = false;

    // Restore listeners
    _setupListeners();
  }

  void dispose() {
    questionTitleController.dispose();
    questionDescriptionController.dispose();
    questionAnswerController.dispose();
  }
}

class _QuestionForm extends StatefulWidget {
  final VoidCallback onRemove;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final _QuestionFormData questionFormData;
  final bool showAIBadge;

  const _QuestionForm({
    required this.questionFormData,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.showAIBadge,
    Key? key,
  }) : super(key: key);

  @override
  State<_QuestionForm> createState() => _QuestionFormState();
}

class _QuestionFormState extends State<_QuestionForm> {
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    // Add listeners to all controllers
    widget.questionFormData.questionTitleController.addListener(_updateState);
    widget.questionFormData.questionDescriptionController.addListener(_updateState);
    widget.questionFormData.questionAnswerController.addListener(_updateState);
    
    // Set the edit callback
    widget.questionFormData.onEdit = _updateState;
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    // Clean up listeners
    widget.questionFormData.questionTitleController.removeListener(_updateState);
    widget.questionFormData.questionDescriptionController.removeListener(_updateState);
    widget.questionFormData.questionAnswerController.removeListener(_updateState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questionFormData;
    final hasTitleError = question.questionTitleController.text.isEmpty;
    final hasAnswerError = question.questionAnswerController.text.isEmpty;
    final showAIBadge =  question.aiMade && !question._hasBeenEdited;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _isExpanded
                  ? Row(
                      children: [
                        Text("Question ${question.index}"),
                        if (showAIBadge)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
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
                    )
                  : Expanded(
                      child: Row(
                        children: [
                          Text("Question ${question.index}: "),
                          if (showAIBadge)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
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
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _isExpanded
                ? Column(
                    children: [
                      const SizedBox(height: 10),
                      TextField(
                        controller: question.questionTitleController,
                        maxLength: question.maxQuestionTitleLength,
                        onChanged: (value) {
                          if (question.aiMade && !question._hasBeenEdited) {
                            setState(() {});
                          }
                        },
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
                        onChanged: (value) {
                          if (question.aiMade && !question._hasBeenEdited) {
                            setState(() {});
                          }
                        },
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
                        onChanged: (value) {
                          if (question.aiMade && !question._hasBeenEdited) {
                            setState(() {});
                          }
                        },
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
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}