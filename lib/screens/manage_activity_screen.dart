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
                  Text("Aún no hay solicitudes", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pending.isNotEmpty) ...[
                const Text("Solicitudes Pendientes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 10),
                ...pending.map((doc) => _buildUserTile(context, doc, true)),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
              ],

              if (accepted.isNotEmpty) ...[
                const Text("Participantes Aceptados", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                const SizedBox(height: 10),
                ...accepted.map((doc) => _buildUserTile(context, doc, false)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, DocumentSnapshot doc, bool isPending) {
    final data = doc.data() as Map<String, dynamic>;
    final applicationId = doc.id;
    final name = data['applicantName'] ?? 'Desconocido';
    final pic = data['applicantProfilePictureUrl'] ?? '';
    final dataService = Provider.of<DataService>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
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
                       dataService.rejectApplicant(applicationId);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () {
                       dataService.acceptApplicant(applicationId, activity.id, pic);
                    },
                  ),
                ],
              )
            else 
              // --- BOTÓN ELIMINAR PARTICIPANTE (NUEVO) ---
              IconButton(
                icon: const Icon(Icons.person_remove, color: Colors.red),
                tooltip: "Eliminar participante",
                onPressed: () {
                  // Confirmación antes de eliminar
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("¿Eliminar participante?"),
                      content: Text("¿Estás seguro de que quieres sacar a $name de la actividad?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Cancelar"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx); // Cierra el diálogo
                            dataService.removeParticipant(applicationId, activity.id, pic);
                          },
                          child: const Text("Eliminar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}