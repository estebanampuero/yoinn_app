import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../models/user_model.dart';
import '../models/activity_model.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import 'edit_profile_screen.dart';
import 'edit_activity_screen.dart';
import 'admin_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;

  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    if (_isUploading) return;
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      if (image != null) {
        setState(() => _isUploading = true);
        await Provider.of<DataService>(context, listen: false)
            .uploadGalleryImage(widget.uid, File(image.path));
        setState(() => _isUploading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("¡Foto agregada a tu galería!")),
          );
        }
      }
    } catch (e) {
      print("Error subiendo foto: $e");
      setState(() => _isUploading = false);
    }
  }

  // --- DIÁLOGO PARA ELIMINAR CUENTA (COMPATIBLE CON GOOGLE) ---
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
            const Text(
              "Esta acción borrará permanentemente tu perfil y tus datos. No se puede deshacer.",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            const Text(
              "Escribe la palabra ELIMINAR para confirmar:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmationController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "ELIMINAR",
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              if (confirmationController.text.trim() != "ELIMINAR") {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Debes escribir ELIMINAR correctamente."))
                );
                return;
              }

              try {
                // Llamamos a deleteAccount del AuthService
                await Provider.of<AuthService>(context, listen: false).deleteAccount();
                
                if (mounted) {
                  Navigator.pop(ctx); 
                  Navigator.of(context).popUntil((route) => route.isFirst); 
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Tu cuenta ha sido eliminada."))
                  );
                }
              } catch (e) {
                Navigator.pop(ctx);
                // Si es un string (error nuestro) o una excepción
                String errorMsg = e.toString();
                if (errorMsg.contains("requires-recent-login")) {
                  errorMsg = "Por seguridad, cierra sesión e inicia de nuevo para poder borrar tu cuenta.";
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
              }
            },
            child: const Text("BORRAR DEFINITIVAMENTE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    final currentUserUid = currentUser?.uid;
    final currentUserEmail = currentUser?.email;
    
    final isMe = currentUserUid == widget.uid;
    final dataService = Provider.of<DataService>(context, listen: false);

    // RECUERDA PONER TU EMAIL REAL AQUÍ
    final adminEmails = ['miguel.moreira.ampuero@gmail.com', 'letsgo@yoinn.cl']; 
    final isAdmin = isMe && adminEmails.contains(currentUserEmail);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.red),
              tooltip: "Panel Admin",
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
              },
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
      body: FutureBuilder<UserModel?>(
        future: dataService.getUserProfile(widget.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Usuario no encontrado"));
          }

          final user = snapshot.data!;
          final isLocalGuide = user.activitiesCreatedCount > 5;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(), 
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: isLocalGuide ? Border.all(color: Colors.amber, width: 3) : null,
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: user.profilePictureUrl.isNotEmpty
                        ? CachedNetworkImageProvider(user.profilePictureUrl)
                        : null,
                    child: user.profilePictureUrl.isEmpty ? const Icon(Icons.person, size: 60) : null,
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    if (user.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, color: Colors.blue, size: 20),
                    ]
                  ],
                ),

                if (isLocalGuide)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: const Text("🌟 Guía Local", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                
                if (user.bio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    user.bio,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],

                if (user.instagramHandle != null && user.instagramHandle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: InkWell(
                      onTap: () async {
                        final Uri url = Uri.parse("https://instagram.com/${user.instagramHandle}");
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.camera_alt, color: Colors.pink, size: 18), 
                          const SizedBox(width: 4),
                          Text("@${user.instagramHandle}", style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                if (isMe)
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditProfileScreen(user: user)),
                      );
                      setState(() {}); 
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text("Editar Perfil"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF97316),
                      side: const BorderSide(color: Color(0xFFF97316)),
                    ),
                  ),

                const SizedBox(height: 30),

                if (user.hobbies.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Intereses", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: user.hobbies.map((hobby) => Chip(
                        label: Text(hobby.replaceAll('_', ' ').toUpperCase()),
                        backgroundColor: const Color(0xFFF97316).withOpacity(0.1),
                        labelStyle: const TextStyle(color: Color(0xFFF97316), fontSize: 12, fontWeight: FontWeight.bold),
                        side: BorderSide.none,
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Galería", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (isMe && user.galleryImages.length < 6)
                      if (_isUploading)
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        IconButton(
                          onPressed: _pickAndUploadImage,
                          icon: const Icon(Icons.add_a_photo, color: Color(0xFFF97316)),
                          tooltip: "Agregar foto",
                        ),
                  ],
                ),
                const SizedBox(height: 10),
                
                if (user.galleryImages.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text("Aún no hay fotos", style: TextStyle(color: Colors.grey)),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(), 
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: user.galleryImages.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: user.galleryImages[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[200]),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      );
                    },
                  ),
                
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 20),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Actividades Creadas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),

                StreamBuilder<QuerySnapshot>(
                  stream: dataService.getUserActivitiesStream(widget.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData) return const SizedBox();

                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) return const Text("No has creado actividades aún.", style: TextStyle(color: Colors.grey));

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(), 
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final act = Activity.fromFirestore(docs[index]);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(8),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: act.imageUrl.isNotEmpty ? act.imageUrl : 'https://via.placeholder.com/100',
                                width: 60, height: 60, 
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.grey[200]),
                                errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                            title: Text(act.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(DateFormat('dd MMM yyyy • HH:mm').format(act.dateTime)),
                            trailing: isMe 
                              ? IconButton(
                                  icon: const Icon(Icons.edit, color: Color(0xFFF97316)),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => EditActivityScreen(activity: act)),
                                    );
                                  },
                                )
                              : null,
                          ),
                        );
                      },
                    );
                  },
                ),
                
                // --- BOTÓN DE ELIMINAR CUENTA (REQUERIDO POR APPLE) ---
                const SizedBox(height: 40),
                if (isMe)
                  Center(
                    child: TextButton(
                      onPressed: () => _showDeleteAccountDialog(context),
                      child: Text(
                        "Eliminar mi cuenta", 
                        style: TextStyle(color: Colors.red[300], fontSize: 13, decoration: TextDecoration.underline)
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}