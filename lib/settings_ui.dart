import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:knowledgeswap/welcome.dart';
import 'package:knowledgeswap/genre_selection_ui.dart';
import 'dart:convert';
import 'models/user_info.dart';
import 'user_info_provider.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  late UserInfo user_info;
  TextEditingController usernameController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController passRepeatController = TextEditingController();
  TextEditingController passNewController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Retrieve user information from the provider
    user_info = Provider.of<UserInfoProvider>(context, listen: false).userInfo!;
    initializeControllers();
  }

  void initializeControllers() {
    usernameController.text = user_info.username;
    nameController.text = user_info.name;
    emailController.text = user_info.email;
  }

  void saveUserInfo() async {
    const apiUrl = 'http://10.0.2.2//settings.php';

    // Get the updated user information
    String newUsername = usernameController.text;
    String newName = nameController.text;
    String newEmail = emailController.text;
    String newPassword = passNewController.text;
    String oldPassword = passController.text;
    String repeatedPassword = passRepeatController.text;

    // Validate the input
    if (newPassword.isNotEmpty && newPassword != repeatedPassword) {
      // Show an error message if new password and repeated password don't match
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Passwords don't match"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
      return;
    }

    // Prepare the data for the POST request
    Map<String, dynamic> requestData = {
      'idUser': user_info.idUser,
      'newUsername': newUsername,
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

      if (response.body != null) {
        final responseData = jsonDecode(response.body);

        if (responseData['success']) {
          // Update the user_info with the new information
          user_info = UserInfo.fromJson(responseData['userData']);
          Provider.of<UserInfoProvider>(context, listen: false)
              .setUserInfo(user_info);

          // Show a success message
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("User info updated successfully"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("OK"),
                  ),
                ],
              );
            },
          );
        } else {
          // Show a failure message
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Update Failed"),
                content: Text(responseData['message']),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("OK"),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void disconnectUser() {
    // Clear user_info and navigate to WelcomeScreen
    Provider.of<UserInfoProvider>(context, listen: false).setUserInfo(null);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
  }

  void deleteAccount() async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Are you sure you want to delete your account?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // No, do not delete
              },
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Yes, delete
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // User confirmed, proceed with account deletion
      const apiUrl = 'http://10.0.2.2//deleteaccount.php';

      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'idUser': user_info.idUser}),
        );

        print('Server Response: ${response.body}');

        if (response.body != null) {
          final responseData = jsonDecode(response.body);

          if (responseData['success']) {
            // Clear user_info and navigate to WelcomeScreen
            Provider.of<UserInfoProvider>(context, listen: false)
                .setUserInfo(null);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            );
          } else {
            // Show a failure message
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Deletion Failed"),
                  content: Text(responseData['message']),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("OK"),
                    ),
                  ],
                );
              },
            );
          }
        }
      } catch (e) {
        print('Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      resizeToAvoidBottomInset:
          true, // This will resize the screen when the keyboard appears
      body: SingleChildScrollView(
        // Wrap your body with SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current User Info:'),
              Text('Username: ${user_info.username}'),
              Text('Name: ${user_info.name}'),
              Text('Email: ${user_info.email}'),
              const SizedBox(height: 20),
              Text('Update User Info:'),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: passNewController,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              TextField(
                controller: passRepeatController,
                decoration:
                    const InputDecoration(labelText: 'Repeat New Password'),
              ),
              TextField(
                controller: passController,
                decoration:
                    const InputDecoration(labelText: 'Old Password(required)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveUserInfo,
                child: const Text('Save'),
              ),
              const SizedBox(height: 10), // Added a SizedBox for spacing
              ElevatedButton(
                onPressed: () {
                  // Navigate to the GenreSelectionScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => GenreSelectionScreen()),
                  );
                },
                child: const Text('Select Genre'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: disconnectUser,
                child: const Text('Disconnect'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: deleteAccount,
                child: const Text('Delete Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
