import 'package:flutter/material.dart';

class WebLearningResource {
  const WebLearningResource({
    required this.id,
    required this.title,
    required this.tagline,
    required this.description,
    required this.url,
    required this.lessonSummary,
    required this.icon,
    required this.accent,
    required this.about,
    this.is3D = false,
  });

  final String id;
  final String title;
  final String tagline;
  final String description;
  final String url;
  final String lessonSummary;
  final IconData icon;
  final Color accent;
  final String about;
  final bool is3D;
}
