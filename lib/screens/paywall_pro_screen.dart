import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'dart:ui';
import 'package:yoinn_app/l10n/app_localizations.dart'; // <--- IMPORTANTE

import '../config/subscription_limits.dart';

// --- PALETA DE COLORES PREMIUM ---
const kWhiteBg = Colors.white;
const kYoinnCyan = Color(0xFF00BCD4);
const kTextBlack = Color(0xFF1A1A1A);
const kTextGrey = Color(0xFF757575);

const kGoldDark = Color(0xFFB8860B);
const kGoldLight = Color(0xFFFFD700);
const kGoldMetallic = Color(0xFFD4AF37);

class PaywallProScreen extends StatefulWidget {
  const PaywallProScreen({super.key});

  @override
  State<PaywallProScreen> createState() => _PaywallProScreenState();
}

class _PaywallProScreenState extends State<PaywallProScreen> {
  Package? _monthlyPackage;
  Package? _annualPackage;
  String _selectedPlanKey = 'annual'; 
  bool _isLoading = true;

  final String _termsUrl = "https://estebanampuero.github.io/yoinn.info/#terminos"; 
  final String _privacyUrl = "https://estebanampuero.github.io/yoinn.info/#privacidad"; 

  @override
  void initState() {
    super.initState();
    // Purchases.setLogLevel(LogLevel.debug); 
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        if (mounted) {
          setState(() {
            _monthlyPackage = offerings.current!.monthly;
            _annualPackage = offerings.current!.annual;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _buyPro() async {
    final l10n = AppLocalizations.of(context)!;
    Package? packageToBuy;
    if (_selectedPlanKey == 'annual') {
      packageToBuy = _annualPackage;
    } else {
      packageToBuy = _monthlyPackage;
    }

    if (packageToBuy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.paywallErrNoPlan))
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      CustomerInfo customerInfo = await Purchases.purchasePackage(packageToBuy);
      final isPro = customerInfo.entitlements.all["Yoinn Pro"]?.isActive == true;

      if (isPro && mounted) {
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted && !e.toString().contains("User cancelled")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${l10n.errorGeneric}: ${e.toString()}"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restore() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      CustomerInfo info = await Purchases.restorePurchases();
      final isPro = info.entitlements.all["Yoinn Pro"]?.isActive == true;
      
      if (isPro && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.paywallErrNoPurchases))
        );
      }
    } catch (e) {
      print("Error restoring: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      debugPrint('No se pudo abrir $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    String monthlyEquivalent = "";
    if (_annualPackage != null) {
      // Calculamos el precio mensual equivalente del plan anual
      final price = _annualPackage!.storeProduct.price;
      final currency = _annualPackage!.storeProduct.currencyCode; 
      final double monthlyPrice = price / 12;
      // "Solo $ 9.99 / mes"
      monthlyEquivalent = l10n.lblOnlyPricePerMonth("$currency ${monthlyPrice.toStringAsFixed(2)}");
    }

    return Scaffold(
      backgroundColor: kWhiteBg,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: kYoinnCyan))
        : Column(
            children: [
              // 1. HEADER
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/icons/pin.png'),
                          fit: BoxFit.cover,
                          opacity: 0.8
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF006064), kYoinnCyan], 
                        )
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 30),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 30,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          Text(
                            l10n.paywallTitle, // "Desbloquea el Mundo"
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              shadows: [Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 2))]
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.paywallSubtitle, // "Con Yoinn Premium"
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: kGoldLight, 
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              // 2. CONTENIDO
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    children: [
                      _buildComparisonTable(l10n),
                      
                      const SizedBox(height: 30),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildPlanCard(
                              keyName: 'annual',
                              title: l10n.paywallPlanAnnual, // "ANUAL"
                              price: _annualPackage?.storeProduct.priceString ?? "--",
                              subtitle: "/${l10n.fieldDate.substring(0, 3)}", // Truco rápido: "Fecha" -> "Fec" o usar "/yr" si agregas key
                              savings: l10n.lblSavePercent, 
                              isBestValue: true,
                              monthlyEquivalent: monthlyEquivalent, 
                            ),
                          ),
                          
                          const SizedBox(width: 12),

                          Expanded(
                            child: _buildPlanCard(
                              keyName: 'monthly',
                              title: l10n.paywallPlanMonthly, // "MENSUAL"
                              price: _monthlyPackage?.storeProduct.priceString ?? "--",
                              subtitle: "/${l10n.fieldDate.substring(0, 3) == 'Dat' ? 'mo' : 'mes'}", // Fallback simple
                              savings: null,
                              isBestValue: false,
                              monthlyEquivalent: null, 
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      GestureDetector(
                        onTap: _buyPro,
                        child: Container(
                          width: double.infinity,
                          height: 55,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [kYoinnCyan, Color(0xFF0097A7)], 
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: kYoinnCyan.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4)
                              )
                            ]
                          ),
                          child: Center(
                            child: Text(
                              l10n.paywallBtnStart, // "Comenzar Ahora"
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),
                      Center(
                        child: TextButton(
                          onPressed: _restore,
                          child: Text(
                            l10n.paywallBtnRestore, // "Restaurar Compras"
                            style: const TextStyle(color: Colors.grey, fontSize: 13, decoration: TextDecoration.underline),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      
                      Padding(
                        padding: const EdgeInsets.only(bottom: 80), 
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 15,    
                          runSpacing: 10, 
                          children: [
                            GestureDetector(
                              onTap: () => _launchURL(_termsUrl),
                              child: Text(
                                l10n.paywallLegalTerms,
                                style: const TextStyle(color: Colors.grey, fontSize: 12, decoration: TextDecoration.underline),
                              ),
                            ),
                            
                            const Text("|", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            
                            GestureDetector(
                              onTap: () => _launchURL(_privacyUrl),
                              child: Text(
                                l10n.paywallLegalPrivacy,
                                style: const TextStyle(color: Colors.grey, fontSize: 12, decoration: TextDecoration.underline),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // --- WIDGETS AUXILIARES ---
  Widget _buildComparisonTable(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Expanded(flex: 4, child: SizedBox()), 
                Expanded(
                  flex: 3, 
                  child: Center(child: Text(l10n.paywallLabelFree, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold)))
                ),
                Expanded(
                  flex: 3, 
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [kGoldMetallic, kGoldLight]),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: kGoldDark.withOpacity(0.3), blurRadius: 4)]
                      ),
                      child: Text(l10n.paywallLabelPro, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900)),
                    ),
                  )
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          
          _buildTableRow(l10n.featRadius, 
            "${SubscriptionLimits.freeMaxRadius.toInt()} ${l10n.kmUnit}", 
            "${SubscriptionLimits.proMaxRadius.toInt()} ${l10n.kmUnit}"
          ),
          _buildTableRow(l10n.featGlobal, l10n.valGlobalFree, l10n.valGlobalPro),
          _buildTableRow(l10n.featGuests, 
            l10n.valGuestsFree(SubscriptionLimits.freeMaxAttendees), 
            l10n.valGuestsPro(SubscriptionLimits.proMaxAttendees)
          ),
          _buildTableRow(l10n.featJoins, 
            l10n.valJoinsFree(SubscriptionLimits.freeMaxJoinsPerWeek), 
            l10n.valJoinsPro
          ),
          _buildTableRow(l10n.featBadge, l10n.valBadgeFree, l10n.valBadgePro, isLast: true),
        ],
      ),
    );
  }

  Widget _buildTableRow(String feature, String free, String pro, {bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 4, 
            child: Text(feature, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextBlack))
          ),
          Expanded(
            flex: 3, 
            child: Center(child: Text(free, style: const TextStyle(fontSize: 11, color: kTextGrey), textAlign: TextAlign.center))
          ),
          Expanded(
            flex: 3, 
            child: Center(
              child: Text(pro, 
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11, 
                  fontWeight: FontWeight.bold, 
                  color: Color(0xFFB8860B) 
                )
              )
            )
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String keyName, 
    required String title,
    required String price,
    required String subtitle,
    String? savings,
    bool isBestValue = false,
    String? monthlyEquivalent, 
  }) {
    final isSelected = _selectedPlanKey == keyName;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanKey = keyName;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? kYoinnCyan.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? kYoinnCyan : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected 
                ? [BoxShadow(color: kYoinnCyan.withOpacity(0.2), blurRadius: 8)] 
                : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? kTextBlack : kTextGrey,
                        fontWeight: FontWeight.bold,
                        fontSize: 11 
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? kYoinnCyan : Colors.grey.shade300,
                      size: 18,
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.w900,
                    color: kTextBlack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: kTextGrey, fontSize: 12),
                ),
                if (monthlyEquivalent != null && monthlyEquivalent.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: kGoldLight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4)
                    ),
                    child: Text(
                      monthlyEquivalent,
                      style: const TextStyle(fontSize: 10, color: Color(0xFFB8860B), fontWeight: FontWeight.bold),
                    ),
                  )
                ] else ...[
                   const SizedBox(height: 24),
                ]
              ],
            ),
          ),
          
          if (savings != null && isBestValue)
            Positioned(
              top: -10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [kGoldMetallic, kGoldLight]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                    ]
                  ),
                  child: Text(
                    savings,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}