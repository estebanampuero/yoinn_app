import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:yoinn_app/l10n/app_localizations.dart';

import '../models/activity_model.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';

import 'edit_activity_screen.dart';
import 'chat_screen.dart';
import 'manage_requests_screen.dart';

import '../widgets/activity_detail_components.dart';
import '../widgets/activity_limit_paywall.dart';

class ActivityDetailScreen extends StatefulWidget {
  final Activity activity;
  const ActivityDetailScreen({super.key, required this.activity});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  bool _isJoining = false;

  // COLORES AESTHETIC PRO
  final Color _brandColor = const Color(0xFF00BCD4);
  final Color _bgScreenColor = const Color(0xFFF0F8FA);

  // Helper para traducir la categoría visualmente
  String _getCategoryName(String key) {
    final l10n = AppLocalizations.of(context)!;
    if (key == 'Todas') return l10n.catAll;
    if (key == 'Deporte') return l10n.catSport;
    if (key == 'Comida') return l10n.catFood;
    if (key == 'Arte') return l10n.catArt;
    if (key == 'Fiesta') return l10n.catParty;
    if (key == 'Viaje') return l10n.catOutdoor; 
    if (key == 'Musica') return l10n.hobbyMusic;
    if (key == 'Tecnología') return l10n.hobbyTech;
    if (key == 'Bienestar') return l10n.hobbyWellness;
    return l10n.catOther;
  }

