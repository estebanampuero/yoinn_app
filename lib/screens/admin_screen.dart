import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:yoinn_app/l10n/app_localizations.dart'; // <--- IMPORTANTE

import '../models/user_model.dart';
import '../models/activity_model.dart';
import 'activity_detail_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final Color _brandColor = const Color(0xFF00BCD4);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- NAVEGACIÓN A DETALLE ---
  Future<void> _inspectActivity(String activityId) async {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.msgActivityLoading), duration: const Duration(milliseconds: 500)),
    );

    try {
      final doc = await FirebaseFirestore.instance.collection('activities').doc(activityId).get();
      
      if (doc.exists && mounted) {
        final activity = Activity.fromFirestore(doc);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ActivityDetailScreen(activity: activity)),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.msgActivityNotFound), backgroundColor: Colors.orange),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${l10n.errorGeneric}: $e")));
      }
    }
  }

  // --- ACCIONES DE ELIMINACIÓN ---
  Future<void> _deleteUser(String userId, String userName) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dialogDeleteUserTitle),
        content: Text(l10n.dialogDeleteUserBody(userName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.btnCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.btnDelete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.successMessage)));
    }
  }

  Future<void> _deleteActivity(String activityId, String title) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dialogDeleteTitle),
        content: Text("${l10n.dialogDeleteBody} '$title'?"), // Reutilizamos string genérico
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.btnCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.btnDelete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('activities').doc(activityId).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.msgActivityDeleted)));
    }
  }

  // --- ACCIONES DE REPORTES ---
  Future<void> _dismissReport(String reportId) async {
    final l10n = AppLocalizations.of(context)!;
    await FirebaseFirestore.instance.collection('reports').doc(reportId).delete();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.msgReportDismissed)));
  }

  Future<void> _acceptReport(String reportId, String activityId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dialogSanctionTitle),
        content: Text(l10n.dialogSanctionBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.btnCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.btnDeleteAll, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('activities').doc(activityId).delete();
      await FirebaseFirestore.instance.collection('reports').doc(reportId).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.msgContentDeleted)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchPlaceholder,
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear, size: 20, color: Colors.grey), onPressed: () => _searchController.clear())
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: InputBorder.none,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _brandColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _brandColor,
          tabs: [
            Tab(icon: const Icon(Icons.people), text: l10n.tabUsers),
            Tab(icon: const Icon(Icons.event), text: l10n.tabActivities),
            Tab(icon: const Icon(Icons.warning_amber_rounded), text: l10n.tabReports),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // PESTAÑA 1: USUARIOS
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').orderBy('name').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery) || email.contains(_searchQuery);
              }).toList();

              if (docs.isEmpty) return Center(child: Text(l10n.msgNoUsers));

              return ListView.separated(
                padding: const EdgeInsets.all(10),
                itemCount: docs.length,
                separatorBuilder: (c, i) => const Divider(),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (data['profilePictureUrl'] ?? '').isNotEmpty ? NetworkImage(data['profilePictureUrl']) : null,
                      child: (data['profilePictureUrl'] ?? '').isEmpty ? const Icon(Icons.person) : null,
                    ),
                    title: Text(data['name'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(data['email'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () => _deleteUser(docs[index].id, data['name'] ?? ''),
                    ),
                  );
                },
              );
            },
          ),

          // PESTAÑA 2: ACTIVIDADES
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('activities').orderBy('dateTime', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs.where((doc) {
                final activity = Activity.fromFirestore(doc);
                return activity.title.toLowerCase().contains(_searchQuery) || activity.category.toLowerCase().contains(_searchQuery);
              }).toList();

              if (docs.isEmpty) return Center(child: Text(l10n.msgNoActivities));

              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final activity = Activity.fromFirestore(docs[index]);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: activity.imageUrl.isNotEmpty
                          ? Image.network(activity.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                          : const Icon(Icons.event),
                      title: Text(activity.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(activity.category),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        onPressed: () => _deleteActivity(activity.id, activity.title),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // PESTAÑA 3: REPORTES
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('reports').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              
              final reports = snapshot.data!.docs;

              if (reports.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
                      const SizedBox(height: 10),
                      Text(l10n.msgNoReports),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final reportData = reports[index].data() as Map<String, dynamic>;
                  final reportId = reports[index].id;
                  final activityId = reportData['activityId'] ?? '';
                  final reason = reportData['reason'] ?? 'Sin razón';
                  final date = (reportData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

                  return Card(
                    color: Colors.red[50],
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell( 
                      onTap: () => _inspectActivity(activityId),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning, color: Colors.red),
                                const SizedBox(width: 8),
                                Text(l10n.lblReportedActivity, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                const Spacer(),
                                Text(DateFormat('dd/MM HH:mm').format(date), style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text("${l10n.lblReason} $reason", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text("ID Actividad: $activityId", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.touch_app, size: 14, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text(l10n.lblTapDetails, style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),

                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () => _dismissReport(reportId),
                                  style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
                                  child: Text(l10n.btnDismiss),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () => _acceptReport(reportId, activityId),
                                  icon: const Icon(Icons.delete, color: Colors.white, size: 16),
                                  label: Text(l10n.btnDelete, style: const TextStyle(color: Colors.white)),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}