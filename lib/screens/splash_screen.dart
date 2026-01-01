import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math' as math;
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Animaciones de ENTRADA
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _textOpacityAnimation;
  
  // NOTA: Hemos eliminado la animación de "Salida" (_exitOpacityAnimation).
  // Esto hace que el logo y el texto se queden QUIETOS y SÓLIDOS
  // hasta que la siguiente pantalla (Feed) termine de cargar y los cubra.

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), 
    );

    // 1. Escala (Rebote)
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // 2. Opacidad Inicial
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
      ),
    );

    // 3. Rotación
    _rotateAnimation = Tween<double>(begin: 0.0, end: 6 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutQuart),
      ),
    );

    // 4. Texto "Yoinn"
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.8, curve: Curves.easeIn),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Al terminar, damos una pequeña pausa con el logo completo y texto visible
        // para asegurar que el usuario lea la marca y dar tiempo al Feed de prepararse.
        SchedulerBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _navigateToNext();
          });
        });
      }
    });

    _controller.forward();
  }

  void _navigateToNext() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        // Mantenemos el fondo blanco por seguridad
        barrierColor: Colors.white, 
        pageBuilder: (_, __, ___) => const AuthWrapper(),
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (_, animation, __, child) {
          // TRANSICIÓN CLAVE:
          // La nueva pantalla (Feed/Auth) aparece suavemente (FadeIn)
          // SOBRE este Splash Screen que se mantiene estático (con texto).
          // Así, si el Feed tiene un logo de carga, el Splash lo tapa
          // hasta que la opacidad es alta.
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
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
            // Ya no hay Opacity global de salida. Todo se queda visible.
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO
                Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.rotate(
                      angle: _rotateAnimation.value,
                      child: Image.asset(
                        'assets/icons/pin.png',
                        width: 150,
                        height: 150,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.location_on, size: 120, color: Color(0xFF00BCD4));
                        },
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),

                // TEXTO
                Opacity(
                  opacity: _textOpacityAnimation.value,
                  child: const Text(
                    "Yoinn",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF00BCD4),
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}