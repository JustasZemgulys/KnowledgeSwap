import 'package:flutter/material.dart';
import 'package:knowledgeswap/login_ui.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'get_ip.dart';

Future<String?> sendMail(String recipientEmail, BuildContext context) async {
  final getIP = GetIP();
  String userIP = await getIP.getUserIP();
  final sendMailApiUrl = '$userIP/send_reminder.php';
  try {
    final response = await http.post(
      Uri.parse(sendMailApiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': recipientEmail,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success']) {
        return responseData['verificationCode'];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Failed to send email'),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Server error occurred while sending email'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Network error occurred. Please check your connection.'),
        backgroundColor: Colors.red,
      ),
    );
    return null;
  }
}

class ForgotPassScreen extends StatefulWidget {
  const ForgotPassScreen({super.key});

  @override
  State<ForgotPassScreen> createState() => _ForgotPassScreenState();
}

class _ForgotPassScreenState extends State<ForgotPassScreen> {
  TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Enter Email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (emailController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your email address'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final String? EmailVerification = 
                    await sendMail(emailController.text, context);

                if (EmailVerification != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CodeConfirmationScreen(
                        generatedCode: EmailVerification,
                        email: emailController.text,
                      ),
                    ),
                  );
                }
              },
              child: const Text('Send Verification Code'),
            ),
          ],
        ),
      ),
    );
  }
}

class CodeConfirmationScreen extends StatelessWidget {
  final String generatedCode;
  final String email;
  final TextEditingController codeController = TextEditingController();

  CodeConfirmationScreen({required this.generatedCode, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Verification Code')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Enter Verification Code',
                prefixIcon: Icon(Icons.code),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (codeController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter the verification code'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (codeController.text == generatedCode) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangePasswordScreen(email: email),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid code. Please try again!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Verify Code'),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  final String email;
  const ChangePasswordScreen({required this.email});
  
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  Future<void> changePassword(String email, String newPassword) async {
    if (newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a new password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final getIP = GetIP();
    String userIP = await getIP.getUserIP();
    final String apiUrl = '$userIP/change_password.php';
    
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Password changed successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Failed to change password'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error occurred. Please check your connection.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'Enter New Password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                changePassword(widget.email, newPasswordController.text);
              },
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }
}