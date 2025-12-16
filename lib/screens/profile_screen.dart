import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart'; // <--- Importante para caché
import '../models/user_model.dart';
import '../models/activity_model.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import 'edit_profile_screen.dart';
import 'edit_activity_screen.dart'; // <--- Importante para editar actividades

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
        // Optimización
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

  @override
  Widget build(BuildContext context) {
    final currentUserUid = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    final isMe = currentUserUid == widget.uid;
    final dataService = Provider.of<DataService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (isMe)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: () {
                Provider.of<AuthService>(context, listen: false).signOut();
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

          return SingleChildScrollView(
            // Importante para que el scroll funcione siempre y se sienta nativo
            physics: const AlwaysScrollableScrollPhysics(), 
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: user.profilePictureUrl.isNotEmpty
                      ? CachedNetworkImageProvider(user.profilePictureUrl)
                      : null,
                  child: user.profilePictureUrl.isEmpty ? const Icon(Icons.person, size: 60) : null,
                ),
                const SizedBox(height: 16),
                
                Text(
                  user.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                
                if (user.bio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    user.bio,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],

                const SizedBox(height: 20),

                // Botón Editar Perfil
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

                // Intereses
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

                // Galería
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
                    physics: const NeverScrollableScrollPhysics(), // Scroll lo maneja el padre
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

                // --- MIS ACTIVIDADES ---
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Actividades Creadas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),

                // StreamBuilder para ver cambios en tiempo real (si edito, se actualiza solo)
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
                      physics: const NeverScrollableScrollPhysics(), // Scroll lo maneja el padre
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
                                    // Ir a la pantalla de edición
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => EditActivityScreen(activity: act)),
                                    );
                                  },
                                )
                              : null,
                            onTap: () {
                              // Ir al detalle si no se quiere editar
                              // (Opcional, pero buena práctica)
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}