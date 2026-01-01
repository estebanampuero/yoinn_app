import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yoinn_app/l10n/app_localizations.dart'; // <--- IMPORTANTE

import '../models/activity_model.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';

class ChatScreen extends StatefulWidget {
  final Activity activity;
  const ChatScreen({super.key, required this.activity});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTypingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsRead();
    });
  }

  void _markAsRead() {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      Provider.of<DataService>(context, listen: false)
          .markMessagesAsRead(widget.activity.id, user.uid);
    }
  }

  void _onTextChanged(String text) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return;
    final dataService = Provider.of<DataService>(context, listen: false);

    if (_debounceTypingTimer?.isActive ?? false) _debounceTypingTimer!.cancel();

    dataService.setTypingStatus(widget.activity.id, user.uid, true);

    _debounceTypingTimer = Timer(const Duration(seconds: 2), () {
      dataService.setTypingStatus(widget.activity.id, user.uid, false);
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      final dataService = Provider.of<DataService>(context, listen: false);
      
      dataService.sendMessage(widget.activity.id, text, user);
      dataService.setTypingStatus(widget.activity.id, user.uid, false);
      
      _messageController.clear();
      
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    }
  }

  void _toggleLike(String messageId, bool isLiked) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      Provider.of<DataService>(context, listen: false).toggleMessageLike(
        widget.activity.id, 
        messageId, 
        user.uid, 
        isLiked
      );
    }
  }

  @override
  void dispose() {
    _debounceTypingTimer?.cancel();
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      Provider.of<DataService>(context, listen: false).setTypingStatus(widget.activity.id, user.uid, false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserUid = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    final dataService = Provider.of<DataService>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
              child: CircleAvatar(backgroundImage: CachedNetworkImageProvider(widget.activity.imageUrl), radius: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.activity.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis),
                  Text(l10n.activityGroup, style: const TextStyle(fontSize: 12, color: Color(0xFF00BCD4), fontWeight: FontWeight.w500)), // "Actividad Grupal"
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: Colors.grey.shade100, height: 1)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: dataService.getActivityMessages(widget.activity.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)));
                final docs = snapshot.data!.docs;

                if (docs.isNotEmpty) _markAsRead();

                if (docs.isEmpty) return _buildEmptyState(context);

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final messageId = docs[index].id;
                    final isMe = data['senderUid'] == currentUserUid;
                    
                    final bool isLastInSequence = (index == 0) || ((index - 1 >= 0) && (docs[index - 1]['senderUid'] != data['senderUid']));
                    final bool isFirstInSequence = (index == docs.length - 1) || ((index + 1 < docs.length) && (docs[index + 1]['senderUid'] != data['senderUid']));

                    final readBy = List.from(data['readBy'] ?? []);
                    final isRead = readBy.length > 1;

                    final likedBy = List.from(data['likedBy'] ?? []);
                    final bool isLikedByMe = likedBy.contains(currentUserUid);
                    final bool hasLikes = likedBy.isNotEmpty;

                    return _ChatBubble(
                      messageId: messageId,
                      text: data['text'] ?? '',
                      senderName: data['senderName'] ?? 'Usuario',
                      senderPic: data['senderProfilePictureUrl'],
                      timestamp: data['timestamp'],
                      isMe: isMe,
                      isFirstInGroup: isFirstInSequence,
                      isLastInGroup: isLastInSequence,
                      isRead: isRead,
                      isLikedByMe: isLikedByMe,
                      hasLikes: hasLikes,
                      onDoubleTap: () => _toggleLike(messageId, isLikedByMe),
                    );
                  },
                );
              },
            ),
          ),
          
          StreamBuilder<QuerySnapshot>(
            stream: dataService.getTypingStatus(widget.activity.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
              final typingUsers = snapshot.data!.docs.where((doc) => doc.id != currentUserUid).toList();
              if (typingUsers.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 5),
                child: Row(
                  children: [
                    const _TypingDots(),
                    const SizedBox(width: 8),
                    Text(
                      typingUsers.length == 1 ? l10n.lblTypingSingle : l10n.lblTypingMultiple,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              );
            },
          ),

          _buildInputArea(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFFE0F7FA).withOpacity(0.5), shape: BoxShape.circle),
            child: const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: Color(0xFF00BCD4)),
          ),
          const SizedBox(height: 16),
          Text(l10n.msgEmptyChatTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 8),
          Text(l10n.msgEmptyChatBody, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 10)]),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      child: Row(
        children: [
          InkWell(
            onTap: () {}, 
            child: const Padding(padding: EdgeInsets.only(right: 12.0), child: Icon(Icons.add_circle_outline, color: Color(0xFF00BCD4), size: 28)),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(24)),
              child: TextField(
                controller: _messageController,
                onChanged: _onTextChanged,
                decoration: InputDecoration(
                  hintText: l10n.chatPlaceholder, // "Escribe un mensaje..."
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  isDense: true,
                ),
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 4,
                cursorColor: const Color(0xFF00BCD4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Text(l10n.sendButton, style: const TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold, fontSize: 16)), // "Enviar"
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return FadeTransition(
            opacity: DelayTween(begin: 0.0, end: 1.0, delay: index * 0.2).animate(_controller),
            child: const CircleAvatar(radius: 3, backgroundColor: Color(0xFF00BCD4)),
          );
        }),
      ),
    );
  }
}

