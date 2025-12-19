import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weekly_match_provider.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/core/services/team_mapping_service.dart';

class MatchHeader extends StatelessWidget {
  const MatchHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final matchProvider = context.watch<WeeklyMatchProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 600;

        if (isWideScreen) {
          return _buildWebHeader(textTheme, colorScheme, matchProvider);
        } else {
          return _buildMobileHeader(context, matchProvider);
        }
      },
    );
  }

  Widget _buildWebHeader(
    TextTheme textTheme,
    ColorScheme colorScheme,
    WeeklyMatchProvider provider,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.matchTitle,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              _buildMetadataRowWeb(provider),
            ],
          ),
        ),
        if (provider.matchScore != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              provider.matchScore!,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  /// Disseny mòbil millorat amb targeta visual
  Widget _buildMobileHeader(
    BuildContext context,
    WeeklyMatchProvider provider,
  ) {
    // Extreure data i hora
    String dateText = '';
    String timeText = '';
    if (provider.dateDisplay.isNotEmpty) {
      final parts = provider.dateDisplay.split(', ');
      if (parts.length >= 2) {
        dateText = parts[0];
        timeText = parts[1];
      } else {
        dateText = provider.dateDisplay;
      }
    }

    // Obtenir logos dels equips
    final teamMapping = TeamMappingService.instance;
    final homeResult = teamMapping.findTeamSync(provider.homeTeam);
    final awayResult = teamMapping.findTeamSync(provider.awayTeam);
    final homeLogo = homeResult.logoAssetPath;
    final awayLogo = awayResult.logoAssetPath;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.porpraFosc,
            AppTheme.porpraFosc.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.porpraFosc.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Badge de jornada i competició
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.mostassa.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      color: AppTheme.mostassa,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Jornada ${provider.matchday}',
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mostassa,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.mostassa.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    provider.league,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.grisPistacho.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Secció principal: Equips + Resultat
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                // Equip Local
                Expanded(
                  child: _buildTeamColumn(
                    teamName: provider.homeTeam,
                    logoPath: homeLogo,
                    score: provider.homeScore,
                    isHome: true,
                  ),
                ),

                // VS / Resultat central
                _buildCenterScore(provider),

                // Equip Visitant
                Expanded(
                  child: _buildTeamColumn(
                    teamName: provider.awayTeam,
                    logoPath: awayLogo,
                    score: provider.awayScore,
                    isHome: false,
                  ),
                ),
              ],
            ),
          ),

          // Footer amb data, hora i pavelló
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.grisBody.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Data i Hora
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildInfoChip(
                      icon: Icons.calendar_today_rounded,
                      text: dateText,
                    ),
                    if (timeText.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      _buildInfoChip(
                        icon: Icons.schedule_rounded,
                        text: timeText,
                      ),
                    ],
                  ],
                ),
                // Pavelló (si existeix)
                if (provider.location != null &&
                    provider.location!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          provider.location!,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Columna d'un equip (logo + nom + puntuació)
  Widget _buildTeamColumn({
    required String teamName,
    required String? logoPath,
    required int? score,
    required bool isHome,
  }) {
    return Column(
      children: [
        // Logo de l'equip
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: logoPath != null
                ? Image.asset(
                    logoPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _buildDefaultLogo(teamName),
                  )
                : _buildDefaultLogo(teamName),
          ),
        ),
        const SizedBox(height: 10),
        // Nom de l'equip
        Text(
          _formatTeamName(teamName),
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.grisPistacho,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        // Etiqueta LOCAL/VISITANT
        const SizedBox(height: 4),
        Text(
          isHome ? 'LOCAL' : 'VISITANT',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppTheme.grisPistacho.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  /// Format del nom de l'equip (escurça si és massa llarg)
  String _formatTeamName(String name) {
    // Si és massa llarg, agafem les primeres paraules
    if (name.length > 18) {
      final words = name.split(' ');
      if (words.length > 2) {
        return '${words[0]} ${words[1]}';
      }
    }
    return name;
  }

  /// Logo per defecte si no es troba
  Widget _buildDefaultLogo(String teamName) {
    return Container(
      color: AppTheme.grisBody.withValues(alpha: 0.5),
      child: Center(
        child: Text(
          teamName.isNotEmpty ? teamName[0].toUpperCase() : '?',
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.grisPistacho,
          ),
        ),
      ),
    );
  }

  /// Secció central amb el resultat
  Widget _buildCenterScore(WeeklyMatchProvider provider) {
    final hasScore = provider.homeScore != null && provider.awayScore != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          if (hasScore)
            // Resultat
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.mostassa.withValues(alpha: 0.9),
                    AppTheme.mostassa,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.mostassa.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${provider.homeScore}',
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.porpraFosc,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '-',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.porpraFosc,
                      ),
                    ),
                  ),
                  Text(
                    '${provider.awayScore}',
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.porpraFosc,
                    ),
                  ),
                ],
              ),
            )
          else
            // VS si no hi ha resultat
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.grisBody.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'VS',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.grisPistacho,
                ),
              ),
            ),
          const SizedBox(height: 6),
          // Estat del partit
          Text(
            hasScore ? 'FINALITZAT' : 'PENDENT',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: hasScore
                  ? AppTheme.mostassa.withValues(alpha: 0.8)
                  : AppTheme.grisPistacho.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Chip d'informació (data, hora)
  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppTheme.grisPistacho.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.grisPistacho.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRowWeb(WeeklyMatchProvider provider) {
    String dateText = 'Data no disponible';
    String timeText = '';

    if (provider.dateDisplay.isNotEmpty) {
      final parts = provider.dateDisplay.split(', ');
      if (parts.length >= 2) {
        dateText = parts[0];
        timeText = parts[1];
      } else {
        dateText = provider.dateDisplay;
      }
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildMetadataItem(Icons.calendar_today, dateText),
        if (timeText.isNotEmpty)
          _buildMetadataItem(Icons.access_time, timeText),
        if (provider.location != null && provider.location!.isNotEmpty)
          _buildMetadataItem(Icons.location_on, provider.location!),
        _buildMetadataItem(Icons.emoji_events, 'Jornada ${provider.matchday}'),
      ],
    );
  }

  Widget _buildMetadataItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }
}
