import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:yoinn_app/l10n/app_localizations.dart'; // <--- IMPORTANTE

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

  final Color _activeColor = const Color(0xFFF97316); 
  final Color _iosBtnColor = const Color(0xFF00BCD4); 

  final List<String> _categories = [
    'Deportes', 'Comida', 'Arte', 'Fiestas', 'Viajes', 'Musica', 'Tecnología', 'Bienestar', 'Otros'
  ];
  
  // Lista dinámica de acompañantes
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

    // Mapeo inverso básico por si viene en inglés desde la BD antigua
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

  // Función auxiliar para mostrar el nombre traducido en el Dropdown
  String _getDisplayCategory(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'Deportes': return l10n.catSport;
      case 'Comida': return l10n.catFood;
      case 'Arte': return l10n.catArt;
      case 'Fiestas': return l10n.catParty;
      case 'Viajes': return l10n.catOutdoor; 
      case 'Musica': return l10n.hobbyMusic; // Reutilizamos hobbyMusic
      case 'Tecnología': return l10n.catOther; // O hobbyTech si existe
      case 'Bienestar': return l10n.hobbyWellness;
      case 'Otros': return l10n.catOther;
      default: return key;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // --- LÓGICA DE LÍMITES FREEMIUM ---
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    final isPremium = user?.isPremium ?? false;

    // Definir límite según plan
    final int maxLimit = isPremium 
        ? SubscriptionLimits.proMaxAttendees 
        : SubscriptionLimits.freeMaxAttendees;

    // Generar la lista
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

  // --- FECHA NATIVA ---
  Future<void> _pickDate() async {
    final l10n = AppLocalizations.of(context)!;
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
                        child: Text(l10n.btnReady, style: TextStyle(color: _iosBtnColor, fontWeight: FontWeight.bold)),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: _selectedDate,
                    minimumDate: DateTime.now().subtract(const Duration(days: 365)), 
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
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime(2026),
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
                        child: Text(l10n.btnReady, style: TextStyle(color: _iosBtnColor, fontWeight: FontWeight.bold)),
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
                  Container(
                    color: Colors.grey[100],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Text(l10n.btnReady, style: TextStyle(color: _iosBtnColor, fontWeight: FontWeight.bold)),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 32,
                      scrollController: FixedExtentScrollController(
                        initialItem: _categories.indexOf(_selectedCategory) >= 0 ? _categories.indexOf(_selectedCategory) : 0
                      ),
                      onSelectedItemChanged: (index) {
                        setState(() => _selectedCategory = _categories[index]);
                      },
                      children: _categories.map((c) => Text(_getDisplayCategory(context, c))).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: l10n.lblCategory,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(_getDisplayCategory(context, _selectedCategory), style: const TextStyle(fontSize: 16)),
        ),
      );
    } else {
      return DropdownButtonFormField<String>(
        value: _selectedCategory,
        decoration: InputDecoration(labelText: l10n.lblCategory, border: const OutlineInputBorder()),
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
                  Container(
                    color: Colors.grey[100],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Text(l10n.btnReady, style: TextStyle(color: _iosBtnColor, fontWeight: FontWeight.bold)),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 32,
                      scrollController: FixedExtentScrollController(
                        initialItem: _attendeesOptions.indexOf(_maxAttendees) >= 0 ? _attendeesOptions.indexOf(_maxAttendees) : 0
                      ),
                      onSelectedItemChanged: (index) {
                        setState(() => _maxAttendees = _attendeesOptions[index]);
                      },
                      children: _attendeesOptions.map((n) => Text(formatAttendees(n))).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: l10n.lblMaxAttendees,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            suffixIcon: const Icon(Icons.people_outline),
          ),
          child: Text("$_maxAttendees", style: const TextStyle(fontSize: 16)),
        ),
      );
    } else {
      return DropdownButtonFormField<int>(
        value: _attendeesOptions.contains(_maxAttendees) ? _maxAttendees : _attendeesOptions.first,
        decoration: InputDecoration(labelText: l10n.lblMaxAttendees, border: const OutlineInputBorder()),
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
        await dataService.resetActivityData(widget.activity.id);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(shouldReset 
              ? l10n.msgActivityRenewed 
              : l10n.msgActivityUpdated),
            backgroundColor: shouldReset ? Colors.green : _activeColor,
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
      appBar: AppBar(title: Text(l10n.screenEditActivityTitle)),
      body: _isSaving 
        ? const Center(child: CircularProgressIndicator())
        : Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.lblPhotoHeader, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_imageFile!, fit: BoxFit.cover))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(widget.activity.imageUrl, fit: BoxFit.cover),
                      ),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: l10n.fieldTitle, border: const OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? l10n.errorGeneric : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(labelText: l10n.fieldDesc, border: const OutlineInputBorder()),
                maxLines: 4,
                validator: (v) => v!.isEmpty ? l10n.errorGeneric : null,
              ),
              const SizedBox(height: 16),

              _buildCategoryInput(),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate, 
                      icon: const Icon(Icons.calendar_today),
                      label: Text(DateFormat.yMd(Localizations.localeOf(context).toString()).format(_selectedDate)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime, 
                      icon: const Icon(Icons.access_time),
                      label: Text(_selectedTime.format(context)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                readOnly: true,
                onTap: _openLocationSearch,
                decoration: InputDecoration(
                  labelText: l10n.fieldLocation, 
                  border: const OutlineInputBorder(), 
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  hintText: l10n.hintLocation
                ),
                validator: (v) => v!.isEmpty ? l10n.errorGeneric : null,
              ),
              const SizedBox(height: 16),

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
                  child: Text(l10n.btnSaveChanges, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
    );
  }
}