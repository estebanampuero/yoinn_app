import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import 'profile_screen.dart';

class ManageRequestsScreen extends StatelessWidget {
  final String activityId;
  final String activityTitle;

  const ManageRequestsScreen({
    super.key, 
    required this.activityId,
    required this.activityTitle,
  });

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FA),
      appBar: AppBar(
        title: Text("Solicitudes para $activityTitle"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: dataService.getActivityApplications(activityId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error cargando solicitudes"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          // Filtramos solo las pendientes
          final pendingRequests = docs.where((doc) => doc['status'] == 'pending').toList();

          if (pendingRequests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("No hay solicitudes pendientes", style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pendingRequests.length,
            itemBuilder: (context, index) {
              final req = pendingRequests[index];
              final applicantUid = req['applicantUid'];
              final applicantName = req['applicantName'];
              final applicantPhoto = req['applicantProfilePictureUrl'] ?? '';
              final reqId = req.id;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  // FOTO Y PERFIL CLICKABLE
                  leading: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProfileScreen(uid: applicantUid)),
                      );
                    },
                    child: CircleAvatar(
                      backgroundImage: applicantPhoto.isNotEmpty ? NetworkImage(applicantPhoto) : null,
                      backgroundColor: const Color(0xFF00BCD4),
                      child: applicantPhoto.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                    ),
                  ),
                  title: Text(applicantName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Quiere unirse"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // BOTÓN RECHAZAR
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => dataService.rejectApplicant(reqId),
                      ),
                      // BOTÓN ACEPTAR
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          dataService.acceptApplicant(reqId, activityId, applicantPhoto);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("$applicantName aceptado"))
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}