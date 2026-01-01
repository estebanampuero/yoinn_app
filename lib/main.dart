import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
// IMPORTANTE: Paquete nativo de Flutter para localización
import 'package:flutter_localizations/flutter_localizations.dart';
// IMPORTANTE: Archivo generado automáticamente
import 'package:yoinn_app/l10n/app_localizations.dart'; 
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/data_service.dart';
import 'services/notification_service.dart';
import 'services/subscription_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart'; // <--- Import del Splash Screen

// --- 1. MANEJADOR DE SEGUNDO PLANO (BACKGROUND) ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("🌙 Notificación recibida en Segundo Plano/Terminado: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
        localizationsDelegates: const [
          AppLocalizations.delegate, 
          GlobalMaterialLocalizations.delegate, 
          GlobalWidgetsLocalizations.delegate, 
          GlobalCupertinoLocalizations.delegate, 
        ],

        supportedLocales: const [
          Locale('en'), // Inglés
          Locale('es'), // Español
        ],

        localeResolutionCallback: (locale, supportedLocales) {
          if (locale != null) {
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale.languageCode) {
                return supportedLocale;
              }
            }
          }
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
        
        // Iniciamos con el Splash Screen
        home: const SplashScreen(), 
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

    // --- CAMBIO CLAVE PARA TRANSICIÓN FLUIDA ---
    // Si la app está cargando, mostramos el MISMO logo estático que en el Splash.
    // Esto evita el círculo de carga y hace que la transición sea invisible.
    if (authService.isLoading) {
      return Scaffold(
        backgroundColor: Colors.white, // Mismo fondo que Splash
        body: Center(
          child: Image.asset(
            'assets/icons/pin.png', // Misma imagen que Splash
            width: 150, // Mismo tamaño que Splash
            height: 150,
          ),
        ),
      );
    }

    if (authService.currentUser == null) {
      _notificationsInitialized = false;
      return const LoginScreen();
    }

    return const HomeScreen(); 
  }
}