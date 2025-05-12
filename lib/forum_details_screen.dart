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

  @override
  void initState() {
    super.initState();
    userInfo = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    _initializeServerIP();
  }

  Future<void> _initializeServerIP() async {
    try {
      serverIP = await getUserIP();
      await _fetchForumItem();
      if (widget.hasTest) {
        await _fetchTestDetails();
      }
      await _fetchComments();
    } catch (e) {
      _showError('Connection error: $e');
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
      }
    } catch (e) {
      _showError('Failed to load forum item');
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
      }
    } catch (e) {
      _showError('Failed to load test details: $e');
    }
  }

  Future<void> _fetchComments() async {
    try {
      final response = await http.get(Uri.parse(
        '$serverIP/get_comments.php?item_id=${widget.forumItemId}&item_type=forum_item&user_id=${userInfo.id}'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => comments = data['comments'] ?? []);
      }
    } catch (e) {
      _showError('Failed to load comments');
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
      await _fetchForumItem(); // Refresh the item
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Forum item deleted successfully')),
            );
            Navigator.pop(context); // Close the details screen
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _postComment() async {
    String commentText = _commentController.text.trim();
    
    if (commentText.isEmpty) return;
    if (commentText.length > _maxCommentLength) {
      _showError('Comment too long');
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
        await _fetchComments();
      }
    } catch (e) {
      _showError('Failed to post comment');
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3))
    );
  }

  Widget _buildTestReviewSection() {
  if (!widget.hasTest || testDetails == null || testDetails!['questions'] == null) {
    return const SizedBox();
  }

  final questions = testDetails!['questions'] as List;
  // ignore: unnecessary_cast
  final answers = userAnswers as List? ?? [];

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
                // Safely get question and answer
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
                        Text(
                          'Question description: ${question['description']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text('User answer: ${answer?['answer'] ?? 'Not answered'}'),
                      Text('Question answer: ${question['correct_answer']}'),
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
                      if (!isDeleted && isAuthor)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20),
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
                          onSelected: (value) {
                            if (value == 'edit') {
                              // Implement edit functionality
                            } else if (value == 'delete') {
                              // Implement delete functionality
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
                  Text(text),
                  const SizedBox(height: 8),
                  if (!isDeleted)
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
        iconTheme: IconThemeData(color: Colors.deepPurple),
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
                  // Forum item details
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

                  // Test review section (if has test)
                  _buildTestReviewSection(),
                  const Divider(),

                  // Comments section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Comments (${comments.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ...comments.map(_buildCommentItem).toList(),
                ],
              ),
            ),
          ),

          // Comment form (reused from DiscussionScreen)
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