  void _confirmAndJoin() async {
    final l10n = AppLocalizations.of(context)!;
    final dataService = Provider.of<DataService>(context, listen: false);
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    if (user == null) return;

    int remaining = await dataService.getRemainingFreeJoins(user.uid);

    if (remaining == -1) {
      _joinActivity();
      return;
    }

    if (remaining == 0) {
      if (mounted) _showPaywall(context);
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.dialogUseTicketTitle,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.dialogUseTicketBody),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.confirmation_number, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(l10n.dialogTicketsRemaining(remaining - 1),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.btnCancel, style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                Navigator.pop(ctx);
                _joinActivity();
              },
              child: Text(l10n.btnUseTicket,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  void _joinActivity() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isJoining = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final dataService = Provider.of<DataService>(context, listen: false);
    final user = authService.currentUser;

    bool isPremium = user?.isPremium ?? false;
    if (!isPremium) {
      isPremium = await SubscriptionService.isUserPremium();
    }

    await FirebaseAnalytics.instance.logEvent(
      name: 'join_activity_request',
      parameters: {
        'category': widget.activity.category,
        'is_premium': isPremium.toString(),
        'activity_id': widget.activity.id,
      },
    );

    if (user != null) {
      try {
        final userModel = await dataService.getUserProfile(user.uid);
        if (userModel != null) {
          await dataService.applyToActivity(widget.activity.id, userModel);
          await FirebaseAnalytics.instance
              .logEvent(name: 'join_activity_success');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(l10n.msgRequestSent),
                  backgroundColor: Colors.green),
            );
          }
        }
      } catch (e) {
        if (e.toString().contains("Ticket") ||
            e.toString().contains("Límite") ||
            e.toString().contains("Limit")) {
          if (mounted) {
            await FirebaseAnalytics.instance.logEvent(
                name: 'paywall_shown',
                parameters: {'source': 'activity_limit'});
            _showPaywall(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      "${l10n.errorGeneric}: ${e.toString().replaceAll('Exception:', '')}")),
            );
          }
        }
      }
    }

    if (mounted) setState(() => _isJoining = false);
  }

  void _showPaywall(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final package = await SubscriptionService.getCurrentOffering();
    if (package != null && mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => ActivityLimitPaywall(package: package),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.msgGoPro)));
      }
    }
  }

  void _mostrarConfirmacionEliminar() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.dialogDeleteTitle),
          content: Text(l10n.dialogDeleteBody),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.btnCancel,
                    style: const TextStyle(color: Colors.grey))),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _eliminarActividad();
              },
              child: Text(l10n.btnDelete,
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _eliminarActividad() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await Provider.of<DataService>(context, listen: false)
          .deleteActivity(widget.activity.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.msgActivityDeleted)));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${l10n.errorGeneric}: $e")));
    }
  }

  void _compartirActividad() {
    final l10n = AppLocalizations.of(context)!;
    final String deepLink = 'https://yoinn.app/activity/${widget.activity.id}';
    final dateFormatted = DateFormat('EEEE d, h:mm a',
            Localizations.localeOf(context).toString())
        .format(widget.activity.dateTime);

    final String mensaje = '''
${l10n.shareMessageIntro}

"${widget.activity.title}"
📅 $dateFormatted
📍 ${widget.activity.location}

${l10n.shareMessageCta}
$deepLink
''';
    Share.share(mensaje);
    FirebaseAnalytics.instance.logEvent(
        name: 'share_activity', parameters: {'activity_id': widget.activity.id});
  }

  void _showOptions(bool isHost) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.share, color: Colors.blue),
                ),
                title: Text(l10n.optShare,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _compartirActividad();
                },
              ),
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(height: 1)),
              if (isHost) ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.edit, color: Colors.blueGrey),
                  ),
                  title: Text(l10n.optEdit,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EditActivityScreen(
                                activity: widget.activity)));
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10)),
                    child:
                        const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: Text(l10n.optDelete,
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _mostrarConfirmacionEliminar();
                  },
                ),
              ] else ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.flag, color: Colors.orange),
                  ),
                  title: Text(l10n.optReport,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showReportDialog();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.block, color: Colors.grey),
                  ),
                  title: Text(l10n.optBlock,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showBlockDialog();
                  },
                ),
              ],
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.dialogReportTitle),
        content: Text(l10n.dialogReportBody),
        actions: [
          TextButton(
            child: Text(l10n.reasonSpam),
            onPressed: () => _submitReport(ctx, "Spam"),
          ),
          TextButton(
            child: Text(l10n.reasonOffensive),
            onPressed: () => _submitReport(ctx, "Ofensivo/Inapropiado"),
          ),
          TextButton(
              child: Text(l10n.btnCancel, style: const TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.pop(ctx)),
        ],
      ),
    );
  }

  Future<void> _submitReport(BuildContext ctx, String reason) async {
    final l10n = AppLocalizations.of(context)!;
    Navigator.pop(ctx);
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'activityId': widget.activity.id,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'reportedBy': Provider.of<AuthService>(context, listen: false).currentUser?.uid ?? 'anon',
        'type': 'activity_report'
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.msgReportThanks),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.msgReportError)));
      }
    }
  }

  void _showBlockDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.dialogBlockTitle),
        content: Text(l10n.dialogBlockBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.btnCancel,
                  style: const TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(l10n.msgUserBlocked)));
            },
            child: Text(l10n.btnBlock, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = Provider.of<AuthService>(context).currentUser;
    final isHost = user?.uid == widget.activity.hostUid;

    return Scaffold(
      backgroundColor: _bgScreenColor,
      body: CustomScrollView(
        slivers: [
          ActivitySliverAppBar(
            activity: widget.activity,
            isHost: isHost,
            onShare: _compartirActividad,
            onOptions: () => _showOptions(isHost),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- CABECERA (BADGE TRADUCIDO + TÍTULO) ---
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: _brandColor.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                              color: _brandColor.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ]),
                    // USA EL HELPER PARA TRADUCIR
                    child: Text(_getCategoryName(widget.activity.category).toUpperCase(),
                        style: TextStyle(
                            color: _brandColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.0)),
                  ),
                  const SizedBox(height: 16),
                  Text(widget.activity.title,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          height: 1.2)),

                  const SizedBox(height: 24),
                  Container(height: 1, color: Colors.grey.shade200),
                  const SizedBox(height: 24),

                  // 1. DESCRIPCIÓN
                  Text(widget.activity.description,
                      style: TextStyle(
                          fontSize: 16, color: Colors.grey[700], height: 1.6)),

                  const SizedBox(height: 32),

                  // 2. INFORMACIÓN (Fecha y Ubicación)
                  ActivityInfoRow(activity: widget.activity),

                  const SizedBox(height: 32),

                  // 3. ASISTENTES CONFIRMADOS
                  Text(l10n.lblConfirmedAttendees,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ParticipantsSection(activityId: widget.activity.id),

                  const SizedBox(height: 32),

                  // 4. ORGANIZADOR (Traducido)
                  Text(l10n.lblOrganizer,
                      style:
                          const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  HostInfoTile(hostUid: widget.activity.hostUid),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -5))
          ],
        ),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: Provider.of<DataService>(context, listen: false)
                .getActivityApplications(widget.activity.id),
            builder: (context, snapshot) {
              String? status;
              if (snapshot.hasData && user != null) {
                try {
                  final myDoc = snapshot.data!.docs
                      .firstWhere((doc) => doc['applicantUid'] == user.uid);
                  status = myDoc['status'];
                } catch (_) {}
              }

              // --- BOTONES DE ACCIÓN ---
              if (isHost) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _brandColor,
                          side: BorderSide(color: _brandColor, width: 2),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ChatScreen(activity: widget.activity)));
                        },
                        child: Text(l10n.btnGoToChat,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _brandColor,
                            elevation: 4,
                            shadowColor: _brandColor.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16))),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ManageRequestsScreen(
                                      activityId: widget.activity.id,
                                      activityTitle: widget.activity.title)));
                        },
                        icon: const Icon(Icons.people, color: Colors.white),
                        label: Text(l10n.btnManageRequests,
                            style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                );
              }

              if (status == 'accepted') {
                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        elevation: 4,
                        shadowColor: Colors.green.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ChatScreen(activity: widget.activity)));
                    },
                    icon: const Icon(Icons.chat_bubble_outline,
                        color: Colors.white),
                    label: Text(l10n.btnYouAreIn,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                );
              }

              if (status == 'pending') {
                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    onPressed: null,
                    child: Text(l10n.btnRequestPending,
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold)),
                  ),
                );
              }

              final spotsLeft =
                  widget.activity.maxAttendees - widget.activity.acceptedCount;
              final isFull = spotsLeft <= 0;

              return SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFull ? Colors.grey : _brandColor,
                    elevation: isFull ? 0 : 4,
                    shadowColor: _brandColor.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed:
                      isFull ? null : (_isJoining ? null : _confirmAndJoin),
                  child: _isJoining
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(isFull ? l10n.btnSoldOut : l10n.btnRequestJoin,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}