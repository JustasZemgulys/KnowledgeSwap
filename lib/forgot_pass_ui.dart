import 'package:flutter/material.dart';
import 'package:knowledgeswap/login_ui.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String?> sendMail(String recipientEmail, BuildContext context) async {
  final sendMailApiUrl = 'https://juszem1-1.stud.if.ktu.lt/send_reminder.php';
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
        //print('Failed to send email: ${responseData['message']}');
        return null;
      }
    } else {
      //print('Failed to send email: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    //print('Error sending email: $e');
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
      appBar: AppBar(title: Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Enter Email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                //generatedCode = generateRandomCode();
                // ignore: non_constant_identifier_names
                String? EmailVerification =
                    await sendMail(emailController.text, context);

                if (EmailVerification != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CodeConfirmationScreen(
                        generatedCode: EmailVerification,
                        email: emailController
                            .text, // Pass the email to CodeConfirmationScreen
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Failed to send verification code. Please try again!')),
                  );
                }
              },
              child: Text('Send Verification Code'),
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
      appBar: AppBar(title: Text('Enter Verification Code')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: 'Enter Verification Code',
                prefixIcon: Icon(Icons.code),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (codeController.text == generatedCode) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangePasswordScreen(email: email),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid code. Try again!')),
                  );
                }
              },
              child: Text('Verify Code'),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  final String email;
  const ChangePasswordScreen({super.key, required this.email});
  @override
  // ignore: library_private_types_in_public_api, no_logic_in_create_state
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState(email: email);
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  TextEditingController newPasswordController = TextEditingController();
  final String email;

  _ChangePasswordScreenState({required this.email});

  Future<void> changePassword(String email, String newPassword) async {
    final String apiUrl = 'https://juszem1-1.stud.if.ktu.lt/change_password.php';
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

    // Print the response body for debugging
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'])),
          );
        }
      } catch (e) {
        print('Error parsing JSON response: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error parsing server response')),
        );
      }
    } else {
      print('Error: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: newPasswordController,
              decoration: InputDecoration(
                labelText: 'Enter New Password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              obscureText: true, // Hides the entered text
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                changePassword(email, newPasswordController.text);
              },
              child: Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }
}
