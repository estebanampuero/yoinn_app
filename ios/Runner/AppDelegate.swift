import UIKit
import Flutter
import GoogleMaps // Mantenemos esto

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // 1. Configuración de Google Maps (Mantenemos tu clave)
    GMSServices.provideAPIKey("AIzaSyDiAUkUBYs3xjQOF3ME7AOv8KI5Oi_8psw") 
    
    // 2. Registro de plugins de Flutter (Vital)
    GeneratedPluginRegistrant.register(with: self)
    
    // 3. --- ESTO ES LO QUE FALTABA PARA FIREBASE ---
    // Esto permite mostrar notificaciones mientras la app está abierta (Banner)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    
    // Esto registra oficialmente la app en los servidores de Apple para recibir Push
    application.registerForRemoteNotifications()
    // ----------------------------------------------

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}