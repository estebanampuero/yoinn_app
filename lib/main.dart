import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // Necesario para fechas en español

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/data_service.dart';
import 'services/notification_service.dart'; // <--- NUEVO: Importar servicio de notificaciones
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializamos el formateo de fechas para español
  await initializeDateFormatting('es_ES', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => DataService()),
      ],
      child: MaterialApp(
        title: 'Yoinn',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFF97316),
            primary: const Color(0xFFF97316),
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

// Convertimos AuthWrapper a StatefulWidget para poder inicializar servicios
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _notificationsInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndInitNotifications();
  }

  // Función para inicializar notificaciones si el usuario está logueado
  void _checkAndInitNotifications() {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (authService.currentUser != null && !_notificationsInitialized) {
      // Inicializar notificaciones push y registrar token
      NotificationService().init(authService);
      _notificationsInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // 1. Estado de carga
    if (authService.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 2. Usuario NO logueado -> Pantalla de Login
    if (authService.currentUser == null) {
      // Reseteamos el flag por si hace logout
      _notificationsInitialized = false;
      return const LoginScreen();
    }

    // 3. Usuario Logueado -> HomeScreen (que tiene Feed y Mapa)
    return const HomeScreen(); 
  }
}