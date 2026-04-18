import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class OptimizedImageService {
  // Load profile image with optimization
  static Widget buildProfileImage({
    required String? imageUrl,
    required double radius,
    required IconData fallbackIcon,
    required double fallbackIconSize,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Icon(fallbackIcon, size: fallbackIconSize);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      memCacheHeight: (radius * 2 * 2).toInt(), // 2x for high DPI
      memCacheWidth: (radius * 2 * 2).toInt(),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 300),
      imageBuilder: (context, imageProvider) =>
          CircleAvatar(radius: radius, backgroundImage: imageProvider),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        child: Icon(
          fallbackIcon,
          color: Colors.grey,
          size: fallbackIconSize / 2,
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        child: Icon(fallbackIcon, color: Colors.grey, size: fallbackIconSize),
      ),
    );
  }

  // Load list item image with optimization
  static Widget buildListImage({
    required String? imageUrl,
    required double radius,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Icon(Icons.person, size: radius * 2 * 0.75);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      memCacheHeight: (radius * 2 * 2).toInt(),
      memCacheWidth: (radius * 2 * 2).toInt(),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 300),
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
        ),
      ),
      placeholder: (context, url) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade200,
        ),
        child: const Center(child: Icon(Icons.person, color: Colors.grey)),
      ),
      errorWidget: (context, url, error) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade200,
        ),
        child: const Icon(Icons.person, color: Colors.grey),
      ),
    );
  }
}
