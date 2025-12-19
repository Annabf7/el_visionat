import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weekly_match_provider.dart';

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
          return _buildMobileHeader(textTheme, colorScheme, matchProvider);
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
              _buildMetadataRow(provider),
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

  Widget _buildMobileHeader(
    TextTheme textTheme,
    ColorScheme colorScheme,
    WeeklyMatchProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          provider.matchTitle,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        if (provider.matchScore != null) ...[
          const SizedBox(height: 4),
          Text(
            'Resultat: ${provider.matchScore}',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
        ],
        const SizedBox(height: 8),
        _buildMetadataRow(provider),
      ],
    );
  }

  Widget _buildMetadataRow(WeeklyMatchProvider provider) {
    // Extreure data i hora del dateDisplay o dateTime
    String dateText = 'Data no disponible';
    String timeText = '';

    if (provider.dateDisplay.isNotEmpty) {
      // Format: "Dissabte 13 Desembre, 18:15"
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
