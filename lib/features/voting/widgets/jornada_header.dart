import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

/// Reusable header that shows the jornada number and voting status.
///
/// - [jornada]: the jornada number to display.
/// - [isClosed]: if true shows "Votació tancada" with a red dot; if false shows
///   "Votació oberta" with a green dot. If null, treated as open.
/// - [closingAt]: optional DateTime when voting closes; if provided and the
///   voting is open we show it as a tooltip on the status text.
class JornadaHeader extends StatelessWidget {
  final int jornada;
  final bool? isClosed;
  final DateTime? closingAt;

  const JornadaHeader({
    super.key,
    required this.jornada,
    this.isClosed,
    this.closingAt,
  });

  String _formatClosing(DateTime dt) {
    // Keep it simple and locale-neutral for now; the app uses 'ca_ES' elsewhere.
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

    return Container(
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
    );
  }
}
