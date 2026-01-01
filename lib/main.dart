import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
// IMPORTANTE: Paquete nativo de Flutter para localización
import 'package:flutter_localizations/flutter_localizations.dart';
// IMPORTANTE: Archivo generado automáticamente (CORREGIDO PARA ARCHIVOS FÍSICOS)
import 'package:yoinn_app/l10n/app_localizations.dart'; 
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/data_service.dart';
import 'services/notification_service.dart';
import 'services/subscription_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// --- 1. MANEJADOR DE SEGUNDO PLANO (BACKGROUND) ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("🌙 Notificación recibida en Segundo Plano/Terminado: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // CORREGIDO: Inicializamos para todos los idiomas soportados (no solo español)
  // Esto permite que las fechas se vean bien en Inglés (Jan 1) y Español (1 Ene)
  await initializeDateFormatting(); 

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase inicializado correctamente en main()");
    
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    await SubscriptionService.init();
    print("✅ RevenueCat inicializado correctamente");

  } catch (e) {
    print("❌ ERROR CRÍTICO AL INICIALIZAR FIREBASE O REVENUECAT: $e");
  }

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
        
        // --- CONFIGURACIÓN DE INTERNACIONALIZACIÓN ---
        // 1. Delegados que "enseñan" a los widgets a hablar idiomas
        localizationsDelegates: const [
          AppLocalizations.delegate, // Tus textos propios (generado)
          GlobalMaterialLocalizations.delegate, // Textos de Material (ej: "CANCELAR" en diálogos)
          GlobalWidgetsLocalizations.delegate, // Textos de widgets básicos (ej: dirección del texto LTR/RTL)
          GlobalCupertinoLocalizations.delegate, // Textos estilo iOS (ej: "Cortar/Pegar")
        ],

        // 2. Lista de idiomas que tu app soporta oficialmente
        supportedLocales: const [
          Locale('en'), // Inglés
          Locale('es'), // Español
        ],

        // 3. Lógica inteligente para decidir qué idioma mostrar
        localeResolutionCallback: (locale, supportedLocales) {
          // Si el celular informa un idioma (ej: 'es_CL')
          if (locale != null) {
            for (var supportedLocale in supportedLocales) {
              // Comparamos solo el código de idioma ('es'), ignorando el país ('CL')
              if (supportedLocale.languageCode == locale.languageCode) {
                return supportedLocale;
              }
            }
          }
          // Si no encontramos coincidencia (ej: el usuario tiene el celu en Japonés),
          // usamos el primero de la lista (Inglés) como fallback.
          return supportedLocales.first;
        },
        // ----------------------------------------------------

        theme: ThemeData(
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
  void initState() {
    super.initState();
    
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      bool isPro = customerInfo.entitlements.all["Yoinn Pro"]?.isActive ?? false;
      
      if (!isPro) {
        print("⚠️ El estado de la suscripción cambió a: INACTIVO");
      } else {
        print("🌟 El estado de la suscripción cambió a: ACTIVO (Yoinn Pro)");
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndInitNotifications();
  }

  Future<void> _checkAndInitNotifications() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (authService.currentUser != null && !_notificationsInitialized) {
      try {
        await SubscriptionService.logIn(authService.currentUser!.uid);

        FirebaseMessaging messaging = FirebaseMessaging.instance;
        
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
          String? token = await messaging.getToken();
          print("========================================");
          print("🔥 TOKEN PARA FIREBASE CONSOLE:");
          print(token);
          print("========================================");

          NotificationService().init(authService, context);
          
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
      _notificationsInitialized = false;
      return const LoginScreen();
    }

    return const HomeScreen(); 
  }
}