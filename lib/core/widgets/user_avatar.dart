import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Profile photo from a URL or local file path, falling back to initials.
/// Circular by default; pass [cornerRadius] for a rounded square.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.cornerRadius,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final double? cornerRadius;

  ImageProvider? get _image {
    final url = imageUrl;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return NetworkImage(url);
    return FileImage(File(url));
  }

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    final initials = Center(
      child: Text(
        _initials,
        style: TextStyle(
          color: AppColors.tealDark,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );

    final content = ColoredBox(
      color: AppColors.mint,
      child: image == null
          ? initials
          : Image(
              image: image,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => initials,
            ),
    );

    return SizedBox.square(
      dimension: size,
      child: cornerRadius == null
          ? ClipOval(child: content)
          : ClipRRect(
              borderRadius: BorderRadius.circular(cornerRadius!),
              child: content,
            ),
    );
  }
}
