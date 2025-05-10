import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:knowledgeswap/profile_details_ui.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'get_ip.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;

class CreateResourceScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final bool isEditMode;

  const CreateResourceScreen({super.key, this.initialData, this.isEditMode = false,});

  @override
  State<CreateResourceScreen> createState() => _CreateResourceScreenState();
}

class _CreateResourceScreenState extends State<CreateResourceScreen> {
  late UserInfo user_info;
  final TextEditingController _resourceNameController = TextEditingController();
  final TextEditingController _resourceDescriptionController = TextEditingController();
  int _resourceNameCharCount = 0;
  int _resourceDescriptionCharCount = 0;
  final int _maxResourceNameLength = 255;
  final int _maxResourceDescriptionLength = 255;
  
  PlatformFile? _selectedFile;
  String? _fileName;
  String? _fileType;
  Uint8List? _fileBytes;
  bool _isPrivate = false;
  bool _isUploading = false;

  Uint8List? _iconBytes;
  String? _iconName;
  String? _iconType;
  bool iconDelete = false;

  @override
  void initState() {
    super.initState();
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    
    // Initialize with existing data if editing
    if (widget.initialData != null) {
      _resourceNameController.text = widget.initialData!['name'] ?? '';
      _resourceDescriptionController.text = widget.initialData!['description'] ?? '';
      _isPrivate = widget.initialData!['visibility'] != 1;
      _fileName = widget.initialData!['resource_link'] != null 
          ? path.basename(widget.initialData!['resource_link']) 
          : null;
      _fileType = _fileName?.split('.').last.toLowerCase();
    }
    
    _resourceNameController.addListener(_updateResourceNameCharCount);
    _resourceDescriptionController.addListener(_updateResourceDescriptionCharCount);

    if (widget.initialData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingIcon();
        _loadExistingFile(); // Load the file too
      });
    }
  }

  Future<void> _uploadResource() async {
    if (_resourceNameController.text.isEmpty) {
      _showErrorSnackBar('Please enter a resource name');
      return;
    }

    if (widget.initialData == null && (_selectedFile == null || _fileBytes == null)) {
      _showErrorSnackBar('Please select a resource file to upload');
      return;
    }

    if (_selectedFile != null && !['pdf', 'jpg', 'jpeg', 'png'].contains(_fileType)) {
      _showErrorSnackBar('Only PDF, JPG, and PNG files are allowed for resources');
      return;
    }

    // Only validate icon file type if we're uploading a new icon (not removing it)
    if (_iconBytes != null && _iconBytes!.isNotEmpty && !['jpg', 'jpeg', 'png'].contains(_iconType)) {
      _showErrorSnackBar('Only JPG and PNG files are allowed for icons');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      if (widget.initialData != null) {
        await _updateResource();
      } else {
        await _createResource();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _createResource() async {
    try {
      final userIP = await getUserIP();
      final url = Uri.parse('$userIP/create_resource.php');

      var request = http.MultipartRequest('POST', url)
        ..fields['name'] = _resourceNameController.text
        ..fields['description'] = _resourceDescriptionController.text
        ..fields['visibility'] = _isPrivate ? '0' : '1'
        ..fields['fk_user'] = user_info.id.toString();

      request.files.add(http.MultipartFile.fromBytes(
        'resource_file',
        _fileBytes!,
        filename: _fileName,
      ));

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
          _showSuccessMessage('Resource uploaded successfully!');
          Navigator.pop(context, true); // Return true to indicate success
          return;
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
      _showErrorSnackBar('Error uploading: $e');
    }
  }

  Future<void> _updateResource() async {
    try {
      final userIP = await getUserIP();
      final url = Uri.parse('$userIP/update_resource.php');

      var request = http.MultipartRequest('POST', url)
        ..fields['resource_id'] = widget.initialData!['id'].toString()
        ..fields['name'] = _resourceNameController.text
        ..fields['description'] = _resourceDescriptionController.text
        ..fields['visibility'] = _isPrivate ? '0' : '1';

      // Add resource file if changed
      if (_fileBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'resource_file',
          _fileBytes!,
          filename: _fileName,
        ));
      }

      // Add new icon if provided (removal is handled separately)
      if (_iconBytes != null && _iconBytes!.isNotEmpty) {
        request.files.add(http.MultipartFile.fromBytes(
          'icon_file',
          _iconBytes!,
          filename: _iconName,
        ));
      } else if (_iconBytes == null && widget.initialData?['resource_photo_link'] != null) {
        // This indicates we want to remove the existing icon
        request.fields['remove_icon'] = '1';
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        if (jsonResponse['success'] == true) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Resource updated successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _showErrorSnackBar(jsonResponse['message'] ?? 'Update failed');
        }
      } else {
        _showErrorSnackBar('Server error: ${response.statusCode}');
      }
    } on SocketException {
      _showErrorSnackBar('Network error - check connection');
    } on TimeoutException {
      _showErrorSnackBar('Request timed out');
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  Future<void> _loadExistingIcon() async {
    // Check if we have valid initial data and a non-empty photo link
    if (widget.initialData == null || 
        widget.initialData!['resource_photo_link'] == null || 
        (widget.initialData!['resource_photo_link'] as String).trim().isEmpty) {
      //print('No icon available for this resource');
      return;
    }

    final iconPath = widget.initialData!['resource_photo_link'].trim();
    //print('Attempting to load icon from path: $iconPath');

    try {
      final userIP = await getUserIP();
      final encodedPath = Uri.encodeComponent(iconPath);
      final url = Uri.parse('$userIP/image_proxy.php?path=$encodedPath');
      
      //print('Loading icon from: ${url.toString()}');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final contentType = response.headers['content-type']?.toLowerCase();
        if (contentType?.startsWith('image/') ?? false) {
          setState(() {
            _iconBytes = response.bodyBytes;
            _iconName = path.basename(iconPath);
            _iconType = _iconName?.split('.').last.toLowerCase();
          });
          //print('Successfully loaded icon');
        } else {
          //print('Received non-image content. Type: $contentType');
        }
      } else {
        //print('Failed to load icon. Status: ${response.statusCode}');
        //print('Response: ${response.body}');
      }
    } catch (e) {
      //print('Error loading icon: $e');
    }
  }

  Future<void> _loadExistingFile() async {
    if (widget.initialData == null || 
        widget.initialData!['resource_link'] == null || 
        (widget.initialData!['resource_link'] as String).trim().isEmpty) {
      //print('No file available for this resource');
      return;
    }

    final filePath = widget.initialData!['resource_link'].trim();
    //print('Attempting to load file from path: $filePath');

    try {
      final userIP = await getUserIP();
      final encodedPath = Uri.encodeComponent(filePath);
      final fileType = path.basename(filePath).split('.').last.toLowerCase();
      
      // For images, use the image proxy
      if (fileType == 'jpg' || fileType == 'jpeg' || fileType == 'png') {
        final url = Uri.parse('$userIP/image_proxy.php?path=$encodedPath');
        //print('Loading image file from proxy: ${url.toString()}');
        final response = await http.get(url);
        
        if (response.statusCode == 200) {
          setState(() {
            _fileBytes = response.bodyBytes;
            _fileName = path.basename(filePath);
            _fileType = fileType;
            _selectedFile = PlatformFile(
              name: _fileName!,
              size: response.bodyBytes.length,
              bytes: response.bodyBytes,
            );
          });
          //print('Successfully loaded image file');
          return;
        }
      }
      
      // For PDFs or if image proxy fails, try direct download
      final directUrl = Uri.parse('$userIP/download_file.php?path=$encodedPath');
      final response = await http.get(directUrl);
      
      if (response.statusCode == 200) {
        setState(() {
          _fileBytes = response.bodyBytes;
          _fileName = path.basename(filePath);
          _fileType = fileType;
          _selectedFile = PlatformFile(
            name: _fileName!,
            size: response.bodyBytes.length,
            bytes: response.bodyBytes,
          );
        });
      } else {
        setState(() {
          _fileName = path.basename(filePath);
          _fileType = fileType;
        });
      }
    } catch (e) {
      setState(() {
        _fileName = path.basename(widget.initialData!['resource_link']);
        _fileType = _fileName?.split('.').last.toLowerCase();
      });
    }
  }

  @override
  void dispose() {
    _resourceNameController.dispose();
    _resourceDescriptionController.dispose();
    super.dispose();
  }

  void _updateResourceNameCharCount() {
    setState(() {
      _resourceNameCharCount = _resourceNameController.text.length;
    });
  }

  void _updateResourceDescriptionCharCount() {
    setState(() {
      _resourceDescriptionCharCount = _resourceDescriptionController.text.length;
    });
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _fileName = _selectedFile!.name;
          _fileType = _selectedFile!.extension?.toLowerCase();
          _fileBytes = _selectedFile!.bytes;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking file: $e');
    }
  }

  Future<void> _takePhoto() async {
    if (kIsWeb) {
      _showErrorSnackBar('Camera not supported on web');
      return;
    }

    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
      
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        setState(() {
          _fileName = path.basename(pickedFile.path);
          _fileType = 'jpg';
          _fileBytes = file.readAsBytesSync();
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error taking photo: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    //print('Showing error snackbar: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
      ),
    );
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

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _deleteIcon() async {
    if (widget.initialData == null || widget.initialData!['id'] == null) {
      // If we're not editing or don't have a resource ID, just clear the local icon
      setState(() {
        _iconBytes = null;
        _iconName = null;
        _iconType = null;
      });
      return;
    }

    try {
      final userIP = await getUserIP();
      final url = '$userIP/delete_icon.php';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'resource_id': widget.initialData!['id']}),
      );

      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true) {
        setState(() {
          _iconBytes = null;
          _iconName = null;
          _iconType = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Icon removed successfully')),
        );
      } else {
        throw Exception(responseData['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove icon: $e')),
      );
    }
  }

  Widget _buildIconPreview() {
    return Row(
      children: [
        // Icon Preview
        if (_iconBytes != null && _iconBytes!.isNotEmpty)
          Image.memory(
            _iconBytes!,
            height: 150,
            width: 150,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.broken_image, size: 60, color: Colors.red);
            },
          )
        else if (widget.isEditMode && widget.initialData?['resource_photo_link'] != null && 
                _iconBytes == null) // Only show if we haven't marked for deletion
          const Icon(Icons.image, size: 60, color: Colors.blue)
        else
          const Icon(Icons.photo_camera, size: 60, color: Colors.grey),
        
        // Remove Icon Button (only shown when there's an icon)
        if ((_iconBytes != null && _iconBytes!.isNotEmpty) || 
            (widget.isEditMode && widget.initialData?['resource_photo_link'] != null && _iconBytes == null))
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

  Widget _buildFilePreview() {
    // Show selected new file if available
    if (_fileBytes != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //const Text(
          //  'Selected file:',
          //  style: TextStyle(fontWeight: FontWeight.bold),
          //),
          //const SizedBox(height: 10),
          if (_fileType == 'jpg' || _fileType == 'jpeg' || _fileType == 'png')
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 200,
                maxWidth: MediaQuery.of(context).size.width,
              ),
              child: Image.memory(
                _fileBytes!,
                fit: BoxFit.contain,
              ),
            )
          else if (_fileType == 'pdf')
            const Icon(Icons.picture_as_pdf, size: 100, color: Colors.red)
          else
            const Icon(Icons.insert_drive_file, size: 100),
          const SizedBox(height: 10),
          Text(
            '${_fileName ?? 'No filename'} (${_fileType?.toUpperCase()})',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      );
    }

    // Show existing file info when editing
    if (widget.isEditMode && widget.initialData?['resource_link'] != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current file:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (_fileType == 'pdf')
            const Icon(Icons.picture_as_pdf, size: 100, color: Colors.red)
          else if (_fileType == 'jpg' || _fileType == 'jpeg' || _fileType == 'png')
            _fileBytes != null 
              ? ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 200,
                    maxWidth: MediaQuery.of(context).size.width,
                  ),
                  child: Image.memory(
                    _fileBytes!,
                    fit: BoxFit.contain,
                  ),
                )
              : const CircularProgressIndicator()
          else
            const Icon(Icons.insert_drive_file, size: 100),
          const SizedBox(height: 10),
          Text(
            _fileName ?? 'Loading...',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 5),
          const Text(
            '(Select a new file to replace)',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      );
    }

    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditMode ? "Edit Resource" : "Create a Resource",
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
              controller: _resourceNameController,
              maxLength: _maxResourceNameLength,
              decoration: InputDecoration(
                labelText: "Resource Name*",
                hintText: "Enter the resource name here",
                border: const OutlineInputBorder(),
                counterText: "$_resourceNameCharCount/$_maxResourceNameLength",
                counterStyle: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _resourceDescriptionController,
              maxLength: _maxResourceDescriptionLength,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: "Description",
                hintText: "Enter the resource description here",
                border: const OutlineInputBorder(),
                counterText: "$_resourceDescriptionCharCount/$_maxResourceDescriptionLength",
                counterStyle: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Choose File'),
                    onPressed: _pickFile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                if (!kIsWeb) const SizedBox(width: 10),
                if (!kIsWeb)
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                      onPressed: _takePhoto,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              'Allowed file types: PDF, JPG, PNG',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            if (_selectedFile != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected file:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildFilePreview(),
                ],
              ),
            const SizedBox(height: 20),
            const Text(
              'Resource Icon (Optional):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text('Select Icon'),
              onPressed: _pickIcon,
            ),
            const SizedBox(height: 5),
            const Text(
              'Allowed file types: JPG, PNG',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            _buildIconPreview(),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Make this resource private'),
              subtitle: const Text('Private resources are only visible to you'),
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
                onPressed: _isUploading ? null : _uploadResource,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
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
                        widget.isEditMode ? 'Update Resource' : 'Upload Resource',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}