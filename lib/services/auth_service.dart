import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // <--- IMPORTACIÓN NUEVA
import '../models/user_model.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance; // <--- INSTANCIA NUEVA

  UserModel? _currentUser;
  bool _isLoading = true;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  AuthService() {
    _auth.authStateChanges().listen((User? firebaseUser) {
      _handleAuthChange(firebaseUser);
    });
  }

  Future<void> _handleAuthChange(User? firebaseUser) async {
    if (kDebugMode) print("Auth State Changed: ${firebaseUser?.uid}");

    _isLoading = true;
    notifyListeners();

    if (firebaseUser == null) {
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      DocumentSnapshot doc = await _db.collection('users').doc(firebaseUser.uid).get();

      if (doc.exists) {
        _currentUser = UserModel.fromFirestore(doc);
        
        // Actualizar última conexión
        await _db.collection('users').doc(firebaseUser.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        }).catchError((e) => print("Error actualizando lastLogin: $e"));
        
      } else {
        final newUser = UserModel(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'Usuario Nuevo',
          email: firebaseUser.email ?? '',
          profilePictureUrl: firebaseUser.photoURL ?? '',
          bio: '',
          birthDate: '',
          hobbies: [],
          isSubscribed: true,
          phoneVerified: false,
          profileCompleted: false,
          galleryImages: [],
          location: null,
        );

        await _db.collection('users').doc(firebaseUser.uid).set(newUser.toMap());
        
        await _db.collection('users').doc(firebaseUser.uid).update({
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        _currentUser = newUser;
      }

      // --- NUEVO: GUARDAR EL TOKEN DE NOTIFICACIONES ---
      // Se ejecuta siempre que el usuario se autentica exitosamente
      await _saveUserToken(firebaseUser.uid);

    } catch (e) {
      if (kDebugMode) print("CRITICAL ERROR en _handleAuthChange: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- NUEVA FUNCIÓN PARA GESTIONAR EL TOKEN ---
  Future<void> _saveUserToken(String uid) async {
    try {
      // 1. Pedir permiso (Crítico para iOS)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // 2. Obtener el token
        String? token = await _messaging.getToken();
        
        if (token != null) {
          if (kDebugMode) print("FCM Token obtenido: $token");
          
          // 3. Guardarlo en Firestore
          await _db.collection('users').doc(uid).update({
            'fcmToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          });
        }
      } else {
        if (kDebugMode) print("Permiso de notificaciones denegado");
      }
    } catch (e) {
      if (kDebugMode) print("Error guardando FCM Token: $e");
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      if (kDebugMode) print("Error en Google Sign In: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) print("Error al cerrar sesión: $e");
    }
  }

  Future<void> deleteAccount([String? confirmationText]) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _db.collection('users').doc(user.uid).delete();
        await user.delete();
        await _googleSignIn.signOut();
        _currentUser = null;
        notifyListeners();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'Por seguridad, cierra sesión e ingresa nuevamente para poder eliminar tu cuenta.';
      } else {
        rethrow;
      }
    } catch (e) {
      if (kDebugMode) print("Error eliminando cuenta: $e");
      rethrow;
    }
  }
}