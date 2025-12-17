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
  
  final int acceptedCount;
  // --- NUEVO CAMPO ---
  final List<String> participantImages; // Las últimas 3-4 fotos para mostrar en la tarjeta

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
    this.acceptedCount = 0,
    this.participantImages = const [],
  });

  factory Activity.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return Activity(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Other',
      dateTime: (data['dateTime'] as Timestamp).toDate(), 
      location: data['location'] ?? '',
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      maxAttendees: (data['maxAttendees'] ?? 0).toInt(),
      imageUrl: data['imageUrl'] ?? '',
      hostUid: data['hostUid'] ?? '',
      acceptedCount: (data['acceptedCount'] ?? 0).toInt(),
      // Mapeo seguro de la lista
      participantImages: List<String>.from(data['participantImages'] ?? []),
    );
  }

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
      'acceptedCount': acceptedCount,
      'participantImages': participantImages,
    };
  }
}