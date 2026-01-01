import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:yoinn_app/l10n/app_localizations.dart'; 

import '../models/activity_model.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import '../config/subscription_limits.dart'; 
import 'map_picker_screen.dart';

class EditActivityScreen extends StatefulWidget {
  final Activity activity;
  const EditActivityScreen({super.key, required this.activity});

  @override
  State<EditActivityScreen> createState() => _EditActivityScreenState();
}

class _EditActivityScreenState extends State<EditActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _locationController;
  
  late String _selectedCategory;
  late int _maxAttendees;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  
  bool _isSaving = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  double? _selectedLat;
  double? _selectedLng;

  // COLORES DE MARCA (Diseño Aesthetic)
  final Color _brandColor = const Color(0xFF00BCD4); 
  final Color _bgInputColor = const Color(0xFFFFFFFF); // Blanco para inputs
  final Color _bgScreenColor = const Color(0xFFF0F8FA); // Fondo suave

  final List<String> _categories = [
    'Deportes', 'Comida', 'Arte', 'Fiestas', 'Viajes', 'Musica', 'Tecnología', 'Bienestar', 'Otros'
  ];
  
  List<int> _attendeesOptions = [];

  @override
  void initState() {
    super.initState();
    final a = widget.activity;
    _titleController = TextEditingController(text: a.title);
    _descController = TextEditingController(text: a.description);
    _locationController = TextEditingController(text: a.location);
    _maxAttendees = a.maxAttendees;
    _selectedDate = a.dateTime;
    _selectedTime = TimeOfDay.fromDateTime(a.dateTime);
    _selectedLat = a.lat;
    _selectedLng = a.lng;

    String incomingCategory = a.category;
    Map<String, String> translationMap = {
      'Sports': 'Deportes', 'Food': 'Comida', 'Art': 'Arte', 'Party': 'Fiestas',
      'Travel': 'Viajes', 'Music': 'Musica', 'Tech': 'Tecnología', 'Other': 'Otros',
      'Wellness': 'Bienestar'
    };
    String translated = translationMap[incomingCategory] ?? incomingCategory;

    if (_categories.contains(translated)) {
      _selectedCategory = translated;
    } else {
      _selectedCategory = 'Otros';
    }
  }

  String _getDisplayCategory(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'Deportes': return l10n.catSport;
      case 'Comida': return l10n.catFood;
      case 'Arte': return l10n.catArt;
      case 'Fiestas': return l10n.catParty;
      case 'Viajes': return l10n.catOutdoor; 
      case 'Musica': return l10n.hobbyMusic;
      case 'Tecnología': return l10n.hobbyTech; 
      case 'Bienestar': return l10n.hobbyWellness;
      case 'Otros': return l10n.catOther;
      default: return key;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    final isPremium = user?.isPremium ?? false;

    final int maxLimit = isPremium 
        ? SubscriptionLimits.proMaxAttendees 
        : SubscriptionLimits.freeMaxAttendees;

    _attendeesOptions = List.generate(maxLimit, (index) => index + 1);

    if (_maxAttendees > maxLimit) {
      _maxAttendees = maxLimit;
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
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      debugPrint("Error seleccionando imagen: $e");
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

  // --- FECHA NATIVA (FIXED 2030) ---
  Future<void> _pickDate() async {
    final l10n = AppLocalizations.of(context)!;
    
    final safeMinDate = DateTime(2020, 1, 1);
    final safeMaxDate = DateTime(2030); // <--- FIX: Ampliado para evitar crash

    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => Container(
          height: 250,
          color: Colors.white,
          child: Column(
            children: [
              _buildIosPickerHeader(context, l10n),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDate,
                  minimumDate: safeMinDate,
                  maximumDate: safeMaxDate,
                  onDateTimeChanged: (val) => setState(() => _selectedDate = val),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: safeMinDate,
        lastDate: safeMaxDate,
        builder: (context, child) => Theme(
          data: ThemeData.light().copyWith(colorScheme: ColorScheme.light(primary: _brandColor)),
          child: child!,
        ),
      );
      if (picked != null) setState(() => _selectedDate = picked);
    }
  }

  // --- HORA NATIVA ---
  Future<void> _pickTime() async {
    final l10n = AppLocalizations.of(context)!;
    final bool is24HourFormat = MediaQuery.of(context).alwaysUse24HourFormat;

    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => Container(
          height: 250,
          color: Colors.white,
          child: Column(
            children: [
              _buildIosPickerHeader(context, l10n),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(
                    DateTime.now().year, DateTime.now().month, DateTime.now().day,
                    _selectedTime.hour, _selectedTime.minute,
                  ),
                  use24hFormat: is24HourFormat, 
                  onDateTimeChanged: (val) => setState(() => _selectedTime = TimeOfDay.fromDateTime(val)),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final picked = await showTimePicker(
        context: context, 
        initialTime: _selectedTime,
        builder: (context, child) => Theme(
          data: ThemeData.light().copyWith(colorScheme: ColorScheme.light(primary: _brandColor)),
          child: child!,
        ),
      );
      if (picked != null) setState(() => _selectedTime = picked);
    }
  }

  Widget _buildIosPickerHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: Text(l10n.btnReady, style: TextStyle(color: _brandColor, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  // --- ESTILOS DE INPUTS ---
  InputDecoration _buildInputDecoration(String label, IconData icon, String? hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey[400]),
      filled: true,
      fillColor: _bgInputColor,
      labelStyle: TextStyle(color: Colors.grey[600]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none, 
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _brandColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    );
  }

  // --- WIDGETS ---
  Widget _buildCategoryInput() {
    final l10n = AppLocalizations.of(context)!;
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
                  _buildIosPickerHeader(context, l10n),
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 32,
                      scrollController: FixedExtentScrollController(
                        initialItem: _categories.indexOf(_selectedCategory) >= 0 ? _categories.indexOf(_selectedCategory) : 0
                      ),
                      onSelectedItemChanged: (index) => setState(() => _selectedCategory = _categories[index]),
                      children: _categories.map((c) => Text(_getDisplayCategory(context, c))).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: AbsorbPointer(
          child: TextFormField(
            decoration: _buildInputDecoration(l10n.lblCategory, Icons.category_outlined, null).copyWith(
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
            controller: TextEditingController(text: _getDisplayCategory(context, _selectedCategory)),
          ),
        ),
      );
    } else {
      return DropdownButtonFormField<String>(
        value: _selectedCategory,
        decoration: _buildInputDecoration(l10n.lblCategory, Icons.category_outlined, null),
        icon: const Icon(Icons.arrow_drop_down),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(16),
        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(_getDisplayCategory(context, c)))).toList(),
        onChanged: (v) => setState(() => _selectedCategory = v!),
      );
    }
  }

  Widget _buildAttendeesInput() {
    final l10n = AppLocalizations.of(context)!;
    if (_attendeesOptions.isEmpty) return const SizedBox();
    String formatAttendees(int n) => "$n ${n > 1 ? l10n.personPlural : l10n.personSingular}";

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
                  _buildIosPickerHeader(context, l10n),
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 32,
                      scrollController: FixedExtentScrollController(
                        initialItem: _attendeesOptions.indexOf(_maxAttendees) >= 0 ? _attendeesOptions.indexOf(_maxAttendees) : 0
                      ),
                      onSelectedItemChanged: (index) => setState(() => _maxAttendees = _attendeesOptions[index]),
                      children: _attendeesOptions.map((n) => Text(formatAttendees(n))).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: AbsorbPointer(
          child: TextFormField(
            decoration: _buildInputDecoration(l10n.lblMaxAttendees, Icons.people_outline, null).copyWith(
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
            controller: TextEditingController(text: "$_maxAttendees"),
          ),
        ),
      );
    } else {
      return DropdownButtonFormField<int>(
        value: _attendeesOptions.contains(_maxAttendees) ? _maxAttendees : _attendeesOptions.first,
        decoration: _buildInputDecoration(l10n.lblMaxAttendees, Icons.people_outline, null),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(16),
        items: _attendeesOptions.map((n) => DropdownMenuItem(value: n, child: Text("$n"))).toList(),
        onChanged: (v) => setState(() => _maxAttendees = v!),
      );
    }
  }

  Future<String> _uploadImage() async {
    final l10n = AppLocalizations.of(context)!;
    if (_imageFile == null) return widget.activity.imageUrl; 
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('activities')
          .child(widget.activity.hostUid)
          .child(fileName);
          
      final UploadTask uploadTask = storageRef.putFile(_imageFile!);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception(l10n.errImageUpload);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedLat == null || _selectedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.msgSelectLocationVerify)),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dataService = Provider.of<DataService>(context, listen: false);
      String imageUrl = await _uploadImage();

      final finalDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final now = DateTime.now();
      
      // LÓGICA DE RECICLAJE (RENEWAL):
      // Si la actividad era antigua (antes de hoy) y se mueve al futuro, se resetea.
      bool shouldReset = false;
      if (widget.activity.dateTime.isBefore(now) && finalDateTime.isAfter(now)) {
        shouldReset = true;
      }

      final updatedData = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'category': _selectedCategory,
        'location': _locationController.text.trim(),
        'maxAttendees': _maxAttendees,
        'dateTime': Timestamp.fromDate(finalDateTime),
        'imageUrl': imageUrl,
        'lat': _selectedLat,
        'lng': _selectedLng,
      };

      await dataService.updateActivity(widget.activity.id, updatedData);

      if (shouldReset) {
        // Borramos participantes y chat porque es un "evento nuevo"
        await dataService.resetActivityData(widget.activity.id);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(shouldReset 
              ? l10n.msgActivityRenewed 
              : l10n.msgActivityUpdated),
            backgroundColor: shouldReset ? Colors.green : _brandColor,
          ),
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
        title: Text(l10n.screenEditActivityTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _isSaving 
        ? Center(child: CircularProgressIndicator(color: _brandColor))
        : Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // --- SECCIÓN FOTO (Tarjeta Aesthetic) ---
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _imageFile != null
                            ? Image.file(_imageFile!, fit: BoxFit.cover)
                            : Image.network(widget.activity.imageUrl, fit: BoxFit.cover),
                        Container(color: Colors.black26), // Overlay oscuro suave
                        const Center(child: Icon(Icons.edit, color: Colors.white, size: 40)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- INPUTS ---
              TextFormField(
                controller: _titleController,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                decoration: _buildInputDecoration(l10n.fieldTitle, Icons.title, null),
                validator: (v) => v!.isEmpty ? l10n.errorGeneric : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descController,
                decoration: _buildInputDecoration(l10n.fieldDesc, Icons.description_outlined, null),
                maxLines: 4,
                validator: (v) => v!.isEmpty ? l10n.errorGeneric : null,
              ),
              const SizedBox(height: 16),

              _buildCategoryInput(),
              const SizedBox(height: 16),

              // --- FECHA Y HORA (Tarjetas Visuales) ---
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: _bgInputColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: _brandColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                DateFormat.MMMd(Localizations.localeOf(context).toString()).format(_selectedDate),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: _bgInputColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, color: _brandColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _selectedTime.format(context),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                readOnly: true,
                onTap: _openLocationSearch,
                decoration: _buildInputDecoration(l10n.fieldLocation, Icons.location_on_outlined, l10n.hintLocation),
                validator: (v) => v!.isEmpty ? l10n.errorGeneric : null,
              ),
              const SizedBox(height: 16),

              _buildAttendeesInput(),

              const SizedBox(height: 40),

              // --- BOTÓN PRINCIPAL ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: _brandColor.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    l10n.btnSaveChanges, 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
    );
  }
}