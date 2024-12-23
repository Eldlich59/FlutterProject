import 'package:flutter/material.dart';
import 'package:flutter_demo/screens/list_notes/list_notes_screen.dart';

class LoginScreen extends StatelessWidget {
  static const String route = "LoginScreen";

  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const TextField(decoration: InputDecoration(labelText: "Username")),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: "Password")),
            const SizedBox(height: 32),
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(ListNotesScreen.route);
                },
                child: const Text("Log in"))
          ],
        ),
      ),
    );
  }
}
