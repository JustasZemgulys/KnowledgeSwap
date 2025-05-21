import 'package:flutter/material.dart';
import 'package:knowledgeswap/edit_forum_ui.dart';
import 'package:knowledgeswap/profile_details_ui.dart';
import 'package:knowledgeswap/voting_system.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'get_ip.dart';

class ForumDetailsScreen extends StatefulWidget {
  final int forumItemId;
  final bool hasTest;

  const ForumDetailsScreen({
    super.key,
    required this.forumItemId,
    required this.hasTest,
  });

  @override
  State<ForumDetailsScreen> createState() => _ForumDetailsScreenState();
}

class _ForumDetailsScreenState extends State<ForumDetailsScreen> {
  late UserInfo userInfo;
  String? serverIP;
  Map<String, dynamic>? forumItem;
  Map<String, dynamic>? testDetails;
  List<dynamic>? userAnswers;
  bool isLoading = true;
  bool isTestExpanded = false;
  final TextEditingController _commentController = TextEditingController();
  int? replyingToCommentId;
  String? replyingToUsername;
  List<dynamic> comments = [];
  final int _maxCommentLength = 1000;
  final Map<int, bool> _minimizedComments = {};
  final int _minimizeThreshold = 100;


  @override
  void initState() {
    super.initState();
    userInfo = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    _initializeServerIP();
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _initializeServerIP() async {
    try {
      final getIP = GetIP();
      serverIP = await getIP.getUserIP();
      await _fetchForumItem();
      if (widget.hasTest) {
        await _fetchTestDetails();
      }
      await _fetchComments();
    } catch (e) {
      _showErrorSnackBar('Failed to connect to server. Please try again.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchForumItem() async {
    try {
      final response = await http.get(Uri.parse(
        '$serverIP/get_forum_item.php?id=${widget.forumItemId}&user_id=${userInfo.id}'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => forumItem = data['item']);
      } else {
        _showErrorSnackBar('Failed to load forum item. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Network error occurred. Please check your connection.');
    }
  }

  Future<void> _fetchTestDetails() async {
    try {
      final response = await http.get(Uri.parse(
        '$serverIP/get_forum_item_test.php?forum_item_id=${widget.forumItemId}'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          testDetails = data['test'];
          userAnswers = data['answers'];
        });
      } else {
        _showErrorSnackBar('Failed to load test details. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Network error occurred while loading test details.');
    }
  }

  Future<void> _fetchComments() async {
    try {
      final response = await http.get(Uri.parse(
        '$serverIP/get_comments.php?item_id=${widget.forumItemId}&item_type=forum_item&user_id=${userInfo.id}'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => comments = data['comments'] ?? []);
      } else {
        _showErrorSnackBar('Failed to load comments. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Network error occurred while loading comments.');
    }
  }

  Future<void> _editForumItem() async {
    if (forumItem == null) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditForumScreen(forumItem: forumItem!),
      ),
    );
    
    if (result == true) {
      _showSuccessSnackBar('Forum item updated successfully');
      await _fetchForumItem();
    }
  }

  Future<void> _deleteForumItem(int itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Forum Item'),
        content: const Text('Are you sure you want to delete this forum item and all its comments?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await http.post(
          Uri.parse('$serverIP/delete_forum_item.php'),
          body: {
            'forum_item_id': itemId.toString(),
            'user_id': userInfo.id.toString(),
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            _showSuccessSnackBar('Forum item deleted successfully');
            Navigator.pop(context);
          } else {
            _showErrorSnackBar(data['message'] ?? 'Failed to delete forum item');
          }
        }
      } catch (e) {
        _showErrorSnackBar('Network error occurred. Please try again.');
      }
    }
  }

  Future<void> _postComment() async {
    String commentText = _commentController.text.trim();
    
    if (commentText.isEmpty) {
      _showErrorSnackBar('Comment cannot be empty');
      return;
    }
    
    if (commentText.length > _maxCommentLength) {
      _showErrorSnackBar('Comment exceeds maximum length of $_maxCommentLength characters');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$serverIP/create_comment.php'),
        body: {
          'user_id': userInfo.id.toString(),
          'item_id': widget.forumItemId.toString(),
          'item_type': 'forum_item',
          'text': commentText,
          if (replyingToCommentId != null) 
            'parent_id': replyingToCommentId.toString(),
        },
      );

      if (response.statusCode == 200) {
        _commentController.clear();
        setState(() {
          replyingToCommentId = null;
          replyingToUsername = null;
        });
        _showSuccessSnackBar('Comment posted successfully');
        await _fetchComments();
      } else {
        _showErrorSnackBar('Failed to post comment. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Network error occurred. Please try again.');
    }
  }

  void _handleReply(int commentId, String username) {
    setState(() {
      replyingToCommentId = commentId;
      replyingToUsername = username;
    });
  }

  void _cancelReply() {
    setState(() {
      replyingToCommentId = null;
      replyingToUsername = null;
    });
  }

  String _getParentCommentName(int parentId) {
    try {
      for (var comment in comments) {
        if (comment['id'] == parentId) {
          return comment['name'];
        }
      }
      return '[deleted]';
    } catch (e) {
      return '[deleted]';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildTestReviewSection() {
    if (!widget.hasTest || testDetails == null || testDetails!['questions'] == null) {
      return const SizedBox();
    }

    final questions = testDetails!['questions'] as List;
    final answers = userAnswers ?? [];

    return ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        setState(() => isTestExpanded = !isTestExpanded);
      },
      children: [
        ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(
              title: Text(
                'Test Review - ${testDetails!['name'] ?? 'Test'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          },
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 8),
                ...List.generate(questions.length, (index) {
                  final question = index < questions.length ? questions[index] : null;
                  final answer = index < answers.length ? answers[index] : null;
                  
                  if (question == null) return const SizedBox();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question ${index + 1}: ${question['text']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (question['description'] != null && question['description'].isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Description: ${question['description']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'User answer: ${answer?['answer'] ?? 'Not answered'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Correct answer: ${question['correct_answer']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 1,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          isExpanded: isTestExpanded,
        ),
      ],
    );
  }

// Fix the _buildNestedComments method (line 364-368)
Widget _buildNestedComments(List<dynamic> allComments, {int? parentId, int depth = 0}) {
  final childComments = allComments.where((c) => 
    (parentId == null && c['parent_id'] == null) || 
    (parentId != null && c['parent_id'] == parentId)
  ).toList(); // Fixed the parenthesis and toList placement
  
  if (childComments.isEmpty) return const SizedBox();

  return Column(
    children: [
      for (final comment in childComments) ...[
        Container(
          decoration: depth > 0
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Colors.grey[300]!,
                      width: 2.0,
                    ),
                  ),
                )
              : null,
          padding: EdgeInsets.only(left: depth * 16.0),
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _buildCommentItem(comment),
          ),
        ),
        if (!(_minimizedComments[comment['id']] ?? false))
          _buildNestedComments(allComments, parentId: comment['id'], depth: depth + 1),
      ],
    ],
  );
}

  Widget _buildCommentItem(dynamic comment) {
    final isAuthor = comment['fk_user'] == userInfo.id;
    final isDeleted = comment['is_deleted'] == true || comment['user_exists'] == false;
    final name = isDeleted ? '[deleted]' : comment['name'] ?? 'Unknown';
    final text = isDeleted ? '[deleted]' : comment['text'] ?? '';
    final date = comment['creation_date']?.toString() ?? '';
    final score = comment['score'] ?? 0;
    final userVote = comment['user_vote'];
    final isReply = comment['parent_id'] != null;
    final parentUsername = isReply ? _getParentCommentName(comment['parent_id']) : null;
    final shouldOfferMinimize = text.length > _minimizeThreshold || 
        comments.any((c) => c['parent_id'] == comment['id']);
    final isMinimized = _minimizedComments[comment['id']] ?? false;

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(
        left: isReply ? 40.0 : 16.0,
        top: 8.0,
        right: 16.0,
        bottom: 8.0,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VotingWidget(
              score: score,
              userVote: userVote,
              onUpvote: () {
                VotingController(
                  context: context,
                  itemType: 'comment',
                  itemId: comment['id'],
                  currentScore: score,
                  onScoreUpdated: (newScore) {
                    setState(() {
                      comment['score'] = newScore;
                      comment['user_vote'] = userVote == 1 ? null : 1;
                    });
                  },
                ).upvote();
              },
              onDownvote: () {
                VotingController(
                  context: context,
                  itemType: 'comment',
                  itemId: comment['id'],
                  currentScore: score,
                  onScoreUpdated: (newScore) {
                    setState(() {
                      comment['score'] = newScore;
                      comment['user_vote'] = userVote == -1 ? null : -1;
                    });
                  },
                ).downvote();
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: isDeleted 
                            ? const AssetImage('assets/usericon.jpg') as ImageProvider
                            : (comment['user_image'] != null && comment['user_image'] != "default"
                                ? NetworkImage(comment['user_image'])
                                : const AssetImage('assets/usericon.jpg')) as ImageProvider,
                        radius: 16,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _formatDate(date),
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (shouldOfferMinimize)
                        IconButton(
                          icon: Icon(isMinimized ? Icons.expand_more : Icons.expand_less),
                          onPressed: () {
                            setState(() {
                              _minimizedComments[comment['id']] = !isMinimized;
                            });
                          },
                        ),
                      if (!isDeleted && isAuthor)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit, size: 20),
                                title: Text('Edit', style: TextStyle(fontSize: 14)),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete, size: 20, color: Colors.red),
                                title: Text('Delete', style: TextStyle(fontSize: 14, color: Colors.red)),
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'edit') {
                              await _editComment(comment['id'], text);
                            } else if (value == 'delete') {
                              await _deleteComment(comment['id']);
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (isReply && parentUsername != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        'Replying to @$parentUsername',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (!isMinimized) Text(text),
                  if (isMinimized)
                    Text(
                      text.length > 50 ? '${text.substring(0, 50)}...' : text,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 8),
                  if (!isDeleted && !isMinimized)
                    TextButton(
                      onPressed: () => _handleReply(comment['id'], name),
                      child: const Text('Reply'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editComment(int commentId, String currentText) async {
    final comment = comments.firstWhere((c) => c['id'] == commentId);
    if (comment['is_deleted'] == true) {
      _showErrorSnackBar('Cannot edit deleted comments');
      return;
    }

    final textController = TextEditingController(text: currentText);
    
    final newText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              maxLines: 5,
              maxLength: _maxCommentLength,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.length <= _maxCommentLength) {
                Navigator.pop(context, textController.text);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newText != null && newText.trim() != currentText.trim()) {
      // Optimistic update
      setState(() {
        final index = comments.indexWhere((c) => c['id'] == commentId);
        if (index != -1) {
          comments[index]['text'] = newText.trim();
          comments[index]['is_edited'] = true;
          comments[index]['last_edit_date'] = DateTime.now().toString();
        }
      });

      try {
        final response = await http.post(
          Uri.parse('$serverIP/update_comment.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'comment_id': commentId,
            'user_id': userInfo.id,
            'text': newText.trim(),
          }),
        );

        if (response.statusCode != 200) {
          await _fetchComments();
          _showErrorSnackBar('Failed to update comment');
        }
      } catch (e) {
        await _fetchComments();
        _showErrorSnackBar('Failed to update comment');
      }
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Optimistic update
      setState(() {
        final index = comments.indexWhere((c) => c['id'] == commentId);
        if (index != -1) {
          comments[index]['is_deleted'] = 1;
          comments[index]['text'] = '[deleted]';
        }
      });

      final response = await http.post(
        Uri.parse('$serverIP/delete_comment.php'),
        body: {
          'comment_id': commentId.toString(),
          'user_id': userInfo.id.toString(),
        },
      );

      if (response.statusCode != 200) {
        await _fetchComments();
        _showErrorSnackBar('Failed to delete comment');
      }
    } catch (e) {
      await _fetchComments();
      _showErrorSnackBar('Failed to delete comment');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Forum Discussion',
          style: TextStyle(color: Colors.deepPurple),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        actions: [
          if (forumItem != null && forumItem!['fk_user'] == userInfo.id)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editForumItem();
                } else if (value == 'delete') {
                  _deleteForumItem(widget.forumItemId);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
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
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          forumItem?['title'] ?? 'Forum Item',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        if (forumItem?['description'] != null)
                          Text(forumItem?['description']),
                        const SizedBox(height: 16),
                        Text(
                          'Posted by: ${forumItem?['creator_name'] ?? 'Unknown'}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),

                  _buildTestReviewSection(),
                  const Divider(),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Comments (${comments.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _buildNestedComments(comments),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (replyingToCommentId != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Text(
                          'Replying to $replyingToUsername',
                          style: const TextStyle(color: Colors.blue),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _cancelReply,
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  maxLength: _maxCommentLength,
                  decoration: InputDecoration(
                    labelText: 'Add a comment...',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _commentController.text.trim().isNotEmpty
                          ? _postComment
                          : null,
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}