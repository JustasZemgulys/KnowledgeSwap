import 'package:flutter/material.dart';
import 'package:knowledgeswap/discussion_ui.dart';
import 'package:knowledgeswap/edit_resource_ui.dart';
import 'package:knowledgeswap/edit_test_ui.dart';
import 'package:knowledgeswap/profile_details_ui.dart';
import 'package:knowledgeswap/take_test_ui.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'package:http/http.dart' as http;
import "package:universal_html/html.dart" as html;
import 'dart:convert';
import 'get_ip.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late UserInfo user_info;
  List<dynamic> results = [];
  int currentPage = 1;
  final int itemsPerPage = 10;
  int totalResults = 0;
  String sortOrder = 'desc';
  String searchQuery = '';
  String resourceType = 'all';
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = false;
  String? serverIP;

  @override
  void initState() {
    super.initState();
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    _initializeServerIP();
  }

  Future<void> _initializeServerIP() async {
    serverIP = await getUserIP();
  }

  Future<void> _performSearch() async {
    if (serverIP == null || searchQuery.isEmpty) return;

    setState(() {
      isLoading = true;
      currentPage = 1;
    });

    try {
      final url = Uri.parse(
        'http://$serverIP/search.php?'
        'query=${Uri.encodeComponent(searchQuery)}'
        '&page=$currentPage'
        '&per_page=$itemsPerPage'
        '&sort=$sortOrder'
        '&type=$resourceType'
        '&user_id=${user_info.id}'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          results = List<dynamic>.from(data['results']);
          totalResults = int.tryParse(data['total'].toString()) ?? 0;
          isLoading = false;
        });
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    }
  }

  Future<void> _downloadResource(Map<String, dynamic> resource) async {
    final resourcePath = resource['resource_link'] ?? '';
    final resourceName = resource['name'] ?? 'Untitled Resource';
    
    if (resourcePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No resource available')),
      );
      return;
    }

    try {
      final cleanPath = resourcePath.replaceAll(RegExp(r'^/+'), '');
      final fullUrl = 'http://$serverIP/$cleanPath';
      
      // Extract file extension
      final fileExt = resourcePath.split('.').last.toLowerCase();
      final mimeTypes = {
        'pdf': 'application/pdf',
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
      };
      final mimeType = mimeTypes[fileExt] ?? 'application/octet-stream';

      // Create download link
      // ignore: unused_local_variable
      final anchor = html.AnchorElement(href: fullUrl)
        ..setAttribute('download', resourceName)
        ..setAttribute('type', mimeType)
        ..click();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloading $resourceName...')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download resource: $e')),
      );
    }
  }

  void _goToPage(int page) {
    setState(() => currentPage = page);
    _performSearch();
  }

  Widget _buildSearchResultCard(Map<String, dynamic> item) {
    final isOwner = item['fk_user'] == user_info.id;
    final isTest = item['type'] == 'test';
    final itemId = item['id'];
    final isPrivate = item['visibility'] == 0;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(item['name'] ?? 'Untitled'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${isTest ? 'Test' : 'Resource'} • Created: ${item['creation_date']}'),
            Text('By: ${item['creator_name'] ?? 'Unknown'}'),
            if (isPrivate) Text('Private', style: TextStyle(color: Colors.grey)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            if (isTest)
              const PopupMenuItem(
                value: 'take_test',
                child: Text('Take Test'),
              ),
            if (!isTest)
              const PopupMenuItem(
                value: 'download',
                child: Text('Download'),
              ),
            const PopupMenuItem(
              value: 'discussions',
              child: ListTile(
                leading: Icon(Icons.forum, size: 20),
                title: Text('View Discussions', style: TextStyle(fontSize: 14)),
              ),
            ),
            if (isOwner) ...[
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ],
          onSelected: (value) async {
            if (value == 'take_test') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TakeTestScreen(testId: itemId),
                ),
              );
            } else if (value == 'download') {
              await _downloadResource(item);
            } else if (value == 'edit') {
              if (isTest) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditTestScreen(test: item),
                  ),
                ).then((_) => _performSearch());
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditResourceScreen(resource: item),
                  ),
                ).then((_) => _performSearch());
              }
            } else if (value == 'delete') {
              _confirmDeleteItem(context, itemId, item['name'], isTest);
            }  else if (value == 'discussions') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DiscussionScreen(
                    itemId: itemId,
                    itemType: 'test',
                  ),
                ),
              );
            }
          },
        ),
        onTap: () {
          if (isTest) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TakeTestScreen(testId: itemId),
              ),
            );
          } else {
            _downloadResource(item);
          }
        },
      ),
    );
  }

  Future<void> _confirmDeleteItem(BuildContext context, int itemId, String itemName, bool isTest) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${isTest ? 'Test' : 'Resource'}'),
        content: Text('Are you sure you want to delete "$itemName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteItem(itemId, isTest);
    }
  }

  Future<void> _deleteItem(int itemId, bool isTest) async {
    try {
      final endpoint = isTest ? 'delete_test.php' : 'delete_resource.php';
      final url = Uri.parse('http://$serverIP/$endpoint');
      final response = await http.post(
        url,
        body: {
          isTest ? 'test_id' : 'resource_id': itemId.toString(),
          'user_id': user_info.id.toString(),
        },
      );

      final responseData = json.decode(response.body);
      
      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${isTest ? 'Test' : 'Resource'} deleted successfully')),
        );
        _performSearch();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Failed to delete ${isTest ? 'test' : 'resource'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting ${isTest ? 'test' : 'resource'}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
        ),
        title: const Text('Search'),
        actions: [
          //IconButton(
          //  icon: const Icon(Icons.search),
          //  onPressed: _performSearch,
          //),
          //const SizedBox(width: 8),
          IconButton(
            icon: Image.asset("assets/usericon.jpg"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileDetailsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => searchQuery = '');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) => searchQuery = value,
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text('Filter:'),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: resourceType,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'resource', child: Text('Resources')),
                    DropdownMenuItem(value: 'test', child: Text('Tests')),
                  ],
                  onChanged: (value) {
                    setState(() => resourceType = value!);
                    _performSearch();
                  },
                ),
                const Spacer(),
                const Text('Sort:'),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: sortOrder,
                  items: const [
                    DropdownMenuItem(value: 'desc', child: Text('Newest first')),
                    DropdownMenuItem(value: 'asc', child: Text('Oldest first')),
                  ],
                  onChanged: (value) {
                    setState(() => sortOrder = value!);
                    _performSearch();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : results.isEmpty
                    ? const Center(child: Text('No results found'))
                    : ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          return _buildSearchResultCard(results[index]);
                        },
                      ),
          ),
          if (totalResults > itemsPerPage)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: currentPage > 1
                        ? () => _goToPage(currentPage - 1)
                        : null,
                  ),
                  Text('Page $currentPage of ${(totalResults / itemsPerPage).ceil()}'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: currentPage < (totalResults / itemsPerPage).ceil()
                        ? () => _goToPage(currentPage + 1)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}