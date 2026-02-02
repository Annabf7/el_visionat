import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

/// Secció hero amb gradient per a la capçalera de "El Vestidor"
class VestidorHero extends StatelessWidget {
  final int totalProducts;

  const VestidorHero({super.key, required this.totalProducts});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.porpraFosc,
            AppTheme.porpraFosc.withValues(alpha: 0.85),
            AppTheme.lilaMitja.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.porpraFosc.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icona + badge productes
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.mostassa.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.checkroom_rounded,
                  color: AppTheme.mostassa,
                  size: 28,
                ),
              ),
              const Spacer(),
              if (totalProducts > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.mostassa.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.mostassa.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '$totalProducts productes',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mostassa,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Títol
          const Text(
            'El Vestidor',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.grisPistacho,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Equipament oficial per a l\'equip arbitral',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppTheme.grisPistacho.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
