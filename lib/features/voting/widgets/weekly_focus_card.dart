// ============================================================================
// WeeklyFocusCard - Widget per mostrar el partit guanyador i equip arbitral
// ============================================================================
// Mostra les dades de weekly_focus/current:
// - Àrbitre principal (destacat)
// - Competició
// - Partit (Local vs Visitant)
// - Jornada
// - Oficials de taula (anotador, cronometrador, etc.)

import 'package:flutter/material.dart';

import 'package:el_visionat/core/theme/app_theme.dart';
import '../models/weekly_focus.dart';
import '../services/weekly_focus_service.dart';

class WeeklyFocusCard extends StatefulWidget {
  const WeeklyFocusCard({super.key});

  @override
  State<WeeklyFocusCard> createState() => _WeeklyFocusCardState();
}

class _WeeklyFocusCardState extends State<WeeklyFocusCard> {
  final WeeklyFocusService _service = WeeklyFocusService();
  WeeklyFocus? _focus;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFocus();
  }

  Future<void> _loadFocus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final focus = await _service.getCurrentFocus();
      if (mounted) {
        setState(() {
          _focus = focus;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Si és error de permisos (usuari no autenticat), mostrar "no focus" en lloc d'error
      final isPermissionError = e.toString().contains('permission-denied');
      if (mounted) {
        setState(() {
          if (isPermissionError) {
            _focus = null; // Mostrarà _buildNoFocusCard
          } else {
            _error = e.toString();
          }
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingCard();
    }

    if (_error != null) {
      return _buildErrorCard();
    }

    if (_focus == null || !_focus!.isValid) {
      return _buildNoFocusCard();
    }

    return _buildFocusCard(_focus!);
  }

  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.porpraFosc,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.porpraFosc.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: const Center(
        child: CircularProgressIndicator(color: AppTheme.grisPistacho),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.porpraFosc,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.mostassa, size: 32),
          const SizedBox(height: 12),
          Text(
            'Error carregant dades',
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              color: AppTheme.grisPistacho,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _loadFocus, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _buildNoFocusCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.porpraFosc,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.porpraFosc.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Partit de la Setmana',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.grisPistacho,
            ),
          ),
          const SizedBox(height: 20),
          const Icon(
            Icons.how_to_vote_outlined,
            color: AppTheme.mostassa,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Encara no hi ha partit seleccionat.\nLa votació està oberta!',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppTheme.grisPistacho.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFocusCard(WeeklyFocus focus) {
    final referee = focus.refereeInfo;
    final match = focus.winningMatch;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.porpraFosc,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.porpraFosc.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Títol amb badge d'estat
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Partit de la Setmana',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.grisPistacho,
                ),
              ),
              _buildStatusBadge(focus.status),
            ],
          ),
          const SizedBox(height: 16),

          // Àrbitre Principal (destacat)
          _buildDetailRow(
            icon: Icons.sports,
            label: 'Àrbitre Principal',
            value: referee.principal ?? 'Pendent',
            isHighlighted: true,
          ),
          _buildDivider(),

          // Auxiliar (si existeix)
          if (referee.auxiliar != null && referee.auxiliar!.isNotEmpty) ...[
            _buildDetailRow(
              icon: Icons.person_outline,
              label: 'Àrbitre Auxiliar',
              value: referee.auxiliar!,
            ),
            _buildDivider(),
          ],

          // Competició
          _buildDetailRow(
            icon: Icons.emoji_events,
            label: 'Competició',
            value: focus.competitionName,
          ),
          _buildDivider(),

          // Partit
          _buildDetailRow(
            icon: Icons.sports_basketball,
            label: 'Partit',
            value: match.matchDisplayName,
          ),
          _buildDivider(),

          // Jornada
          _buildDetailRow(
            icon: Icons.calendar_month,
            label: 'Jornada',
            value: focus.jornada.toString(),
          ),

          // Vots
          const SizedBox(height: 12),
          _buildVotesInfo(focus.totalVotes),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    String label;

    switch (status) {
      case 'minutatge':
        badgeColor = AppTheme.mostassa;
        label = 'Minutatge';
        break;
      case 'entrevista_pendent':
        badgeColor = Colors.orange;
        label = 'Entrevista';
        break;
      case 'completat':
        badgeColor = Colors.green;
        label = 'Completat';
        break;
      default:
        badgeColor = AppTheme.grisPistacho;
        label = 'Pendent';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isHighlighted
                  ? AppTheme.mostassa.withValues(alpha: 0.3)
                  : AppTheme.grisBody.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isHighlighted ? AppTheme.mostassa : AppTheme.mostassa,
            ),
          ),
          const SizedBox(width: 16),
          // Label and Value
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.grisPistacho,
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isHighlighted
                          ? AppTheme.mostassa
                          : AppTheme.grisPistacho.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: AppTheme.grisPistacho.withValues(alpha: 0.15),
      height: 1,
    );
  }

  Widget _buildVotesInfo(int totalVotes) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.mostassa.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.how_to_vote, size: 16, color: AppTheme.mostassa),
            const SizedBox(width: 8),
            Text(
              '$totalVotes vots',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.mostassa,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
