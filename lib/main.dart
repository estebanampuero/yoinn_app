import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // <--- IMPORTANTE
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

// Asegúrate de que estos imports sean correctos según la estructura de tus carpetas
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/data_service.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// --- 1. MANEJADOR DE SEGUNDO PLANO (BACKGROUND) ---
// Esta función debe estar FUERA de cualquier clase (Top Level) y marcada con @pragma
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Es vital inicializar Firebase aquí también porque el hilo está aislado
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("🌙 Notificación recibida en Segundo Plano/Terminado: ${message.messageId}");
}

void main() async {
  // 1. Bloqueamos el arranque para inicializar los motores nativos
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Inicializamos el formato de fechas
  await initializeDateFormatting('es_ES', null);

  // 3. Inicializamos Firebase con manejo de errores
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase inicializado correctamente en main()");
    
    // 4. Registramos el manejador de segundo plano
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
  } catch (e) {
    print("❌ ERROR CRÍTICO AL INICIALIZAR FIREBASE: $e");
  }

  // 5. Arrancamos la UI
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
          // --- PALETA CIAN / AZUL ---
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00BCD4),
            primary: const Color(0xFF00BCD4),
            secondary: const Color(0xFF29B6F6),
            tertiary: const Color(0xFF26C6DA),
            surfaceTint: const Color(0xFF4DD0E1),
            background: const Color(0xFFF0F8FA),
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF0F8FA),
          
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
              foregroundColor: Colors.white,
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF00BCD4),
            foregroundColor: Colors.white,
          ),
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

  Future<void> _checkAndInitNotifications() async {
    // Obtenemos el authService sin escuchar cambios para evitar reconstrucciones infinitas
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Solo inicializamos si hay usuario logueado y no lo hemos hecho antes
    if (authService.currentUser != null && !_notificationsInitialized) {
      try {
        FirebaseMessaging messaging = FirebaseMessaging.instance;
        
        // --- 3. SOLICITUD DE PERMISOS EXPLÍCITA (Vital para iOS) ---
        NotificationSettings settings = await messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

        print('🔔 Permiso de notificaciones estado: ${settings.authorizationStatus}');

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          // Obtener e imprimir el token
          String? token = await messaging.getToken();
          print("========================================");
          print("🔥 TOKEN PARA FIREBASE CONSOLE:");
          print(token);
          print("========================================");

          // Inicializar tu servicio de notificaciones personalizado
          // Asegúrate de que NotificationService maneje errores internamente
          NotificationService().init(authService, context);
          
          // Configurar presentación en primer plano (Heads-up notification)
          await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
            alert: true, 
            badge: true,
            sound: true,
          );
        } else {
          print("⚠️ El usuario no autorizó las notificaciones");
        }
        
        _notificationsInitialized = true;
        
      } catch (e) {
        print("⚠️ Error inicializando notificaciones (posible problema de red): $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (authService.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00BCD4))
        )
      );
    }

    if (authService.currentUser == null) {
      _notificationsInitialized = false; // Resetear flag al salir
      return const LoginScreen();
    }

    return const HomeScreen(); 
  }
}