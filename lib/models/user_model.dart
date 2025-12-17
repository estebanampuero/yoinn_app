import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String profilePictureUrl;
  final String bio;
  final String birthDate;
  final List<String> hobbies;
  final bool isSubscribed;
  final bool phoneVerified;
  final bool profileCompleted;
  final List<String> galleryImages;
  final Map<String, dynamic>? location;

  // --- NUEVOS CAMPOS (Gamificación y Redes) ---
  final String? instagramHandle;
  final bool isVerified; // Check azul de confianza
  final int karmaPoints; // Puntos por participar/crear
  final int activitiesCreatedCount; // Para badge de "Guía Local"

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
      'lastLogin': FieldValue.serverTimestamp(),
    };
  }
}