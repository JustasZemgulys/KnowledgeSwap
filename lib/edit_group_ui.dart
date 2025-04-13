import 'package:flutter/material.dart';
import 'package:knowledgeswap/create_group_ui.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';

class EditGroupScreen extends StatefulWidget {
  final Map<String, dynamic> group;

  const EditGroupScreen({super.key, required this.group});

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  late UserInfo userinfo;

  @override
  void initState() {
    super.initState();
    userinfo = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
  }

  @override
  Widget build(BuildContext context) {
    return CreateGroupScreen(
      initialData: widget.group,
      isEditMode: true,
    );
  }
}