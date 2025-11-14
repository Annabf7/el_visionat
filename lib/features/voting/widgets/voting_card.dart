import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

typedef VoteCallback = void Function();

class VotingCard extends StatelessWidget {
  final String homeName;
  final String homeLogo;
  final String awayName;
  final String awayLogo;
  final String dateTimeIso;
  final VoteCallback? onVote;
  // optional identifiers to allow caller to indicate vote state
  final String? matchId;
  final int? jornada;
  final bool isVoted;
  final bool isDisabled;
  final bool isLoading;
  final int? voteCount;

  const VotingCard({
    super.key,
    required this.homeName,
    required this.homeLogo,
    required this.awayName,
    required this.awayLogo,
    required this.dateTimeIso,
    this.onVote,
    this.matchId,
    this.jornada,
    this.isVoted = false,
    this.isDisabled = false,
    this.isLoading = false,
    this.voteCount,
  });

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      elevation: 6,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.porpraFosc.withAlpha(250), // strong base
              AppTheme.lilaMitja.withAlpha(120), // more presence
              AppTheme.grisBody.withAlpha(220),
            ],
            stops: const [0.0, 0.55, 1.0],
            tileMode: TileMode.clamp,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(89),
              offset: const Offset(0, 6),
              blurRadius: 14,
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                // Responsive logo sizes tuned for small phones (API 35) and larger
                double logoSize = 72; // base for very small phones
                if (w >= 800) {
                  logoSize = 120;
                } else if (w >= 420) {
                  logoSize = 96;
                } else if (w >= 360) {
                  logoSize = 80;
                }
                final compact = w < 420;
                // Responsive gap between the two logos. Compute from available width
                // so the spacing increases a bit on wider (but still compact) screens.
                // We clamp to a sensible range to avoid extreme gaps on odd widths.
                final double logoGap = ((w * 0.32).clamp(
                  126.0,
                  160.0,
                )).toDouble();

                Widget logoWidget(String name, String logo) {
                  final asset = logo.isNotEmpty
                      ? 'assets/images/teams/$logo'
                      : '';
                  if (asset.isNotEmpty) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image(
                        image: ResizeImage(
                          AssetImage(asset),
                          width: logoSize.round(),
                        ),
                        width: logoSize,
                        height: logoSize,
                        fit: BoxFit.contain,
                        semanticLabel: name,
                        errorBuilder: (c, e, s) => CircleAvatar(
                          radius: logoSize / 2,
                          backgroundColor: Colors.grey[700],
                          child: Text(
                            _initials(name),
                            style: GoogleFonts.montserrat(
                              textStyle: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return CircleAvatar(
                    radius: logoSize / 2,
                    backgroundColor: Colors.grey[700],
                    child: Text(
                      _initials(name),
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }

                Widget teamBlock(
                  String name,
                  String logo, {
                  bool right = false,
                  bool showName = true,
                }) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: right
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      logoWidget(name, logo),
                      if (showName) ...[
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: GoogleFonts.montserrat(
                              textStyle: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                }

                // Prepare date/time parts: expect format like 'dd/MM/yyyy • HH:mm'
                final parts = dateTimeIso.contains('•')
                    ? dateTimeIso.split('•').map((s) => s.trim()).toList()
                    : [dateTimeIso];

                if (compact) {
                  return Column(
                    children: [
                      // Logos with centered 'vs' overlay — keeps 'vs' centered even with large spacing
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              logoWidget(homeName, homeLogo),
                              SizedBox(width: logoGap),
                              logoWidget(awayName, awayLogo),
                            ],
                          ),
                          Center(
                            child: Text(
                              'vs',
                              style: GoogleFonts.montserrat(
                                textStyle: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Date and time stacked vertically for better readability on small screens
                      Center(
                        child: Column(
                          children: [
                            Text(
                              parts[0],
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (parts.length > 1) ...[
                              const SizedBox(height: 2),
                              Text(
                                parts[1],
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: teamBlock(homeName, homeLogo)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            'vs',
                            style: GoogleFonts.montserrat(
                              textStyle: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: teamBlock(awayName, awayLogo, right: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            parts[0],
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (parts.length > 1) ...[
                            const SizedBox(height: 4),
                            Text(
                              parts[1],
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),

            Align(
              alignment: Alignment.center,
              child: FilledButton.icon(
                onPressed: (isDisabled || isLoading) ? null : onVote,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(isVoted ? Icons.check : Icons.how_to_vote, size: 18),
                label: Text(
                  isVoted ? 'Votat' : 'Votar',
                  style: GoogleFonts.montserrat(
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: isVoted
                      ? AppTheme.porpraFosc
                      : AppTheme.grisPistacho,
                  foregroundColor: isVoted
                      ? Colors.white
                      : const Color.fromRGBO(41, 40, 40, 1),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Bottom-right vote count (singular/plural)
            if (voteCount != null) ...[
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  voteCount == 1 ? '1 vot' : '$voteCount vots',
                  style: GoogleFonts.montserrat(
                    textStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
