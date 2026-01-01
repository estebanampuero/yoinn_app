import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yoinn_app/l10n/app_localizations.dart';

import '../models/user_model.dart';
import '../screens/edit_profile_screen.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;
  final bool isMe;
  final bool isLocalGuide;
  final bool isPro; 
  final VoidCallback onEditProfile;

  static const Color brandColor = Color(0xFF00BCD4);

  const ProfileHeader({
    super.key,
    required this.user,
    required this.isMe,
    required this.isLocalGuide,
    this.isPro = false, 
    required this.onEditProfile,
  });

  String _getHobbyName(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    final k = key.trim();
    if (k == 'Deportes') return l10n.hobbySports;
    if (k == 'Comida') return l10n.hobbyFood;
    if (k == 'Fiesta') return l10n.hobbyParty;
    if (k == 'Música') return l10n.hobbyMusic;
    if (k == 'Arte') return l10n.hobbyArt;
    if (k == 'Aire Libre') return l10n.hobbyOutdoors;
    if (k == 'Tecnología') return l10n.hobbyTech;
    if (k == 'Cine') return l10n.hobbyCinema;
    if (k == 'Juegos') return l10n.hobbyGames;
    if (k == 'Viajes') return l10n.hobbyTravel;
    if (k == 'Bienestar') return l10n.hobbyWellness;
    if (k == 'Educación') return l10n.hobbyEducation;
    if (k == 'Mascotas') return l10n.hobbyPets;
    if (k == 'Negocios') return l10n.hobbyBusiness;
    if (k == 'Idiomas') return l10n.hobbyLanguages;
    if (k == 'Voluntariado') return l10n.hobbyVolunteering;
    if (k == 'Fotografía') return l10n.hobbyPhotography;
    if (k == 'Literatura') return l10n.hobbyLiterature;
    if (k == 'Familia') return l10n.hobbyFamily;
    return l10n.hobbyOther;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // --- FOTO DE PERFIL CON BADGE EN EL BORDE INFERIOR ---
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // AVATAR
            Container(
              padding: const EdgeInsets.all(4), 
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isPro 
                    ? const LinearGradient(
                        colors: [
                          Color(0xFFB8860B), 
                          Color(0xFFFFD700), 
                          Color(0xFFD4AF37), 
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

            // BADGE PRO (CENTRADO ABAJO)
            if (isPro)
              Positioned(
                bottom: -10, // Cuelga elegantemente del borde
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A), // Negro Matte
                      borderRadius: BorderRadius.circular(16), // Más redondeado
                      border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ]
                    ),
                    child: const Text(
                      "PRO", 
                      style: TextStyle(
                        color: Color(0xFFFFD700), 
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 20), // Espacio extra para compensar el badge colgante

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
            child: Text(l10n.badgeLocalGuide, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
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
            label: Text(l10n.btnEditProfile), 
            style: OutlinedButton.styleFrom(
              foregroundColor: brandColor,
              side: const BorderSide(color: brandColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        
        const SizedBox(height: 30),

        // --- INTERESES TRADUCIDOS ---
        if (user.hobbies.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(l10n.lblInterestsTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), 
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.hobbies.map((hobby) => Chip(
                label: Text(_getHobbyName(context, hobby).toUpperCase()),
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