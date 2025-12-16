import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'auth_service.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Plugin para notificaciones locales (Android/iOS foreground)
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init(AuthService authService) async {
    // 1. Pedir permiso a iOS/Android
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permiso de notificaciones concedido');
      
      // 2. Configurar presentación en primer plano (iOS)
      // Esto hace que la notificación baje como banner aunque tengas la app abierta
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Obtener Token y guardarlo
      String? token = await _firebaseMessaging.getToken();
      print("📲 FCM TOKEN: $token"); // <-- Si esto imprime null, hay un problema
      
      if (token != null && authService.currentUser != null) {
        await _db.collection('users').doc(authService.currentUser!.uid).update({
          'fcmToken': token,
        });
      }

      // 4. Configurar Notificaciones Locales (Para mostrar el aviso bonito)
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings();

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _localNotifications.initialize(initializationSettings);

      // 5. Escuchar mensajes en primer plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📩 Mensaje recibido en foreground: ${message.notification?.title}');
        
        // Mostrar notificación local
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'yoinn_channel_high',
                'Notificaciones Importantes',
                importance: Importance.max,
                priority: Priority.high,
                icon: android?.smallIcon,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
          );
        }
      });
    } else {
      print('❌ Permiso denegado');
    }
  }
}