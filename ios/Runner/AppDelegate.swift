import UIKit
import Flutter
import GoogleMaps // <--- Importante

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // REEMPLAZA ESTO CON TU CLAVE REAL DE GOOGLE MAPS QUE EMPIEZA CON "AIza..."
    GMSServices.provideAPIKey("AIzaSyDiAUkUBYs3xjQOF3ME7AOv8KI5Oi_8psw") 
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}