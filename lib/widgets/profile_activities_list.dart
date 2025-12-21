import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/activity_model.dart';
import '../services/data_service.dart';
import '../screens/edit_activity_screen.dart';

class ProfileActivitiesList extends StatelessWidget {
  final String uid;
  final bool isMe;
  
  // COLOR DE MARCA
  static const Color brandColor = Color(0xFF00BCD4);

  const ProfileActivitiesList({super.key, required this.uid, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Actividades Creadas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        
        StreamBuilder<QuerySnapshot>(
          stream: dataService.getUserActivitiesStream(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: brandColor));
            }
            if (!snapshot.hasData) return const SizedBox();

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return const Text("No has creado actividades aún.", style: TextStyle(color: Colors.grey));

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final act = Activity.fromFirestore(docs[index]);
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0,
                  color: const Color(0xFFF5F7F8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: act.imageUrl.isNotEmpty ? act.imageUrl : 'https://via.placeholder.com/100',
                        width: 60, height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey[200]),
                        errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                    title: Text(act.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(DateFormat('dd MMM yyyy • HH:mm').format(act.dateTime)),
                    trailing: isMe
                        ? IconButton(
                            // LÁPIZ CIAN
                            icon: const Icon(Icons.edit, color: brandColor),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => EditActivityScreen(activity: act)),
                              );
                            },
                          )
                        : null,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}