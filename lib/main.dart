import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/data_service.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
          // --- NUEVA PALETA CIAN / AZUL ---
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00BCD4), // Deep Cyan (Principal)
            primary: const Color(0xFF00BCD4),   // Deep Cyan
            secondary: const Color(0xFF29B6F6), // Azul Brillante (Centro del círculo)
            tertiary: const Color(0xFF26C6DA),  // Turquesa (Transición)
            surfaceTint: const Color(0xFF4DD0E1), // Cian Claro
            background: const Color(0xFFF0F8FA), // Fondo muy suave azulado
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF0F8FA), // Fondo global ligeramente azulado
          
          // Estilo global de botones
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4), // Deep Cyan
              foregroundColor: Colors.white,
            ),
          ),
          // Estilo global de botones flotantes
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF00BCD4),
            foregroundColor: Colors.white,
          ),
          // Estilo de inputs
          inputDecorationTheme: InputDecorationTheme(
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 2),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

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

  void _checkAndInitNotifications() {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (authService.currentUser != null && !_notificationsInitialized) {
      NotificationService().init(authService);
      _notificationsInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (authService.isLoading) {
      // Loader color Cian
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4))));
    }

    if (authService.currentUser == null) {
      _notificationsInitialized = false;
      return const LoginScreen();
    }

    return const HomeScreen(); 
  }
}