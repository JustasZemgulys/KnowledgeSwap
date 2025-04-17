import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'get_ip.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';

class ResourceSearchScreen extends StatefulWidget {
  const ResourceSearchScreen({super.key});

  @override
  State<ResourceSearchScreen> createState() => _ResourceSearchScreenState();
}

class _ResourceSearchScreenState extends State<ResourceSearchScreen> {
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
    serverIP = await getUserIP();
  }

  Future<void> _performSearch() async {
    if (serverIP == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse(
        'https://juszem1-1.stud.if.ktu.lt/search.php?'
        'query=${Uri.encodeComponent(searchQuery)}'
        '&page=$currentPage'
        '&per_page=$itemsPerPage'
        '&sort=$sortOrder'
        '&type=resource'  // Only search for resources
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

Widget _buildResourcePreview(String iconPath, String filePath) {
  // Debug print to verify paths
  //debugPrint('Icon Path: $iconPath');
  //debugPrint('File Path: $filePath');

  // 1. Always try to show icon image first if available
  if (iconPath.isNotEmpty) {
    final iconUrl = 'https://juszem1-1.stud.if.ktu.lt/${iconPath.replaceAll(RegExp(r'^/+'), '')}';
    //debugPrint('Icon URL: $iconUrl');
    
    return Image.network(
      iconUrl,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const SizedBox(
          width: 40,
          height: 40,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Icon load error: $error');
        return _getFileTypeIcon(filePath);
      },
    );
  }
  
  // 2. No icon available - show file type specific icon
  return _getFileTypeIcon(filePath);
}

Widget _getFileTypeIcon(String filePath) {
  if (filePath.isEmpty) {
    return const Icon(Icons.insert_drive_file, size: 40);
  }
  
  // Show PDF icon only for PDF files with no icon image
  if (filePath.toLowerCase().endsWith('.pdf')) {
    return const Icon(Icons.picture_as_pdf, size: 40, color: Colors.red);
  }
  
  // Try to show preview for image files with no icon
  if (filePath.toLowerCase().endsWith('.jpg') || 
      filePath.toLowerCase().endsWith('.jpeg') ||
      filePath.toLowerCase().endsWith('.png')) {
    final imageUrl = 'https://juszem1-1.stud.if.ktu.lt/${filePath.replaceAll(RegExp(r'^/+'), '')}';
    debugPrint('File image URL: $imageUrl');
    
    return Image.network(
      imageUrl,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const SizedBox(
          width: 40,
          height: 40,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('File image load error: $error');
        return const Icon(Icons.insert_drive_file, size: 40);
      },
    );
  }
  
  // Default file icon
  return const Icon(Icons.insert_drive_file, size: 40);
}

Widget _buildResourceCard(Map<String, dynamic> resource) {
  final iconPath = (resource['resource_photo_link'] ?? '').trim().replaceAll(RegExp(r'^/+'), '');
  final filePath = (resource['resource_link'] ?? '').trim().replaceAll(RegExp(r'^/+'), '');
  final resourceName = resource['name'] ?? 'Untitled Resource';
  final isOwner = resource['fk_user'] == userInfo.id;
  final isPrivate = resource['visibility'] == 0 && isOwner;

  return Card(
    margin: const EdgeInsets.all(8.0),
    child: ListTile(
      leading: SizedBox(
        width: 40,
        height: 40,
        child: _buildResourcePreview(iconPath, filePath),
      ),
      title: Text(resourceName, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Uploaded: ${resource['creation_date']?.split(' ')[0] ?? 'Unknown'}'),
          if (isPrivate) 
            Text('Private', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
      onTap: () {
        Navigator.pop(context, {
          'id': resource['id'],
          'name': resource['name'] ?? 'Untitled Resource',
          'resource_link': resource['resource_link'] ?? '',
          'resource_photo_link': resource['resource_photo_link'] ?? '',
        });
      },
    ),
  );
}
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Resources'),
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
                hintText: 'Search resources...',
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
                              ? 'Search for resources'
                              : 'No resources found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          return _buildResourceCard(results[index]);
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