import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../designations/models/designation_model.dart';

/// Targeta que mostra la informació d'un partit de l'historial
class MatchHistoryCard extends StatelessWidget {
  final DesignationModel designation;
  final VoidCallback onTap;

  const MatchHistoryCard({
    super.key,
    required this.designation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.grisBody.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Data
            Container(
              width: 60,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.lilaMitja.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('dd').format(designation.date),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lilaMitja,
                    ),
                  ),
                  Text(
                    DateFormat('MMM', 'ca').format(designation.date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lilaMitja.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Detalls del partit
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Equips
                  Text(
                    '${designation.localTeam} vs ${designation.visitantTeam}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.grisPistacho,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Partit número i hora
                  Row(
                    children: [
                      const Icon(
                        Icons.sports_basketball,
                        size: 14,
                        color: AppTheme.grisPistacho,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Partit #${designation.matchNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.grisPistacho,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('HH:mm').format(designation.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),

                  // Notes si n'hi ha
                  if (designation.notes != null && designation.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.note,
                          size: 14,
                          color: AppTheme.lilaMitja,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            designation.notes!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.grisPistacho.withValues(alpha: 0.6),
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Icona de fletxa
            const Icon(
              Icons.chevron_right,
              color: AppTheme.grisPistacho,
            ),
          ],
        ),
      ),
    );
  }
}