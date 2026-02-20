import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

class LaboratoriSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? textColor;

  const LaboratoriSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.onTap,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppTheme.porpraFosc;
    final contentColor = textColor ?? Colors.white;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardColor, cardColor.withValues(alpha: 0.88)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Capçalera: icona + badge
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: contentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: contentColor, size: 22),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: contentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: contentColor.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Títol
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: contentColor,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Subtítol
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      color: contentColor.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Separador + fletxa
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: contentColor.withValues(alpha: 0.12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: contentColor.withValues(alpha: 0.55),
                        size: 13,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
