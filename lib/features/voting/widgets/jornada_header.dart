import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:el_visionat/core/theme/app_theme.dart';

/// Reusable header that shows the jornada number and voting status.
///
/// - [jornada]: the jornada number to display.
/// - [isClosed]: if true shows "Votació tancada" with a red dot; if false shows
///   "Votació oberta" with a green dot. If null, treated as open.
/// - [closingAt]: optional DateTime when voting closes; if provided and the
///   voting is open we show it as a tooltip on the status text.
/// - [restWeek]: if true, shows a rest week banner below the header.
/// - [nextVotingDate]: date when new voting opens (shown in rest week banner).
class JornadaHeader extends StatelessWidget {
  final int jornada;
  final bool? isClosed;
  final DateTime? closingAt;
  final bool restWeek;
  final DateTime? nextVotingDate;

  const JornadaHeader({
    super.key,
    required this.jornada,
    this.isClosed,
    this.closingAt,
    this.restWeek = false,
    this.nextVotingDate,
  });

  String _formatClosing(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} • ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final closed = isClosed ?? false;
    final statusText = closed ? 'Votació tancada' : 'Votació oberta';
    final statusColor = closed ? Colors.red : Colors.green;

    final statusChild = Row(
      children: [
        Icon(Icons.circle, size: 10, color: statusColor),
        const SizedBox(width: 6),
        Text(
          statusText,
          style: GoogleFonts.montserrat(
            textStyle: const TextStyle(color: AppTheme.grisPistacho),
          ),
        ),
      ],
    );

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.porpraFosc,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jornada $jornada',
                style: GoogleFonts.montserrat(
                  textStyle: const TextStyle(
                    color: AppTheme.grisPistacho,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (closingAt != null && !closed) ...[
                Tooltip(
                  message: 'Tanca: ${_formatClosing(closingAt!)}',
                  child: statusChild,
                ),
              ] else ...[
                statusChild,
              ],
            ],
          ),
        ),
        if (restWeek) ...[
          const SizedBox(height: 8),
          _buildRestWeekBanner(),
        ],
      ],
    );
  }

  Widget _buildRestWeekBanner() {
    final nextDateText = nextVotingDate != null
        ? DateFormat("EEEE d MMMM, HH:mm'h'", 'ca_ES')
            .format(nextVotingDate!.toLocal())
        : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.mostassa.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.mostassa.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.pause_circle_outline_rounded,
            color: AppTheme.mostassa,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Setmana de descans',
                  style: GoogleFonts.montserrat(
                    textStyle: const TextStyle(
                      color: AppTheme.mostassa,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (nextDateText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Properes votacions: $nextDateText',
                    style: GoogleFonts.montserrat(
                      textStyle: TextStyle(
                        color: AppTheme.grisPistacho.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
