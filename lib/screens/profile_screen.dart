import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:purchases_flutter/purchases_flutter.dart'; // Ya no es estrictamente necesario aquí si usamos el servicio
import '../models/user_model.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import 'admin_screen.dart';

// Importamos la nueva pantalla PRO
import 'paywall_pro_screen.dart'; 

import '../widgets/profile_header.dart';
import '../widgets/profile_gallery.dart';
import '../widgets/profile_activities_list.dart';

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

  // Verificamos si es Premium usando tu servicio (RevenueCat)
  Future<void> _checkPremiumStatus() async {
    final status = await SubscriptionService.isUserPremium();
    if (mounted) {
      setState(() {
        _isPremium = status;
        _loadingPremium = false;
      });
    }
  }

  // Lógica para mostrar el NUEVO Paywall
  void _showPaywall() async {
    // Navegamos a la pantalla PaywallProScreen que creamos
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const PaywallProScreen())
    );

    // Si devuelve 'true', significa que compró o restauró exitosamente
    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Bienvenido a Yoinn PRO! 🌟"))
        );
      }
      // Volvemos a chequear el estado para actualizar la UI (borde dorado, etc.)
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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text("Usuario no encontrado")));
        }

        final user = snapshot.data!;
        final isAdmin = isMe && user.isAdmin;
        final isLocalGuide = user.activitiesCreatedCount > 5;
        
        // --- LÓGICA DE UNIFICACIÓN DE ESTADO ---
        // Es PRO si pagó (_isPremium de RevenueCat) O si tiene el flag manual en Firebase
        final bool isProReal = _isPremium || user.isManualPro;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text("Perfil"),
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.security, color: Colors.red),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
                ),
              if (isMe)
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  onPressed: () {
                    authService.signOut();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                )
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ProfileHeader(
                  user: user, 
                  isMe: isMe, 
                  isLocalGuide: isLocalGuide,
                  onEditProfile: () => setState((){}), 
                ),

                // --- BANNER DE SUSCRIPCIÓN (Solo si soy yo) ---
                if (isMe && !_loadingPremium) ...[
                  const SizedBox(height: 20),
                  // Le pasamos el estado REAL (Pagado o Manual)
                  _buildPremiumBanner(isProReal),
                ],

                // 2. GALERÍA
                ProfileGallery(
                  user: user, 
                  isMe: isMe,
                  onImageUploaded: () => setState((){}),
                ),

                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 20),

                // 3. ACTIVIDADES
                ProfileActivitiesList(
                  uid: widget.uid, 
                  isMe: isMe
                ),

                const SizedBox(height: 40),

                if (isMe)
                  TextButton(
                    onPressed: () => _showDeleteAccountDialog(context),
                    child: const Text("Eliminar cuenta", style: TextStyle(color: Colors.red, decoration: TextDecoration.underline)),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET DEL BANNER PREMIUM ---
  // Modificado para recibir el estado 'isVip'
  Widget _buildPremiumBanner(bool isVip) {
    if (isVip) {
      // Diseño para USUARIO PRO (Ya pagó o es Manual) - Oro y Elegancia
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]), // Dorado
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            const Icon(Icons.verified, color: Colors.white, size: 30),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Eres Yoinn PRO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("Membresía activa", style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gestiona tu suscripción en los ajustes de Apple.")));
              },
              child: const Icon(Icons.settings, color: Colors.white70),
            )
          ],
        ),
      );
    } else {
      // Diseño para USUARIO GRATIS - "Pásate a PRO"
      return GestureDetector(
        onTap: _showPaywall, // Ahora abre la PaywallProScreen
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E), // Gris oscuro muy elegante
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD700), // Icono dorado sobre fondo oscuro
                  shape: BoxShape.circle
                ),
                child: const Icon(Icons.star, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Pásate a Yoinn PRO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text("Únete sin límites y destaca", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      );
    }
  }
}