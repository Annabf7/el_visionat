import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../models/profile_model.dart';

/// Widget que mostra els badges/assoliments de l'usuari basats en dades reals
class BadgesWidget extends StatelessWidget {
  final ProfileModel profile;

  const BadgesWidget({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBadgeCard(
          '${profile.analyzedMatches} VISIONATS',
          _getVisionatsMessage(profile.analyzedMatches),
          AppTheme.mostassa,
          'V',
        ),
        const SizedBox(height: 12),
        _buildBadgeCard(
          '${profile.personalNotesCount} APUNTS PERSONALS',
          _getApuntsMessage(profile.personalNotesCount),
          AppTheme.lilaMitja,
          '✏',
        ),
        const SizedBox(height: 12),
        _buildBadgeCard(
          '${profile.sharedClipsCount} CLIPS COMPARTITS',
          _getClipsMessage(profile.sharedClipsCount),
          Colors.orange,
          '🔥',
        ),
      ],
    );
  }

  /// Genera un missatge dinàmic segons el nombre de visionats
  String _getVisionatsMessage(int count) {
    if (count == 0) return 'Comença a analitzar partits!';
    if (count < 5) return 'Bon inici! Continua així.';
    if (count < 10) return 'Bona feina! Estàs agafant ritme.';
    if (count < 20) return 'Primer objectiu assolit. Bona constància.';
    if (count < 50) return 'Excel·lent dedicació a l\'anàlisi.';
    return 'Expert en anàlisi de partits!';
  }

  /// Genera un missatge dinàmic segons el nombre d'apunts personals
  String _getApuntsMessage(int count) {
    if (count == 0) return 'Crea el teu primer apunt!';
    if (count < 10) return 'Bon començament amb els apunts.';
    if (count < 25) return 'Estàs construint una bona base.';
    if (count < 50) return 'Gran dedicació al detall!';
    if (count < 100) return 'La teva dedicació és extraordinària.';
    return 'Mestre de l\'aprenentatge continu!';
  }

  /// Genera un missatge dinàmic segons el nombre de clips compartits
  String _getClipsMessage(int count) {
    if (count == 0) return 'Comparteix el teu primer clip!';
    if (count < 3) return 'Bon inici compartint coneixement.';
    if (count < 6) return 'Estàs contribuint a la comunitat!';
    if (count < 12) return 'Excel·lent compromís i esforç.';
    return 'Referent de la comunitat!';
  }

  Widget _buildBadgeCard(
    String title,
    String description,
    Color color,
    String icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(
                  color: AppTheme.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.grisBody,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
