import 'package:flutter/material.dart';

/// Verde &lt; 7 días, rojo &gt; 60 días, escala intermedia.
Color colorForDaysSinceVisit(int? days) {
  if (days == null) return Colors.grey;
  if (days <= 7) return const Color(0xFF43A047); // verde
  if (days <= 14) return const Color(0xFF8BC34A);
  if (days <= 30) return const Color(0xFFCDDC39);
  if (days <= 45) return const Color(0xFFFFC107); // amarillo
  if (days <= 60) return const Color(0xFFFF9800); // naranja
  return const Color(0xFFE53935); // rojo 60+
}

int? daysSince(DateTime? lastVisit) {
  if (lastVisit == null) return null;
  return DateTime.now().difference(lastVisit).inDays;
}
