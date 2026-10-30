import 'package:flutter/material.dart';
import 'login_screen.dart'; // <-- Import LoginScreen

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(), // <-- Changed to LoginScreen
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 150,
                width: 150,
                errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.local_gas_station, color: Colors.deepPurple, size: 150),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chirag LPG',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Efficient Transport, Trusted Service',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Colors.deepPurple),
          ],
        ),
      ),
    );
  }
}