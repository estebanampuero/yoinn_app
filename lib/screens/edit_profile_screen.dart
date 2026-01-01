import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoinn_app/l10n/app_localizations.dart';

import '../models/user_model.dart';
import '../services/data_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _instaController;

  // COLORES DE MARCA
  final Color _brandColor = const Color(0xFF00BCD4);
  final Color _bgScreenColor = const Color(0xFFF0F8FA);
  final Color _bgInputColor = const Color(0xFFF5F5F5);

  // Lista de IDs (se mantiene en inglés/base para la BD)
  final List<String> _allHobbies = [
    'Deportes', 'Comida', 'Fiesta', 'Música', 'Arte', 'Aire Libre',
    'Tecnología', 'Cine', 'Juegos', 'Viajes', 'Bienestar', 'Educación',
    'Mascotas', 'Negocios', 'Idiomas', 'Voluntariado', 'Fotografía',
    'Literatura', 'Familia', 'Otro'
  ];

  List<String> _selectedHobbies = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _bioController = TextEditingController(text: widget.user.bio);
    _instaController = TextEditingController(text: widget.user.instagramHandle ?? '');
    _selectedHobbies = List.from(widget.user.hobbies);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _instaController.dispose();
    super.dispose();
  }

  // Helper para traducir el hobby visualmente
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

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final cleanInsta = _instaController.text.trim().replaceAll('@', '').replaceAll(' ', '');

      final updatedData = {
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'instagramHandle': cleanInsta, 
        'hobbies': _selectedHobbies,
        'profileCompleted': true,
      };

      await Provider.of<DataService>(context, listen: false)
          .updateUserProfile(widget.user.uid, updatedData);

      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.msgProfileUpdated), backgroundColor: _brandColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorGeneric}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _bgScreenColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          l10n.screenEditProfileTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.black87),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving 
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _brandColor))
                : Text(l10n.btnSave, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _brandColor)),
            ),
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- AVATAR SECTION ---
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: NetworkImage(widget.user.profilePictureUrl),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _brandColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- FORM FIELDS ---
              Text(l10n.lblName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Tu nombre",
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _brandColor, width: 1.5)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
                validator: (v) => v!.isEmpty ? l10n.errNameRequired : null,
              ),
              const SizedBox(height: 24),

              Text(l10n.lblBio, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                maxLength: 300,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Cuéntanos sobre ti...",
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _brandColor, width: 1.5)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
              ),
              const SizedBox(height: 20),

              Text(l10n.lblInstagram, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const SizedBox(height: 8),
              TextFormField(
                controller: _instaController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'usuario_insta',
                  prefixIcon: const Icon(Icons.alternate_email_rounded, color: Colors.grey, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _brandColor, width: 1.5)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
              ),
              
              const SizedBox(height: 32),

              // --- INTERESTS ---
              Row(
                children: [
                  Icon(Icons.stars_rounded, color: _brandColor),
                  const SizedBox(width: 8),
                  Text(l10n.lblInterests, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allHobbies.map((hobby) {
                    final isSelected = _selectedHobbies.contains(hobby);
                    return FilterChip(
                      label: Text(
                        _getHobbyName(context, hobby),
                        style: TextStyle(
                          color: isSelected ? _brandColor : Colors.grey[600],
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13
                        ),
                      ),
                      selected: isSelected,
                      backgroundColor: Colors.grey[50],
                      selectedColor: _brandColor.withOpacity(0.1),
                      checkmarkColor: _brandColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? _brandColor : Colors.grey.shade300,
                          width: 1
                        )
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedHobbies.add(hobby);
                          } else {
                            _selectedHobbies.remove(hobby);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}