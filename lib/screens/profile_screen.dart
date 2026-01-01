import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoinn_app/l10n/app_localizations.dart'; 

import '../models/user_model.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../config/subscription_limits.dart';
import 'admin_screen.dart';
import 'paywall_pro_screen.dart'; 
import '../widgets/profile_header.dart';
import '../widgets/profile_gallery.dart';
import '../widgets/profile_activities_list.dart';

// COLORES AESTHETIC PRO
const kYoinnCyan = Color(0xFF00BCD4);
const kBgScreen = Color(0xFFF0F8FA);
const kTextBlack = Color(0xFF1A1A1A);
const kTextGrey = Color(0xFF757575);
const kGoldDark = Color(0xFFB8860B);
const kGoldLight = Color(0xFFFFD700);
const kGoldMetallic = Color(0xFFD4AF37); 

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isPremium = false;
  bool _loadingPremium = true;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    final status = await SubscriptionService.isUserPremium();
    if (mounted) {
      setState(() {
        _isPremium = status;
        _loadingPremium = false;
      });
    }
  }

  void _showPaywall() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const PaywallProScreen())
    );

    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.msgWelcomePro))
        );
      }
      _checkPremiumStatus();
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final confirmationController = TextEditingController();
    
    final keyword = l10n.hintDelete; 

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.dialogDeleteAccountTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.dialogDeleteAccountBody),
            const SizedBox(height: 10),
            Text(l10n.lblTypeDelete, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: confirmationController,
              decoration: InputDecoration(
                hintText: keyword,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: Text(l10n.btnCancel, style: const TextStyle(color: Colors.grey))
          ),
          TextButton(
            onPressed: () async {
              if (confirmationController.text.trim().toUpperCase() != keyword.toUpperCase()) return;
              try {
                await Provider.of<AuthService>(context, listen: false).deleteAccount();
                if (mounted) {
                  Navigator.pop(ctx);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } catch (e) {
                if (mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${l10n.errorGeneric}: $e")));
              }
            },
            child: Text(l10n.btnDeleteConfirm, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);
    final dataService = Provider.of<DataService>(context, listen: false); 
    final isMe = authService.currentUser?.uid == widget.uid;

    return FutureBuilder<UserModel?>(
      future: dataService.getUserProfile(widget.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: kBgScreen,
            body: Center(child: CircularProgressIndicator(color: kYoinnCyan))
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(appBar: AppBar(), body: Center(child: Text(l10n.errUserNotFound)));
        }

        final user = snapshot.data!;
        final isAdmin = isMe && user.isAdmin;
        final isLocalGuide = user.activitiesCreatedCount > 5;
        final bool isProReal = _isPremium || user.isManualPro;

        return Scaffold(
          backgroundColor: kBgScreen,
          appBar: AppBar(
            title: Text(
              l10n.screenProfileTitle, 
              style: const TextStyle(color: kYoinnCyan, fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -0.5)
            ),
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: kTextBlack,
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.security, color: Colors.red),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
                ),
              if (isMe)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.grey),
                    onPressed: () {
                      authService.signOut();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                )
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                // 1. HEADER DEL PERFIL
                ProfileHeader(
                  user: user, 
                  isMe: isMe, 
                  isLocalGuide: isLocalGuide,
                  isPro: isProReal, 
                  onEditProfile: () => setState((){}), 
                ),

                // 2. BANNER PRO (Si no es pro)
                if (isMe && !_loadingPremium && !isProReal) ...[
                  const SizedBox(height: 24),
                  _buildUpgradeBanner(l10n), 
                ],

                // 3. PREFERENCIAS DE BÚSQUEDA (Slider)
                if (isMe && !_loadingPremium) ...[
                  const SizedBox(height: 24),
                  _buildDistancePreference(isProReal, l10n),
                ],

                const SizedBox(height: 30),
                
                // 4. GALERÍA (Sin título, visualmente limpia)
                ProfileGallery(
                  user: user, 
                  isMe: isMe,
                  onImageUploaded: () => setState((){}),
                ),

                const SizedBox(height: 30),

                // 5. ACTIVIDADES (Sin título, flujo continuo)
                ProfileActivitiesList(
                  uid: widget.uid, 
                  isMe: isMe
                ),

                const SizedBox(height: 50),

                // 6. ELIMINAR CUENTA
                if (isMe)
                  TextButton(
                    onPressed: () => _showDeleteAccountDialog(context),
                    child: Text(
                      l10n.btnDeleteAccount, 
                      style: TextStyle(color: Colors.red.shade300, fontSize: 13, decoration: TextDecoration.underline)
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUpgradeBanner(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _showPaywall, 
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kGoldMetallic.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(color: kGoldMetallic.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [kGoldLight, kGoldMetallic], begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: kGoldMetallic.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]
              ),
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.bannerUpgradeTitle, style: const TextStyle(color: kTextBlack, fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(l10n.bannerUpgradeSubtitle, style: const TextStyle(color: kTextGrey, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: kGoldMetallic, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDistancePreference(bool isPro, AppLocalizations l10n) {
    return Consumer<DataService>(
      builder: (context, dataService, _) {
        double currentRadius = dataService.filterRadius;
        
        final double freeMax = SubscriptionLimits.freeMaxRadius;
        final double proMax = SubscriptionLimits.proMaxRadius;
        final double currentMax = isPro ? proMax : freeMax;

        double safeValue = currentRadius.clamp(1.0, currentMax);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado interno de la tarjeta
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.radar_rounded, color: kYoinnCyan.withOpacity(0.8), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.radiusLabel, 
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kTextBlack)
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kYoinnCyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)
                    ),
                    child: Text(
                      "${safeValue.toInt()} ${l10n.kmUnit}", 
                      style: const TextStyle(fontWeight: FontWeight.w900, color: kYoinnCyan, fontSize: 14)
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Slider Moderno
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: kYoinnCyan,
                  inactiveTrackColor: Colors.grey.shade100,
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14, elevation: 4),
                  overlayColor: kYoinnCyan.withOpacity(0.1),
                  trackHeight: 6.0,
                ),
                child: Slider(
                  value: safeValue, 
                  min: 1,
                  max: currentMax, 
                  onChanged: (val) {
                    dataService.setRadiusFilter(val);
                  },
                  onChangeEnd: (val) {
                    if (!isPro && val >= freeMax) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.msgProSearchFeature),
                          duration: const Duration(seconds: 2),
                          backgroundColor: kTextBlack,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        )
                      );
                    }
                  },
                ),
              ),
              
              if (!isPro)
                GestureDetector(
                  onTap: _showPaywall,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_rounded, size: 14, color: kGoldMetallic),
                        const SizedBox(width: 6),
                        Text(
                          l10n.lblUnlockPro(proMax.toInt()), 
                          style: const TextStyle(
                            color: kGoldMetallic, 
                            fontSize: 12, 
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5
                          )
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}