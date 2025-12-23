import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:ui'; // Para el efecto Blur (Glassmorphism)

// --- PALETA DE COLORES "YOINN PRO" ---
const kPremiumBg = Color(0xFF15202B); // Plomo Oscuro (Fondo)
const kPremiumCard = Color(0xFF1E2732); // Plomo un poco más claro (Tarjetas)
const kYoinnCyan = Color(0xFF00BCD4);   // Tu color de marca original
const kProGold = Color(0xFFFFD700);     // Color Premium
const kTextWhite = Color(0xFFECEFF1);   // Blanco hueso

class PaywallProScreen extends StatefulWidget {
  const PaywallProScreen({super.key});

  @override
  State<PaywallProScreen> createState() => _PaywallProScreenState();
}

class _PaywallProScreenState extends State<PaywallProScreen> {
  Package? _monthlyPackage;
  bool _isLoading = true;
  int _carouselIndex = 0;

  // --- CAROUSEL DE BENEFICIOS ---
  final List<Map<String, dynamic>> _features = [
    {
      "title": "Sin Límites de Unión",
      "desc": "Olvídate del límite de 3 uniones semanales. Únete a todo lo que quieras.",
      "icon": Icons.all_inclusive,
      "color": kYoinnCyan,
    },
    {
      "title": "Eventos Masivos",
      "desc": "Pasa de 3 invitados a 20. Organiza las mejores fiestas y reuniones.",
      "icon": Icons.groups,
      "color": kProGold,
    },
    {
      "title": "Multitasking Real",
      "desc": "Crea hasta 10 actividades simultáneas. El plan gratuito solo permite 1.",
      "icon": Icons.layers_outlined,
      "color": kYoinnCyan,
    },
    {
      "title": "Insignia de Verificado",
      "desc": "Destaca en el feed con el borde dorado y genera más confianza.",
      "icon": Icons.verified,
      "color": kProGold,
    },
  ];

  @override
  void initState() {
    super.initState();
    // 1. ACTIVAMOS MODO CHISMOSO DE REVENUECAT
    Purchases.setLogLevel(LogLevel.debug); 
    _fetchOfferings();
  }

  // --- LÓGICA DE CARGA DE PRODUCTOS (CON LOGS) ---
  Future<void> _fetchOfferings() async {
    print("🔵 [DEBUG] Iniciando _fetchOfferings()...");
    
    try {
      Offerings offerings = await Purchases.getOfferings();
      
      // Diagnóstico de la oferta actual
      if (offerings.current != null) {
        print("🟢 [DEBUG] Oferta 'Current' encontrada. ID: ${offerings.current!.identifier}");
        
        if (offerings.current!.monthly != null) {
          final product = offerings.current!.monthly!.storeProduct;
          print("🟢 [DEBUG] Paquete Mensual OK: ${product.title} - Precio: ${product.priceString}");
          
          if (mounted) {
            setState(() {
              _monthlyPackage = offerings.current!.monthly;
              _isLoading = false;
            });
          }
        } else {
          print("🔴 [DEBUG] La oferta actual (${offerings.current!.identifier}) NO tiene paquete 'monthly'.");
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        print("🔴 [DEBUG] Offerings.current es NULL. Revisa el Dashboard de RevenueCat.");
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print("🔴 [DEBUG] EXCEPCIÓN al traer ofertas: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LÓGICA DE COMPRA (CON LOGS) ---
  Future<void> _buyPro() async {
    print("🟡 [DEBUG] Botón 'ACTIVAR' presionado.");

    if (_monthlyPackage == null) {
      print("🔴 [DEBUG] Error: _monthlyPackage es null. No se puede iniciar transacción.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: No se cargó el producto de Apple"), backgroundColor: Colors.red)
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print("🟡 [DEBUG] Enviando solicitud de compra a Apple...");
      CustomerInfo customerInfo = await Purchases.purchasePackage(_monthlyPackage!);
      
      print("🟢 [DEBUG] Transacción finalizada. Info del cliente recibida.");
      
      // CORRECCIÓN AQUÍ: Usamos "Yoinn Pro" en lugar de "pro"
      final isPro = customerInfo.entitlements.all["Yoinn Pro"]?.isActive == true;
      print("🔍 [DEBUG] Estado del Entitlement 'Yoinn Pro': ${isPro ? 'ACTIVO ✅' : 'INACTIVO ❌'}");

      if (isPro) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("¡Bienvenido a Yoinn PRO! 🌟"), backgroundColor: kProGold)
          );
          Navigator.pop(context, true); // Volvemos con éxito
        }
      } else {
        print("🟠 [DEBUG] La compra se procesó pero RevenueCat dice que 'Yoinn Pro' no es válido.");
      }

    } catch (e) {
      print("🔴 [DEBUG] Error en la transacción: $e");
      if (mounted) {
        // Mostramos el error en pantalla para que lo veas en el celular
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString().split(']').last}"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LÓGICA DE RESTAURAR ---
  Future<void> _restore() async {
    print("🔵 [DEBUG] Intentando restaurar compras...");
    setState(() => _isLoading = true);
    try {
      CustomerInfo info = await Purchases.restorePurchases();
      // CORRECCIÓN AQUÍ: Usamos "Yoinn Pro" en lugar de "pro"
      final isPro = info.entitlements.all["Yoinn Pro"]?.isActive == true;
      
      print("🔍 [DEBUG] Restauración terminada. Es PRO: $isPro");

      if (isPro) {
        if (mounted) Navigator.pop(context, true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No se encontraron compras activas para restaurar."))
          );
        }
      }
    } catch (e) {
      print("🔴 [DEBUG] Error al restaurar: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPremiumBg, 
      body: Stack(
        children: [
          // 1. LUCES AMBIENTALES
          Positioned(
            top: -80,
            left: -50,
            child: _buildBlurBlob(kYoinnCyan, 250),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: _buildBlurBlob(kProGold, 250),
          ),
          
          // Filtro Glassmorphism
          Positioned.fill(
             child: BackdropFilter(
               filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
               child: Container(color: kPremiumBg.withOpacity(0.85)),
             ),
          ),

          SafeArea(
            child: Column(
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : _restore,
                        child: const Text("Restaurar", style: TextStyle(color: Colors.white30, fontSize: 12)),
                      )
                    ],
                  ),
                ),

                // LOGO
                Hero(
                  tag: 'pro_icon',
                  child: Icon(Icons.star_rounded, color: kProGold, size: 48),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, fontFamily: 'Rounded', letterSpacing: 1),
                    children: [
                      const TextSpan(text: "Yoinn ", style: TextStyle(color: kTextWhite)),
                      TextSpan(text: "PRO", style: TextStyle(color: kProGold, shadows: [Shadow(color: kProGold.withOpacity(0.5), blurRadius: 15)])),
                    ],
                  ),
                ),
                
                const Spacer(flex: 1),

                // 2. CAROUSEL
                SizedBox(
                  height: 260, 
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 0.85),
                    onPageChanged: (index) => setState(() => _carouselIndex = index),
                    itemCount: _features.length,
                    itemBuilder: (context, index) {
                      return _buildFeatureCard(_features[index], index == _carouselIndex);
                    },
                  ),
                ),

