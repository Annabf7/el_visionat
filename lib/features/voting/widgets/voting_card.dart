import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:el_visionat/core/theme/app_theme.dart';

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
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.porpraFosc.withAlpha(250),
              AppTheme.lilaMitja.withAlpha(120),
              AppTheme.grisBody.withAlpha(220),
            ],
            stops: const [0.0, 0.55, 1.0],
            tileMode: TileMode.clamp,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(89),
              offset: const Offset(0, 3),
              blurRadius: 8,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                const double logoSize = 72;
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
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
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
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
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
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: logoSize,
                        height: logoSize,
                        child: logoWidget(name, logo),
                      ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Center(child: teamBlock(homeName, homeLogo)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Text(
                              'vs',
                              style: GoogleFonts.montserrat(
                                textStyle: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(child: teamBlock(awayName, awayLogo)),
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
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (parts.length > 1) ...[
                              const SizedBox(height: 2),
                              Text(
                                parts[1],
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 8,
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
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Center(child: teamBlock(homeName, homeLogo)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            'vs',
                            style: GoogleFonts.montserrat(
                              textStyle: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(child: teamBlock(awayName, awayLogo)),
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
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (parts.length > 1) ...[
                            const SizedBox(height: 2),
                            Text(
                              parts[1],
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 9,
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

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 28,
                  child: FilledButton.icon(
                    onPressed: (isDisabled || isLoading) ? null : onVote,
                    icon: isLoading
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isVoted ? Icons.check : Icons.how_to_vote,
                            size: 12,
                          ),
                    label: Text(
                      isVoted ? 'Votat' : 'Votar',
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(fontSize: 10),
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: isVoted
                          ? AppTheme.porpraFosc
                          : AppTheme.grisPistacho,
                      foregroundColor: isVoted
                          ? Colors.white
                          : const Color.fromRGBO(41, 40, 40, 1),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 28),
                    ),
                  ),
                ),
                if (voteCount != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(51),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[700]!, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 11,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          voteCount == 1 ? '1 vot' : '$voteCount vots',
                          style: GoogleFonts.montserrat(
                            textStyle: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
