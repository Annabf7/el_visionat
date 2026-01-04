import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../models/profile_model.dart';

/// Widget que mostra l'empremta de l'usuari al Visionat
/// Inclou partits analitzats, apunts creats i clips compartits
class ProfileFootprintWidget extends StatelessWidget {
  /// Model de perfil amb les dades reals
  final ProfileModel profile;

  const ProfileFootprintWidget({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Títol principal
        Align(
          alignment: isDesktop ? Alignment.centerRight : Alignment.centerLeft,
          child: const Text(
            'La teva Empremta',
            style: TextStyle(
              fontFamily: 'Geist',
              color: AppTheme.textBlackLow,
              fontWeight: FontWeight.w600,
              fontSize: 18,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Taula d'estadístiques
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildFootprintItem(
                'Partits analitzats',
                profile.analyzedMatches.toString(),
                isFirst: true,
                itemIndex: 0,
              ),
              _buildFootprintItem(
                'Apunts personals creats',
                profile.personalNotesCount.toString(),
                itemIndex: 1,
              ),
              _buildFootprintItem(
                'Clips compartits',
                profile.sharedClipsCount.toString(),
                subtitle: profile.communityAccessDescription,
                isLast: true,
                itemIndex: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construeix cada fila de la taula d'estadístiques
  Widget _buildFootprintItem(
    String title,
    String value, {
    bool isFirst = false,
    bool isLast = false,
    required int itemIndex,
    String? subtitle,
  }) {
    // Alternar entre dos tons de gris
    final backgroundColor = itemIndex % 2 == 0
        ? AppTheme.grisPistacho.withValues(alpha: 0.4) // Més fosc
        : AppTheme.grisPistacho.withValues(alpha: 0.2); // Més clar

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        // Només la primera fila té stroke mostassa superior
        border: isFirst
            ? const Border(top: BorderSide(color: AppTheme.mostassa, width: 2))
            : null,
        borderRadius: isFirst
            ? const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              )
            : isLast
                ? const BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  )
                : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Títol i subtítol
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppTheme.textBlackLow,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppTheme.textBlackLow.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Valor
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppTheme.textBlackLow,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
