import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'get_ip.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';

class TestSearchScreen extends StatefulWidget {
  const TestSearchScreen({super.key});

  @override
  State<TestSearchScreen> createState() => _TestSearchScreenState();
}

class _TestSearchScreenState extends State<TestSearchScreen> {
  late UserInfo userInfo;
  List<dynamic> results = [];
  int currentPage = 1;
  final int itemsPerPage = 10;
  int totalResults = 0;
  String sortOrder = 'desc';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = false;
  String? serverIP;

  @override
  void initState() {
    super.initState();
    userInfo = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    _initializeServerIP();
  }

  Future<void> _initializeServerIP() async {
    final getIP = GetIP();
    serverIP = await getIP.getUserIP();
  }

  Future<void> _performSearch() async {
    if (serverIP == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse(
        '$serverIP/search.php?'
        'query=${Uri.encodeComponent(searchQuery)}'
        '&page=$currentPage'
        '&per_page=$itemsPerPage'
        '&sort=$sortOrder'
        '&type=test'  // Only search for tests
        '&user_id=${userInfo.id}'
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

  void _goToPage(int page) {
    setState(() => currentPage = page);
    _performSearch();
  }

  Widget _buildTestCard(Map<String, dynamic> test) {
    final testName = test['name'] ?? 'Untitled Test';
    //final questionCount = test['question_count'] ?? 0;
    final creatorName = test['creator_name'] ?? 'Unknown';
    final creationDate = test['creation_date'] ?? 0;
    final isOwner = test['fk_user'] == userInfo.id;
    final isPrivate = test['visibility'] == 0 && isOwner;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(testName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Created: $creationDate'),
            Text('Created by: $creatorName'),
            if (isPrivate) 
              Text('Private', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        onTap: () {
          Navigator.pop(context, {
            'id': test['id'],
            'name': test['name'] ?? 'Untitled Test',
            'creation_date': creationDate,
            'creator_name': creatorName,
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Tests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tests...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      searchQuery = '';
                      results = [];
                    });
                  },
                ),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
              onSubmitted: (_) {
                _performSearch();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
                    ? Center(
                        child: Text(
                          searchQuery.isEmpty 
                              ? 'Search for tests'
                              : 'No tests found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          return _buildTestCard(results[index]);
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