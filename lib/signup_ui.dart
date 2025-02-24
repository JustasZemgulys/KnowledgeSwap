import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:knowledgeswap/genre_selection_ui.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'dart:math';
import 'dart:async';
import 'get_ip.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  UserInfo? user_info;
  TextEditingController usernameController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController repeatPasswordController = TextEditingController();
  String? userType;
  String email = '';
  String password = '';
  String name = '';
  String username = '';

  Future<void> registerUser() async {
    if (usernameController.text.isEmpty ||
        passwordController.text.isEmpty ||
        nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        repeatPasswordController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Please fill all fields"),
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

    if (passwordController.text != repeatPasswordController.text) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Passwords do not match"),
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

    String userIP = await getUserIP();
    final apiUrl = 'http://$userIP/check_existing.php';
    email = emailController.text;
    password = passwordController.text;
    name = nameController.text;
    username = usernameController.text;

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': usernameController.text,
          'name': nameController.text,
          'email': emailController.text,
          'password': passwordController.text,
          'userType': userType,
        }),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          processRegistration(responseData['userData'], email);
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(responseData['message']),
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
      } else {
        print('Failed to check existing user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking existing user: $e');
    }
  }

  Future<void> processRegistration(
      dynamic userData, String recipientEmail) async {
    String? verificationCode = await sendMail(recipientEmail, context);

    if (verificationCode != null) {
      String userIP = await getUserIP();
      final registerApiUrl = 'http://$userIP/register.php';
      try {
        final registerResponse = await http.post(
          Uri.parse(registerApiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'name': name,
            'email': email,
            'password': password,
            'userType': userType,
          }),
        );

        print('Register Response: ${registerResponse.body}');

        if (registerResponse.statusCode == 200) {
          final registerData = jsonDecode(registerResponse.body);
          if (registerData['success']) {
            user_info = UserInfo.fromJson(registerData['userData']);
            UserInfoProvider userInfoProvider =
                Provider.of<UserInfoProvider>(context, listen: false);
            userInfoProvider.setUserInfo(user_info);
            clearControllers();
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const GenreSelectionScreen()),
            );
          } else {
            print('Registration failed: ${registerData['message']}');
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(registerData['message']),
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
        } else {
          print('Failed to register user: ${registerResponse.statusCode}');
        }
      } catch (e) {
        print('Error registering user: $e');
      }
    }
  }

  Future<String?> sendMail(String recipientEmail, BuildContext context) async {
    String username = 'officialknowledgeswap@gmail.com';
    String password = 'mved mdeg lvlg yvnw';
    final smtpServer = gmail(username, password);
    int randomCode = Random().nextInt(900000) + 100000;
    String verificationCode = randomCode.toString();

    final message = Message()
      ..from = Address(username, 'knowledgeswap')
      ..recipients.add(recipientEmail)
      ..subject = 'Registration'
      ..text = 'Your verification code is: $verificationCode '
      ..html =
          "<h1>Verification Code</h1>\n<p>Your verification code is: <strong>$verificationCode </strong></p>";

    Completer<String?> completer = Completer<String?>();

    // Send the email
    try {
      await send(message, smtpServer);
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      completer.completeError("Failed to send verification email.");
      return completer.future;
    }

    // Show dialog for user input
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Enter Verification Code"),
          content: TextField(
            onChanged: (value) {
              if (value == verificationCode) {
                Navigator.pop(context); // Close dialog
                completer.complete(verificationCode); // Complete the future
              }
            },
            decoration: const InputDecoration(hintText: "Enter Code"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Submit'),
              onPressed: () {
                if (completer.isCompleted) {
                  Navigator.pop(context); // Close dialog
                }
              },
            ),
          ],
        );
      },
    );

    return completer.future; // Return the future from completer
  }

  void clearControllers() {
    usernameController.text = "";
    nameController.text = "";
    emailController.text = "";
    passwordController.text = "";
    repeatPasswordController.text = "";
    userType = 'Listener';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: const Color(0x00000000),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width, // Full screen width
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/welcomeBG.png'),
            fit: BoxFit.cover, // Ensure the image covers the entire space
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 50),
                width: 250,
                child: TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    hintText: 'Username',
                    prefixIcon: const Icon(Icons.person),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    fillColor: Colors.deepPurple.withOpacity(0.30),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Colors.black,
                          width: 500), // Adjust the width here
                    ),
                  ),
                )),
            const SizedBox(
              height: 20,
            ),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 50),
                width: 250,
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Name',
                    prefixIcon: const Icon(Icons.abc),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    fillColor: Colors.deepPurple.withOpacity(0.30),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Colors.black,
                          width: 500), // Adjust the width here
                    ),
                  ),
                )),
            const SizedBox(
              height: 20,
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 50),
              width: 250,
              child: DropdownButtonFormField<String>(
                value: userType,
                icon: const Icon(Icons.arrow_downward),
                iconSize: 24,
                elevation: 16,
                style: const TextStyle(color: Colors.deepPurple),
                onChanged: (String? newValue) {
                  setState(() {
                    userType = newValue ?? 'Listener';
                  });
                },
                items: <String>['Listener', 'Creator']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: InputDecoration(
                  hintText: 'User Type',
                  prefixIcon: const Icon(Icons.person),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  fillColor: Colors.deepPurple.withOpacity(0.30),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Colors.black,
                      width: 500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 50),
                width: 250,
                child: TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    fillColor: Colors.deepPurple.withOpacity(0.30),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Colors.black,
                          width: 500), // Adjust the width here
                    ),
                  ),
                )),
            const SizedBox(
              height: 20,
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 50),
              width: 250,
              child: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  fillColor: Colors.deepPurple.withOpacity(0.30),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Colors.black,
                      width: 500,
                    ), // Adjust the width here
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 50),
                width: 250,
                child: TextField(
                  controller: repeatPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Repeat password",
                    prefixIcon: const Icon(Icons.lock),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    fillColor: Colors.deepPurple.withOpacity(0.30),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Colors.black,
                          width: 500), // Adjust the width here
                    ),
                  ),
                )),
            const SizedBox(
              height: 20,
            ),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 50),
                //padding: EdgeInsets.only(bottom: 100),
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    registerUser();
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(fontFamily: "Karla", color: Colors.white),
                  ),
                )),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
