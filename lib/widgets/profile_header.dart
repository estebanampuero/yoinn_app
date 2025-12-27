import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import '../screens/edit_profile_screen.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;
  final bool isMe;
  final bool isLocalGuide;
  final bool isPro; // <--- Nuevo parámetro para estatus PRO
  final VoidCallback onEditProfile;

  // COLOR DE MARCA
  static const Color brandColor = Color(0xFF00BCD4);

  const ProfileHeader({
    super.key,
    required this.user,
    required this.isMe,
    required this.isLocalGuide,
    this.isPro = false, // Por defecto falso
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- FOTO CON BORDE PRO Y BADGE ---
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Contenedor de la Foto + Borde
            Container(
              padding: const EdgeInsets.all(4), // Grosor del borde
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Lógica del Borde:
                // 1. Si es PRO -> Gradiente Dorado Metálico
                // 2. Si es Local Guide (y no Pro) -> Borde Amber
                // 3. Si no -> Nada
                gradient: isPro 
                    ? const LinearGradient(
                        colors: [
                          Color(0xFFB8860B), // Dorado Oscuro
                          Color(0xFFFFD700), // Oro Brillante
                          Color(0xFFD4AF37), // Oro Metálico
                          Color(0xFFFFD700), 
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: [0.0, 0.4, 0.7, 1.0]
                      )
                    : null,
                border: (!isPro && isLocalGuide) 
                    ? Border.all(color: Colors.amber, width: 3) 
                    : null,
                color: isPro ? null : Colors.transparent,
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[200],
                backgroundImage: user.profilePictureUrl.isNotEmpty
                    ? CachedNetworkImageProvider(user.profilePictureUrl)
                    : null,
                child: user.profilePictureUrl.isEmpty 
                    ? const Icon(Icons.person, size: 60, color: Colors.grey) 
                    : null,
              ),
            ),

            // --- BADGE "PRO" (Solo si es PRO) ---
            if (isPro)
              Positioned(
                bottom: -2, // Justo en el borde inferior
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black, // Fondo negro para contraste premium
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ]
                  ),
                  child: const Text(
                    "PRO",
                    style: TextStyle(
                      color: Color(0xFFFFD700), // Texto Dorado
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 16),

        // --- NOMBRE ---
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

        // --- BADGE GUÍA LOCAL ---
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

        // --- BIO ---
        if (user.bio.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            user.bio,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],

        // --- INSTAGRAM ---
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

        // --- BOTÓN EDITAR ---
        if (isMe)
          OutlinedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen(user: user)),
              );
              onEditProfile(); 
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text("Editar Perfil"),
            style: OutlinedButton.styleFrom(
              foregroundColor: brandColor,
              side: const BorderSide(color: brandColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        
        const SizedBox(height: 30),

        // --- INTERESES ---
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
                backgroundColor: brandColor.withOpacity(0.1),
                labelStyle: const TextStyle(color: brandColor, fontSize: 12, fontWeight: FontWeight.bold),
                side: BorderSide.none,
              )).toList(),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ],
    );
  }
}