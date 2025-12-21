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

  String _searchQuery = '';
  String _selectedCategory = 'Todas';
  DateTime? _selectedDate;

  // --- MEJORA 1: Getter público para que la UI sepa qué categoría pintar ---
  String get selectedCategory => _selectedCategory;
  DateTime? get currentFilterDate => _selectedDate;

  DataService() {
    _listenToActivities();
  }

  void _listenToActivities() {
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

  void setDateFilter(DateTime? date) {
    _selectedDate = date;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredActivities = _allActivities.where((activity) {
      final matchesSearch = activity.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            activity.location.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesCategory = _selectedCategory == 'Todas' || 
                              activity.category == _selectedCategory;

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

  // --- SEGURIDAD ---
  Future<void> reportContent({
    required String reporterUid,
    required String reportedId,
    required String type, // 'activity' o 'user'
    required String reason
  }) async {
    await _db.collection('reports').add({
      'reporterUid': reporterUid,
      'reportedId': reportedId,
      'type': type,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending_review'
    });
  }

  Future<void> blockUser(String myUid, String userToBlockUid) async {
    await _db.collection('users').doc(myUid).collection('blocked').doc(userToBlockUid).set({
      'timestamp': FieldValue.serverTimestamp()
    });
    notifyListeners();
  }

  // --- ACTIVIDADES ---
  Future<void> createActivity(Map<String, dynamic> activityData) async {
    try {
      activityData['createdAt'] = FieldValue.serverTimestamp();
      activityData['acceptedCount'] = 0; // Inicio en 0
      activityData['participantImages'] = []; // Lista vacía
      
      await _db.collection('activities').add(activityData);

      // --- MEJORA 2: Resetear filtros para ver la nueva actividad ---
      _searchQuery = '';
      _selectedCategory = 'Todas';
      _selectedDate = null;
      _applyFilters(); // Re-aplicar filtros limpios
      notifyListeners(); // Avisar a la UI
      
    } catch (e) {
      if (kDebugMode) print("Error creando actividad: $e");
      rethrow;
    }
  }

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

  Future<void> deleteActivity(String activityId) async {
    try {
      await _db.collection('activities').doc(activityId).delete();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error borrando actividad: $e");
    }
  }

  // NUEVO: Limpiar datos de actividad (Reciclaje)
  Future<void> resetActivityData(String activityId) async {
    final batch = _db.batch();

    // 1. Borrar Participantes
    var participants = await _db
        .collection('applications') // Ojo: Si usas subcolección, ajusta la ruta a activities/id/applications
        .where('activityId', isEqualTo: activityId) 
        .get();
    
    // Si tus applications están en una colección raíz, esto las borra.
    // Si están dentro de la actividad (subcolección), usa: _db.collection('activities').doc(activityId).collection('applications').get();
    
    for (var doc in participants.docs) {
      batch.delete(doc.reference);
    }

    // 2. Borrar Chat
    var messages = await _db
        .collection('activities')
        .doc(activityId)
        .collection('messages')
        .get();

    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }

    // 3. Reiniciar contadores en la Actividad principal
    final activityRef = _db.collection('activities').doc(activityId);
    batch.update(activityRef, {
      'acceptedCount': 0,
      'participantImages': [], // Limpiamos las caritas
    });

    await batch.commit();
    notifyListeners();
  }

  Stream<QuerySnapshot> getUserActivitiesStream(String uid) {
    return _db.collection('activities')
        .where('hostUid', isEqualTo: uid)
        .orderBy('dateTime', descending: true)
        .snapshots();
  }

  // --- SOLICITUDES Y GESTIÓN ---
  
  // 1. Unirse
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
  
  // 2. ACEPTAR USUARIO
  Future<void> acceptApplicant(String applicationId, String activityId, String applicantPhotoUrl) async {
    try {
      await _db.collection('applications').doc(applicationId).update({
        'status': 'accepted'
      });

      await _db.collection('activities').doc(activityId).update({
        'acceptedCount': FieldValue.increment(1),
        'participantImages': FieldValue.arrayUnion([applicantPhotoUrl]),
      });
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error aceptando usuario: $e");
    }
  }

  // 3. RECHAZAR USUARIO
  Future<void> rejectApplicant(String applicationId) async {
    await _db.collection('applications').doc(applicationId).update({
      'status': 'rejected'
    });
    notifyListeners();
  }

  // 4. ELIMINAR PARTICIPANTE
  Future<void> removeParticipant(String applicationId, String activityId, String applicantPhotoUrl) async {
    try {
      await _db.collection('applications').doc(applicationId).update({
        'status': 'rejected'
      });

      await _db.collection('activities').doc(activityId).update({
        'acceptedCount': FieldValue.increment(-1),
        'participantImages': FieldValue.arrayRemove([applicantPhotoUrl]),
      });
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error eliminando participante: $e");
    }
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

  // --- NOTIFICACIONES ---
  Stream<QuerySnapshot> getUserNotifications(String uid) {
    return _db.collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> markNotificationAsRead(String uid, String notifId) async {
    await _db.collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notifId)
        .update({'read': true});
  }
  
  Stream<int> getUnreadCount(String uid) {
    return _db.collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // --- ZONA ADMINISTRADOR (MODERACIÓN) ---
  Stream<QuerySnapshot> getAdminReportsStream() {
    return _db.collection('reports')
        .where('status', isEqualTo: 'pending_review') 
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> adminDeleteActivity(String activityId, String reportId) async {
    try {
      await _db.collection('activities').doc(activityId).delete();
      await _db.collection('reports').doc(reportId).update({
        'status': 'resolved_deleted',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      print("Error admin delete activity: $e");
    }
  }

  Future<void> adminBanUser(String userId, String reportId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'isBanned': true, 
      });
      await _db.collection('reports').doc(reportId).update({
        'status': 'resolved_banned',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      print("Error admin ban user: $e");
    }
  }

  Future<void> adminDismissReport(String reportId) async {
    await _db.collection('reports').doc(reportId).update({
      'status': 'dismissed',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }
  
  Future<void> refresh() async {
    notifyListeners();
  }
}