                // PUNTOS
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_features.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      width: _carouselIndex == index ? 20 : 6,
                      decoration: BoxDecoration(
                        color: _carouselIndex == index ? kYoinnCyan : Colors.white12,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),

                const Spacer(flex: 2),

                // 3. ZONA DE COMPRA
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: kPremiumCard,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                    border: Border(top: BorderSide(color: Colors.white10)),
                  ),
                  child: Column(
                    children: [
                      // Tarjeta de precio
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: kProGold.withOpacity(0.5), width: 1.5),
                          borderRadius: BorderRadius.circular(16),
                          color: kProGold.withOpacity(0.05),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Suscripción Mensual", style: TextStyle(color: kTextWhite, fontWeight: FontWeight.bold, fontSize: 15)),
                                Text("Cancela cuando quieras", style: TextStyle(color: Colors.white38, fontSize: 12)),
                              ],
                            ),
                            _isLoading 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: kProGold))
                              : Text(
                                  _monthlyPackage?.storeProduct.priceString ?? "--",
                                  style: const TextStyle(color: kProGold, fontWeight: FontWeight.bold, fontSize: 20),
                                ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),

                      // BOTÓN
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              colors: [kProGold, Color(0xFFFFA000)],
                            ),
                            boxShadow: [
                              BoxShadow(color: kProGold.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))
                            ]
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                            ),
                            onPressed: (_isLoading || _monthlyPackage == null) ? null : _buyPro,
                            child: const Text(
                              "ACTIVAR YOINN PRO",
                              style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      const Text(
                        "Términos y condiciones • Política de privacidad",
                        style: TextStyle(color: Colors.white24, fontSize: 10),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DE DISEÑO ---

  Widget _buildBlurBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> item, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      transform: Matrix4.identity()..scale(isActive ? 1.0 : 0.95),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kPremiumCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive ? item['color'].withOpacity(0.3) : Colors.transparent,
          width: 1.5
        ),
        boxShadow: isActive ? [
           BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
        ] : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: (item['color'] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item['icon'], size: 48, color: item['color']),
          ),
          const SizedBox(height: 20),
          Text(
            item['title'],
            style: const TextStyle(color: kTextWhite, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            item['desc'],
            style: const TextStyle(color: Colors.white60, fontSize: 14, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}