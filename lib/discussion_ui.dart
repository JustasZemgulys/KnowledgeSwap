import 'package:flutter/material.dart';
import 'package:knowledgeswap/voting_system.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'get_ip.dart';

class DiscussionScreen extends StatefulWidget {
  final int itemId;
  final String itemType; // 'resource', 'test', 'group', 'answer'

  const DiscussionScreen({
    super.key, 
    required this.itemId, 
    required this.itemType
  });

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  late UserInfo userInfo;
  String? serverIP;
  Map<String, dynamic>? itemDetails;
  List<dynamic> comments = [];
  bool isLoading = true;
  final TextEditingController _commentController = TextEditingController();
  int? replyingToCommentId;
  String? replyingToUsername;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _commentFormKey = GlobalKey();
  final Map<int, bool> _minimizedComments = {};
  final int _maxCommentLength = 1000;
  final int _minimizeThreshold = 100;

  @override
  void initState() {
    super.initState();
    userInfo = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    _initializeServerIP();
  }

  Future<void> _initializeServerIP() async {
    try {
      final getIP = GetIP();
      serverIP = await getIP.getUserIP();
      await _fetchItemDetails();
      await _fetchComments();
    } catch (e) {
      _showError('Connection error: $e');
    }
  }

  Future<void> _fetchItemDetails() async {
    try {
      final response = await http.get(Uri.parse(
          '$serverIP/get_item_details.php?id=${widget.itemId}&type=${widget.itemType}'));
          
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => itemDetails = data['item']);
      }
    } catch (e) {
      _showError('Failed to load item details');
    }
  }

  Future<void> _fetchComments() async {
    try {
      final response = await http.get(Uri.parse(
        '$serverIP/get_comments.php?item_id=${widget.itemId}&item_type=${widget.itemType}&user_id=${userInfo.id}'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            comments = data['comments'];
            isLoading = false;
          });
        } else {
          _showError(data['message'] ?? 'Failed to load comments');
        }
      }
    } catch (e) {
      _showError('Failed to load comments: $e');
    }
  }

  Future<void> _postComment() async {
    String commentText = _commentController.text.trim();
    
    if (commentText.isEmpty) {
      _showError('Comment cannot be empty');
      return;
    }

    if (commentText.length > _maxCommentLength) {
      _showError('Comment cannot exceed $_maxCommentLength characters');
      return;
    }

    try {
      final Map<String, String> body = {
        'user_id': userInfo.id.toString(),
        'item_id': widget.itemId.toString(),
        'item_type': widget.itemType,
        'text': commentText,
      };

      if (replyingToCommentId != null) {
        body['parent_id'] = replyingToCommentId.toString();
      }

      final response = await http.post(
        Uri.parse('$serverIP/create_comment.php'),
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _commentController.clear();
          if (replyingToCommentId != null) {
            setState(() {
              replyingToCommentId = null;
              replyingToUsername = null;
            });
          }
          await _fetchComments();
        } else {
          _showError(data['message'] ?? 'Failed to post comment');
        }
      }
    } catch (e) {
      _showError('Failed to post comment: $e');
    }
  }

  Future<void> _editComment(int commentId, String currentText) async {
  // Check if comment is deleted
  final comment = comments.firstWhere((c) => c['id'] == commentId);
  if (comment['is_deleted'] == true) {
    _showError('Cannot edit deleted comments');
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
    // Optimistic update - show changes immediately
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
        _showError('Failed to update comment');
      }
    } catch (e) {
      await _fetchComments();
      _showError('Failed to update comment: $e');
    }
  }
}

  Future<void> _deleteComment(int commentId) async {
    try {
      // Optimistic update - mark as deleted immediately
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
        // If failed, reload comments to revert
        await _fetchComments();
        _showError('Failed to delete comment');
      } else {
        await _fetchComments();
      }
    } catch (e) {
      await _fetchComments();
      _showError('Failed to delete comment: $e');
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
    _commentController.clear();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3))
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getParentCommentName(int parentId) {
    //print("parentId $parentId");
    try {
      // Search through all comments to find the parent
      for (var comment in comments) {
        //print("comment['id'] ${comment['id']}");
        if (comment['id'] == parentId) {
          // Return the name if user exists, otherwise '[deleted]'
          return comment['name'];
        }
      }
      return '[deleted]';
    } catch (e) {
      return '[deleted]';
    }
  }

  Widget _buildItemDetails() {
    if (itemDetails == null) return const SizedBox();

    switch (widget.itemType) {
      case 'resource':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              itemDetails!['name'] ?? 'Resource',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (itemDetails!['description'] != null)
              Text(itemDetails!['description']),
            /*if (itemDetails!['resource_photo_link'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Image.network(itemDetails!['resource_photo_link']),
              ),*/
          ],
        );
      case 'test':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              itemDetails!['name'] ?? 'Test',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (itemDetails!['description'] != null)
              Text(itemDetails!['description']),
          ],
        );
      case 'group':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              itemDetails!['name'] ?? 'Group',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (itemDetails!['description'] != null)
              Text(itemDetails!['description']),
          ],
        );
      case 'answer':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Answer Discussion',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(itemDetails!['answer'] ?? ''),
            if (itemDetails!['answer_link'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Link: ${itemDetails!['answer_link']}'),
              ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildCommentItem(dynamic comment) {
    final isDeleted = comment['is_deleted'] == true || comment['user_exists'] == false;
    final isAuthor = comment['fk_user'] == userInfo.id;
    final name = isDeleted ? '[deleted]' : comment['name']?.toString() ?? 'Unknown';
    final text = isDeleted ? '[deleted]' : comment['text']?.toString() ?? '';
    final date = comment['creation_date']?.toString() ?? '';
    final isReply = comment['parent_id'] != null;
    final parentUsername = isReply ? _getParentCommentName(comment['parent_id']) : null;
    final score = comment['score'] ?? 0;
    final userVote = comment['user_vote']; // 1 for upvote, -1 for downvote, null for no vote
    
    // Check if this comment should offer minimize option
    final shouldOfferMinimize = text.length > _minimizeThreshold || 
        comments.any((c) => c['parent_id'] == comment['id']);
    final isMinimized = _minimizedComments[comment['id']] ?? false;

    return Card(
      margin: EdgeInsets.only(
        left: isReply ? 40.0 : 8.0,
        top: 8.0,
        right: 8.0,
        bottom: 8.0,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Voting buttons column
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_upward,
                    color: userVote == 1 ? Colors.orange : Colors.grey,
                    size: 20,
                  ),
                  onPressed: isDeleted ? null : () {
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
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Text(
                  score.toString(),
                  style: const TextStyle(fontSize: 14),
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_downward,
                    color: userVote == -1 ? Colors.blue : Colors.grey,
                    size: 20,
                  ),
                  onPressed: isDeleted ? null : () {
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
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(width: 8),
            // Rest of the comment content
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
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              Text(
                                _formatDate(date),
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                              if (comment['last_edit_date'] != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  "edited: ${_formatDate(comment['last_edit_date'])}",
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ],
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
                      if (isAuthor && !isDeleted)
                        PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editComment(comment['id'], text);
                            } else if (value == 'delete') {
                              _deleteComment(comment['id']);
                            }
                          },
                        ),
                    ],
                  ),
                  if (isReply && parentUsername != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Replying to @$parentUsername',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (!isMinimized)
                    Html(
                      data: text,
                      onLinkTap: (url, _, __) {
                        if (url != null) launchUrl(Uri.parse(url));
                      },
                    ),
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

  Widget _buildNestedComments(List<dynamic> allComments, {int? parentId, int depth = 0}) {
    final childComments = allComments.where((c) => 
      (parentId == null && c['parent_id'] == null) || 
      (parentId != null && c['parent_id'] == parentId)
    ).toList();
    
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
    
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussions'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Item details section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildItemDetails(),
                ),
                const Divider(),
                
                // Comments list - now using nested structure
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    children: [
                      _buildNestedComments(comments), // Top-level comments
                    ],
                  ),
                ),
                
                // Comment form (keep existing implementation)
                Container(
                  key: _commentFormKey,
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
                                style: TextStyle(color: Colors.blue),
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
                          suffixIcon: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.send),
                                onPressed: _commentController.text.trim().isNotEmpty && 
                                    _commentController.text.length <= _maxCommentLength
                                    ? _postComment
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {}); // Update character count
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}