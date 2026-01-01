import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoinn_app/l10n/app_localizations.dart'; // <--- IMPORTANTE

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
    // Normalizamos clave por si acaso
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
          SnackBar(content: Text(l10n.msgProfileUpdated)),
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
      appBar: AppBar(
        title: Text(l10n.screenEditProfileTitle),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving 
              ? const CircularProgressIndicator.adaptive() 
              : Text(l10n.btnSave, style: const TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(widget.user.profilePictureUrl),
                child: const Icon(Icons.camera_alt, size: 30, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.lblName, border: const OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? l10n.errNameRequired : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _bioController,
              decoration: InputDecoration(labelText: l10n.lblBio, border: const OutlineInputBorder()),
              maxLines: 3,
              maxLength: 300,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _instaController,
              decoration: InputDecoration(
                labelText: l10n.lblInstagram, 
                hintText: 'ej: usuario123',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.camera_alt, color: Colors.pink), 
                prefixText: '@', 
              ),
            ),
            
            const SizedBox(height: 20),

            Text(l10n.lblInterests, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _allHobbies.map((hobby) {
                final isSelected = _selectedHobbies.contains(hobby);
                return FilterChip(
                  label: Text(_getHobbyName(context, hobby).toUpperCase()),
                  selected: isSelected,
                  selectedColor: const Color(0xFFF97316).withOpacity(0.2),
                  checkmarkColor: const Color(0xFFF97316),
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
          ],
        ),
      ),
    );
  }
}