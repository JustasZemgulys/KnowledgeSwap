import 'package:flutter/material.dart';
import 'package:knowledgeswap/resource_test_handler.dart';
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

  const ResourceScreen({
    super.key,
    this.initialPage = 1,
    this.initialSort = 'desc',
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
      print('Error initializing server IP: $e');
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
      final url = Uri.parse('http://$serverIP/get_resources.php?page=$currentPage&per_page=$itemsPerPage&sort=$sortOrder');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        totalResources = int.tryParse(data['total'].toString()) ?? 0;

        setState(() {
          resources = List<dynamic>.from(data['resources']);
          isLoading = false;
        });
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching resources: $e');
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
      final anchor = html.AnchorElement(href: fullUrl)
        ..setAttribute('download', resourceName)
        ..setAttribute('type', mimeType)
        ..click();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloading $resourceName...')),
      );
    } catch (e) {
      print('Error downloading resource: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download resource: $e')),
      );
    }
  }

  Widget _buildResourceCard(Map<String, dynamic> resource) {
    final previewPath = (resource['resource_photo_link'] ?? '').trim().replaceAll(RegExp(r'^/+'), '');
    final resourcePath = (resource['resource_link'] ?? '').trim().replaceAll(RegExp(r'^/+'), '');
    final resourceName = resource['name'] ?? 'Untitled Resource';
    final resourceId = resource['id']; // Get resource ID from the resource data

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
                            child: _buildResourcePreview(previewPath.isNotEmpty ? previewPath : resourcePath, resourceName),
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
                            Text(
                              'Uploaded: ${resource['creation_date']?.split(' ')[0] ?? 'Unknown'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
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
                    ],
                    /*onSelected: (value) async {
                      if (value == 'generate_test') {
                        await ResourceTestHandler.handleResourceTestCreation(
                          context: context,
                          resourceId: resourceId,
                          userId: user_info.id,
                          resourceName: resourceName,
                        );
                      }
                    },*/
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WebStorage.saveLastRoute(ModalRoute.of(context)?.settings.name ?? '');
    });
  
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context, {
            'page': currentPage,
            'sort': sortOrder,
          }),
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
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : resources.isEmpty
                    ? const Center(child: Text('No resources found'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: resources.length,
                        itemBuilder: (context, index) {
                          return _buildResourceCard(resources[index]);
                        },
                      ),
          ),
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
                Text('Page $currentPage of ${(totalResources / itemsPerPage).ceil()}'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: currentPage < (totalResources / itemsPerPage).ceil()
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
