import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // Necesario para el auto-play del slider
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1), // Espacio flexible arriba
            
            // --- 1. TU LOGO Y MARCA ---
            // Usamos tu imagen personalizada
            Image.asset(
              'assets/icons/pin.png', 
              height: 100, // Tamaño controlado
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Por si acaso fallara la carga, mostramos un ícono de respaldo
                return const Icon(Icons.location_on, size: 80, color: Color(0xFF00BCD4));
              },
            ),
            const SizedBox(height: 16),
            const Text(
              "Yoinn",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900, // Letra muy gruesa para impacto
                color: Color(0xFF00BCD4),    // Tu color Cian
                letterSpacing: 1.5,
              ),
            ),

            const Spacer(flex: 1),

            // --- 2. CARRUSEL INFORMATIVO ---
            SizedBox(
              height: 280, // Altura fija para el slider
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

            // --- 3. PUNTITOS INDICADORES ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingData.length,
                (index) => _buildDot(index: index),
              ),
            ),

            const Spacer(flex: 2), // Empuja el botón hacia abajo

            // --- 4. BOTÓN DE GOOGLE ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Provider.of<AuthService>(context, listen: false).signInWithGoogle();
                      },
                      // Usamos el logo oficial de Google desde la red para que se vea nítido
                      icon: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                        height: 24,
                        loadingBuilder: (context, child, loadingProgress) {
                           if (loadingProgress == null) return child;
                           return const Icon(Icons.login, color: Colors.grey); // Fallback mientras carga
                        },
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
                          side: const BorderSide(color: Color(0xFFE0E0E0)), // Borde gris suave
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Texto legal pequeño (Da confianza)
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
    );
  }

  // Widget interno para cada diapositiva
  Widget _buildOnboardingContent({required IconData icon, required String title, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Círculo decorativo detrás del ícono explicativo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F7FA), // Tu color fondo muy claro
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
      width: _currentPage == index ? 24 : 8, // El activo es más ancho
      decoration: BoxDecoration(
        color: _currentPage == index ? const Color(0xFF00BCD4) : const Color(0xFFB2EBF2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}