import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yoinn_app/l10n/app_localizations.dart'; // <--- IMPORTANTE

import '../models/activity_model.dart';
import '../models/user_model.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import '../screens/profile_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/manage_requests_screen.dart';

// --- HEADER (IMAGEN Y BOTONES SUPERIORES) ---
class ActivitySliverAppBar extends StatelessWidget {
  final Activity activity;
  final bool isHost;
  final VoidCallback onShare;
  final VoidCallback onOptions;

  const ActivitySliverAppBar({
    super.key,
    required this.activity, 
    required this.isHost,
    required this.onShare,
    required this.onOptions,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white, 
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: activity.imageUrl.isNotEmpty
            ? CachedNetworkImage(imageUrl: activity.imageUrl, fit: BoxFit.cover)
            : Image.network('https://via.placeholder.com/400x300', fit: BoxFit.cover),
      ),
      actions: [
         IconButton(
          icon: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.share, color: Colors.black, size: 20)),
          onPressed: onShare,
        ),
         IconButton(
          icon: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.more_vert, color: Colors.black)),
          onPressed: onOptions,
        ),
      ],
    );
  }
}

// --- INFO DEL HOST ---
class HostInfoTile extends StatelessWidget {
  final String hostUid;
  const HostInfoTile({super.key, required this.hostUid});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dataService = Provider.of<DataService>(context, listen: false);
    
    return FutureBuilder<UserModel?>(
      future: dataService.getUserProfile(hostUid),
      builder: (context, snapshot) {
        final host = snapshot.data;
        if (host == null) return const SizedBox();
        final isPro = host.activitiesCreatedCount > 5;
        
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(uid: host.uid))),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isPro ? Border.all(color: Colors.amber, width: 2) : null,
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundImage: host.profilePictureUrl.isNotEmpty ? NetworkImage(host.profilePictureUrl) : null,
                  child: host.profilePictureUrl.isEmpty ? const Icon(Icons.person) : null,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(host.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (host.isVerified) ...[const SizedBox(width: 4), const Icon(Icons.verified, color: Colors.blue, size: 16)]
                    ],
                  ),
                  Text(l10n.lblOrganizer, style: const TextStyle(color: Colors.grey, fontSize: 12)), // "Organizador"
                ],
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }
}

// --- FILAS DE INFO (FECHA, LUGAR, CUPOS) ---
class ActivityInfoRow extends StatelessWidget {
  final Activity activity;
  const ActivityInfoRow({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Fecha localizada
    final dateStr = DateFormat('EEEE, d MMMM yyyy', Localizations.localeOf(context).toString()).format(activity.dateTime);
    final timeStr = DateFormat('h:mm a').format(activity.dateTime);
    
    final spotsLeft = activity.maxAttendees - activity.acceptedCount;
    final spotsColor = spotsLeft <= 2 ? Colors.red : Colors.green;
    
    final spotsText = spotsLeft <= 0 
        ? l10n.msgActivityFull // "¡Actividad Llena!"
        : l10n.msgSpotsLeft(spotsLeft); // "Quedan X cupos..."

    return Column(
      children: [
        _buildRow(Icons.calendar_today, Colors.orange, dateStr, timeStr),
        const SizedBox(height: 16),
        _buildRow(Icons.location_on, Colors.blue, activity.location, l10n.lblEventLocation, // "Ubicación del evento"
          onTap: () async {
             final googleUrl = 'http://googleusercontent.com/maps.google.com/?q=${activity.lat},${activity.lng}';
             if (await canLaunchUrl(Uri.parse(googleUrl))) await launchUrl(Uri.parse(googleUrl));
          }, isLink: true
        ),
        const SizedBox(height: 16),
        _buildRow(Icons.people, spotsColor, spotsText, l10n.lblTotalCapacity(activity.maxAttendees)), // "Capacidad total: X"
      ],
    );
  }

  Widget _buildRow(IconData icon, Color color, String title, String subtitle, {VoidCallback? onTap, bool isLink = false}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ])),
          if (isLink) IconButton(icon: Icon(Icons.open_in_new, color: color, size: 20), onPressed: onTap),
        ],
      ),
    );
  }
}

