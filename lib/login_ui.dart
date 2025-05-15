import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:knowledgeswap/web_storage.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'models/user_info.dart';
import 'user_info_provider.dart';
import 'forgot_pass_ui.dart';
import 'app_router.dart';
import 'get_ip.dart';

class LoginPage extends StatefulWidget {
  final http.Client? httpClient;
  final UserInfoProvider? userInfoProvider;

  const LoginPage({Key? key, this.httpClient, this.userInfoProvider})
      : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  late final http.Client httpClient;
  UserInfoProvider? userInfoProvider;

  @override
  void initState() {
    super.initState();
    // Use injected client if provided, else default
    httpClient = widget.httpClient ?? http.Client();
    // UserInfoProvider can be injected or obtained from context lazily
    userInfoProvider = widget.userInfoProvider;
  }

  Future<void> loginUser() async {
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      await showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text("Please fill all fields"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final getIP = GetIP();
      String userIP = await getIP.getUserIP();

      final response = await httpClient.post(
        Uri.parse('$userIP/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': usernameController.text,
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          UserInfo userInfo = UserInfo.fromJson(responseData['userData']);

          // Use injected userInfoProvider or obtain from context
          final provider = userInfoProvider ??
              Provider.of<UserInfoProvider>(context, listen: false);
          await provider.setUserInfo(userInfo);

          final lastRoute = await WebStorage.getLastRoute() ?? '/main';

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => AppRouter.getScreenFromRoute(lastRoute),
              settings: RouteSettings(name: lastRoute),
            ),
            (route) => false,
          );
        } else {
          await showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text("Wrong username or password"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
      } else {
        await showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text("Server Error"),
            content: Text("Status code: ${response.statusCode}"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
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
          color: Color(0xFF6e10a6), // Purple background fallback
          image: DecorationImage(
            image: AssetImage('assets/welcomeBG.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Welcome back!",
              style: TextStyle(
                  fontFamily: "Karla-LightItalic",
                  fontStyle: FontStyle.italic,
                  fontSize: 30),
            ),
            const SizedBox(height: 50),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 50),
              width: 500,
              child: TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  hintText: "Username",
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
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 50),
              width: 500,
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
            TextButton(
              child: const Text("Forgot password?"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ForgotPassScreen()),
                );
              },
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 50),
              width: 200,
              child: ElevatedButton(
                onPressed: loginUser,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.deepPurple,
                ),
                child: const Text(
                  'Log In',
                  style: TextStyle(fontFamily: "Karla", color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
