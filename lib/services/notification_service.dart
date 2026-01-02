import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart'; 
// --- IMPORTS DEL PROYECTO ---
import 'package:yoinn_app/main.dart'; // Para navigatorKey
import 'package:yoinn_app/models/activity_model.dart'; // Tu modelo Activity
import 'package:yoinn_app/screens/activity_detail_screen.dart'; // Tu pantalla detalle
import 'package:yoinn_app/screens/chat_screen.dart'; // <--- IMPORTANTE: Tu pantalla de Chat
import 'auth_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init(AuthService authService, BuildContext context) async {
    // 1. Pedir Permisos
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permiso de notificaciones concedido');
      
      // 2. Configuración Foreground (iOS)
      // iOS mostrará la notificación nativa automáticamente
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true,
      );

      // 3. Configurar Canales Locales (Android)
      await _setupLocalNotifications();

      // 4. Obtener y Guardar Token
      await _saveToken(authService);

      // 5. LISTENERS DE INTERACCIÓN

      // A. Segundo Plano -> Usuario toca la notificación
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print("👆 Tocado en segundo plano/background");
        _handleMessageNavigation(message); 
      });

      // B. App Cerrada -> Usuario toca la notificación y la app se abre
      _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          print("🚀 App abierta desde terminada por notificación");
          _handleMessageNavigation(message); 
        }
      });

      // C. Primer Plano -> Mostrar banner local (Solo Android)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // En iOS no hacemos nada manual (el sistema lo maneja).
        // En Android generamos la notificación local.
        if (Platform.isAndroid) {
           _showLocalNotification(message);
        }
      });
      
    } else {
      print('❌ Permiso denegado');
    }
  }

  // --- LÓGICA DE NAVEGACIÓN ---
  Future<void> _handleMessageNavigation(RemoteMessage message) async {
    final data = message.data;
    final activityId = data['activityId'];
    final type = data['type']; // 'chat', 'request_join', 'request_accepted'

    print("🚀 Intentando navegar. Tipo: $type, ID: $activityId");

    if (activityId != null) {
      // Delegamos la descarga y redirección
      await _fetchAndNavigate(activityId, type);
    }
  }

  // Descarga la actividad completa y elige a qué pantalla ir
  Future<void> _fetchAndNavigate(String activityId, String? type) async {
    try {
      DocumentSnapshot doc = await _db.collection('activities').doc(activityId).get();

      if (doc.exists) {
        // Convertimos el documento en tu objeto Activity usando tu factory
        Activity activity = Activity.fromFirestore(doc); 

        // 🔀 DECISIÓN DE RUTA
        if (type == 'chat') {
          print("💬 Navegando al CHAT de ${activity.title}");
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(activity: activity), // <--- Integración Real
            ),
          );
        } else {
          // Para 'request_join', 'request_accepted' o cualquier otro, vamos al Detalle
          print("📄 Navegando al DETALLE de ${activity.title}");
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => ActivityDetailScreen(activity: activity),
            ),
          );
        }

      } else {
        print("⚠️ Actividad no encontrada en Firebase (posiblemente borrada)");
      }
    } catch (e) {
      print("❌ Error crítico navegando: $e");
    }
  }

  Future<void> _saveToken(AuthService authService) async {
    String? token;
    if (Platform.isIOS) {
      String? apnsToken = await _firebaseMessaging.getAPNSToken();
      if (apnsToken == null) {
        await Future.delayed(const Duration(seconds: 3));
        apnsToken = await _firebaseMessaging.getAPNSToken();
      }
      if (apnsToken != null) {
         token = await _firebaseMessaging.getToken();
      }
    } else {
      token = await _firebaseMessaging.getToken();
    }

    if (token != null && authService.currentUser != null) {
      // Actualizamos el token en Firestore
      await _db.collection('users').doc(authService.currentUser!.uid).update({
        'fcmToken': token,
      });
    }
  }

  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings, iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      // ✅ IMPORTANTE: Manejar clic en notificación LOCAL (Android Primer Plano)
      onDidReceiveNotificationResponse: (NotificationResponse response) {
         final String? activityId = response.payload;
         // Como en la notificación local no guardamos el 'type' en el payload simple,
         // por defecto intentamos navegar. Podrías mejorar esto guardando un JSON string.
         if (activityId != null && activityId.isNotEmpty) {
            print("👆 Tocado en notificación local (Android). ID: $activityId");
            // Nota: Aquí no sabemos si es Chat o Detalle porque el payload solo tiene ID.
            // Por defecto irá al Detalle, salvo que modifiquemos el payload.
            // Para simplificar, lo mandamos a descargar y que decida (pasando null type irá a detalle)
            // O idealmente: _fetchAndNavigate(activityId, 'chat') si quieres priorizar chat.
            _fetchAndNavigate(activityId, null); 
         }
      },
    );
  }

  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    
    // Extraemos ID para pasarlo como payload
    final String? activityId = message.data['activityId'];

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'yoinn_channel_high', 'Notificaciones Importantes',
            importance: Importance.max, priority: Priority.high,
            icon: android?.smallIcon,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true,
          ),
        ),
        payload: activityId, // Esto habilita el clic en Android Foreground
      );
    }
  }
}