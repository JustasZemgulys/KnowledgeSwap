import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:knowledgeswap/edit_forum_ui.dart';
import 'package:knowledgeswap/settings_ui.dart';
import 'package:knowledgeswap/discussion_ui.dart';
import 'package:knowledgeswap/take_test_ui.dart';
import 'package:knowledgeswap/group_detail_screen.dart';
import 'package:knowledgeswap/voting_system.dart';
import 'package:knowledgeswap/edit_test_ui.dart';
import 'package:knowledgeswap/edit_resource_ui.dart';
import 'package:knowledgeswap/edit_group_ui.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'package:http/http.dart' as http;
import 'get_ip.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  late UserInfo userinfo;
  bool _isLoadingTests = false;
  bool _isLoadingResources = false;
  bool _isLoadingForumItems = false;
  bool _isLoadingGroups = false;
  List<dynamic> _userTests = [];
  List<dynamic> _userResources = [];
  List<dynamic> _userForumItems = [];
  List<dynamic> _userGroups = [];
  bool _isTestsExpanded = false;
  bool _isResourcesExpanded = false;
  bool _isForumItemsExpanded = false;
  bool _isGroupsExpanded = false;

  @override
  void initState() {
    super.initState();
    userinfo = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoadingTests = true;
      _isLoadingResources = true;
      _isLoadingForumItems = true;
      _isLoadingGroups = true;
    });

    try {
      final getIP = GetIP();
      final userIP = await getIP.getUserIP();
      final response = await http.get(
        Uri.parse('$userIP/user_data.php?user_id=${userinfo.id}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _userTests = data['tests'] ?? [];
            _userResources = data['resources'] ?? [];
            _userForumItems = data['forum_items'] ?? [];
            _userGroups = data['groups'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    } finally {
      setState(() {
        _isLoadingTests = false;
        _isLoadingResources = false;
        _isLoadingForumItems = false;
        _isLoadingGroups = false;
      });
    }
  }

  Future<void> _deleteTest(int testId) async {
    try {
      final getIP = GetIP();
      final userIP = await getIP.getUserIP();
      final response = await http.post(
        Uri.parse('$userIP/delete_test.php'),
        body: {'test_id': testId.toString()},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test deleted successfully')),
        );
        _fetchUserData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete test')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting test: $e')),
      );
    }
  }

  Future<void> _deleteResource(int resourceId) async {
    try {
      final getIP = GetIP();
      final userIP = await getIP.getUserIP();
      final response = await http.post(
        Uri.parse('$userIP/delete_resource.php'),
        body: {'resource_id': resourceId.toString()},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resource deleted successfully')),
        );
        _fetchUserData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete resource')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting resource: $e')),
      );
    }
  }

  Future<void> _deleteForumItem(int forumItemId) async {
    try {
      final getIP = GetIP();
      final userIP = await getIP.getUserIP();
      final response = await http.post(
        Uri.parse('$userIP/delete_forum_item.php'),
        body: {'forum_item_id': forumItemId.toString()},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Forum post deleted successfully')),
        );
        _fetchUserData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete forum post')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting forum post: $e')),
      );
    }
  }

  Future<void> _leaveGroup(int groupId) async {
    try {
      final getIP = GetIP();
      final userIP = await getIP.getUserIP();
      final response = await http.post(
        Uri.parse('$userIP/leave_group.php'),
        body: {'group_id': groupId.toString()},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left group successfully')),
        );
        _fetchUserData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to leave group')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error leaving group: $e')),
      );
    }
  }

  Future<void> _confirmDeleteTest(BuildContext context, int testId, String testName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Test'),
        content: Text('Are you sure you want to delete "$testName"?'),
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
      await _deleteTest(testId);
    }
  }

  Future<void> _confirmDeleteResource(BuildContext context, int resourceId, String resourceName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resource'),
        content: Text('Are you sure you want to delete "$resourceName"?'),
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
      await _deleteResource(resourceId);
    }
  }

  Future<void> _confirmDeleteForumItem(BuildContext context, int forumItemId, String forumItemTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Forum Post'),
        content: Text('Are you sure you want to delete "$forumItemTitle"?'),
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
      await _deleteForumItem(forumItemId);
    }
  }

  Future<void> _confirmLeaveGroup(BuildContext context, int groupId, String groupName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Are you sure you want to leave "$groupName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _leaveGroup(groupId);
    }
  }

  Widget _buildTestCard(Map<String, dynamic> test) {
    final testId = test['id'];
    final testName = test['name'] ?? 'Untitled Test';
    final isOwner = test['fk_user'] == userinfo.id;
    int localScore = test['score'] ?? 0;
    int? localUserVote = test['user_vote'];

    return StatefulBuilder(
      builder: (context, setState) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            children: [
              ListTile(
                title: Text(testName),
                subtitle: Text('Created: ${test['creation_date']}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TakeTestScreen(testId: testId),
                    ),
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_upward,
                          color: localUserVote == 1 ? Colors.orange : Colors.grey,
                        ),
                        onPressed: () {
                          final newVote = localUserVote == 1 ? null : 1;
                          final scoreChange = newVote == null ? -1 : (localUserVote == -1 ? 2 : 1);
                          
                          setState(() {
                            localUserVote = newVote;
                            localScore = localScore + scoreChange;
                          });

                          VotingController(
                            context: context,
                            itemType: 'test',
                            itemId: testId,
                            currentScore: localScore,
                            onScoreUpdated: (newScore) {
                              if (mounted) {
                                setState(() {
                                  test['score'] = newScore;
                                  test['user_vote'] = newVote;
                                });
                              }
                            },
                          ).upvote();
                        },
                      ),
                      Text(localScore.toString()),
                      IconButton(
                        icon: Icon(
                          Icons.arrow_downward,
                          color: localUserVote == -1 ? Colors.blue : Colors.grey,
                        ),
                        onPressed: () {
                          final newVote = localUserVote == -1 ? null : -1;
                          final scoreChange = newVote == null ? 1 : (localUserVote == 1 ? -2 : -1);
                          
                          setState(() {
                            localUserVote = newVote;
                            localScore = localScore + scoreChange;
                          });

                          VotingController(
                            context: context,
                            itemType: 'test',
                            itemId: testId,
                            currentScore: localScore,
                            onScoreUpdated: (newScore) {
                              if (mounted) {
                                setState(() {
                                  test['score'] = newScore;
                                  test['user_vote'] = newVote;
                                });
                              }
                            },
                          ).downvote();
                        },
                      ),
                    ],
                  ),
                  if (isOwner)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditTestScreen(test: test),
                              ),
                            ).then((_) => _fetchUserData());
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () => _confirmDeleteTest(context, testId, testName),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResourceCard(Map<String, dynamic> resource) {
    final resourceId = resource['id'];
    final resourceName = resource['name'] ?? 'Untitled Resource';
    final isOwner = resource['fk_user'] == userinfo.id;
    int localScore = resource['score'] ?? 0;
    int? localUserVote = resource['user_vote'];

    return StatefulBuilder(
      builder: (context, setState) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            children: [
              ListTile(
                title: Text(resourceName),
                subtitle: Text('Created: ${resource['creation_date']}'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_upward,
                          color: localUserVote == 1 ? Colors.orange : Colors.grey,
                        ),
                        onPressed: () {
                          final newVote = localUserVote == 1 ? null : 1;
                          final scoreChange = newVote == null ? -1 : (localUserVote == -1 ? 2 : 1);
                          
                          setState(() {
                            localUserVote = newVote;
                            localScore = localScore + scoreChange;
                          });

                          VotingController(
                            context: context,
                            itemType: 'resource',
                            itemId: resourceId,
                            currentScore: localScore,
                            onScoreUpdated: (newScore) {
                              if (mounted) {
                                setState(() {
                                  resource['score'] = newScore;
                                  resource['user_vote'] = newVote;
                                });
                              }
                            },
                          ).upvote();
                        },
                      ),
                      Text(localScore.toString()),
                      IconButton(
                        icon: Icon(
                          Icons.arrow_downward,
                          color: localUserVote == -1 ? Colors.blue : Colors.grey,
                        ),
                        onPressed: () {
                          final newVote = localUserVote == -1 ? null : -1;
                          final scoreChange = newVote == null ? 1 : (localUserVote == 1 ? -2 : -1);
                          
                          setState(() {
                            localUserVote = newVote;
                            localScore = localScore + scoreChange;
                          });

                          VotingController(
                            context: context,
                            itemType: 'resource',
                            itemId: resourceId,
                            currentScore: localScore,
                            onScoreUpdated: (newScore) {
                              if (mounted) {
                                setState(() {
                                  resource['score'] = newScore;
                                  resource['user_vote'] = newVote;
                                });
                              }
                            },
                          ).downvote();
                        },
                      ),
                    ],
                  ),
                  if (isOwner)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditResourceScreen(resource: resource),
                              ),
                            ).then((_) => _fetchUserData());
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () => _confirmDeleteResource(context, resourceId, resourceName),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildForumItemCard(Map<String, dynamic> forumItem) {
    final forumItemId = forumItem['id'];
    final forumItemTitle = forumItem['title'] ?? 'Untitled Forum Item';
    final isOwner = forumItem['fk_user'] == userinfo.id;
    int localScore = forumItem['score'] ?? 0;
    int? localUserVote = forumItem['user_vote'];

    return StatefulBuilder(
      builder: (context, setState) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            children: [
              ListTile(
                title: Text(forumItemTitle),
                subtitle: Text('Created: ${forumItem['creation_date']}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DiscussionScreen(
                        itemId: forumItemId,
                        itemType: 'forum_item',
                      ),
                    ),
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_upward,
                          color: localUserVote == 1 ? Colors.orange : Colors.grey,
                        ),
                        onPressed: () {
                          final newVote = localUserVote == 1 ? null : 1;
                          final scoreChange = newVote == null ? -1 : (localUserVote == -1 ? 2 : 1);
                          
                          setState(() {
                            localUserVote = newVote;
                            localScore = localScore + scoreChange;
                          });

                          VotingController(
                            context: context,
                            itemType: 'forum_item',
                            itemId: forumItemId,
                            currentScore: localScore,
                            onScoreUpdated: (newScore) {
                              if (mounted) {
                                setState(() {
                                  forumItem['score'] = newScore;
                                  forumItem['user_vote'] = newVote;
                                });
                              }
                            },
                          ).upvote();
                        },
                      ),
                      Text(localScore.toString()),
                      IconButton(
                        icon: Icon(
                          Icons.arrow_downward,
                          color: localUserVote == -1 ? Colors.blue : Colors.grey,
                        ),
                        onPressed: () {
                          final newVote = localUserVote == -1 ? null : -1;
                          final scoreChange = newVote == null ? 1 : (localUserVote == 1 ? -2 : -1);
                          
                          setState(() {
                            localUserVote = newVote;
                            localScore = localScore + scoreChange;
                          });

                          VotingController(
                            context: context,
                            itemType: 'forum_item',
                            itemId: forumItemId,
                            currentScore: localScore,
                            onScoreUpdated: (newScore) {
                              if (mounted) {
                                setState(() {
                                  forumItem['score'] = newScore;
                                  forumItem['user_vote'] = newVote;
                                });
                              }
                            },
                          ).downvote();
                        },
                      ),
                    ],
                  ),
                  if (isOwner)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditForumScreen(forumItem: forumItem),
                              ),
                            ).then((_) => _fetchUserData());
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: () => _confirmDeleteForumItem(context, forumItemId, forumItemTitle),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final groupId = group['id'];
    final groupName = group['name'] ?? 'Untitled Group';
    final isOwner = group['is_owner'] == true;
    final isMember = group['is_member'] == true;
    int localScore = group['score'] ?? 0;
    int? localUserVote = group['user_vote'];

    return StatefulBuilder(
      builder: (context, setState) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            children: [
              ListTile(
                title: Text(groupName),
                subtitle: Text('Members: ${group['member_count'] ?? 0}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupDetailScreen(
                        groupId: groupId,
                        groupName: groupName,
                      ),
                    ),
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_upward,
                          color: localUserVote == 1 ? Colors.orange : Colors.grey,
                        ),
                        onPressed: () {
                          final newVote = localUserVote == 1 ? null : 1;
                          final scoreChange = newVote == null ? -1 : (localUserVote == -1 ? 2 : 1);
                          
                          setState(() {
                            localUserVote = newVote;
                            localScore = localScore + scoreChange;
                          });

                          VotingController(
                            context: context,
                            itemType: 'group',
                            itemId: groupId,
                            currentScore: localScore,
                            onScoreUpdated: (newScore) {
                              if (mounted) {
                                setState(() {
                                  group['score'] = newScore;
                                  group['user_vote'] = newVote;
                                });
                              }
                            },
                          ).upvote();
                        },
                      ),
                      Text(localScore.toString()),
                      IconButton(
                        icon: Icon(
                          Icons.arrow_downward,
                          color: localUserVote == -1 ? Colors.blue : Colors.grey,
                        ),
                        onPressed: () {
                          final newVote = localUserVote == -1 ? null : -1;
                          final scoreChange = newVote == null ? 1 : (localUserVote == 1 ? -2 : -1);
                          
                          setState(() {
                            localUserVote = newVote;
                            localScore = localScore + scoreChange;
                          });

                          VotingController(
                            context: context,
                            itemType: 'group',
                            itemId: groupId,
                            currentScore: localScore,
                            onScoreUpdated: (newScore) {
                              if (mounted) {
                                setState(() {
                                  group['score'] = newScore;
                                  group['user_vote'] = newVote;
                                });
                              }
                            },
                          ).downvote();
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isOwner)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditGroupScreen(group: group),
                              ),
                            ).then((_) => _fetchUserData());
                          },
                        ),
                      if (isMember)
                        IconButton(
                          icon: const Icon(Icons.exit_to_app, size: 20, color: Colors.red),
                          onPressed: () => _confirmLeaveGroup(context, groupId, groupName),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> updateProfilePicture(String newImageUrl, int userId) async {
    if (newImageUrl == "") newImageUrl = "default";

    final getIP = GetIP();
    final userIP = await getIP.getUserIP();
    final String apiUrl = '$userIP/profile_pic.php';
    final response = await http.post(
      Uri.parse(apiUrl),
      body: {
        'newImageUrl': newImageUrl,
        'Id': userId.toString(),
      },
    );

    if (response.statusCode == 200) {
      userinfo.imageURL = newImageUrl;
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile picture!')),
      );
    }
  }

  void _showImageUpdateDialog() {
    String newImageUrl = '';
    int userId = userinfo.id;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Profile Picture'),
          content: TextField(
            onChanged: (value) {
              newImageUrl = value;
            },
            decoration: const InputDecoration(hintText: 'Enter new image URL'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Submit'),
              onPressed: () {
                updateProfilePicture(newImageUrl, userId);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      actions: [
        PopupMenuButton<String>(
          onSelected: (selectChoice) {
            if (selectChoice == 'settings') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingScreen()),
              );
            }
          },
          itemBuilder: (BuildContext context) {
            return <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'settings',
                child: Text('Settings'),
              ),
            ];
          },
        ),
      ],
      elevation: 0.0,
      backgroundColor: const Color(0x00000000),
    ),
    body: SingleChildScrollView(
      child: Stack(
        children: [
          ClipPath(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: GestureDetector(
                      onTap: _showImageUpdateDialog,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: userinfo.imageURL != "default"
                                ? NetworkImage(userinfo.imageURL) as ImageProvider
                                : const AssetImage('assets/usericon.jpg') as ImageProvider,
                            onError: (_, __) {
                              setState(() {
                                userinfo.imageURL = "default";
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      userinfo.name,
                      style: const TextStyle(
                        fontFamily: "Karla",
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 190.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tests Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _isTestsExpanded 
                            ? Colors.deepPurple.withOpacity(0.2)
                            : Colors.transparent,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        title: Text('My Tests (${_userTests.length})'),
                        initiallyExpanded: _isTestsExpanded,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _isTestsExpanded = expanded;
                          });
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        collapsedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              ),
                            ),
                            child: _isLoadingTests
                                ? const Center(child: CircularProgressIndicator())
                                : _userTests.isEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text('No tests created yet'),
                                      )
                                    : Column(
                                        children: _userTests
                                            .map((test) => _buildTestCard(test))
                                            .toList(),
                                      ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Resources Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _isResourcesExpanded 
                            ? Colors.deepPurple.withOpacity(0.2)
                            : Colors.transparent,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        title: Text('My Resources (${_userResources.length})'),
                        initiallyExpanded: _isResourcesExpanded,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _isResourcesExpanded = expanded;
                          });
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        collapsedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              ),
                            ),
                            child: _isLoadingResources
                                ? const Center(child: CircularProgressIndicator())
                                : _userResources.isEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text('No resources created yet'),
                                      )
                                    : Column(
                                        children: _userResources
                                            .map((resource) => _buildResourceCard(resource))
                                            .toList(),
                                      ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Forum Items Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _isForumItemsExpanded 
                            ? Colors.deepPurple.withOpacity(0.2)
                            : Colors.transparent,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        title: Text('My Forum Posts (${_userForumItems.length})'),
                        initiallyExpanded: _isForumItemsExpanded,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _isForumItemsExpanded = expanded;
                          });
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        collapsedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              ),
                            ),
                            child: _isLoadingForumItems
                                ? const Center(child: CircularProgressIndicator())
                                : _userForumItems.isEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text('No forum posts created yet'),
                                      )
                                    : Column(
                                        children: _userForumItems
                                            .map((item) => _buildForumItemCard(item))
                                            .toList(),
                                      ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Groups Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _isGroupsExpanded 
                            ? Colors.deepPurple.withOpacity(0.2)
                            : Colors.transparent,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        title: Text('My Groups (${_userGroups.length})'),
                        initiallyExpanded: _isGroupsExpanded,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _isGroupsExpanded = expanded;
                          });
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        collapsedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              ),
                            ),
                            child: _isLoadingGroups
                                ? const Center(child: CircularProgressIndicator())
                                : _userGroups.isEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text('No groups joined yet'),
                                      )
                                    : Column(
                                        children: _userGroups
                                            .map((group) => _buildGroupCard(group))
                                            .toList(),
                                      ),
                          ),
                        ],
                      ),
                    ),
                  ),
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