// --- SECCIÓN DE PARTICIPANTES ---
class ParticipantsSection extends StatelessWidget {
  final String activityId;
  const ParticipantsSection({super.key, required this.activityId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dataService = Provider.of<DataService>(context, listen: false);
    
    return StreamBuilder<QuerySnapshot>(
      stream: dataService.getActivityApplications(activityId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final acceptedDocs = snapshot.data?.docs.where((doc) => doc['status'] == 'accepted').toList() ?? [];

        if (acceptedDocs.isEmpty) {
          return Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(l10n.msgNoParticipants, style: const TextStyle(color: Colors.grey))), // "Aún nadie se ha unido..."
          );
        }

        return SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: acceptedDocs.length,
            itemBuilder: (context, index) {
              final data = acceptedDocs[index].data() as Map<String, dynamic>;
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(uid: data['applicantUid']))),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: data['applicantProfilePictureUrl'] != null && data['applicantProfilePictureUrl'].isNotEmpty 
                            ? NetworkImage(data['applicantProfilePictureUrl']) 
                            : null,
                        child: (data['applicantProfilePictureUrl'] ?? '').isEmpty ? const Icon(Icons.person) : null,
                      ),
                      const SizedBox(height: 4),
                      Text((data['applicantName'] ?? '').split(' ')[0], style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis)
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// --- BOTONERA INFERIOR (JOIN / CHAT / MANAGE) ---
class ActivityActionSheet extends StatelessWidget {
  final Activity activity;
  final bool isHost;
  final bool isJoining;
  final VoidCallback onJoinPressed;

  const ActivityActionSheet({
    super.key,
    required this.activity,
    required this.isHost,
    required this.isJoining,
    required this.onJoinPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = Provider.of<AuthService>(context).currentUser;
    final dataService = Provider.of<DataService>(context, listen: false);
    final spotsLeft = activity.maxAttendees - activity.acceptedCount;
    final isFull = spotsLeft <= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: dataService.getActivityApplications(activity.id),
          builder: (context, snapshot) {
            String? status;
            if (snapshot.hasData && currentUser != null) {
              try {
                final myDoc = snapshot.data!.docs.firstWhere((doc) => doc['applicantUid'] == currentUser.uid);
                status = myDoc['status'];
              } catch (_) {}
            }

            if (isHost) {
               return Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   _buildButton(l10n.btnGoToChat, Colors.white, const Color(0xFF00BCD4), () => 
                     Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(activity: activity))),
                     outline: true
                   ),
                   const SizedBox(height: 12),
                   _buildButton(l10n.btnManageRequests, const Color(0xFF00BCD4), Colors.white, () =>
                     Navigator.push(context, MaterialPageRoute(builder: (_) => ManageRequestsScreen(activityId: activity.id, activityTitle: activity.title))),
                     icon: Icons.people
                   ),
                 ],
               );
            }

            if (status == 'accepted') {
              return _buildButton(l10n.btnYouAreIn, Colors.green, Colors.white, () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(activity: activity))),
                icon: Icons.chat
              );
            }

            if (status == 'pending') {
              return _buildButton(l10n.btnRequestPending, Colors.grey, Colors.white, null);
            }

            return SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFull ? Colors.grey : const Color(0xFF00BCD4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isFull ? null : (isJoining ? null : onJoinPressed),
                child: isJoining
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isFull ? l10n.btnSoldOut : l10n.btnRequestJoin, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildButton(String text, Color bg, Color fg, VoidCallback? onTap, {IconData? icon, bool outline = false}) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: bg, foregroundColor: fg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: outline ? BorderSide(color: fg, width: 2) : null,
    );
    return SizedBox(
      width: double.infinity, height: 50,
      child: icon != null 
        ? ElevatedButton.icon(style: style, onPressed: onTap, icon: Icon(icon), label: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))
        : ElevatedButton(style: style, onPressed: onTap, child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
    );
  }
}