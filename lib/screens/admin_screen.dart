import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:yoinn_app/l10n/app_localizations.dart'; 

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

  // COLORES AESTHETIC PRO
  final Color _brandColor = const Color(0xFF00BCD4);
  final Color _bgScreenColor = const Color(0xFFF0F8FA);
  final Color _dangerColor = const Color(0xFFFF5252);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- LOGICA DE INSPECCIÓN ---
  Future<void> _inspectActivity(String activityId) async {
    if (activityId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('activities').doc(activityId).get();
      if (doc.exists && mounted) {
        final activity = Activity.fromFirestore(doc);
        Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityDetailScreen(activity: activity)));
      }
    } catch (e) {
      debugPrint("Error inspeccionando: $e");
    }
  }

  // --- ACCIONES DE MODERACIÓN ---
  Future<void> _deleteUser(BuildContext context, String userId, String userName) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await _showConfirmDialog(
      l10n.dialogDeleteUserTitle, 
      l10n.dialogDeleteUserBody(userName), 
      isDanger: true
    );

    if (confirm) {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      // Opcional: Borrar también sus actividades o marcarlo como "banned"
      if (mounted) _showSnack(l10n.successMessage, Colors.green);
    }
  }

  Future<void> _deleteActivity(BuildContext context, String activityId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await _showConfirmDialog(
      l10n.dialogDeleteTitle, 
      l10n.dialogDeleteBody,
      isDanger: true
    );

    if (confirm) {
      await FirebaseFirestore.instance.collection('activities').doc(activityId).delete();
      if (mounted) _showSnack(l10n.msgActivityDeleted, Colors.green);
    }
  }

  Future<void> _resolveReport(String reportId, {bool banAction = false, String? targetId, String? type}) async {
    final l10n = AppLocalizations.of(context)!;
    
    if (banAction && targetId != null) {
      final confirm = await _showConfirmDialog(
        l10n.dialogSanctionTitle,
        type == 'user_report' ? "¿Banear permanentemente a este usuario?" : l10n.dialogSanctionBody,
        isDanger: true
      );
      
      if (!confirm) return;

      if (type == 'user_report') {
        await FirebaseFirestore.instance.collection('users').doc(targetId).update({'isBanned': true}); // O delete()
      } else {
        await FirebaseFirestore.instance.collection('activities').doc(targetId).delete();
      }
    }

    // Borramos el reporte porque ya fue atendido o descartado
    await FirebaseFirestore.instance.collection('reports').doc(reportId).delete();
    if (mounted) _showSnack(banAction ? l10n.msgContentDeleted : l10n.msgReportDismissed, banAction ? _dangerColor : _brandColor);
  }

  // --- UI HELPERS ---
  Future<bool> _showConfirmDialog(String title, String body, {bool isDanger = false}) async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.btnCancel, style: const TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text(l10n.btnDeleteConfirm, style: TextStyle(color: isDanger ? _dangerColor : _brandColor, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _bgScreenColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          height: 44,
          decoration: BoxDecoration(color: _bgScreenColor, borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchPlaceholder,
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => _searchController.clear()) : null,
              border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 10)
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _brandColor,
          unselectedLabelColor: Colors.grey[400],
          indicatorColor: _brandColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: l10n.tabUsers),
            Tab(text: l10n.tabActivities),
            Tab(text: l10n.tabReports),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersList(l10n),
          _buildActivitiesList(l10n),
          _buildReportsList(l10n),
        ],
      ),
    );
  }

  // 1. LISTA DE USUARIOS
  Widget _buildUsersList(AppLocalizations l10n) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').orderBy('name').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: _brandColor));
        
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery) || email.contains(_searchQuery);
        }).toList();

        if (docs.isEmpty) return Center(child: Text(l10n.msgNoUsers));

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  backgroundImage: (data['profilePictureUrl'] ?? '').isNotEmpty ? NetworkImage(data['profilePictureUrl']) : null,
                  child: (data['profilePictureUrl'] ?? '').isEmpty ? Icon(Icons.person, color: Colors.grey[400]) : null,
                ),
                title: Text(data['name'] ?? 'Anon', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(data['email'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: _dangerColor),
                  onPressed: () => _deleteUser(context, docs[index].id, data['name'] ?? ''),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 2. LISTA DE ACTIVIDADES
  Widget _buildActivitiesList(AppLocalizations l10n) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('activities').orderBy('dateTime', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: _brandColor));
        
        final docs = snapshot.data!.docs.where((doc) {
          final activity = Activity.fromFirestore(doc);
          return activity.title.toLowerCase().contains(_searchQuery);
        }).toList();

        if (docs.isEmpty) return Center(child: Text(l10n.msgNoActivities));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final activity = Activity.fromFirestore(docs[index]);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
              child: ListTile(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityDetailScreen(activity: activity))),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(activity.imageUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey[200])),
                ),
                title: Text(activity.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(DateFormat.MMMd().format(activity.dateTime), style: TextStyle(fontSize: 12, color: _brandColor)),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: _dangerColor),
                  onPressed: () => _deleteActivity(context, activity.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 3. LISTA DE REPORTES (ROBUSTA)
  Widget _buildReportsList(AppLocalizations l10n) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reports').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: _brandColor));
        final reports = snapshot.data!.docs;

        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 60, color: Colors.green[200]),
                const SizedBox(height: 16),
                Text(l10n.msgNoReports, style: TextStyle(color: Colors.grey[400])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final data = reports[index].data() as Map<String, dynamic>;
            final reportId = reports[index].id;
            
            // Detectamos si es reporte de Actividad o Usuario
            final type = data['type'] ?? 'activity_report'; 
            final targetId = type == 'user_report' ? (data['reportedUid'] ?? '') : (data['activityId'] ?? '');
            final reason = data['reason'] ?? 'Sin razón';
            final reportedBy = data['reportedBy'] ?? 'anon';
            final date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

            final isUserReport = type == 'user_report';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isUserReport ? Colors.orange.withOpacity(0.3) : _dangerColor.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isUserReport ? Colors.orange[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Row(
                          children: [
                            Icon(isUserReport ? Icons.person_off : Icons.event_busy, size: 14, color: isUserReport ? Colors.orange : _dangerColor),
                            const SizedBox(width: 6),
                            Text(isUserReport ? "USUARIO REPORTADO" : "ACTIVIDAD REPORTADA", style: TextStyle(color: isUserReport ? Colors.orange : _dangerColor, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(DateFormat('dd MMM HH:mm').format(date), style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text("Motivo: $reason", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text("Reportado por ID: $reportedBy", style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!isUserReport)
                        TextButton.icon(
                          onPressed: () => _inspectActivity(targetId),
                          icon: const Icon(Icons.visibility, size: 16, color: Colors.grey),
                          label: const Text("Ver", style: TextStyle(color: Colors.grey)),
                        ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () => _resolveReport(reportId),
                        child: Text(l10n.btnDismiss, style: const TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: isUserReport ? Colors.orange : _dangerColor, elevation: 0),
                        onPressed: () => _resolveReport(reportId, banAction: true, targetId: targetId, type: type),
                        child: Text(isUserReport ? "BANEAR" : l10n.btnDelete, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}