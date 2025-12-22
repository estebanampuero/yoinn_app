import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import 'admin_screen.dart';

// Importamos los widgets que creamos en la carpeta /widgets
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
  // Lógica de borrado de cuenta (Obligatorio para Apple)
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
                // Llamamos al servicio para borrar en Firebase Auth y Firestore
                await Provider.of<AuthService>(context, listen: false).deleteAccount();
                if (mounted) {
                  Navigator.pop(ctx);
                  // Volvemos a la pantalla de inicio/login
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } catch (e) {
                if (mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error al eliminar: $e"))
                );
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
        // ESTADO DE CARGA
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // ESTADO DE ERROR O NO EXISTE
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Perfil")),
            body: const Center(child: Text("Usuario no encontrado")),
          );
        }

        final user = snapshot.data!;
        // Verificamos si es admin usando el campo del modelo
        final isAdmin = isMe && user.isAdmin;
        final isLocalGuide = user.activitiesCreatedCount > 5;

        // UI PRINCIPAL LIMPIA
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text("Perfil"),
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            actions: [
              // BOTÓN DE ADMIN (Solo visible si isAdmin es true)
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.security, color: Colors.red),
                  tooltip: "Panel de Admin",
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
                ),
              // BOTÓN DE LOGOUT
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
                // 1. CABECERA (Foto, Bio, Botones)
                ProfileHeader(
                  user: user, 
                  isMe: isMe, 
                  isLocalGuide: isLocalGuide,
                  onEditProfile: () => setState((){}), // Recarga al volver de editar
                ),

                // 2. GALERÍA
                ProfileGallery(
                  user: user, 
                  isMe: isMe,
                  onImageUploaded: () => setState((){}), // Recarga al subir foto
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

                // 4. BORRAR CUENTA (Requisito Apple)
                if (isMe)
                  TextButton(
                    onPressed: () => _showDeleteAccountDialog(context),
                    child: const Text(
                      "Eliminar cuenta", 
                      style: TextStyle(
                        color: Colors.red, // Rojo explícito para indicar peligro
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500
                      )
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}