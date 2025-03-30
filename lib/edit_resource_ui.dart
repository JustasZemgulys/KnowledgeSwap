import 'package:flutter/material.dart';
import 'package:knowledgeswap/create_resource_ui.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';

class EditResourceScreen extends StatefulWidget {
  final Map<String, dynamic> resource;

  const EditResourceScreen({super.key, required this.resource});

  @override
  State<EditResourceScreen> createState() => _EditResourceScreenState();
}

class _EditResourceScreenState extends State<EditResourceScreen> {
  late UserInfo user_info;

  @override
  void initState() {
    super.initState();
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
  }

  @override
  Widget build(BuildContext context) {
    return CreateResourceScreen(
      // Pass the existing resource data to the create screen
      initialData: widget.resource,
    );
  }
}