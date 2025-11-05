import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:el_visionat/theme/app_theme.dart';

/// Reusable TeamCard used to show a team's logo, name, vote count and a
/// "Votar" button. Designed to match styles used in `voting_section.dart`.
class TeamCard extends StatelessWidget {
  final String name;
  final String? assetLogo; // e.g. 'barcelona.png' or null
  final int votes;
  final bool isVoted;
  final VoidCallback? onVote;
  final bool enabled;
  final double logoSize;

  const TeamCard({
    super.key,
    required this.name,
    this.assetLogo,
    this.votes = 0,
    this.isVoted = false,
    this.onVote,
    this.enabled = true,
    this.logoSize = 80,
  });

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Widget logoWidget() {
      if (assetLogo != null && assetLogo!.isNotEmpty) {
        final assetPath = 'assets/images/teams/${assetLogo!}';
        return Container(
          width: logoSize,
          height: logoSize,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          alignment: Alignment.center,
          child: ClipOval(
            child: Image.asset(
              assetPath,
              width: logoSize * 0.8,
              height: logoSize * 0.8,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => CircleAvatar(
                radius: logoSize / 2,
                backgroundColor: AppTheme.white,
                child: Text(_initials(name)),
              ),
            ),
          ),
        );
      }
      return CircleAvatar(
        radius: logoSize / 2,
        backgroundColor: AppTheme.white,
        child: Text(_initials(name), style: GoogleFonts.montserrat()),
      );
    }

    // No-op here; the separate TeamInfo widget is defined below for reuse.

    return Card(
      color: AppTheme.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            logoWidget(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: GoogleFonts.inter(
                      textStyle: textTheme.titleMedium?.copyWith(
                        color: AppTheme.porpraFosc,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$votes vots',
                    style: GoogleFonts.inter(
                      textStyle: textTheme.bodySmall?.copyWith(
                        color: AppTheme.grisBody,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: (!enabled || isVoted) ? null : onVote,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.porpraFosc,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(72, 36),
              ),
              child: Text(
                isVoted ? 'Votat' : 'Votar',
                style: GoogleFonts.inter(
                  textStyle: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small widget that shows a team's logo and name (optionally votes) without
/// rendering the action button. Useful inside match cards where the match has
/// a single shared vote control.
class TeamInfo extends StatelessWidget {
  final String name;
  final String? assetLogo;
  final int? votes;
  final double size;
  final bool showName;
  final bool showVotes;

  const TeamInfo({
    super.key,
    required this.name,
    this.assetLogo,
    this.votes,
    this.size = 48,
    this.showName = true,
    this.showVotes = false,
  });

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final asset = assetLogo != null && assetLogo!.isNotEmpty
        ? 'assets/images/teams/${assetLogo!}'
        : null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (asset != null)
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            alignment: Alignment.center,
            child: ClipOval(
              child: Image.asset(
                asset,
                width: size * 0.8,
                height: size * 0.8,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => CircleAvatar(
                  radius: size / 2,
                  backgroundColor: AppTheme.white,
                  child: Text(_initials(name)),
                ),
              ),
            ),
          )
        else
          CircleAvatar(
            radius: size / 2,
            backgroundColor: AppTheme.white,
            child: Text(_initials(name)),
          ),
        if (showName) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: GoogleFonts.inter(
                    textStyle: textTheme.titleMedium?.copyWith(
                      color: AppTheme.porpraFosc,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (showVotes && votes != null) const SizedBox(height: 4),
                if (showVotes && votes != null)
                  Text(
                    '${votes!} vots',
                    style: GoogleFonts.inter(
                      textStyle: textTheme.bodySmall?.copyWith(
                        color: AppTheme.grisBody,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
