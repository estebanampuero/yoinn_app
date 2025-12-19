import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  late TextEditingController _instaController; // <--- Controlador Instagram
  
  final List<String> _allHobbies = [
    'Deportes',
    'Comida',
    'Fiesta',
    'Música',
    'Arte',
    'Aire Libre',
    'Tecnología',
    'Cine',
    'Juegos',
    'Viajes',
    'Bienestar',
    'Educación',
    'Mascotas',
    'Negocios',
    'Idiomas',
    'Voluntariado',
    'Fotografía',
    'Literatura',
    'Familia',
    'Otro'
  ];

  List<String> _selectedHobbies = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _bioController = TextEditingController(text: widget.user.bio);
    // Cargamos el instagram actual o vacío
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Limpiamos el input de Instagram (quitamos @ y espacios)
      final cleanInsta = _instaController.text.trim().replaceAll('@', '').replaceAll(' ', '');

      final updatedData = {
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'instagramHandle': cleanInsta, // Guardamos el nuevo campo
        'hobbies': _selectedHobbies,
        'profileCompleted': true,
      };

      await Provider.of<DataService>(context, listen: false)
          .updateUserProfile(widget.user.uid, updatedData);

      if (mounted) {
        Navigator.pop(context); // Volver al perfil
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil"),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving 
              ? const CircularProgressIndicator.adaptive() 
              : const Text("GUARDAR", style: TextStyle(fontWeight: FontWeight.bold)),
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
              decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'El nombre es obligatorio' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: 'Biografía', border: OutlineInputBorder()),
              maxLines: 3,
              maxLength: 300,
            ),
            const SizedBox(height: 16),

            // --- CAMPO INSTAGRAM (Confianza) ---
            TextFormField(
              controller: _instaController,
              decoration: const InputDecoration(
                labelText: 'Usuario de Instagram (Opcional)', 
                hintText: 'ej: usuario123',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.camera_alt, color: Colors.pink), // Icono visual
                prefixText: '@', // Muestra la arroba fija
              ),
            ),
            
            const SizedBox(height: 20),

            const Text("Intereses / Hobbies", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _allHobbies.map((hobby) {
                final isSelected = _selectedHobbies.contains(hobby);
                return FilterChip(
                  label: Text(hobby.replaceAll('_', ' ').toUpperCase()),
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