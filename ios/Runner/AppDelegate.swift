import UIKit
import Flutter
import GoogleMaps
import UserNotifications // <--- MEJORA: Import necesario para asegurar que UNUserNotificationCenter funcione bien

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // 1. Configuración de Google Maps (Tu clave intacta)
    GMSServices.provideAPIKey("AIzaSyDiAUkUBYs3xjQOF3ME7AOv8KI5Oi_8psw")
    
    // 2. Registro de plugins de Flutter
    GeneratedPluginRegistrant.register(with: self)
    
    // 3. Configuración de Notificaciones (Firebase / Local Notifications)
    if #available(iOS 10.0, *) {
      // Esto conecta los eventos de iOS con el plugin de mensajería de Flutter
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    
    // Solicita el token de dispositivo a Apple (Vital para Firebase)
    application.registerForRemoteNotifications()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}