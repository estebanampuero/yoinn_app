import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:yoinn_app/l10n/app_localizations.dart'; 
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/data_service.dart';
import 'services/notification_service.dart';
import 'services/subscription_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart'; 

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
        
        localizationsDelegates: const [
          AppLocalizations.delegate, 
          GlobalMaterialLocalizations.delegate, 
          GlobalWidgetsLocalizations.delegate, 
          GlobalCupertinoLocalizations.delegate, 
        ],

        supportedLocales: const [
          Locale('en'), 
          Locale('es'), 
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

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          NotificationService().init(authService, context);
          await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
            alert: true, 
            badge: true,
            sound: true,
          );
        }
        
        _notificationsInitialized = true;
        
      } catch (e) {
        print("⚠️ Error inicializando notificaciones: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    // 1. Escuchamos también al DataService para saber si ya bajó las actividades
    final dataService = Provider.of<DataService>(context);

    // 2. Definimos "Cargando Inicial" como:
    //    - Auth está cargando... O BIEN
    //    - Ya hay usuario, PERO las actividades se están cargando Y la lista está vacía (arranque en frío)
    bool isInitialLoading = authService.isLoading || 
                            (authService.currentUser != null && dataService.isLoading && dataService.activities.isEmpty);

    // 3. Mientras sea carga inicial, retornamos BLANCO VACÍO.
    //    Esto permite que el SplashScreen (que tiene el logo fijo) cubra este momento
    //    hasta que la transición termine, evitando el "salto" del logo.
    if (isInitialLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SizedBox(), 
      );
    }

    // 4. Si no hay usuario, Login
    if (authService.currentUser == null) {
      _notificationsInitialized = false;
      return const LoginScreen();
    }

    // 5. ¡Listo! Ya tenemos Usuario y Actividades cargadas. Vamos al Home sin saltos visuales.
    return const HomeScreen(); 
  }
}