class DelayTween extends Tween<double> {
  final double delay;
  DelayTween({super.begin, super.end, required this.delay});
  @override
  double lerp(double t) => super.lerp((0.5 * (1.0 + ((t - delay) / (t - delay).abs()))).clamp(0.0, 1.0));
}

class _ChatBubble extends StatelessWidget {
  final String messageId;
  final String text;
  final String senderName;
  final String? senderPic;
  final Timestamp? timestamp;
  final bool isMe;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool isRead;
  final bool isLikedByMe;
  final bool hasLikes;
  final VoidCallback onDoubleTap;

  const _ChatBubble({
    required this.messageId,
    required this.text, 
    required this.senderName, 
    this.senderPic, 
    this.timestamp, 
    required this.isMe,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.isRead,
    required this.isLikedByMe,
    required this.hasLikes,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = timestamp != null ? DateFormat('HH:mm').format(timestamp!.toDate()) : '';

    return GestureDetector(
      onDoubleTap: onDoubleTap,
      child: Padding(
        padding: EdgeInsets.only(bottom: isLastInGroup ? 12 : 2),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe && isFirstInGroup)
              Padding(
                padding: const EdgeInsets.only(left: 44, bottom: 4),
                child: Text(senderName, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              ),
      
            Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe) 
                  SizedBox(
                    width: 32,
                    child: isLastInGroup 
                        ? CircleAvatar(
                            radius: 14,
                            backgroundImage: senderPic != null ? NetworkImage(senderPic!) : null,
                            backgroundColor: Colors.grey[200],
                            child: senderPic == null ? const Icon(Icons.person, size: 14, color: Colors.grey) : null,
                          )
                        : null,
                  ),
                
                if (!isMe) const SizedBox(width: 8),
                
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isMe 
                            ? const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF0097A7)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                            : null,
                        color: isMe ? null : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: !isMe && !isLastInGroup ? const Radius.circular(4) : const Radius.circular(20),
                          bottomRight: isMe && !isLastInGroup ? const Radius.circular(4) : const Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16, height: 1.3)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(timeStr, style: TextStyle(fontSize: 10, color: isMe ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.4))),
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  isRead ? Icons.done_all : Icons.check, 
                                  size: 14,
                                  color: isRead 
                                      ? const Color.fromARGB(255, 179, 237, 255) 
                                      : Colors.white.withOpacity(0.7), 
                                )
                              ]
                            ],
                          )
                        ],
                      ),
                    ),
                    
                    if (hasLikes)
                      Positioned(
                        bottom: -6,
                        right: isMe ? null : -6,
                        left: isMe ? -6 : null,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2)],
                          ),
                          child: const Icon(Icons.favorite, color: Colors.red, size: 14),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}