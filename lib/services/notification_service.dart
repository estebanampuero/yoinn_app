import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart'; // Necesario para la navegación
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
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true,
      );

      // 3. Configurar Canales Locales
      await _setupLocalNotifications();

      // 4. Obtener y Guardar Token
      await _saveToken(authService);

      // 5. LISTENERS
      // A. Segundo Plano -> Usuario toca la notificación
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleMessageNavigation(message, context);
      });

      // B. App Cerrada -> Usuario toca la notificación y la app se abre
      _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          _handleMessageNavigation(message, context);
        }
      });

      // C. Primer Plano -> Mostrar banner local
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });
      
    } else {
      print('❌ Permiso denegado');
    }
  }

  // Lógica de Navegación Inteligente
  void _handleMessageNavigation(RemoteMessage message, BuildContext context) {
    final data = message.data;
    final type = data['type'];
    final activityId = data['activityId'];

    print("🚀 Navegando por notificación: Tipo $type, ID: $activityId");

    if (activityId != null) {
      if (type == 'chat') {
        // Navegar al Chat de la actividad (Ajusta la ruta según tu app)
        // Navigator.pushNamed(context, '/chat', arguments: activityId);
        print("-> Ir al chat de $activityId");
      } else if (type == 'request_join' || type == 'request_accepted') {
        // Navegar al Detalle o a la pantalla de Notificaciones
        // Navigator.pushNamed(context, '/activity_detail', arguments: activityId);
        print("-> Ir al detalle de $activityId");
      }
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
      print("📲 FCM TOKEN ACTUALIZADO: $token");
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

    await _localNotifications.initialize(settings);
  }

  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

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
      );
    }
  }
}