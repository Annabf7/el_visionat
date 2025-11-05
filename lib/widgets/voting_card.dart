import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

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
      color: const Color.fromRGBO(57, 59, 71, 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                // MOBILE: slightly larger logos by default
                double logoSize = 64; // increased from previous 48
                if (w >= 800) {
                  logoSize = 120;
                } else if (w >= 400) {
                  logoSize = 88;
                }
                final compact = w < 420;

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
                        const SizedBox(width: 8),
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

                if (compact) {
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          logoWidget(homeName, homeLogo),
                          Text(
                            'vs',
                            style: GoogleFonts.montserrat(
                              textStyle: const TextStyle(color: Colors.white70),
                            ),
                          ),
                          logoWidget(awayName, awayLogo),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          dateTimeIso,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'vs',
                            style: GoogleFonts.montserrat(
                              textStyle: const TextStyle(color: Colors.white70),
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
                      child: Text(
                        dateTimeIso,
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            if (voteCount != null) ...[
              const SizedBox(height: 6),
              Center(
                child: Text(
                  '${voteCount ?? 0} vots',
                  style: GoogleFonts.montserrat(
                    textStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

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
          ],
        ),
      ),
    );
  }
}
