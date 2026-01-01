import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:yoinn_app/l10n/app_localizations.dart'; // <--- IMPORTANTE: TRADUCCIONES

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

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // NOTA: Movemos los datos del onboarding dentro del build o usamos un getter
  // para poder acceder al contexto de localización (l10n).
  List<Map<String, dynamic>> _getOnboardingData(AppLocalizations l10n) {
    return [
      {
        "title": l10n.exploreCityTitle,
        "text": l10n.exploreCityText,
        "icon": Icons.map_outlined,
      },
      {
        "title": l10n.joinActivityTitle,
        "text": l10n.joinActivityText,
        "icon": Icons.volunteer_activism,
      },
      {
        "title": l10n.connectChatTitle,
        "text": l10n.connectChatText,
        "icon": Icons.chat_bubble_outline,
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    // Iniciamos el timer del carrusel
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      // Necesitamos una forma de saber el largo de la lista,
      // como es constante en tamaño (3 items), podemos usar 3 directamente
      // o acceder a la data si la moviéramos a una variable de estado.
      // Para simplificar y no romper el initState, usaremos 3 fijo por ahora.
      if (_currentPage < 2) {
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

  // 🔐 APPLE LOGIN
  void _handleAppleLogin() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final user = await authService.signInWithApple();
      if (user == null) {
        throw Exception("Apple Sign-In returned null user");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorAppleLogin), // "Error al iniciar sesión con Apple"
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 📧 EMAIL LOGIN
  void _handleEmailLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    
    try {
      await Provider.of<AuthService>(context, listen: false).signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${l10n.errorGeneric}: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. OBTENEMOS LAS TRADUCCIONES
    final l10n = AppLocalizations.of(context)!;
    
    // 2. OBTENEMOS DATOS TRADUCIDOS
    final onboardingData = _getOnboardingData(l10n);

    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top,
            child: Column(
              children: [
                if (!isKeyboardOpen) const Spacer(flex: 1),

                // --- LOGO Y TÍTULO ---
                if (!isKeyboardOpen) ...[
                  Image.asset(
                    'assets/icons/pin.png',
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.location_on,
                          size: 80, color: Color(0xFF00BCD4));
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

                // --- ONBOARDING CAROUSEL ---
                if (!isKeyboardOpen) ...[
                  SizedBox(
                    height: 200,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (value) =>
                          setState(() => _currentPage = value),
                      itemCount: onboardingData.length,
                      itemBuilder: (context, index) =>
                          _buildOnboardingContent(
                        icon: onboardingData[index]["icon"],
                        title: onboardingData[index]["title"],
                        text: onboardingData[index]["text"],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      onboardingData.length,
                      (index) => _buildDot(index: index),
                    ),
                  ),
                  const Spacer(flex: 2),
                ] else
                  const SizedBox(height: 40),

                // --- BOTONES DE LOGIN ---
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 20.0),
                    child: Column(
                      children: [
                        // APPLE
                        if (Platform.isIOS)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SignInWithAppleButton(
                              onPressed: _handleAppleLogin,
                              height: 50,
                              // El texto del botón viene dentro del widget,
                              // pero podríamos personalizarlo si el widget lo permite.
                              // Por defecto "Sign in with Apple" se localiza solo si el SO lo soporta.
                              style: SignInWithAppleButtonStyle.black,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(30)),
                            ),
                          ),

                        // GOOGLE
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Provider.of<AuthService>(context, listen: false)
                                  .signInWithGoogle();
                            },
                            icon: Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                              height: 24,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.login, color: Colors.grey),
                            ),
                            label: Text(l10n.continueWithGoogle), // "Continuar con Google"
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              elevation: 3,
                              textStyle: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        const Divider(),
                        
                        // --- ACCESO DEMO ---
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            l10n.demoAccessLabel, // "Acceso Demo / Admin"
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),

                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: l10n.emailDemoLabel, // "Email Demo"
                            isDense: true,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: l10n.passwordLabel, // "Contraseña"
                            isDense: true,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock_outline),
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
                            child: Text(l10n.enterButton), // "Ingresar"
                          ),
                        ),

                        const SizedBox(height: 20),

                        // --- TÉRMINOS ---
                        Text(
                          l10n.termsAndConditionsText, // "Al continuar, aceptas..."
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
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

  // --- WIDGETS AUXILIARES ---

  Widget _buildOnboardingContent(
      {required IconData icon,
      required String title,
      required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFE0F7FA),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: const Color(0xFF00BCD4)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 6),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? const Color(0xFF00BCD4)
            : const Color(0xFFB2EBF2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}