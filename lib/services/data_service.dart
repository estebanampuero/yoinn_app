import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/activity_model.dart';
import '../models/user_model.dart';

class DataService with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<Activity> _allActivities = [];
  List<Activity> _filteredActivities = [];
  bool _isLoading = true;

  List<Activity> get activities => _filteredActivities;
  bool get isLoading => _isLoading;

  // Estado de los filtros
  String _searchQuery = '';
  String _selectedCategory = 'Todas';
  DateTime? _selectedDate; // Nuevo filtro de fecha

  // Getter para saber si hay fecha seleccionada
  DateTime? get currentFilterDate => _selectedDate;

  DataService() {
    _listenToActivities();
  }

  void _listenToActivities() {
    // Escuchamos actividades desde hoy en adelante
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day); 

    _db.collection('activities')
       .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
       .orderBy('dateTime')
       .snapshots()
       .listen((snapshot) {
      
      _allActivities = snapshot.docs.map((doc) {
        return Activity.fromFirestore(doc);
      }).toList();

      _applyFilters();
      
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      if (kDebugMode) print("Error escuchando actividades: $error");
      _isLoading = false;
      notifyListeners();
    });
  }

  // --- FILTROS ---
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setCategoryFilter(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  // Nuevo: Filtro de fecha
  void setDateFilter(DateTime? date) {
    _selectedDate = date;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredActivities = _allActivities.where((activity) {
      // 1. Texto (Título o Ubicación)
      final matchesSearch = activity.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            activity.location.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // 2. Categoría
      final matchesCategory = _selectedCategory == 'Todas' || 
                              activity.category == _selectedCategory;

      // 3. Fecha (Si hay una seleccionada)
      bool matchesDate = true;
      if (_selectedDate != null) {
        final actDate = activity.dateTime;
        matchesDate = actDate.year == _selectedDate!.year &&
                      actDate.month == _selectedDate!.month &&
                      actDate.day == _selectedDate!.day;
      }

      return matchesSearch && matchesCategory && matchesDate;
    }).toList();
  }

  // --- USUARIOS ---
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
    } catch (e) {
      if (kDebugMode) print("Error obteniendo usuario: $e");
    }
    return null;
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      data['lastUpdate'] = FieldValue.serverTimestamp();
      await _db.collection('users').doc(uid).update(data);
      notifyListeners(); 
    } catch (e) {
      if (kDebugMode) print("Error actualizando perfil: $e");
      rethrow;
    }
  }

  Future<void> uploadGalleryImage(String uid, File imageFile) async {
    try {
      final String fileName = 'gallery/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child('users').child(uid).child(fileName);
      
      final UploadTask task = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await task;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      await _db.collection('users').doc(uid).update({
        'galleryImages': FieldValue.arrayUnion([downloadUrl]),
        'lastUpdate': FieldValue.serverTimestamp(),
      });
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error subiendo imagen a galería: $e");
      rethrow;
    }
  }

  // --- ACTIVIDADES ---

  Future<void> createActivity(Map<String, dynamic> activityData) async {
    try {
      activityData['createdAt'] = FieldValue.serverTimestamp();
      await _db.collection('activities').add(activityData);
    } catch (e) {
      if (kDebugMode) print("Error creando actividad: $e");
      rethrow;
    }
  }

  // Nuevo: Editar Actividad
  Future<void> updateActivity(String activityId, Map<String, dynamic> newData) async {
    try {
      newData['lastUpdate'] = FieldValue.serverTimestamp();
      await _db.collection('activities').doc(activityId).update(newData);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error editando actividad: $e");
      rethrow;
    }
  }

  // Nuevo: Obtener actividades creadas por un usuario (para el perfil)
  Stream<QuerySnapshot> getUserActivitiesStream(String uid) {
    return _db.collection('activities')
        .where('hostUid', isEqualTo: uid)
        .orderBy('dateTime', descending: true)
        .snapshots();
  }

  // --- SOLICITUDES ---
  Future<void> applyToActivity(String activityId, UserModel user) async {
    try {
      await _db.collection('applications').add({
        'activityId': activityId,
        'applicantUid': user.uid,
        'applicantName': user.name,
        'applicantProfilePictureUrl': user.profilePictureUrl,
        'status': 'pending', 
        'appliedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error aplicando: $e");
      rethrow;
    }
  }

  Future<String?> getApplicationStatus(String activityId, String userId) async {
    try {
      final snapshot = await _db.collection('applications')
          .where('activityId', isEqualTo: activityId)
          .where('applicantUid', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first['status'] as String;
      }
    } catch (e) {
      if (kDebugMode) print("Error checkeando status: $e");
    }
    return null;
  }

  Stream<QuerySnapshot> getActivityApplications(String activityId) {
    return _db.collection('applications')
        .where('activityId', isEqualTo: activityId)
        .snapshots();
  }
  
  Future<void> updateApplicationStatus(String applicationId, String newStatus) async {
    await _db.collection('applications').doc(applicationId).update({
      'status': newStatus
    });
  }

  // --- CHAT ---
  Future<void> sendMessage(String activityId, String text, UserModel sender) async {
    try {
      await _db.collection('activities').doc(activityId).collection('messages').add({
        'text': text,
        'senderUid': sender.uid,
        'senderName': sender.name,
        'senderProfilePictureUrl': sender.profilePictureUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) print("Error enviando mensaje: $e");
      rethrow;
    }
  }

  Stream<QuerySnapshot> getActivityMessages(String activityId) {
    return _db.collection('activities')
        .doc(activityId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
  
  Future<void> refresh() async {
    notifyListeners();
  }
   // Borrar actividad
  Future<void> deleteActivity(String activityId) async {
    try {
      await _db.collection('activities').doc(activityId).delete();
      // Opcional: Borrar aplicaciones y subcolecciones (mensajes)
      // En Firestore cliente no se puede borrar colecciones enteras fácil, 
      // pero esto borra la actividad del feed.
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error borrando actividad: $e");
    }
  }

  // --- NOTIFICACIONES ---

  // 1. Obtener conteo de no leídas para el badge del Home
  Stream<int> getUnreadCount(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // 2. Obtener la lista de notificaciones para la pantalla
  Stream<QuerySnapshot> getUserNotifications(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // 3. Marcar una notificación como leída
  Future<void> markNotificationAsRead(String uid, String notificationId) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      if (kDebugMode) print("Error marcando notificación como leída: $e");
    }
  }
}