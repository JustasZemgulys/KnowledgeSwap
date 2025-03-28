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
  const CreateResourceScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    _resourceNameController.addListener(_updateResourceNameCharCount);
    _resourceDescriptionController.addListener(_updateResourceDescriptionCharCount);
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
      print('Starting file picker...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        print('File selected: ${result.files.first.name}');
        setState(() {
          _selectedFile = result.files.first;
          _fileName = _selectedFile!.name;
          _fileType = _selectedFile!.extension?.toLowerCase();
          _fileBytes = _selectedFile!.bytes;
        });
      } else {
        print('No file selected or selection cancelled');
      }
    } catch (e) {
      print('Error in _pickFile: $e');
      _showErrorSnackBar('Error picking file: $e');
    }
  }

  Future<void> _takePhoto() async {
    if (kIsWeb) {
      print('Camera not supported on web platform');
      _showErrorSnackBar('Camera not supported on web');
      return;
    }

    try {
      print('Launching camera...');
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
      
      if (pickedFile != null) {
        print('Photo taken: ${pickedFile.path}');
        final file = File(pickedFile.path);
        setState(() {
          _fileName = path.basename(pickedFile.path);
          _fileType = 'jpg';
          _fileBytes = file.readAsBytesSync();
        });
      } else {
        print('No photo taken or operation cancelled');
      }
    } catch (e) {
      print('Error in _takePhoto: $e');
      _showErrorSnackBar('Error taking photo: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    print('Showing error snackbar: $message');
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

  Widget _buildIconPreview() {
    if (_iconBytes == null) {
      print('No icon to preview');
      return Container();
    }
    
    print('Building icon preview');
    return Column(
      children: [
        Image.memory(
          _iconBytes!,
          height: 100,
          width: 100,
          fit: BoxFit.cover,
        ),
        Text(
          'Icon: $_iconName',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _uploadResource() async {

    if (_resourceNameController.text.isEmpty) {
      _showErrorSnackBar('Please enter a resource name');
      return;
    }

    if (_selectedFile == null || _fileBytes == null) {
      _showErrorSnackBar('Please select a resource file to upload');
      return;
    }

    if (!['pdf', 'jpg', 'jpeg', 'png'].contains(_fileType)) {
      _showErrorSnackBar('Only PDF, JPG, and PNG files are allowed for resources');
      return;
    }

    if (_iconBytes != null && !['jpg', 'jpeg', 'png'].contains(_iconType)) {
      _showErrorSnackBar('Only JPG and PNG files are allowed for icons');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final userIP = await getUserIP();
      final url = Uri.parse('http://$userIP/upload_resource.php');

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

      try {
        final decodedResponse = jsonDecode(responseData);

        if (response.statusCode == 200) {
          if (decodedResponse['success'] == true) {
            
            _showSuccessMessage('Resource uploaded successfully!');
            _resetForm();
          } else {
            _showErrorSnackBar('Error: ${decodedResponse['message']}');
          }
        } else {
          _showErrorSnackBar('Upload failed: ${decodedResponse['message'] ?? 'Server error'}');
        }
      } catch (e) {
        _showErrorSnackBar('Error processing server response');
      }
    } on SocketException {
      _showErrorSnackBar('Network error: Please check your connection');
    } on TimeoutException {
      _showErrorSnackBar('Request timed out. Please try again');
    } catch (e) {
      _showErrorSnackBar('Error uploading: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showSuccessMessage(String message) {
    print('Showing success message: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
      ),
    );
  }
  
  void _resetForm() {
    print('Resetting form...');
    _resourceNameController.clear();
    _resourceDescriptionController.clear();
    setState(() {
      _selectedFile = null;
      _fileName = null;
      _fileType = null;
      _fileBytes = null;
      _iconName = null;
      _iconType = null;
      _iconBytes = null;
      _isPrivate = false;
      _resourceNameCharCount = 0;
      _resourceDescriptionCharCount = 0;
    });
    print('Form reset complete');
  }

  Widget _buildFilePreview() {
    if (_fileBytes == null) {
      return Container();
    }

    if (_fileType == 'jpg' || _fileType == 'jpeg' || _fileType == 'png') {
      return Column(
        children: [
          Image.memory(
            _fileBytes!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 10),
          Text(
            '$_fileName',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          const Icon(Icons.insert_drive_file, size: 100),
          const SizedBox(height: 10),
          Text(
            '$_fileName (${_fileType?.toUpperCase()})',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building CreateResourceScreen UI');
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create a Resource"),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          const SizedBox(width: 1),
          IconButton(
            icon: Image.asset("assets/usericon.jpg"),
            onPressed: () {
              print('Navigating to profile details');
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
            const SizedBox(height: 10),
            _buildIconPreview(),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Make this resource private'),
              subtitle: const Text('Private resources are only visible to you'),
              value: _isPrivate,
              onChanged: (bool value) {
                print('Privacy setting changed to: ${value ? 'private' : 'public'}');
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
                  backgroundColor: Colors.blue[700],
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
                    : const Text(
                        'Upload Resource',
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