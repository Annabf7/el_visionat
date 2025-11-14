import 'package:flutter/material.dart';
import 'package:el_visionat/features/teams/models/team_platform.dart';

/// Widget card per mostrar informació d'un equip de bàsquet
/// Segueix les guidelines UI/UX del projecte amb:
/// - Cards amb cantonades suaus (radius 16)
/// - Ombres subtils
/// - Colors del AppTheme
/// - Layout responsive
class TeamCard extends StatelessWidget {
  final Team team;

  const TeamCard({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Logo de l'equip
            _buildTeamLogo(),
            const SizedBox(width: 16),
            // Informació de l'equip
            Expanded(child: _buildTeamInfo(context)),
            // Indicador de gènere
            _buildGenderIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamLogo() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: team.logoUrl != null && team.logoUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                team.logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultLogo();
                },
              ),
            )
          : _buildDefaultLogo(),
    );
  }

  Widget _buildDefaultLogo() {
    return Icon(Icons.groups, size: 32, color: Colors.grey[600]);
  }

  Widget _buildTeamInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nom de l'equip
        Text(
          team.name,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Acrònim
        if (team.acronym.isNotEmpty)
          Text(
            team.acronym,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        const SizedBox(height: 8),
        // ID Firestore (només per debug si és necessari)
        if (team.firestoreId.isNotEmpty)
          Text(
            'ID: ${team.firestoreId}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
      ],
    );
  }

  Widget _buildGenderIndicator() {
    Color indicatorColor;
    IconData indicatorIcon;

    switch (team.gender.toLowerCase()) {
      case 'masculí':
      case 'masculino':
      case 'male':
        indicatorColor = Colors.blue[600]!;
        indicatorIcon = Icons.male;
        break;
      case 'femení':
      case 'femenino':
      case 'female':
        indicatorColor = Colors.pink[600]!;
        indicatorIcon = Icons.female;
        break;
      default:
        indicatorColor = Colors.grey[600]!;
        indicatorIcon = Icons.group;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(indicatorIcon, color: indicatorColor, size: 20),
    );
  }
}
