import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

const kYoinnCyan = Color(0xFF00BCD4);
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
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const PaywallProScreen())
    );

    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Bienvenido a Yoinn PRO! 🌟"))
        );
      }
      _checkPremiumStatus();
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final confirmationController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminar Cuenta"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Esta acción es irreversible. Se borrarán tus datos y actividades."),
            const SizedBox(height: 10),
            const Text("Escribe ELIMINAR para confirmar:", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: confirmationController,
              decoration: const InputDecoration(hintText: "ELIMINAR"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              if (confirmationController.text.trim() != "ELIMINAR") return;
              try {
                await Provider.of<AuthService>(context, listen: false).deleteAccount();
                if (mounted) {
                  Navigator.pop(ctx);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } catch (e) {
                if (mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("BORRAR", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final dataService = Provider.of<DataService>(context, listen: false); 
    final isMe = authService.currentUser?.uid == widget.uid;

    return FutureBuilder<UserModel?>(
      future: dataService.getUserProfile(widget.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: kYoinnCyan)));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text("Usuario no encontrado")));
        }

        final user = snapshot.data!;
        final isAdmin = isMe && user.isAdmin;
        final isLocalGuide = user.activitiesCreatedCount > 5;
        final bool isProReal = _isPremium || user.isManualPro;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text("Perfil", style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: false,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: kTextBlack,
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.security, color: Colors.red),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
                ),
              if (isMe)
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.grey),
                  onPressed: () {
                    authService.signOut();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                )
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                ProfileHeader(
                  user: user, 
                  isMe: isMe, 
                  isLocalGuide: isLocalGuide,
                  isPro: isProReal, 
                  onEditProfile: () => setState((){}), 
                ),

                // Banner de Venta solo si es Free
                if (isMe && !_loadingPremium && !isProReal) ...[
                  const SizedBox(height: 25),
                  _buildUpgradeBanner(), 
                ],

                if (isMe && !_loadingPremium) ...[
                  const SizedBox(height: 30),
                  const Align(
                    alignment: Alignment.centerLeft, 
                    child: Text("Preferencias de Búsqueda", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: kTextBlack))
                  ),
                  const SizedBox(height: 15),
                  
                  _buildDistancePreference(isProReal),
                  
                  // Se eliminó la sección "Modo Viajero" para simplificar la lógica
                ],

                const SizedBox(height: 30),
                const Divider(color: Colors.black12),
                const SizedBox(height: 20),

                const Align(
                  alignment: Alignment.centerLeft, 
                  child: Text("Galería", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: kTextBlack))
                ),
                const SizedBox(height: 15),
                ProfileGallery(
                  user: user, 
                  isMe: isMe,
                  onImageUploaded: () => setState((){}),
                ),

                const SizedBox(height: 30),

                const Align(
                  alignment: Alignment.centerLeft, 
                  child: Text("Actividades", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: kTextBlack))
                ),
                const SizedBox(height: 15),
                ProfileActivitiesList(
                  uid: widget.uid, 
                  isMe: isMe
                ),

                const SizedBox(height: 50),

                if (isMe)
                  TextButton(
                    onPressed: () => _showDeleteAccountDialog(context),
                    child: Text("Eliminar cuenta", style: TextStyle(color: Colors.red.shade300, decoration: TextDecoration.underline, fontSize: 12)),
                  ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUpgradeBanner() {
    return GestureDetector(
      onTap: _showPaywall, 
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kGoldMetallic.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(color: kGoldMetallic.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kGoldLight.withOpacity(0.2),
                shape: BoxShape.circle
              ),
              child: const Icon(Icons.star_rounded, color: kGoldMetallic, size: 28),
            ),
            const SizedBox(width: 15),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pásate a Yoinn PRO", style: TextStyle(color: kTextBlack, fontWeight: FontWeight.w800, fontSize: 16)),
                  Text("Desbloquea viajes y más alcance", style: TextStyle(color: kTextGrey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: kGoldMetallic, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDistancePreference(bool isPro) {
    return Consumer<DataService>(
      builder: (context, dataService, _) {
        double currentRadius = dataService.filterRadius;
        
        final double freeMax = SubscriptionLimits.freeMaxRadius;
        final double proMax = SubscriptionLimits.proMaxRadius;
        final double currentMax = isPro ? proMax : freeMax;

        // Aseguramos que el valor visual nunca supere el máximo permitido
        // Si tienes 80km guardados pero ahora eres Free, el slider se queda en 30km visualmente.
        double safeValue = currentRadius.clamp(1.0, currentMax);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))
            ],
            border: Border.all(color: Colors.grey.shade100)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Radio de búsqueda", 
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kTextBlack)
                  ),
                  Text(
                    "${safeValue.toInt()} km", 
                    style: const TextStyle(fontWeight: FontWeight.w900, color: kYoinnCyan, fontSize: 16)
                  ),
                ],
              ),
              const SizedBox(height: 15),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: kYoinnCyan,
                  inactiveTrackColor: Colors.grey.shade200,
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12, elevation: 4),
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
                        const SnackBar(
                          content: Text("Hazte PRO para buscar hasta 150 km 🌍"),
                          duration: Duration(seconds: 2),
                          backgroundColor: kTextBlack,
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
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline, size: 14, color: kGoldMetallic),
                        const SizedBox(width: 6),
                        Text(
                          "Desbloquear hasta ${proMax.toInt()} km", 
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