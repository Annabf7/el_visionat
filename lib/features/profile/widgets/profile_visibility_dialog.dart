import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../models/profile_model.dart';

/// Diàleg per configurar quins camps del perfil són públics o privats
class ProfileVisibilityDialog extends StatefulWidget {
  final ProfileVisibility initialVisibility;

  const ProfileVisibilityDialog({super.key, required this.initialVisibility});

  @override
  State<ProfileVisibilityDialog> createState() =>
      _ProfileVisibilityDialogState();
}

class _ProfileVisibilityDialogState extends State<ProfileVisibilityDialog> {
  late ProfileVisibility _visibility;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _visibility = widget.initialVisibility;
  }

  Future<void> _saveVisibility() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'profileVisibility': _visibility.toMap()},
      );

      if (mounted) {
        Navigator.of(context).pop('success');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error guardant: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final content = Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header amb gradient subtil
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 16, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.porpraFosc.withValues(alpha: 0.03),
                  AppTheme.mostassa.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.mostassa.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.visibility_outlined,
                    color: AppTheme.porpraFosc,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Visibilitat del perfil',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.porpraFosc,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Controla què veuen els altres àrbitres',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.grisBody.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppTheme.grisBody.withValues(alpha: 0.6),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.grisPistacho.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contingut
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Camps sempre públics
                _buildSectionHeader(
                  'Sempre públic',
                  Icons.public_rounded,
                  AppTheme.mostassa,
                ),
                const SizedBox(height: 12),
                _buildPublicItem(
                  'Nom i categoria',
                  'Necessari per identificar-te',
                  Icons.badge_outlined,
                ),
                const SizedBox(height: 8),
                _buildPublicItem(
                  'Clips compartits',
                  'Visibles segons nivell d\'accés',
                  Icons.videocam_outlined,
                ),

                const SizedBox(height: 28),

                // Camps configurables
                _buildSectionHeader(
                  'Tu decideixes',
                  Icons.tune_rounded,
                  AppTheme.lilaMitja,
                ),
                const SizedBox(height: 12),
                _buildToggleItem(
                  'Anys d\'experiència',
                  'Mostra quants anys portes arbitrant',
                  Icons.timeline_outlined,
                  _visibility.showYearsExperience,
                  (value) => setState(() {
                    _visibility = _visibility.copyWith(
                      showYearsExperience: value,
                    );
                  }),
                ),
                const SizedBox(height: 10),
                _buildToggleItem(
                  'Partits analitzats',
                  'Mostra el nombre de partits revisats',
                  Icons.analytics_outlined,
                  _visibility.showAnalyzedMatches,
                  (value) => setState(() {
                    _visibility = _visibility.copyWith(
                      showAnalyzedMatches: value,
                    );
                  }),
                ),
                const SizedBox(height: 10),
                _buildToggleItem(
                  'Objectius de temporada',
                  'Comparteix els teus objectius',
                  Icons.flag_outlined,
                  _visibility.showSeasonGoals,
                  (value) => setState(() {
                    _visibility = _visibility.copyWith(showSeasonGoals: value);
                  }),
                ),

                const SizedBox(height: 28),

                // Camps sempre privats
                _buildSectionHeader(
                  'Sempre privat',
                  Icons.lock_outline_rounded,
                  AppTheme.grisBody,
                ),
                const SizedBox(height: 12),
                _buildPrivateItem(
                  'Notes personals',
                  'Els teus apunts són només teus',
                  Icons.edit_note_outlined,
                ),

                const SizedBox(height: 32),

                // Botons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.grisBody,
                          side: BorderSide(
                            color: AppTheme.grisPistacho.withValues(alpha: 0.8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Cancel·lar',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveVisibility,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.porpraFosc,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Guardar canvis',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isMobile) {
      return Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: content,
              ),
            ),
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: content,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildPublicItem(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.mostassa.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.mostassa.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.mostassa.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppTheme.porpraFosc),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.porpraFosc,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.grisBody.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, size: 22, color: AppTheme.mostassa),
        ],
      ),
    );
  }

  Widget _buildPrivateItem(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.grisPistacho.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grisPistacho.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.grisBody.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppTheme.grisBody),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.grisBody.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.grisBody.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.lock_rounded,
            size: 20,
            color: AppTheme.grisBody.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    void Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: value ? AppTheme.lilaClar.withValues(alpha: 0.15) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? AppTheme.lilaMitja.withValues(alpha: 0.3)
              : AppTheme.grisPistacho.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value
                  ? AppTheme.lilaMitja.withValues(alpha: 0.15)
                  : AppTheme.grisPistacho.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: value ? AppTheme.lilaMitja : AppTheme.grisBody,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: value ? AppTheme.porpraFosc : AppTheme.grisBody,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.grisBody.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppTheme.lilaMitja.withValues(alpha: 0.4),
              activeThumbColor: AppTheme.lilaMitja,
              inactiveTrackColor: AppTheme.grisPistacho.withValues(alpha: 0.5),
              inactiveThumbColor: Colors.white,
              trackOutlineColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppTheme.lilaMitja.withValues(alpha: 0.2);
                }
                return AppTheme.grisPistacho;
              }),
            ),
          ),
        ],
      ),
    );
  }
}
