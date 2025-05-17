import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:knowledgeswap/welcome.dart';
import 'dart:convert';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'get_ip.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  late UserInfo user_info;
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController passRepeatController = TextEditingController();
  TextEditingController passNewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    initializeControllers();
  }

  void initializeControllers() {
    nameController.text = user_info.name;
    emailController.text = user_info.email;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> saveUserInfo() async {
    final getIP = GetIP();
    final userIP = await getIP.getUserIP();
    final apiUrl = '$userIP/settings.php';

    String newName = nameController.text;
    String newEmail = emailController.text;
    String newPassword = passNewController.text;
    String oldPassword = passController.text;
    String repeatedPassword = passRepeatController.text;

    if (oldPassword.isEmpty) {
      _showErrorSnackBar('Please enter your current password');
      return;
    }

    if (newPassword.isNotEmpty && newPassword != repeatedPassword) {
      _showErrorSnackBar('New passwords do not match');
      return;
    }

    Map<String, dynamic> requestData = {
      'id': user_info.id,
      'newName': newName,
      'newEmail': newEmail,
      'newPassword': newPassword,
      'oldPassword': oldPassword,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      final responseData = jsonDecode(response.body);

      if (responseData['success']) {
        user_info = UserInfo.fromJson(responseData['userData']);
        Provider.of<UserInfoProvider>(context, listen: false)
            .setUserInfo(user_info);
        _showSuccessSnackBar('Profile updated successfully');
      } else {
        _showErrorSnackBar(responseData['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      _showErrorSnackBar('Network error. Please try again.');
    }
  }

  Future<void> disconnectUser() async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await Provider.of<UserInfoProvider>(context, listen: false).clearUserInfo();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  Future<void> deleteAccount() async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Account"),
          content: const Text("This action cannot be undone. Your data will be permanently deleted."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final getIP = GetIP();
    final userIP = await getIP.getUserIP();
    final apiUrl = '$userIP/deleteaccount.php';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': user_info.id}),
      );

      final responseData = jsonDecode(response.body);

      if (responseData['success']) {
        await Provider.of<UserInfoProvider>(context, listen: false)
            .clearUserInfo();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
        _showSuccessSnackBar('Account deleted successfully');
      } else {
        _showErrorSnackBar(responseData['message'] ?? 'Failed to delete account');
      }
    } catch (e) {
      _showErrorSnackBar('Network error. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current User Info:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Name: ${user_info.name}'),
            Text('Email: ${user_info.email}'),
            const SizedBox(height: 24),
            const Text('Update User Info:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'New Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'New Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passNewController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passRepeatController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Repeat New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password (required)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveUserInfo,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: disconnectUser,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Logout'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: deleteAccount,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red,
                ),
                child: const Text('Delete Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}