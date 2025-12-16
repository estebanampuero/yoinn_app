import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime dateTime;
  final String location;
  final double lat;
  final double lng;
  final int maxAttendees;
  final String imageUrl;
  final String hostUid;

  Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.dateTime,
    required this.location,
    required this.lat,
    required this.lng,
    required this.maxAttendees,
    required this.imageUrl,
    required this.hostUid,
  });

  // Convierte un documento de Firebase a un objeto Activity
  factory Activity.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return Activity(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Other',
      // Convierte Timestamp de Firebase a DateTime de Dart
      dateTime: (data['dateTime'] as Timestamp).toDate(), 
      location: data['location'] ?? '',
      // Asegura que sean double (decimales)
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      maxAttendees: data['maxAttendees'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      hostUid: data['hostUid'] ?? '',
    );
  }

  // Convierte un objeto Activity a un Mapa para guardar en Firebase
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'lat': lat,
      'lng': lng,
      'maxAttendees': maxAttendees,
      'imageUrl': imageUrl,
      'hostUid': hostUid,
    };
  }
}