import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'package:http/http.dart' as http;
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
  String resourceType = 'all'; // 'all', 'resource', 'test'
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Resources'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _performSearch,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
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
                    ),
                    onChanged: (value) => searchQuery = value,
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
              ],
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
                          final item = results[index];
                          return Card(
                            margin: const EdgeInsets.all(8.0),
                            child: ListTile(
                              title: Text(item['name'] ?? 'Untitled'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Created: ${item['creation_date']}'),
                                  Text('By: ${item['creator_name'] ?? 'Unknown'}'),
                                ],
                              ),
                              // Add onTap functionality if needed
                            ),
                          );
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