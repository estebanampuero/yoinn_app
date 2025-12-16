import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      Provider.of<DataService>(context, listen: false)
          .sendMessage(widget.activity.id, text, user);
      _messageController.clear();
      // Scroll al fondo
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0, 
          duration: const Duration(milliseconds: 300), 
          curve: Curves.easeOut
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserUid = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    final dataService = Provider.of<DataService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFEFE7DD), // Color fondo tipo WhatsApp suave
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(widget.activity.imageUrl),
              radius: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.activity.title, style: const TextStyle(fontSize: 16)),
                  const Text("Chat de grupo", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: dataService.getActivityMessages(widget.activity.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['senderUid'] == currentUserUid;
                    
                    return _ChatBubble(
                      text: data['text'] ?? '',
                      senderName: data['senderName'] ?? 'Usuario',
                      senderPic: data['senderProfilePictureUrl'],
                      timestamp: data['timestamp'],
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: "Mensaje...",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xFFF97316),
              radius: 22,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final String senderName;
  final String? senderPic;
  final Timestamp? timestamp;
  final bool isMe;

  const _ChatBubble({required this.text, required this.senderName, this.senderPic, this.timestamp, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final timeStr = timestamp != null ? DateFormat('HH:mm').format(timestamp!.toDate()) : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) 
            CircleAvatar(
              radius: 14,
              backgroundImage: senderPic != null ? NetworkImage(senderPic!) : null,
              child: senderPic == null ? const Icon(Icons.person, size: 12) : null,
            ),
          if (!isMe) const SizedBox(width: 8),
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFF97316) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(senderName, style: TextStyle(color: Colors.orange[800], fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(timeStr, style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 10)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}