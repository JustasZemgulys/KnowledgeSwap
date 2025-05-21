import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'dart:async';
import 'get_ip.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  UserInfo? user_info;
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController repeatPasswordController = TextEditingController();
  String email = '';
  String password = '';
  String name = '';

  void _showErrorSnackBar(String message) {
    if (!mounted) return;  // Add this check
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    repeatPasswordController.dispose();
    super.dispose();
  }

  Future<void> registerUser() async {
    if (passwordController.text.isEmpty ||
        nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        repeatPasswordController.text.isEmpty) {
      _showErrorSnackBar('Please fill all fields');
      return;
    }

    if (passwordController.text != repeatPasswordController.text) {
      _showErrorSnackBar('Passwords do not match');
      return;
    }

    final getIP = GetIP();
    final userIP = await getIP.getUserIP();
    final apiUrl = '$userIP/check_existing.php';
    email = emailController.text;
    password = passwordController.text;
    name = nameController.text;

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': nameController.text,
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          processRegistration(responseData['userData'], email);
        } else {
          _showErrorSnackBar(responseData['message'] ?? 'Registration failed');
        }
      } else {
        _showErrorSnackBar('Server error occurred. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Network error occurred. Please check your connection.');
    }
  }

  Future<void> processRegistration(dynamic userData, String recipientEmail) async {
    String? verificationCode = await sendMail(recipientEmail, context);

    if (verificationCode != null && mounted) {  // Add mounted check
      bool verified = await showVerificationDialog(verificationCode);
      if (verified && mounted) {  // Add mounted check
        final getIP = GetIP();
        final userIP = await getIP.getUserIP();
        final registerApiUrl = '$userIP/register.php';
        try {
          final registerResponse = await http.post(
            Uri.parse(registerApiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
            }),
          );

          if (registerResponse.statusCode == 200 || registerResponse.statusCode == 201) {
            final registerData = jsonDecode(registerResponse.body);
            if (registerData['success'] && mounted) {  // Add mounted check
              user_info = UserInfo.fromJson(registerData['userData']);
              UserInfoProvider userInfoProvider =
                  Provider.of<UserInfoProvider>(context, listen: false);
              await userInfoProvider.setUserInfo(user_info!);
              clearControllers();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(registerData['message'] ?? 'Registration successful!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
              
              await Future.delayed(const Duration(seconds: 3));
              if (mounted) {  // Check before navigation
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            } else if (mounted) {
              _showErrorSnackBar(registerData['message'] ?? 'Registration failed');
            }
          } else if (mounted) {
            _showErrorSnackBar('Server error occurred during registration');
          }
        } catch (e) {
          if (mounted) _showErrorSnackBar('Error during registration. Please try again.');
        }
      }
    }
  }

  Future<String?> sendMail(String recipientEmail, BuildContext context) async {
    final getIP = GetIP();
    final userIP = await getIP.getUserIP();
    final sendMailApiUrl = '$userIP/send_email.php';
    try {
      final response = await http.post(
        Uri.parse(sendMailApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': recipientEmail,
        }),
      );

      if (response.statusCode == 200 && mounted) {  // Add mounted check
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          return responseData['verificationCode'];
        } else if (mounted) {
          _showErrorSnackBar(responseData['message'] ?? 'Failed to send verification email');
        }
      } else if (mounted) {
        _showErrorSnackBar('Failed to send verification email');
      }
      return null;
    } catch (e) {
      if (mounted) _showErrorSnackBar('Network error while sending verification email');
      return null;
    }
  }

  Future<bool> showVerificationDialog(String correctCode) async {
    TextEditingController codeController = TextEditingController();
    bool verified = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Enter Verification Code"),
          content: TextField(
            controller: codeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "Enter Code"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Submit'),
              onPressed: () {
                if (codeController.text == correctCode) {
                  verified = true;
                  Navigator.pop(context);
                } else {
                  _showErrorSnackBar('Invalid verification code');
                }
              },
            ),
          ],
        );
      },
    );

    return verified;
  }

  void clearControllers() {
    nameController.text = "";
    emailController.text = "";
    passwordController.text = "";
    repeatPasswordController.text = "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF6e10a6),
          image: DecorationImage(
            image: AssetImage('assets/welcomeBG.png'),
            fit: BoxFit.cover,
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
                          width: 500),
                    ),
                  ),
                )),
            const SizedBox(height: 20),
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
                          width: 500),
                    ),
                  ),
                )),
            const SizedBox(height: 20),
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
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                          width: 500),
                    ),
                  ),
                )),
            const SizedBox(height: 20),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 50),
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}