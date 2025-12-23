import 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  // ✅ API KEY CORRECTA INTEGRADA
  static const _apiKey = 'appl_anELedxRZvCqULxNzZvSmXqEfxv';

  // OJO: Este ID debe ser IDÉNTICO al de tu captura de pantalla de RevenueCat
  static const _entitlementId = 'Yoinn Pro'; 

  // Inicialización (llamar en main.dart)
  static Future<void> init() async {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_apiKey);
    } else {
      configuration = PurchasesConfiguration(_apiKey);
    }

    await Purchases.configure(configuration);
  }

  // Identificar usuario (Login)
  static Future<void> logIn(String uid) async {
    await Purchases.logIn(uid);
  }

  // Cerrar sesión (Logout)
  static Future<void> logOut() async {
    await Purchases.logOut();
  }

  // Verificar si es PRO
  static Future<bool> isUserPremium() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      // Verificamos si tiene activo el entitlement "Yoinn Pro"
      return customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
    } catch (e) {
      return false;
    }
  }

  // Obtener la oferta actual para mostrar en el Paywall
  static Future<Package?> getCurrentOffering() async {
    try {
      Offerings offerings = await Purchases.getOfferings();
      // RevenueCat devuelve la oferta "current" configurada en el dashboard
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        return offerings.current!.availablePackages.first;
      }
    } catch (e) {
      print("Error obteniendo ofertas: $e");
    }
    return null;
  }

  // Comprar
  static Future<bool> purchasePackage(Package package) async {
    try {
      CustomerInfo customerInfo = await Purchases.purchasePackage(package);
      return customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        print("Error en compra: $e");
      }
      return false;
    }
  }

  // Restaurar compras (OBLIGATORIO PARA APPLE)
  static Future<bool> restorePurchases() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
    } catch (e) {
      return false;
    }
  }
}