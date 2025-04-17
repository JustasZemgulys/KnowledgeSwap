import 'package:flutter/material.dart';
import 'package:knowledgeswap/login_ui.dart';
import 'package:knowledgeswap/signup_ui.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth + 0.1,  // Slightly over-extend width
            height: constraints.maxHeight + 0.1, // Slightly over-extend height
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF6e10a6),
                image: DecorationImage(
                  image: AssetImage('assets/welcomeBG.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Welcome to KnowledgeSwap',
                      style: TextStyle(
                        fontFamily: "Karla-LightItalic",
                        fontStyle: FontStyle.italic,
                        fontSize: 30,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 50),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 50),
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
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
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 50),
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignUpScreen()),
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
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}