import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String profilePictureUrl;
  final String bio;
  final String birthDate;
  final List<String> hobbies;
  final bool isSubscribed; // Suscripción a newsletter/emails
  final bool phoneVerified;
  final bool profileCompleted;
  final List<String> galleryImages;
  final Map<String, dynamic>? location;

  // --- NUEVOS CAMPOS (Gamificación, Redes y ADMIN) ---
  final String? instagramHandle;
  final bool isVerified; 
  final int karmaPoints; 
  final int activitiesCreatedCount; 
  final bool isAdmin; 
  
  // --- NUEVO CAMPO (Suscripción de Pago) ---
  final bool isPremium; 
  
  // --- NUEVO CAMPO (Suscripción Manual / Admin) ---
  final bool isManualPro;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.profilePictureUrl,
    required this.bio,
    required this.birthDate,
    required this.hobbies,
    required this.isSubscribed,
    required this.phoneVerified,
    required this.profileCompleted,
    required this.galleryImages,
    this.location,
    this.instagramHandle,
    this.isVerified = false,
    this.karmaPoints = 0,
    this.activitiesCreatedCount = 0,
    this.isAdmin = false,
    this.isPremium = false, // Por defecto false
    this.isManualPro = false, // Por defecto false
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};

    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      profilePictureUrl: data['profilePictureUrl'] ?? '',
      bio: data['bio'] ?? '',
      birthDate: data['birthDate'] ?? '',
      hobbies: List<String>.from(data['hobbies'] ?? []),
      isSubscribed: data['isSubscribed'] ?? false,
      phoneVerified: data['phoneVerified'] ?? false,
      profileCompleted: data['profileCompleted'] ?? false,
      galleryImages: List<String>.from(data['galleryImages'] ?? []),
      location: data['location'],
      // Mapeo de nuevos campos
      instagramHandle: data['instagramHandle'],
      isVerified: data['isVerified'] ?? false,
      karmaPoints: (data['karmaPoints'] ?? 0).toInt(),
      activitiesCreatedCount: (data['activitiesCreatedCount'] ?? 0).toInt(),
      isAdmin: data['isAdmin'] ?? false,
      isPremium: data['isPremium'] ?? false,
      isManualPro: data['isManualPro'] ?? false, // <--- Leemos el estado Manual
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'profilePictureUrl': profilePictureUrl,
      'bio': bio,
      'birthDate': birthDate,
      'hobbies': hobbies,
      'isSubscribed': isSubscribed,
      'phoneVerified': phoneVerified,
      'profileCompleted': profileCompleted,
      'galleryImages': galleryImages,
      'location': location,
      // Guardar nuevos campos
      'instagramHandle': instagramHandle,
      'isVerified': isVerified,
      'karmaPoints': karmaPoints,
      'activitiesCreatedCount': activitiesCreatedCount,
      'isAdmin': isAdmin,
      'isPremium': isPremium,
      'isManualPro': isManualPro, // <--- Guardamos el estado Manual
      'lastLogin': FieldValue.serverTimestamp(),
    };
  }
}