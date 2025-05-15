import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:knowledgeswap/profile_details_ui.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'get_ip.dart';
import 'package:flutter/foundation.dart' show Uint8List;

class CreateGroupScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final bool isEditMode;
  final VoidCallback? onGroupUpdated;

  const CreateGroupScreen({super.key, this.initialData, this.isEditMode = false, this.onGroupUpdated});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  late UserInfo user_info;
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController = TextEditingController();
  int _groupNameCharCount = 0;
  int _groupDescriptionCharCount = 0;
  final int _maxGroupNameLength = 100;
  final int _maxGroupDescriptionLength = 500;
  
  Uint8List? _iconBytes;
  String? _iconName;
  String? _iconType;
  bool _isPrivate = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    
    // Initialize with existing data if editing
    if (widget.initialData != null) {
      _groupNameController.text = widget.initialData!['name'] ?? '';
      _groupDescriptionController.text = widget.initialData!['description'] ?? '';
      _isPrivate = widget.initialData!['visibility'] != 1;
    }
    
    _groupNameController.addListener(_updateGroupNameCharCount);
    _groupDescriptionController.addListener(_updateGroupDescriptionCharCount);

    if (widget.initialData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingIcon();
      });
    }
  }

  Future<void> _createOrUpdateGroup() async {
    if (_groupNameController.text.isEmpty) {
      _showErrorSnackBar('Please enter a group name');
      return;
    }

    // Only validate icon file type if we're uploading a new icon
    if (_iconBytes != null && _iconBytes!.isNotEmpty && !['jpg', 'jpeg', 'png'].contains(_iconType)) {
      _showErrorSnackBar('Only JPG and PNG files are allowed for icons');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      if (widget.initialData != null) {
        await _updateGroup();
      } else {
        await _createGroup();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _createGroup() async {
    try {
      final getIP = GetIP();
      final IP = await getIP.getUserIP();
      final url = Uri.parse('$IP/create_group.php');
      var request = http.MultipartRequest('POST', url)
        ..fields['name'] = _groupNameController.text
        ..fields['description'] = _groupDescriptionController.text
        ..fields['visibility'] = _isPrivate ? '0' : '1'
        ..fields['fk_user'] = user_info.id.toString();

      if (_iconBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'icon_file',
          _iconBytes!,
          filename: _iconName,
        ));
      }

      final response = await request.send().timeout(const Duration(seconds: 30));
      final responseData = await response.stream.bytesToString();
      final decodedResponse = jsonDecode(responseData);

      if (response.statusCode == 200) {
        if (decodedResponse['success'] == true) {
          _showSuccessMessage('Group created successfully!');
          Navigator.pop(context, {
            'refresh': true,
            'newGroup': decodedResponse['group_id'],
          });
        } else {
          _showErrorSnackBar('Error: ${decodedResponse['message']}');
        }
      } else {
        _showErrorSnackBar('Upload failed: ${decodedResponse['message'] ?? 'Server error'}');
      }
    } on SocketException {
      _showErrorSnackBar('Network error: Please check your connection');
    } on TimeoutException {
      _showErrorSnackBar('Request timed out. Please try again');
    } catch (e) {
      _showErrorSnackBar('Error creating group: $e');
    }
  }

  Future<void> _updateGroup() async {
    try {
      final getIP = GetIP();
      final userIP = await getIP.getUserIP();
      final url = Uri.parse('$userIP/update_group.php');

      var request = http.MultipartRequest('POST', url)
        ..fields['group_id'] = widget.initialData!['id'].toString()
        ..fields['name'] = _groupNameController.text
        ..fields['description'] = _groupDescriptionController.text
        ..fields['visibility'] = _isPrivate ? '0' : '1';

      if (_iconBytes != null && _iconBytes!.isNotEmpty) {
        request.files.add(http.MultipartFile.fromBytes(
          'icon_file',
          _iconBytes!,
          filename: _iconName,
        ));
      } else if (_iconBytes == null && widget.initialData?['icon_path'] != null) {
        request.fields['remove_icon'] = '1';
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        if (jsonResponse['success'] == true) {
          // Call the callback if it exists
          if (widget.onGroupUpdated != null) {
            widget.onGroupUpdated!();
          } else {
            Navigator.pop(context, true); // Fallback if no callback
          }
        } else {
          _showErrorSnackBar(jsonResponse['message'] ?? 'Update failed');
        }
      } else {
        _showErrorSnackBar('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  Future<void> _loadExistingIcon() async {
    if (widget.initialData == null || 
        widget.initialData!['icon_path'] == null || 
        (widget.initialData!['icon_path'] as String).trim().isEmpty) {
      return;
    }

    final iconPath = widget.initialData!['icon_path'].trim();

    try {
      final getIP = GetIP();
      final userIP = await getIP.getUserIP();
      final encodedPath = Uri.encodeComponent(iconPath);
      final url = Uri.parse('$userIP/image_proxy.php?path=$encodedPath');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final contentType = response.headers['content-type']?.toLowerCase();
        if (contentType?.startsWith('image/') ?? false) {
          setState(() {
            _iconBytes = response.bodyBytes;
            _iconName = path.basename(iconPath);
            _iconType = _iconName?.split('.').last.toLowerCase();
          });
        }
      }
    } catch (e) {
      // Error loading icon - we'll just proceed without it
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
    super.dispose();
  }

  void _updateGroupNameCharCount() {
    setState(() {
      _groupNameCharCount = _groupNameController.text.length;
    });
  }

  void _updateGroupDescriptionCharCount() {
    setState(() {
      _groupDescriptionCharCount = _groupDescriptionController.text.length;
    });
  }

  Future<void> _pickIcon() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (!['jpg', 'jpeg', 'png'].contains(file.extension?.toLowerCase())) {
          _showErrorSnackBar('Please select a JPG or PNG image');
          return;
        }
        
        setState(() {
          _iconName = file.name;
          _iconType = file.extension?.toLowerCase();
          _iconBytes = file.bytes;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking icon: ${e.toString()}');
    }
  }

  Future<void> _deleteIcon() async {
    if (widget.initialData == null || widget.initialData!['id'] == null) {
      // If we're not editing or don't have a group ID, just clear the local icon
      setState(() {
        _iconBytes = null;
        _iconName = null;
        _iconType = null;
      });
      return;
    }

    // For editing, we'll handle icon removal in the update request
    setState(() {
      _iconBytes = null;
      _iconName = null;
      _iconType = null;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Widget _buildIconPreview() {
    return Row(
      children: [
        // Icon Preview
        if (_iconBytes != null && _iconBytes!.isNotEmpty)
          CircleAvatar(
            radius: 50,
            backgroundImage: MemoryImage(_iconBytes!),
          )
        else if (widget.isEditMode && widget.initialData?['icon_path'] != null && 
                _iconBytes == null) // Only show if we haven't marked for deletion
          const CircleAvatar(
            radius: 50,
            child: Icon(Icons.group, size: 40),
          )
        else
          const CircleAvatar(
            radius: 50,
            child: Icon(Icons.camera_alt, size: 30),
          ),
        
        // Remove Icon Button (only shown when there's an icon)
        if ((_iconBytes != null && _iconBytes!.isNotEmpty) || 
            (widget.isEditMode && widget.initialData?['icon_path'] != null && _iconBytes == null))
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: _deleteIcon,
              child: const Text('Remove'),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditMode ? "Edit Group" : "Create a Group",
          style: TextStyle(color: Colors.deepPurple),
          ),
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        actions: [
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
        elevation: 0,
        backgroundColor: const Color(0x00000000),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _groupNameController,
              maxLength: _maxGroupNameLength,
              decoration: InputDecoration(
                labelText: "Group Name*",
                hintText: "Enter the group name here",
                border: const OutlineInputBorder(),
                counterText: "$_groupNameCharCount/$_maxGroupNameLength",
                counterStyle: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _groupDescriptionController,
              maxLength: _maxGroupDescriptionLength,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: "Description",
                hintText: "Enter the group description here",
                border: const OutlineInputBorder(),
                counterText: "$_groupDescriptionCharCount/$_maxGroupDescriptionLength",
                counterStyle: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Group Icon (Optional):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text('Select Icon'),
              onPressed: _pickIcon,
            ),
            const SizedBox(height: 10),
            _buildIconPreview(),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Make this group private'),
              subtitle: const Text('Private groups require approval to join'),
              value: _isPrivate,
              onChanged: (bool value) {
                setState(() {
                  _isPrivate = value;
                });
              },
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _isUploading ? null : _createOrUpdateGroup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  //backgroundColor: Colors.blue[700],
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.isEditMode ? 'Update Group' : 'Create Group',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}