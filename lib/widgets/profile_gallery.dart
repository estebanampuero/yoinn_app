import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yoinn_app/l10n/app_localizations.dart'; // <--- IMPORTANTE

import '../models/user_model.dart';
import '../services/data_service.dart';

class ProfileGallery extends StatefulWidget {
  final UserModel user;
  final bool isMe;
  final VoidCallback onImageUploaded;

  const ProfileGallery({
    super.key,
    required this.user,
    required this.isMe,
    required this.onImageUploaded,
  });

  @override
  State<ProfileGallery> createState() => _ProfileGalleryState();
}

class _ProfileGalleryState extends State<ProfileGallery> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  
  static const Color brandColor = Color(0xFF00BCD4);

  Future<void> _pickAndUploadImage() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isUploading) return;
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      if (image != null) {
        setState(() => _isUploading = true);
        await Provider.of<DataService>(context, listen: false)
            .uploadGalleryImage(widget.user.uid, File(image.path));
        setState(() => _isUploading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.msgPhotoAdded)),
          );
          widget.onImageUploaded();
        }
      }
    } catch (e) {
      debugPrint("Error subiendo foto: $e");
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.lblGallery, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (widget.isMe && widget.user.galleryImages.length < 6)
              if (_isUploading)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: brandColor))
              else
                IconButton(
                  onPressed: _pickAndUploadImage,
                  icon: const Icon(Icons.add_a_photo, color: brandColor), 
                  tooltip: l10n.tooltipAddPhoto,
                ),
          ],
        ),
        const SizedBox(height: 10),
        
        if (widget.user.galleryImages.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(l10n.msgNoPhotos, style: const TextStyle(color: Colors.grey)),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: widget.user.galleryImages.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: widget.user.galleryImages[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              );
            },
          ),
      ],
    );
  }
}