import 'package:flutter/material.dart';
import 'package:knowledgeswap/create_test_ui.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';

class EditTestScreen extends StatefulWidget {
  final Map<String, dynamic> test;

  const EditTestScreen({super.key, required this.test});

  @override
  State<EditTestScreen> createState() => _EditTestScreenState();
}

class _EditTestScreenState extends State<EditTestScreen> {
  late UserInfo userinfo;

  @override
  void initState() {
    super.initState();
    userinfo = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
  }

  @override
  Widget build(BuildContext context) {
    return CreateTestScreen(
      initialTestData: widget.test,
    );
  }
}