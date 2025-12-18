import 'dart:io'; // <--- Importante para detectar Platform.isIOS
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
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Obtener Token y guardarlo (CORRECCIÓN PARA EL ERROR APNS)
      String? token;

      if (Platform.isIOS) {
        // En iOS, el token de Firebase necesita primero el token de APNS.
        // A veces tarda unos milisegundos, así que lo verificamos.
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        
        if (apnsToken == null) {
          print('⏳ Esperando APNS Token...');
          // Esperamos 3 segundos y reintentamos
          await Future.delayed(const Duration(seconds: 3));
          apnsToken = await _firebaseMessaging.getAPNSToken();
        }

        if (apnsToken != null) {
          try {
            token = await _firebaseMessaging.getToken();
          } catch (e) {
            print("Error obteniendo FCM token en iOS: $e");
          }
        } else {
          print("⚠️ No se pudo obtener APNS Token. Las notificaciones pueden fallar en Simulador.");
        }
      } else {
        // En Android es directo
        try {
          token = await _firebaseMessaging.getToken();
        } catch (e) {
          print("Error obteniendo FCM token en Android: $e");
        }
      }

      print("📲 FCM TOKEN: $token");
      
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