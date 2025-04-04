import 'dart:math';

import 'package:flutter/material.dart';
import 'package:knowledgeswap/discussion_ui.dart';
import 'package:knowledgeswap/resource_test_generator.dart';
import 'package:knowledgeswap/web_storage.dart';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'get_ip.dart';
import 'package:universal_html/html.dart' as html; // For web download functionality

class ResourceScreen extends StatefulWidget {
  final int initialPage;
  final String initialSort;
  final bool selectMode;

  const ResourceScreen({
    super.key,
    this.initialPage = 1,
    this.initialSort = 'desc',
    this.selectMode = false,
  });


  @override
  State<ResourceScreen> createState() => _ResourceScreenState();
}

class _ResourceScreenState extends State<ResourceScreen> {
  late UserInfo user_info;
  late int currentPage;
  late String sortOrder;
  List<dynamic> resources = [];
  int itemsPerPage = 6;
  int totalResources = 0;
  bool isLoading = true;
  String? serverIP;

  @override
  void initState() {
    currentPage = widget.initialPage;
    sortOrder = widget.initialSort;
    super.initState();
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    _initializeServerIP();
  }

  Future<void> _initializeServerIP() async {
    try {
      serverIP = await getUserIP();
      _fetchResources();
    } catch (e) {
      //print('Error initializing server IP: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to server: $e')),
      );
    }
  }

  Future<void> _fetchResources() async {
    if (serverIP == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse('http://$serverIP/get_resources.php?page=$currentPage&per_page=$itemsPerPage&sort=$sortOrder&user_id=${user_info.id}');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        totalResources = int.tryParse(data['total'].toString()) ?? 0;
        
        // If we got an empty page but it's not the first page, try previous pages
        if (data['resources'].isEmpty && currentPage > 1) {
          currentPage--;
          _fetchResources();
          return;
        }

        setState(() {
          resources = List<dynamic>.from(data['resources']);
          isLoading = false;
        });
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading resources: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }


  void _changeSortOrder(String newOrder) {
    setState(() {
      sortOrder = newOrder;
      currentPage = 1;
    });
    _fetchResources();
  }

  void _goToPage(int page) {
    setState(() {
      currentPage = page;
    });
    _fetchResources();
  }

  Future<void> _downloadResource(String resourcePath, String resourceName) async {
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
      //print('Error downloading resource: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download resource: $e')),
      );
    }
  }

  Future<void> _editResource(BuildContext context, Map<String, dynamic> resource) async {
    final result = await Navigator.pushNamed(
      context,
      '/edit-resource',
      arguments: resource,
    );
    
    if (result == true) {
      _fetchResources(); // Refresh the list after editing
    }
  }

  Future<void> _confirmDeleteResource(BuildContext context, int resourceId, String resourceName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Resource'),
        content: Text('Are you sure you want to delete "$resourceName"?'),
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
      await _deleteResource(resourceId);
    }
  }

  Future<void> _deleteResource(int resourceId) async {
    try {
      final url = Uri.parse('http://$serverIP/delete_resource.php');
      final response = await http.post(
        url,
        body: {'resource_id': resourceId.toString()},
      );

      final responseData = json.decode(response.body);
      
      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resource deleted successfully')),
        );
        _fetchResources(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Failed to delete resource')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting resource: $e')),
      );
    }
  }

  Widget _buildResourcePreview(String path, String resourceName) {
    if (path.isEmpty) {
      return Container(
        height: 100,
        width: 100,
        child: const Icon(Icons.insert_drive_file, size: 60),
      );
    }

    final proxyUrl = 'http://$serverIP/image_proxy.php?path=${Uri.encodeComponent(path)}';

    // Check if it's a PDF (for the actual resource)
    if (path.toLowerCase().endsWith('.pdf')) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf, size: 60, color: Colors.red),
          SizedBox(height: 8),
          Text('PDF Document'),
        ],
      );
    }

    // Handle image files
    return Image.network(
      proxyUrl,
      fit: BoxFit.contain,
      headers: {'Accept': 'image/*'},
      errorBuilder: (context, error, stackTrace) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, size: 60),
            Text('Failed to load preview'),
          ],
        );
      },
    );
  }

  Widget _buildResourceCard(Map<String, dynamic> resource) {
    final previewPath = (resource['resource_photo_link'] ?? '').trim().replaceAll(RegExp(r'^/+'), '');
    final resourcePath = (resource['resource_link'] ?? '').trim().replaceAll(RegExp(r'^/+'), '');
    final resourceName = resource['name'] ?? 'Untitled Resource';
    final resourceId = resource['id'];
    final isOwner = resource['fk_user'] == user_info.id;
    final isPrivate = resource['visibility'] == 0 && isOwner;

    // If in selection mode, show a simplified card
    if (widget.selectMode) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            Navigator.pop(context, {
              'id': resourceId,
              'name': resourceName,
              'path': resourcePath,
            });
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      color: Colors.transparent,
                    ),
                    child: Center(
                      child: _buildResourcePreview(
                        previewPath.isNotEmpty ? previewPath : resourcePath, 
                        resourceName
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                    color: Colors.transparent,
                  ),
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resourceName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Uploaded: ${resource['creation_date']?.split(' ')[0] ?? 'Unknown'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (isPrivate)
                            Text(
                              'Private',
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
          ),
        ),
      );
    }

    // Original card implementation for normal mode
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _downloadResource(resourcePath, resourceName),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                            color: Colors.transparent,
                          ),
                          child: Center(
                            child: _buildResourcePreview(
                              previewPath.isNotEmpty ? previewPath : resourcePath, 
                              resourceName
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                          color: Colors.transparent,
                        ),
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resourceName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Uploaded: ${resource['creation_date']?.split(' ')[0] ?? 'Unknown'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (isPrivate)
                                  Text(
                                    'Private',
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
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'generate_test',
                        child: ListTile(
                          leading: Icon(Icons.quiz, size: 20),
                          title: Text('Generate Test', style: TextStyle(fontSize: 14)),
                        ),
                      ),
                      const PopupMenuItem( // Always available option
                        value: 'discussions',
                        child: ListTile(
                          leading: Icon(Icons.forum, size: 20),
                          title: Text('View Discussions', style: TextStyle(fontSize: 14)),
                        ),
                      ),
                      if (isOwner) ...[
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit, size: 20),
                            title: Text('Edit Resource', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, size: 20, color: Colors.red),
                            title: Text('Delete Resource', style: TextStyle(fontSize: 14, color: Colors.red)),
                          ),
                        )
                      ],
                    ],
                    onSelected: (value) async {
                      if (value == 'generate_test') {
                        ResourceTestGenerator.navigateToConfigScreen(
                          context: context,
                          resourceId: resourceId,
                          userId: user_info.id,
                          resourceName: resourceName,
                        );
                      } else if (value == 'edit') {
                        _editResource(context, resource);
                      } else if (value == 'delete') {
                        _confirmDeleteResource(context, resourceId, resourceName);
                      }  else if (value == 'discussions') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DiscussionScreen(
                              itemId: resourceId,
                              itemType: 'resource',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WebStorage.saveLastRoute(ModalRoute.of(context)?.settings.name ?? '');
    });
  
    return Scaffold(
      appBar: widget.selectMode
          ? AppBar(
              title: const Text('Select a Resource'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
              ),
              iconTheme: const IconThemeData(color: Colors.black),
              actions: [
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/create-resource',
                    arguments: {'returnPage': currentPage, 'returnSort': sortOrder},
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Create Resource"),
                ),
                const SizedBox(width: 1),
                IconButton(
                  icon: Image.asset("assets/usericon.jpg"),
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
                ),
              ],
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
      body: Column(
        children: [
          if (!widget.selectMode) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  const Text('Sort by date: '),
                  DropdownButton<String>(
                    value: sortOrder,
                    items: const [
                      DropdownMenuItem(value: 'desc', child: Text('Newest first')),
                      DropdownMenuItem(value: 'asc', child: Text('Oldest first')),
                    ],
                    onChanged: (value) => _changeSortOrder(value!),
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : resources.isEmpty
                    ? const Center(child: Text('No resources found'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: widget.selectMode ? 1 : 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: widget.selectMode ? 1.5 : 0.9,
                        ),
                        itemCount: resources.length,
                        itemBuilder: (context, index) {
                          return _buildResourceCard(resources[index]);
                        },
                      ),
          ),
          if (!widget.selectMode) ...[
            Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: currentPage > 1
                      ? () => _goToPage(currentPage - 1)
                      : null,
                ),
                Text('Page $currentPage of ${max(1, (totalResources / itemsPerPage).ceil())}'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: currentPage < (totalResources / itemsPerPage).ceil() && resources.length >= itemsPerPage
                      ? () => _goToPage(currentPage + 1)
                      : null,
                ),
              ],
            ),
          ),
          ],
        ],
      ),
    );
  }
}
