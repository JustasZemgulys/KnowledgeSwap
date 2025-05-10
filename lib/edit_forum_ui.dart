import 'package:flutter/material.dart';
import 'package:knowledgeswap/create_forum_item_ui.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';

class EditForumScreen extends StatefulWidget {
  final Map<String, dynamic> forumItem;

  const EditForumScreen({super.key, required this.forumItem});

  @override
  State<EditForumScreen> createState() => _EditForumScreenState();
}

class _EditForumScreenState extends State<EditForumScreen> {
  late UserInfo userInfo;

  @override
  void initState() {
    super.initState();
    userInfo = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
  }

  @override
  Widget build(BuildContext context) {
    return CreateForumScreen(
      initialData: widget.forumItem,
      isEditMode: true,
    );
  }
}