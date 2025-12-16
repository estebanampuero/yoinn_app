import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_model.dart';
import '../services/data_service.dart';

class ManageActivityScreen extends StatelessWidget {
  final Activity activity;

  const ManageActivityScreen({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestionar Participantes"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: dataService.getActivityApplications(activity.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error al cargar solicitudes"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          // Separamos las solicitudes
          final pending = docs.where((doc) => doc['status'] == 'pending').toList();
          final accepted = docs.where((doc) => doc['status'] == 'accepted').toList();

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("Aún no hay solicitudes", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- SECCIÓN PENDIENTES ---
              if (pending.isNotEmpty) ...[
                const Text(
                  "SOLICITUDES PENDIENTES",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                ...pending.map((doc) => _buildApplicantCard(context, doc, isPending: true)),
                const SizedBox(height: 24),
              ],

              // --- SECCIÓN ACEPTADOS ---
              if (accepted.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "PARTICIPANTES",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    Text(
                      "${accepted.length} / ${activity.maxAttendees}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...accepted.map((doc) => _buildApplicantCard(context, doc, isPending: false)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildApplicantCard(BuildContext context, DocumentSnapshot doc, {required bool isPending}) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['applicantName'] ?? 'Desconocido';
    final pic = data['applicantProfilePictureUrl'] ?? '';
    final applicationId = doc.id;
    final dataService = Provider.of<DataService>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: pic.isNotEmpty ? NetworkImage(pic) : null,
              child: pic.isEmpty ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (isPending)
                    const Text("Quiere unirse", style: TextStyle(color: Colors.grey, fontSize: 12))
                  else
                    const Text("Confirmado", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            // Botones de acción
            if (isPending)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                       dataService.updateApplicationStatus(applicationId, 'rejected');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () {
                       dataService.updateApplicationStatus(applicationId, 'accepted');
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}