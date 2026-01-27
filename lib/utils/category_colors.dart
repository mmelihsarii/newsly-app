import 'package:flutter/material.dart';

/// Helper class for category-based colors
class CategoryColors {
  /// Get color based on category name
  static Color getColor(String? categoryName) {
    if (categoryName == null || categoryName.isEmpty) {
      return const Color(0xFF64748B); // Slate blue - daha iyi görünüm
    }

    final name = categoryName.toLowerCase();

    // Gündem & Son Dakika - Red
    if (name.contains('gündem') || name.contains('son dakika') || name.contains('breaking')) {
      return const Color(0xFFEF4444);
    }

    // Spor - Green
    if (name.contains('spor') || name.contains('sport')) {
      return const Color(0xFF22C55E);
    }

    // Ekonomi & Finans - Orange/Amber
    if (name.contains('ekonomi') || name.contains('finans') || name.contains('economy')) {
      return const Color(0xFFF59E0B);
    }

    // Bilim & Teknoloji - Indigo/Purple
    if (name.contains('teknoloji') || name.contains('bilim') || name.contains('tech') || name.contains('science')) {
      return const Color(0xFF6366F1);
    }

    // Yabancı Kaynaklar & Dünya - Purple
    if (name.contains('yabancı') || name.contains('dünya') || name.contains('world') || name.contains('international')) {
      return const Color(0xFF8B5CF6);
    }

    // Haber Ajansları - Cyan/Sky Blue
    if (name.contains('ajans') || name.contains('agency')) {
      return const Color(0xFF0EA5E9);
    }

    // Yerel Haberler - Teal
    if (name.contains('yerel') || name.contains('local')) {
      return const Color(0xFF14B8A6);
    }

    // Magazin & Yaşam - Pink
    if (name.contains('magazin') || name.contains('yaşam') || name.contains('lifestyle') || name.contains('entertainment')) {
      return const Color(0xFFEC4899);
    }

    // Sağlık - Green variant
    if (name.contains('sağlık') || name.contains('health')) {
      return const Color(0xFF10B981);
    }

    // Kültür & Sanat - Violet
    if (name.contains('kültür') || name.contains('sanat') || name.contains('culture') || name.contains('art')) {
      return const Color(0xFF7C3AED);
    }

    // Eğitim - Blue
    if (name.contains('eğitim') || name.contains('education')) {
      return const Color(0xFF3B82F6);
    }

    // Otomotiv - Gray
    if (name.contains('otomotiv') || name.contains('auto')) {
      return const Color(0xFF6B7280);
    }

    // Default - Slate
    return const Color(0xFF64748B);
  }

  /// Get icon based on category name
  static IconData getIcon(String? categoryName) {
    if (categoryName == null || categoryName.isEmpty) {
      return Icons.public;
    }

    final name = categoryName.toLowerCase();

    if (name.contains('gündem')) return Icons.newspaper;
    if (name.contains('son dakika') || name.contains('breaking')) return Icons.flash_on;
    if (name.contains('spor')) return Icons.sports_soccer;
    if (name.contains('ekonomi') || name.contains('finans')) return Icons.trending_up;
    if (name.contains('teknoloji')) return Icons.computer;
    if (name.contains('bilim')) return Icons.science;
    if (name.contains('yabancı') || name.contains('dünya')) return Icons.language;
    if (name.contains('ajans')) return Icons.rss_feed;
    if (name.contains('yerel')) return Icons.location_city;
    if (name.contains('magazin')) return Icons.star;
    if (name.contains('yaşam')) return Icons.favorite;
    if (name.contains('sağlık')) return Icons.health_and_safety;
    if (name.contains('kültür') || name.contains('sanat')) return Icons.palette;
    if (name.contains('eğitim')) return Icons.school;
    if (name.contains('otomotiv')) return Icons.directions_car;

    return Icons.public;
  }

  /// Get a lighter version of the color (for backgrounds)
  static Color getLightColor(String? categoryName, {double opacity = 0.15}) {
    return getColor(categoryName).withOpacity(opacity);
  }

  /// Get contrasting text color (white or black based on background)
  static Color getTextColor(String? categoryName) {
    final color = getColor(categoryName);
    // Calculate luminance to determine if text should be white or black
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}
