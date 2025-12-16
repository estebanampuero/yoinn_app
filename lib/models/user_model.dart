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
      'lastLogin': FieldValue.serverTimestamp(),
    };
  }
}