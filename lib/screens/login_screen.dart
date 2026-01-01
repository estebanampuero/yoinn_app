import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:yoinn_app/l10n/app_localizations.dart'; 

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
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
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
            content: Text(l10n.errorAppleLogin), 
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
    final l10n = AppLocalizations.of(context)!;
    final onboardingData = _getOnboardingData(l10n);
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Usamos Spacer condicional o flex reducido para evitar espacios grandes
                      if (!isKeyboardOpen) const Spacer(flex: 1),

                      // --- LOGO Y TÍTULO (Versión reducida) ---
                      if (!isKeyboardOpen) ...[
                        Image.asset(
                          'assets/icons/pin.png',
                          height: 70, // Reducido de 100
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.location_on,
                                size: 60, color: Color(0xFF00BCD4)); // Reducido de 80
                          },
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Yoinn",
                          style: TextStyle(
                            fontSize: 26, // Reducido de 32
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF00BCD4),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(flex: 1),
                      ],

                      // --- ONBOARDING CAROUSEL (Versión reducida) ---
                      if (!isKeyboardOpen) ...[
                        SizedBox(
                          height: 150, // Reducido de 200
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
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            onboardingData.length,
                            (index) => _buildDot(index: index),
                          ),
                        ),
                        const Spacer(flex: 2),
                      ] else
                        const SizedBox(height: 20),

                      // --- FORMULARIO Y BOTONES ---
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24.0, vertical: 16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min, // Importante para Wrap implícito
                            children: [
                              // APPLE
                              if (Platform.isIOS)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: SignInWithAppleButton(
                                    onPressed: _handleAppleLogin,
                                    height: 44, // Reducido de 50
                                    style: SignInWithAppleButtonStyle.black,
                                    borderRadius:
                                        const BorderRadius.all(Radius.circular(30)),
                                  ),
                                ),

                              // GOOGLE
                              SizedBox(
                                width: double.infinity,
                                height: 44, // Reducido de 50
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Provider.of<AuthService>(context, listen: false)
                                        .signInWithGoogle();
                                  },
                                  icon: Image.network(
                                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                                    height: 20, // Reducido de 24
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.login, color: Colors.grey, size: 20),
                                  ),
                                  label: Text(l10n.continueWithGoogle),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black87,
                                    elevation: 2,
                                    textStyle: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.bold), // Fuente más chica
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              const Divider(height: 20), // Menos espacio
                              
                              // --- ACCESO DEMO ---
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  l10n.demoAccessLabel,
                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                              ),

                              // Inputs más compactos
                              SizedBox(
                                height: 45,
                                child: TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    labelText: l10n.emailDemoLabel,
                                    labelStyle: const TextStyle(fontSize: 12),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.email_outlined, size: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 45,
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    labelText: l10n.passwordLabel,
                                    labelStyle: const TextStyle(fontSize: 12),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.lock_outline, size: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              SizedBox(
                                width: double.infinity,
                                height: 40, // Botón más compacto
                                child: ElevatedButton(
                                  onPressed: _handleEmailLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[200],
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                  ),
                                  child: Text(l10n.enterButton, style: const TextStyle(fontSize: 13)),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // --- TÉRMINOS ---
                              Text(
                                l10n.termsAndConditionsText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey), // Fuente reducida
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES REDUCIDOS ---

  Widget _buildOnboardingContent(
      {required IconData icon,
      required String title,
      required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30), // Menos padding
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12), // Reducido de 16
            decoration: const BoxDecoration(
              color: Color(0xFFE0F7FA),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: const Color(0xFF00BCD4)), // Reducido de 60
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Reducido de 20
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey), // Reducido de 14
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 6),
      height: 6, // Reducido de 8
      width: _currentPage == index ? 18 : 6, // Reducido de 24
      decoration: BoxDecoration(
        color: _currentPage == index
            ? const Color(0xFF00BCD4)
            : const Color(0xFFB2EBF2),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}