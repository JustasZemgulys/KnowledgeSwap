import 'package:flutter/material.dart';
import 'package:knowledgeswap/create_forum_item_ui.dart';
import 'package:knowledgeswap/discussion_ui.dart';
import 'package:knowledgeswap/edit_forum_ui.dart';
import 'package:knowledgeswap/forum_details_screen.dart';
import 'package:knowledgeswap/profile_details_ui.dart';
import 'package:knowledgeswap/voting_system.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'get_ip.dart';

class ForumScreen extends StatefulWidget {
  final int initialPage;
  final String initialSort;

  const ForumScreen({
    super.key,
    this.initialPage = 1,
    this.initialSort = 'desc',
  });

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  late UserInfo userInfo;
  late int currentPage;
  late String sortOrder;
  List<dynamic> forumItems = [];
  List<dynamic> filteredItems = [];
  int itemsPerPage = 10;
  int totalItems = 0;
  bool isLoading = true;
  bool isSearching = false;
  String? serverIP;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    currentPage = widget.initialPage;
    sortOrder = widget.initialSort;
    super.initState();
    userInfo = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    _initializeServerIP();
  }

  Future<void> _initializeServerIP() async {
    try {
      final getIP = GetIP();
      serverIP = await getIP.getUserIP();
      _fetchForumItems();
    } catch (e) {
      _showErrorSnackBar('Failed to connect to server. Please try again later.');
    }
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

  Future<void> _fetchForumItems() async {
    if (serverIP == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse('$serverIP/get_forum_items.php?page=$currentPage&per_page=$itemsPerPage&sort=$sortOrder&user_id=${userInfo.id}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          totalItems = int.tryParse(data['total'].toString()) ?? 0;
          
          if (data['items'].isEmpty && currentPage > 1) {
            currentPage--;
            _fetchForumItems();
            return;
          }

          forumItems = List<dynamic>.from(data['items']);
          filteredItems = List<dynamic>.from(forumItems);
          isLoading = false;
        });
      } else {
        _showErrorSnackBar('Server error occurred. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load forum items. Please check your connection.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _editForumItem(Map<String, dynamic> item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditForumScreen(forumItem: item),
      ),
    );
    
    if (result == true) {
      _showSuccessSnackBar('Forum item updated successfully');
      await _fetchForumItems();
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
            await _fetchForumItems();
          } else {
            _showErrorSnackBar(data['message'] ?? 'Failed to delete forum item');
          }
        }
      } catch (e) {
        _showErrorSnackBar('Network error occurred. Please try again.');
      }
    }
  }

  void _searchItems(String query) {
    setState(() {
      isSearching = query.isNotEmpty;
      if (isSearching) {
        filteredItems = forumItems.where((item) => 
          item['title'].toString().toLowerCase().contains(query.toLowerCase())
        ).toList();
      } else {
        filteredItems = List<dynamic>.from(forumItems);
      }
    });
  }

  void _changeSortOrder(String newOrder) {
    setState(() {
      sortOrder = newOrder;
      currentPage = 1;
    });

    if (newOrder == 'score') {
      setState(() {
        forumItems.sort((a, b) {
          int scoreA = a['score'] ?? 0;
          int scoreB = b['score'] ?? 0;

          if (scoreA != scoreB) {
            return scoreB.compareTo(scoreA);
          } else {
            String nameA = a['title']?.toLowerCase() ?? '';
            String nameB = b['title']?.toLowerCase() ?? '';
            return nameA.compareTo(nameB);
          }
        });
        filteredItems = List<dynamic>.from(forumItems);
      });
    } else {
      _fetchForumItems();
    }
  }

  void _goToPage(int page) {
    setState(() {
      currentPage = page;
    });
    _fetchForumItems();
  }

  Widget _buildForumItemCard(Map<String, dynamic> item) {
    final isOwner = item['fk_user'] == userInfo.id;
    final itemId = item['id'];
    final itemTitle = item['title'] ?? 'Untitled Forum Item';
    final userVote = item['user_vote'];
    final score = item['score'] ?? 0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ForumDetailsScreen(
                forumItemId: itemId,
                hasTest: item['fk_test'] != null,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VotingWidget(
                    score: score,
                    userVote: userVote,
                    onUpvote: () {
                      VotingController(
                        context: context,
                        itemType: 'forum_item',
                        itemId: itemId,
                        currentScore: score,
                        onScoreUpdated: (newScore) {
                          setState(() {
                            item['score'] = newScore;
                            item['user_vote'] = 1;
                          });
                        },
                      ).upvote();
                    },
                    onDownvote: () {
                      VotingController(
                        context: context,
                        itemType: 'forum_item',
                        itemId: itemId,
                        currentScore: score,
                        onScoreUpdated: (newScore) {
                          setState(() {
                            item['score'] = newScore;
                            item['user_vote'] = -1;
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
                        Text(
                          itemTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['description'] ?? 'No description',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Posted by: ${item['creator_name'] ?? 'Unknown'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              'Created: ${item['creation_date']?.split(' ')[0] ?? 'Unknown'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isOwner) ...[Positioned(
                top: 0,
                right: 0,
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, 
                    color: Colors.grey[600], 
                    size: 20),
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
                      if (value == 'discussions') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DiscussionScreen(
                              itemId: itemId,
                              itemType: 'forum_item',
                            ),
                          ),
                        );
                      } else if (value == 'edit') {
                        await _editForumItem(item);
                      } else if (value == 'delete') {
                        await _deleteForumItem(itemId);
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
          onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
        ),
        title: Container(
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Center(
            child: TextField(
              controller: _searchController,
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Search forum...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                isDense: true,  
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _fetchForumItems();
                          setState(() {
                            isSearching = false;
                          });
                        },
                      ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.sort, color: Colors.deepPurple),
                      color: Colors.white,
                      onSelected: (value) => _changeSortOrder(value),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'desc',
                          child: Text('Newest first', 
                            style: TextStyle(color: Colors.black)),
                        ),
                        PopupMenuItem(
                          value: 'asc',
                          child: Text('Oldest first', 
                            style: TextStyle(color: Colors.black)),
                        ),
                        PopupMenuItem(
                          value: 'score',
                          child: Text('Sort by Score', style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              onChanged: _searchItems,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.deepPurple),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateForumScreen()),
              ).then((refresh) {
                if (refresh == true) {
                  _fetchForumItems();
                  _showSuccessSnackBar('Forum item created successfully');
                }
              });
            },
          ),
          const SizedBox(width: 1),
          IconButton(
            icon: Image.asset("assets/usericon.jpg"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileDetailsScreen()),
              );
            },
          ),
        ],
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(
                color: Colors.deepPurple,
              ))
            : filteredItems.isEmpty
                ? Center(
                    child: Text('No forum items found',
                      style: TextStyle(color: Colors.grey[800])),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          color: Colors.deepPurple,
                          onRefresh: _fetchForumItems,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              return _buildForumItemCard(filteredItems[index]);
                            },
                          ),
                        ),
                      ),
                      if (!isSearching && totalItems > itemsPerPage)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left,
                                  color: Colors.deepPurple),
                                onPressed: currentPage > 1
                                    ? () => _goToPage(currentPage - 1)
                                    : null,
                              ),
                              Text('Page $currentPage of ${(totalItems / itemsPerPage).ceil()}',
                                style: TextStyle(color: Colors.grey[800])),
                              IconButton(
                                icon: const Icon(Icons.chevron_right,
                                  color: Colors.deepPurple),
                                onPressed: currentPage < (totalItems / itemsPerPage).ceil() && 
                                          forumItems.length >= itemsPerPage
                                    ? () => _goToPage(currentPage + 1)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
