import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/features/voting/models/weekly_focus.dart';
import 'package:el_visionat/features/voting/services/weekly_focus_service.dart';

/// Card que mostra l'equip arbitral del partit de la setmana
/// amb boto per veure l'entrevista (publicada divendres 18h)
class RefereeTeamCard extends StatefulWidget {
  const RefereeTeamCard({super.key});

  @override
  State<RefereeTeamCard> createState() => _RefereeTeamCardState();
}

class _RefereeTeamCardState extends State<RefereeTeamCard> {
  final WeeklyFocusService _focusService = WeeklyFocusService();
  WeeklyFocus? _focus;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeeklyFocus();
  }

  Future<void> _loadWeeklyFocus() async {
    try {
      debugPrint('[RefereeTeamCard] Carregant weekly_focus...');
      final focus = await _focusService.getCurrentFocus();
      debugPrint(
        '[RefereeTeamCard] Focus rebut: ${focus != null ? "SÍ" : "NULL"}',
      );
      if (focus != null) {
        debugPrint('[RefereeTeamCard] Jornada: ${focus.jornada}');
        debugPrint(
          '[RefereeTeamCard] refereeInfo.hasData: ${focus.refereeInfo.hasData}',
        );
        debugPrint(
          '[RefereeTeamCard] refereeInfo.principal: ${focus.refereeInfo.principal}',
        );
      }
      if (mounted) {
        setState(() {
          _focus = focus;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[RefereeTeamCard] ERROR: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.porpraFosc, AppTheme.grisBody],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.porpraFosc.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: _isLoading
          ? _buildLoadingState()
          : _error != null
          ? _buildErrorState()
          : _focus == null || !_focus!.refereeInfo.hasData
          ? _buildEmptyState()
          : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(32.0),
      child: Center(
        child: CircularProgressIndicator(
          color: AppTheme.mostassa,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppTheme.mostassa.withValues(alpha: 0.7),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Error carregant dades',
            style: TextStyle(
              color: AppTheme.grisPistacho.withValues(alpha: 0.7),
              fontFamily: 'Inter',
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports_rounded,
            color: AppTheme.lilaMitja.withValues(alpha: 0.5),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'No hi ha equip arbitral',
            style: TextStyle(
              color: AppTheme.grisPistacho.withValues(alpha: 0.7),
              fontFamily: 'Inter',
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final referees = _focus!.refereeInfo;
    final jornada = _focus!.jornada;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildHeader(jornada),
          const SizedBox(height: 16),
          _buildRefereesSection(referees),
          if (referees.tableOfficials.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildTableOfficialsExpansion(referees),
          ],
          const SizedBox(height: 16),
          _buildInterviewButton(jornada),
        ],
      ),
    );
  }

  Widget _buildHeader(int jornada) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.mostassa,
                AppTheme.mostassa.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.mostassa.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.groups_rounded,
            size: 22,
            color: AppTheme.porpraFosc,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'EQUIP ARBITRAL',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.grisPistacho,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Jornada $jornada',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppTheme.lilaMitja.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRefereesSection(RefereeInfo referees) {
    return Column(
      children: [
        if (referees.principal != null)
          _buildRefereeCard(
            role: 'Arbitre Principal',
            name: referees.principal!,
            isPrimary: true,
          ),
        if (referees.auxiliar != null) ...[
          const SizedBox(height: 10),
          _buildRefereeCard(
            role: 'Arbitre Auxiliar',
            name: referees.auxiliar!,
            isPrimary: false,
          ),
        ],
      ],
    );
  }

  Widget _buildRefereeCard({
    required String role,
    required String name,
    required bool isPrimary,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isPrimary
            ? AppTheme.lilaMitja.withValues(alpha: 0.15)
            : AppTheme.grisBody.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrimary
              ? AppTheme.lilaMitja.withValues(alpha: 0.3)
              : AppTheme.grisPistacho.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            role.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isPrimary
                  ? AppTheme.lilaClar
                  : AppTheme.grisPistacho.withValues(alpha: 0.6),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatName(name),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
              color: AppTheme.grisPistacho,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableOfficialsExpansion(RefereeInfo referees) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        trailing: Icon(
          Icons.expand_more,
          color: AppTheme.grisPistacho.withValues(alpha: 0.7),
        ),
        childrenPadding: const EdgeInsets.only(top: 8),
        collapsedIconColor: AppTheme.grisPistacho,
        iconColor: AppTheme.mostassa,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Oficials de Taula',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.grisPistacho.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
        children: referees.tableOfficials.map((official) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  official.role,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                  ),
                ),
                Flexible(
                  child: Text(
                    _formatName(official.name),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppTheme.grisPistacho,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInterviewButton(int jornada) {
    final clipUrl = 'https://elvisionat.cat/clips/jornada-$jornada';

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _openClipUrl(clipUrl),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.mostassa,
              foregroundColor: AppTheme.porpraFosc,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_filled_rounded, size: 22),
                SizedBox(width: 10),
                Text(
                  'VEURE ENTREVISTA',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 12,
              color: AppTheme.grisPistacho.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Text(
              'Publicació: Divendres 18:00h',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  String _formatName(String name) {
    if (name.isEmpty) return name;
    return name
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }

  Future<void> _openClipUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("L'entrevista encara no està disponible"),
              backgroundColor: AppTheme.lilaMitja,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error obrint URL: $e');
    }
  }
}
