import 'dart:io'; // Para detectar si es iOS
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // Necesario para el auto-play del slider
import 'package:sign_in_with_apple/sign_in_with_apple.dart'; // Importante
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  bool _isLoading = false;

  // Controladores para el Login de Demo
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Datos para el carrusel de bienvenida
  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "Explora tu Ciudad",
      "text": "Crea y descubre actividades y eventos únicos que suceden a tu alrededor en tiempo real.",
      "icon": Icons.map_outlined,
    },
    {
      "title": "Únete a la actividad",
      "text": "Solicita unirte a planes de deporte, comida, fiestas y más con un solo toque.",
      "icon": Icons.volunteer_activism, 
    },
    {
      "title": "Conecta y Chatea",
      "text": "Conoce gente nueva, chatea con el grupo y vive experiencias reales.",
      "icon": Icons.chat_bubble_outline,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Configurar el cambio automático de slide cada 4 segundos
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < _onboardingData.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleAppleLogin() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    final user = await authService.signInWithApple();
    
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Error al iniciar con Apple"))
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // Función para Login con Email/Password (Para Demo de Apple)
  void _handleEmailLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthService>(context, listen: false).signInWithEmail(
        _emailController.text.trim(), 
        _passwordController.text.trim()
      );
      // Si funciona, AuthWrapper redirige solo.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Error: $e"))
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si el teclado está abierto, ajustamos para que se vea el formulario
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView( // Scroll para evitar overflow con teclado
          child: SizedBox(
            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            child: Column(
              children: [
                if (!isKeyboardOpen) const Spacer(flex: 1), 
                
                // --- 1. TU LOGO Y MARCA ---
                if (!isKeyboardOpen) ...[
                  Image.asset(
                    'assets/icons/pin.png', 
                    height: 100, 
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.location_on, size: 80, color: Color(0xFF00BCD4));
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Yoinn",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900, 
                      color: Color(0xFF00BCD4),    
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(flex: 1),
                ],

                // --- 2. CARRUSEL INFORMATIVO (Se oculta con teclado) ---
                if (!isKeyboardOpen) ...[
                  SizedBox(
                    height: 200, 
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (value) => setState(() => _currentPage = value),
                      itemCount: _onboardingData.length,
                      itemBuilder: (context, index) => _buildOnboardingContent(
                        icon: _onboardingData[index]["icon"],
                        title: _onboardingData[index]["title"],
                        text: _onboardingData[index]["text"],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingData.length,
                      (index) => _buildDot(index: index),
                    ),
                  ),
                  const Spacer(flex: 2), 
                ] else 
                  const SizedBox(height: 40), // Espacio si teclado abierto

                // --- 4. BOTONES DE INICIO DE SESIÓN ---
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: Column(
                      children: [
                        // --- BOTÓN APPLE ---
                        if (Platform.isIOS) 
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SignInWithAppleButton(
                              onPressed: _handleAppleLogin,
                              height: 50,
                              style: SignInWithAppleButtonStyle.black, 
                              borderRadius: const BorderRadius.all(Radius.circular(30)),
                            ),
                          ),

                        // --- BOTÓN DE GOOGLE ---
                        SizedBox(
                          width: double.infinity,
                          height: 50, 
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Provider.of<AuthService>(context, listen: false).signInWithGoogle();
                            },
                            icon: Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                              height: 24,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.login, color: Colors.grey),
                            ),
                            label: const Text("Continuar con Google"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              elevation: 3,
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: const BorderSide(color: Color(0xFFE0E0E0)), 
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // --- FORMULARIO DEMO PARA APPLE REVIEW ---
                        const Divider(),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text("Acceso Demo / Admin", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                        
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: "Email Demo",
                            isDense: true,
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Contraseña",
                            isDense: true,
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _handleEmailLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black,
                            ),
                            child: const Text("Ingresar"),
                          ),
                        ),

                        const SizedBox(height: 20),
                        
                        // Texto legal 
                        const Text(
                          "Al continuar, aceptas nuestros Términos de Servicio\ny Política de Privacidad.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget interno para cada diapositiva
  Widget _buildOnboardingContent({required IconData icon, required String title, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F7FA), 
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: const Color(0xFF00BCD4)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
          ),
        ],
      ),
    );
  }

  // Widget para los puntitos (Dots)
  Widget _buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 6),
      height: 8,
      width: _currentPage == index ? 24 : 8, 
      decoration: BoxDecoration(
        color: _currentPage == index ? const Color(0xFF00BCD4) : const Color(0xFFB2EBF2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}