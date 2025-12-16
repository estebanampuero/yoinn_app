import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
    // DEBUG: Inicio del proceso
    if (kDebugMode) print("Auth State Changed: ${firebaseUser?.uid}");

    _isLoading = true;
    notifyListeners();

    if (firebaseUser == null) {
      if (kDebugMode) print("Usuario es NULL, limpiando estado local.");
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      if (kDebugMode) print("Buscando usuario en Firestore: ${firebaseUser.uid}...");
      
      DocumentSnapshot doc = await _db.collection('users').doc(firebaseUser.uid).get();

      if (doc.exists) {
        if (kDebugMode) print("Usuario encontrado en Firestore. Cargando datos...");
        _currentUser = UserModel.fromFirestore(doc);
        
        // Actualizar última conexión sin bloquear el flujo principal
        _db.collection('users').doc(firebaseUser.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        }).catchError((e) => print("Error actualizando lastLogin: $e"));
        
      } else {
        if (kDebugMode) print("Usuario NO existe en Firestore. Creando nuevo registro...");
        
        final newUser = UserModel(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'Usuario Nuevo',
          email: firebaseUser.email ?? '',
          profilePictureUrl: firebaseUser.photoURL ?? 'https://ui-avatars.com/api/?name=User',
          bio: '',
          birthDate: '',
          hobbies: [],
          isSubscribed: true,
          phoneVerified: false,
          profileCompleted: false,
          galleryImages: [],
          location: null,
        );

        // Guardar en Firestore
        await _db.collection('users').doc(firebaseUser.uid).set(newUser.toMap());
        
        // Agregar campo de creación
        await _db.collection('users').doc(firebaseUser.uid).update({
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Asignar al estado local
        _currentUser = newUser;
        if (kDebugMode) print("Nuevo usuario creado y asignado a _currentUser.");
      }
    } catch (e) {
      // DEBUG: Error crítico
      if (kDebugMode) print("CRITICAL ERROR en _handleAuthChange: $e");
      // En caso de error (ej: permisos), nos aseguramos que el usuario no quede en un estado limbo
      // _currentUser = null; 
    } finally {
      _isLoading = false;
      // DEBUG: Verificación final
      if (kDebugMode) print("Notificando a la UI. Usuario actual es: ${_currentUser?.email}");
      notifyListeners();
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (kDebugMode) print("Google Sign In cancelado por el usuario.");
        return null;
      }

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
      if (kDebugMode) print("Sesión cerrada correctamente.");
    } catch (e) {
      if (kDebugMode) print("Error al cerrar sesión: $e");
    }
  }
}