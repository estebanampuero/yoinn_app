import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono Cian Oscuro
              const Icon(Icons.location_on, size: 80, color: Color(0xFF00BCD4)),
              const SizedBox(height: 20),
              const Text(
                "Yoinn",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00BCD4), // Cian Oscuro
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Conecta y comparte experiencias",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 50),
              
              ElevatedButton.icon(
                onPressed: () {
                  Provider.of<AuthService>(context, listen: false).signInWithGoogle();
                },
                icon: const Icon(Icons.login),
                label: const Text("Continuar con Google"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0097A7), // Texto Cian más oscuro para contraste
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  side: const BorderSide(color: Color(0xFF26C6DA)), // Borde Turquesa
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}