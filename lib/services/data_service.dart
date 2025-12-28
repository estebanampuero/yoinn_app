import 'dart:async';
import 'dart:io';
import 'dart:math' show cos, sqrt, asin; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // NECESARIO PARA PUSH
import 'package:flutter/foundation.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart'; 
import 'package:geolocator/geolocator.dart'; 
import 'package:rxdart/rxdart.dart'; 

import '../models/activity_model.dart';
import '../models/user_model.dart';
import '../config/subscription_limits.dart'; 
import 'subscription_service.dart'; 

class DataService with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  List<Activity> _allActivities = [];
  List<Activity> _filteredActivities = [];
  bool _isLoading = true;

  // Stream Controllers para la lógica reactiva de ubicación
  final BehaviorSubject<double> _radiusController = BehaviorSubject<double>.seeded(SubscriptionLimits.defaultRadius);
  StreamSubscription? _feedSubscription;

  List<Activity> get activities => _filteredActivities;
  bool get isLoading => _isLoading;

  String _searchQuery = '';
  String _selectedCategory = 'Todas';
  DateTime? _selectedDate;

  // Ubicación GPS y Radio
  double _filterRadiusKm = SubscriptionLimits.defaultRadius; 
  double? _userLat;
  double? _userLng;
  
  double get filterRadius => _filterRadiusKm;
  double? get currentLat => _userLat;
  double? get currentLng => _userLng;

  // Getters para filtros
  String get selectedCategory => _selectedCategory;
  DateTime? get currentFilterDate => _selectedDate;

  DataService() {
    _initRealtimeFeed(); 
    _initPushNotifications(); // INICIALIZA PUSH AL ARRANCAR
  }

  // --- 1. CONFIGURACIÓN PUSH NOTIFICATIONS ---
  Future<void> _initPushNotifications() async {
    try {
      // Pedir permiso al usuario (iOS mostrará el popup nativo)
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true, badge: true, sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await _fcm.getToken();
        if (kDebugMode) print("🔥 FCM TOKEN INICIAL: $token");
        
        // Escuchar cambios de token
        _fcm.onTokenRefresh.listen((newToken) {
           _updateUserTokenInDB(newToken);
        });
      }
    } catch (e) {
      if (kDebugMode) print("Error Push Init: $e");
    }
  }

  // Llamar a esto cuando el usuario hace Login
  Future<void> saveUserToken(String uid) async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _updateUserTokenInDB(token, uid: uid);
      }
    } catch (e) {
      if (kDebugMode) print("Error guardando token: $e");
    }
  }

  Future<void> _updateUserTokenInDB(String token, {String? uid}) async {
    if (uid != null) {
      await _db.collection('users').doc(uid).update({
        'fcmToken': token, 
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    }
  }

  // --- 2. HELPER PRIVADO (Ya no se usa para alertas manuales, pero se deja por utilidad futura) ---
  Future<void> _sendNotification({
    required String toUserId,
    required String title,
    required String body,
    required String type, 
    required String relatedActivityId,
  }) async {
    try {
      await _db.collection('users').doc(toUserId).collection('notifications').add({
        'title': title,
        'body': body,
        'type': type,
        'relatedActivityId': relatedActivityId,
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) print("Error enviando notificación: $e");
    }
  }

  // --- NUEVO MOTOR DE BÚSQUEDA (GeoFlutterFire Plus) ---
  void _initRealtimeFeed() async {
    // 1. Obtener ubicación inicial con TIMEOUT (Protección anti-cuelgue)
    try {
       Position position = await Geolocator.getCurrentPosition()
           .timeout(const Duration(seconds: 5));
       
       _userLat = position.latitude;
       _userLng = position.longitude;
    } catch (e) {
       if (kDebugMode) print("⚠️ GPS demoró o falló. Usando ubicación por defecto.");
       _userLat = -41.3221; // Puerto Varas default
       _userLng = -72.9752;
    }

    // 2. Stream del GPS (Solo actualiza si me muevo 2km)
    Stream<GeoPoint> userLocationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2000, 
      )
    ).map((p) {
      _userLat = p.latitude;
      _userLng = p.longitude;
      return GeoPoint(p.latitude, p.longitude);
    });

    // 3. Forzar carga inicial
    if (_userLat != null && _userLng != null) {
       final initialGeoPoint = GeoPoint(_userLat!, _userLng!);
       _queryActivitiesByLoc(initialGeoPoint, _radiusController.value);
    }

    // 4. Combinar GPS + Radio (Reactividad total)
    _feedSubscription = Rx.combineLatest2<GeoPoint, double, void>(
      userLocationStream,
      _radiusController.stream,
      (userLoc, radius) {
        _queryActivitiesByLoc(userLoc, radius);
      }
    ).listen(null);
  }

  void _queryActivitiesByLoc(GeoPoint center, double radiusInKm) {
    _isLoading = true;
    notifyListeners();

    // Referencia tipada
    final collectionRef = _db.collection('activities').withConverter<Activity>(
      fromFirestore: (snapshot, _) => Activity.fromFirestore(snapshot),
      toFirestore: (activity, _) => activity.toMap(),
    );

    // Solo actividades futuras
    GeoCollectionReference(collectionRef)
      .subscribeWithin(
        center: GeoFirePoint(center),
        radiusInKm: radiusInKm,
        field: 'geo', 
        geopointFrom: (activity) => activity.geoPoint, 
        strictMode: true, 
      )
      .listen((List<DocumentSnapshot<Activity>> docs) {
        
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);

        _allActivities = docs
            .map((d) => d.data()!)
            .where((a) => a.dateTime.isAfter(todayStart)) 
            .toList();

        _applyFilters();
        
        _isLoading = false;
        notifyListeners();
      }, onError: (e) {
        if (kDebugMode) print("Error en GeoQuery: $e");
        _isLoading = false;
        notifyListeners();
      });
  }

  // --- MÉTODOS DE UBICACIÓN ---
  
  void updateUserLocation(double lat, double lng) {
    _userLat = lat;
    _userLng = lng;
    notifyListeners();
  }

  void setRadiusFilter(double km) {
    _filterRadiusKm = km;
    _radiusController.add(km); 
    notifyListeners();
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295; 
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 + 
            c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a)); 
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

  // --- GESTIÓN DE USUARIOS ---
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
    required String type, 
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

  // --- ACTIVIDADES (CRUD) ---
  Future<void> createActivity(Map<String, dynamic> activityData) async {
    try {
      final userUid = activityData['hostUid'];
      
      // 1. Verificar suscripción
      bool isPro = await SubscriptionService.isUserPremium();
      if (!isPro) {
        final userDoc = await _db.collection('users').doc(userUid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data()!;
          if (userData['isManualPro'] == true) {
            isPro = true;
          }
        }
      }
      
      // Validar límite de creación
      final activeQuery = await _db.collection('activities')
          .where('hostUid', isEqualTo: userUid)
          .get(); 
      
      final currentActiveCount = activeQuery.docs.length;
      final limit = isPro ? SubscriptionLimits.proMaxActiveActivities : SubscriptionLimits.freeMaxActiveActivities;

      if (currentActiveCount >= limit) {
        throw Exception("Límite de actividades alcanzado ($limit). ${isPro ? '' : 'Hazte PRO para más.'}");
      }

      // 2. GENERAR GEOHASH
      final GeoFirePoint geoPoint = GeoFirePoint(
        GeoPoint(activityData['lat'], activityData['lng'])
      );
      activityData['geo'] = geoPoint.data; 

      activityData['maxAttendees'] = isPro ? SubscriptionLimits.proMaxAttendees : SubscriptionLimits.freeMaxAttendees;
      activityData['createdAt'] = FieldValue.serverTimestamp();
      activityData['acceptedCount'] = 0; 
      activityData['participantImages'] = []; 
      
      await _db.collection('activities').add(activityData);

      _searchQuery = '';
      _selectedCategory = 'Todas';
      _selectedDate = null;
    } catch (e) {
      if (kDebugMode) print("Error creando actividad: $e");
      rethrow;
    }
  }

  Future<void> updateActivity(String activityId, Map<String, dynamic> newData) async {
    try {
      newData['lastUpdate'] = FieldValue.serverTimestamp();
      
      // Si cambian ubicación, regeneramos hash
      if (newData.containsKey('lat') && newData.containsKey('lng')) {
         final GeoFirePoint geoPoint = GeoFirePoint(
            GeoPoint(newData['lat'], newData['lng'])
         );
         newData['geo'] = geoPoint.data;
      }

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

  Future<void> resetActivityData(String activityId) async {
    final batch = _db.batch();

    var participants = await _db
        .collection('applications') 
        .where('activityId', isEqualTo: activityId) 
        .get();
    
    for (var doc in participants.docs) {
      batch.delete(doc.reference);
    }

    var messages = await _db
        .collection('activities')
        .doc(activityId)
        .collection('messages')
        .get();

    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }

    final activityRef = _db.collection('activities').doc(activityId);
    batch.update(activityRef, {
      'acceptedCount': 0,
      'participantImages': [], 
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

  // --- SOLICITUDES (JOIN) + GAMIFICACIÓN ---
  
  Future<int> getRemainingFreeJoins(String uid) async {
    bool isPro = await SubscriptionService.isUserPremium();
    if (!isPro) {
        final userDoc = await _db.collection('users').doc(uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          if (userDoc.data()!['isManualPro'] == true) isPro = true;
        }
    }

    if (isPro) return -1; 

    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day - (now.weekday - 1)); 

    final joinsQuery = await _db.collection('applications')
        .where('applicantUid', isEqualTo: uid)
        .where('appliedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .get();
    
    int used = joinsQuery.docs.length;
    int remaining = SubscriptionLimits.freeMaxJoinsPerWeek - used;
    return remaining < 0 ? 0 : remaining;
  }

  Future<void> applyToActivity(String activityId, UserModel user) async {
    try {
      bool isPro = await SubscriptionService.isUserPremium() || user.isManualPro;

      if (!isPro) {
        final now = DateTime.now();
        final startOfWeek = DateTime(now.year, now.month, now.day - (now.weekday - 1)); 
        
        final joinsThisWeek = await _db.collection('applications')
            .where('applicantUid', isEqualTo: user.uid)
            .where('appliedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
            .get();
        
        if (joinsThisWeek.docs.length >= SubscriptionLimits.freeMaxJoinsPerWeek) {
           throw Exception("Sin Tickets. Has usado tus ${SubscriptionLimits.freeMaxJoinsPerWeek} intentos semanales. Hazte PRO para seguir apostando.");
        }
      }

      final activityDoc = await _db.collection('activities').doc(activityId).get();
      if (!activityDoc.exists) throw Exception("Actividad no encontrada");
      
      final activityData = activityDoc.data()!;
      int current = activityData['acceptedCount'] ?? 0;
      int max = activityData['maxAttendees'] ?? SubscriptionLimits.freeMaxAttendees;
      
      if (current >= max) {
        throw Exception("La actividad está llena.");
      }

      // Solo crea la solicitud (Ya no envía notificación manual, usa la automática)
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
  
  // ACEPTAR
  Future<void> acceptApplicant(String applicationId, String activityId, String applicantPhotoUrl) async {
    try {
      await _db.collection('applications').doc(applicationId).update({
        'status': 'accepted'
      });

      await _db.collection('activities').doc(activityId).update({
        'acceptedCount': FieldValue.increment(1),
        'participantImages': FieldValue.arrayUnion([applicantPhotoUrl]),
      });
      
      // Notificación manual eliminada. Se espera que tu Cloud Function envíe la naranja.
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error aceptando usuario: $e");
    }
  }

  // RECHAZAR
  Future<void> rejectApplicant(String applicationId) async {
    try {
      await _db.collection('applications').doc(applicationId).update({
        'status': 'rejected'
      });

      // Notificación manual eliminada.
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error rechazando: $e");
    }
  }

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
        'readBy': [sender.uid],
        'likedBy': [], 
      });
    } catch (e) {
      if (kDebugMode) print("Error enviando mensaje: $e");
      rethrow;
    }
  }

  Future<void> toggleMessageLike(String activityId, String messageId, String myUid, bool currentlyLiked) async {
    final docRef = _db.collection('activities')
        .doc(activityId)
        .collection('messages')
        .doc(messageId);

    if (currentlyLiked) {
      await docRef.update({
        'likedBy': FieldValue.arrayRemove([myUid])
      });
    } else {
      await docRef.update({
        'likedBy': FieldValue.arrayUnion([myUid])
      });
    }
  }

  Stream<QuerySnapshot> getActivityMessages(String activityId) {
    return _db.collection('activities')
        .doc(activityId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> markMessagesAsRead(String activityId, String myUid) async {
    final query = await _db.collection('activities')
        .doc(activityId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();

    final batch = _db.batch();
    bool needsCommit = false;

    for (var doc in query.docs) {
      List readBy = doc['readBy'] ?? [];
      if (!readBy.contains(myUid)) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([myUid])
        });
        needsCommit = true;
      }
    }

    if (needsCommit) {
      await batch.commit();
    }
  }

  Future<void> setTypingStatus(String activityId, String uid, bool isTyping) async {
    final docRef = _db.collection('activities').doc(activityId).collection('typing').doc(uid);
    
    if (isTyping) {
      await docRef.set({
        'isTyping': true,
        'timestamp': FieldValue.serverTimestamp(), 
      });
    } else {
      await docRef.delete();
    }
  }

  Stream<QuerySnapshot> getTypingStatus(String activityId) {
    return _db.collection('activities').doc(activityId).collection('typing').snapshots();
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

  // --- ADMIN ---
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
    _applyFilters();
    notifyListeners();
  }

  // --- LIMPIEZA ---
  @override
  void dispose() {
    _radiusController.close();
    _feedSubscription?.cancel();
    super.dispose();
  }
}