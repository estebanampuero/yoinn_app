import 'package:flutter/material.dart';
import 'dart:math' as math; 
import '../main.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Duración: 1.8 segundos
    // Suficiente tiempo para dar varias vueltas sin que sea eterno.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800), 
    );

    // 2. Escala (Aparición)
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut, // Rebote al final para asentar el icono
      ),
    );

    // 3. Opacidad
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
      ),
    );

    // 4. EL EFECTO "MIXING" (MEZCLA) 🌪️
    // Giramos 6 veces PI (equivalente a 3 vueltas completas 360°).
    // Usamos 'easeOutQuart': Empieza rapidísimo (mezclando) y desacelera suavemente hasta parar.
    _rotateAnimation = Tween<double>(begin: 0.0, end: 6 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutQuart, 
      ),
    );

    _controller.forward();

    // Navegamos al terminar
    Future.delayed(const Duration(milliseconds: 2200), () {
      _navigateToNext();
    });
  }

  void _navigateToNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthWrapper(),
        transitionsBuilder: (_, animation, __, child) {
          // Transición suave al logo estático
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotateAnimation.value,
                  // IMPORTANTE: Asegúrate de que esta sea la imagen de las gotas
                  child: Image.asset(
                    'assets/icons/pin.png', 
                    width: 150, 
                    height: 150,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}