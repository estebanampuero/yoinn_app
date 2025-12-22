import 'dart:io'; 
import 'package:flutter/cupertino.dart'; 
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import 'map_picker_screen.dart'; 

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  
  String _selectedCategory = 'Otro'; 
  int _maxAttendees = 2; // Valor inicial
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSaving = false;
  
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  double? _selectedLat;
  double? _selectedLng;

  final List<String> _categories = [
    'Deportes', 'Comida', 'Arte', 'Fiestas', 'Viajes', 'Musica', 'Tecnología', 'Bienestar', 'Otros'
  ];

  // Lista de opciones para acompañantes (del 1 al 20)
  final List<int> _attendeesOptions = List.generate(20, (index) => index + 1);

  final Color _activeColor = const Color(0xFFF97316); 
  final Color _iosBtnColor = const Color(0xFF00BCD4); 

  @override
  void initState() {
    super.initState();
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = _categories.last; 
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 80, 
        maxWidth: 1080,   
        maxHeight: 1080,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Error al seleccionar imagen: $e");
    }
  }

  Future<void> _openLocationSearch() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _locationController.text = result['address'] ?? 'Ubicación seleccionada';
        _selectedLat = result['lat'];
        _selectedLng = result['lng'];
      });
    }
  }

  // --- LÓGICA DE FECHA NATIVA ---
  Future<void> _pickDate() async {
    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return Container(
            height: 250,
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  color: Colors.grey[100],
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Text("Listo", style: TextStyle(color: _iosBtnColor, fontWeight: FontWeight.bold)),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: _selectedDate,
                    minimumDate: DateTime.now().subtract(const Duration(days: 1)),
                    maximumDate: DateTime(2026),
                    onDateTimeChanged: (DateTime newDate) {
                      setState(() => _selectedDate = newDate);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime.now(),
        lastDate: DateTime(2026),
      );
      if (picked != null) setState(() => _selectedDate = picked);
    }
  }

  // --- LÓGICA DE HORA NATIVA ---
  Future<void> _pickTime() async {
    final bool is24HourFormat = MediaQuery.of(context).alwaysUse24HourFormat;

    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return Container(
            height: 250,
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  color: Colors.grey[100],
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Text("Listo", style: TextStyle(color: _iosBtnColor, fontWeight: FontWeight.bold)),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: DateTime(
                      DateTime.now().year, DateTime.now().month, DateTime.now().day,
                      _selectedTime.hour, _selectedTime.minute,
                    ),
                    use24hFormat: is24HourFormat, 
                    onDateTimeChanged: (DateTime newTime) {
                      setState(() {
                        _selectedTime = TimeOfDay.fromDateTime(newTime);
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      final picked = await showTimePicker(
        context: context, 
        initialTime: _selectedTime,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: is24HourFormat),
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(primary: _iosBtnColor, onPrimary: Colors.white, onSurface: Colors.black),
              ),
              child: child!,
            ),
          );
        },
      );
      if (picked != null) setState(() => _selectedTime = picked);
    }
  }

  // --- WIDGET DE CATEGORÍA NATIVO ---
  Widget _buildCategoryInput() {
    if (Platform.isIOS) {
      return GestureDetector(
        onTap: () {
          showCupertinoModalPopup(
            context: context,
            builder: (context) => Container(
              height: 250,
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    color: Colors.grey[100],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Text("Listo", style: TextStyle(color: _iosBtnColor, fontWeight: FontWeight.bold)),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 32,
                      scrollController: FixedExtentScrollController(
                        initialItem: _categories.indexOf(_selectedCategory)
                      ),
                      onSelectedItemChanged: (index) {
                        setState(() => _selectedCategory = _categories[index]);
                      },
                      children: _categories.map((c) => Text(c)).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Categoría',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            suffixIcon: Icon(Icons.arrow_drop_down),
          ),
          child: Text(_selectedCategory, style: const TextStyle(fontSize: 16)),
        ),
      );
    } else {
      return DropdownButtonFormField<String>(
        value: _selectedCategory,
        decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (v) => setState(() => _selectedCategory = v!),
      );
    }
  }

  // --- NUEVO: WIDGET DE ACOMPAÑANTES IGUAL A CATEGORÍAS ---
  Widget _buildAttendeesInput() {
    if (Platform.isIOS) {
      // iOS: Input decorado que abre CupertinoPicker (Igual que Categoría)
      return GestureDetector(
        onTap: () {
          showCupertinoModalPopup(
            context: context,
            builder: (context) => Container(
              height: 250,
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    color: Colors.grey[100],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Text("Listo", style: TextStyle(color: _iosBtnColor, fontWeight: FontWeight.bold)),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 32,
                      scrollController: FixedExtentScrollController(
                        initialItem: _attendeesOptions.indexOf(_maxAttendees)
                      ),
                      onSelectedItemChanged: (index) {
                        setState(() => _maxAttendees = _attendeesOptions[index]);
                      },
                      children: _attendeesOptions.map((n) => Text("$n persona${n > 1 ? 's' : ''}")).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Nº de acompañantes (máx)',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            suffixIcon: Icon(Icons.people_outline),
          ),
          child: Text("$_maxAttendees", style: const TextStyle(fontSize: 16)),
        ),
      );
    } else {
      // Android: Dropdown (Igual que Categoría)
      return DropdownButtonFormField<int>(
        value: _maxAttendees,
        decoration: const InputDecoration(labelText: 'Nº de acompañantes (máx)', border: OutlineInputBorder()),
        items: _attendeesOptions.map((n) => DropdownMenuItem(value: n, child: Text("$n"))).toList(),
        onChanged: (v) => setState(() => _maxAttendees = v!),
      );
    }
  }

  Future<String> _uploadImage(String userId) async {
    if (_imageFile == null) return '';
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('activities')
          .child(userId)
          .child(fileName);

      final UploadTask uploadTask = storageRef.putFile(_imageFile!);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error subiendo imagen: $e");
      throw Exception("No se pudo subir la imagen");
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedLat == null || _selectedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor toca en "Ubicación" para seleccionar en el mapa')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user == null) throw Exception("Usuario no autenticado");

      String imageUrl = '';
      if (_imageFile != null) {
        imageUrl = await _uploadImage(user.uid);
      } else {
        imageUrl = 'https://via.placeholder.com/800x600.png?text=${_selectedCategory}';
      }

      final finalDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final newActivity = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'category': _selectedCategory,
        'location': _locationController.text.trim(),
        'maxAttendees': _maxAttendees,
        'dateTime': Timestamp.fromDate(finalDateTime),
        'hostUid': user.uid,
        'imageUrl': imageUrl,
        'lat': _selectedLat, 
        'lng': _selectedLng,
        'acceptedCount': 0,
        'participantImages': [],
      };

      await Provider.of<DataService>(context, listen: false).createActivity(newActivity);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Actividad creada con éxito!')),
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
      appBar: AppBar(title: const Text("Crear Nueva Actividad")),
      body: _isSaving 
        ? const Center(child: CircularProgressIndicator())
        : Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text("Foto de la actividad", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_outlined, size: 50, color: Colors.grey[400]),
                            const SizedBox(height: 10),
                            Text("Toca para subir una imagen", style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título', border: OutlineInputBorder(), hintText: 'Ej: Tarde de Senderismo'),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder(), hintText: 'Cuéntanos de qué trata...'),
                maxLines: 4,
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              // CATEGORÍA (NATIVA: Picker en iOS, Dropdown en Android)
              _buildCategoryInput(),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate, // Fecha nativa
                      icon: const Icon(Icons.calendar_today),
                      label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime, // Hora nativa inteligente
                      icon: const Icon(Icons.access_time),
                      label: Text(_selectedTime.format(context)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // CAMPO DE UBICACIÓN
              TextFormField(
                controller: _locationController,
                readOnly: true, 
                onTap: _openLocationSearch, 
                decoration: const InputDecoration(
                  labelText: 'Ubicación', 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                  hintText: 'Toca para buscar en el mapa...'
                ),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              // ACOMPAÑANTES (AHORA ES IGUAL A CATEGORÍA)
              // Picker en iOS, Dropdown en Android
              _buildAttendeesInput(),
              
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _activeColor, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Publicar Actividad", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
    );
  }
}