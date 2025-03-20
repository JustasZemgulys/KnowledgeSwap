import 'package:flutter/material.dart';
import 'package:knowledgeswap/login_ui.dart';
import 'package:knowledgeswap/signup_ui.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            Container(
              padding: const EdgeInsets.only(bottom: 100, left: 250),
              child: const Image(
                image: AssetImage("assets/logo.png"),
                height: 100, // Adjust the height as needed
                width: 100,
                fit: BoxFit.cover,
              ),
            ),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 50),
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    side: const BorderSide(width: 2.0, color: Colors.black),
                    elevation: 0,
                    backgroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Log In',
                    style: TextStyle(fontFamily: "Karla", color: Colors.black),
                  ),
                )),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 50),
                //padding: EdgeInsets.only(bottom: 100),
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignUpScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    side: const BorderSide(width: 2.0, color: Colors.black),
                    elevation: 0,
                    backgroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(fontFamily: "Karla", color: Colors.black),
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
