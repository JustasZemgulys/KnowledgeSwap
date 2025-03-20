import 'package:flutter/material.dart';
import 'package:knowledgeswap/profile_details_ui.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';

class CreateQuestionScreen extends StatefulWidget {
  const CreateQuestionScreen({super.key});

  @override
  State<CreateQuestionScreen> createState() => _CreateQuestionScreenState();
}

class _CreateQuestionScreenState extends State<CreateQuestionScreen> {
  late UserInfo user_info;
  final TextEditingController _questionTitleController =
      TextEditingController();
  final TextEditingController _questionDescriptionController =
      TextEditingController();
  final TextEditingController _questionAnswerController =
      TextEditingController();
  int _questionTitleCharCount = 0;
  int _questionDescriptionCharCount = 0;
  int _questionAnswerCharCount = 0;
  final int _maxQuestionTitleLength = 255;
  final int _maxQuestionDescriptionLength = 255;
  final int _maxQuestionAnswerLength = 255;

  @override
  void initState() {
    super.initState();
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    _questionTitleController.addListener(_updateQuestionTitleCharCount);
    _questionDescriptionController
        .addListener(_updateQuestionDescriptionCharCount);
    _questionAnswerController.addListener(_updateQuestionAnswerCharCount);
  }

  @override
  void dispose() {
    _questionTitleController.dispose();
    _questionDescriptionController.dispose();
    _questionAnswerController.dispose();
    super.dispose();
  }

  void _updateQuestionTitleCharCount() {
    setState(() {
      _questionTitleCharCount = _questionTitleController.text.length;
    });
  }

  void _updateQuestionDescriptionCharCount() {
    setState(() {
      _questionDescriptionCharCount = _questionDescriptionController.text.length;
    });
  }

  void _updateQuestionAnswerCharCount() {
    setState(() {
      _questionAnswerCharCount = _questionAnswerController.text.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Question"),
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _questionTitleController,
              maxLength: _maxQuestionTitleLength,
              decoration: InputDecoration(
                labelText: "Question Title",
                hintText: "Enter the question title here",
                border: const OutlineInputBorder(),
                counterText: "$_questionTitleCharCount/$_maxQuestionTitleLength",
                counterStyle: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _questionDescriptionController,
              maxLength: _maxQuestionDescriptionLength,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: "Question Description",
                hintText: "Enter the question description here",
                border: const OutlineInputBorder(),
                counterText:
                    "$_questionDescriptionCharCount/$_maxQuestionDescriptionLength",
                counterStyle: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _questionAnswerController,
              maxLength: _maxQuestionAnswerLength,
              decoration: InputDecoration(
                labelText: "Answer",
                hintText: "Enter the answer here",
                border: const OutlineInputBorder(),
                counterText:
                    "$_questionAnswerCharCount/$_maxQuestionAnswerLength",
                counterStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
