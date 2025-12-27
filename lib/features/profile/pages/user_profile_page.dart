import 'package:flutter/material.dart';
import 'package:el_visionat/core/widgets/global_header.dart';
import 'package:el_visionat/core/navigation/side_navigation_menu.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/profile_model.dart';
import '../models/season_goals_model.dart';
import '../models/video_clip_model.dart';
import '../widgets/profile_info_widget.dart';
import '../widgets/profile_footprint_widget.dart';
import '../widgets/profile_banner_widget.dart';
import '../widgets/profile_header_widget.dart';
import '../widgets/clip_detail_dialog.dart';

/// Pàgina per veure el perfil PÚBLIC d'un usuari
/// Mostra només la informació que l'usuari ha configurat com a visible
class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 900;

        if (isLargeScreen) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.white,
            body: Row(
              children: [
                SizedBox(
                  width: 288,
                  height: double.infinity,
                  child: const SideNavigationMenu(),
                ),
                Expanded(
                  child: Column(
                    children: [
                      GlobalHeader(
                        scaffoldKey: _scaffoldKey,
                        showMenuButton: false,
                      ),
                      Expanded(child: _buildDesktopLayout()),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.white,
            drawer: const SideNavigationMenu(),
            body: Column(
              children: [
                GlobalHeader(scaffoldKey: _scaffoldKey, showMenuButton: true),
                Expanded(
                  child: SingleChildScrollView(child: _buildMobileLayout()),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildDesktopLayout() {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildUserNotFound();
        }

        final profileData = snapshot.data!.data() as Map<String, dynamic>?;
        final profile = ProfileModel.fromMap(profileData);
        final isOwnProfile = currentUser != null && currentUser.uid == widget.userId;

        // Mateix layout que profile_page.dart
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Columna esquerra: ProfileBannerWidget (grandma)
            Flexible(
              flex: 4,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(),
                child: const ProfileBannerWidget(),
              ),
            ),
            // Columna dreta: ProfileHeaderWidget + contingut
            Flexible(
              flex: 5,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    height: constraints.maxHeight,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // ProfileHeaderWidget sense menú kebab
                          ProfileHeaderWidget(
                            imageUrl: profile.resolvedHeaderUrl,
                            showMenu: false, // Sense menú kebab
                            showImageAdjustButton: false, // Sense botó d'ajustament
                            onBackPressed: isOwnProfile
                                ? () => Navigator.of(context).pushReplacementNamed('/profile')
                                : null,
                          ),
                          const SizedBox(height: 24),
                          // ProfileInfoWidget
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: ProfileInfoWidget(profile: profile),
                          ),
                          const SizedBox(height: 32),
                          // Empremta del Visionat
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: ProfileFootprintWidget(profile: profile),
                          ),
                          const SizedBox(height: 32),
                          // Contingut públic segons visibilitat
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: _buildPublicContent(profile),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileLayout() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildUserNotFound();
        }

        final profileData = snapshot.data!.data() as Map<String, dynamic>?;
        final profile = ProfileModel.fromMap(profileData);

        return Column(
          children: [
            // Banner informatiu
            _buildInfoBanner(),

            // Contingut
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ProfileInfoWidget(profile: profile),
                  const SizedBox(height: 20),
                  ProfileFootprintWidget(profile: profile),
                  const SizedBox(height: 20),
                  _buildPublicContent(profile),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Contingut que es mostra segons la configuració de visibilitat
  Widget _buildPublicContent(ProfileModel profile) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnProfile = currentUser != null && currentUser.uid == widget.userId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Clips compartits (sempre visibles per al propietari, segons nivell d'accés per altres)
        _buildSharedClipsSection(profile, isOwnProfile),

        // Objectius de temporada (si visibles)
        if (profile.visibility.showSeasonGoals &&
            profile.seasonGoals.hasAnyGoal) ...[
          _buildSectionHeader('Objectius de temporada', Icons.flag),
          const SizedBox(height: 12),
          _buildSeasonGoalsPreview(profile.seasonGoals),
          const SizedBox(height: 24),
        ],

        // Apunts personals (si visibles)
        if (profile.visibility.showPersonalNotes) ...[
          _buildSectionHeader('Apunts personals', Icons.note),
          const SizedBox(height: 12),
          _buildPersonalNotesInfo(profile.personalNotesCount),
          const SizedBox(height: 24),
        ],

        // Si no hi ha contingut visible
        if (!profile.visibility.showSeasonGoals &&
            !profile.visibility.showPersonalNotes &&
            profile.sharedClipsCount == 0)
          _buildNoPublicContent(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 24, color: AppTheme.porpraFosc),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textBlackLow,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner() {
    // Comprovem si és el perfil del propi usuari
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnProfile = currentUser != null && currentUser.uid == widget.userId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      child: Row(
        children: [
          // Botó per tornar al perfil privat (només si és el propi perfil)
          if (isOwnProfile) ...[
            IconButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/profile'),
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Tornar al meu perfil',
              color: AppTheme.porpraFosc,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
                side: BorderSide(
                  color: AppTheme.grisPistacho.withValues(alpha: 0.3),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          // Banner informatiu
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.mostassa.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.mostassa.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.visibility,
                    color: AppTheme.mostassa,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vista pública del perfil',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textBlackLow,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isOwnProfile
                              ? 'Estàs veient el teu perfil com ho veurien altres usuaris de la comunitat.'
                              : 'Vista pública del perfil d\'aquest usuari.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textBlackLow.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonGoalsPreview(SeasonGoals goals) {
    // Mostrar una previsualització simple dels objectius
    final activeGoals = <String>[];

    // Recollir objectius actius
    if (!goals.objectiuTemporada.isEmpty) {
      activeGoals.add(goals.objectiuTemporada.text);
    }
    for (final goal in goals.objectiusTrimestrals) {
      if (!goal.isEmpty) activeGoals.add(goal.text);
    }
    for (final goal in goals.puntsMillorar) {
      if (!goal.isEmpty) activeGoals.add(goal.text);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.grisPistacho.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.grisPistacho.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, size: 20, color: AppTheme.porpraFosc),
              const SizedBox(width: 8),
              const Text(
                'Objectius actius',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textBlackLow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...activeGoals.take(3).map((goal) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: AppTheme.mostassa,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    goal,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textBlackLow,
                    ),
                  ),
                ),
              ],
            ),
          )),
          if (activeGoals.length > 3) ...[
            const SizedBox(height: 4),
            Text(
              '+ ${activeGoals.length - 3} objectius més',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textBlackLow.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalNotesInfo(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.grisPistacho.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.grisPistacho.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.porpraFosc.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.note_alt_outlined,
              color: AppTheme.porpraFosc,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count apunts personals',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textBlackLow,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aquest àrbitre comparteix els seus aprenentatges',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textBlackLow.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPublicContent() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.grisPistacho.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.grisPistacho.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: AppTheme.textBlackLow.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Perfil privat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textBlackLow.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aquest usuari ha optat per mantenir el seu perfil privat',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textBlackLow.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Secció de clips compartits amb lògica de visibilitat
  Widget _buildSharedClipsSection(ProfileModel profile, bool isOwnProfile) {
    // Si no hi ha clips, no mostrem res
    if (profile.sharedClipsCount == 0) {
      return const SizedBox.shrink();
    }

    // Si és el propi perfil, sempre mostra els clips
    if (isOwnProfile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Clips compartits', Icons.video_library),
          const SizedBox(height: 12),
          _buildClipsList(widget.userId, true, 3),
          const SizedBox(height: 24),
        ],
      );
    }

    // Si és un altre usuari, comprova el nivell d'accés
    return FutureBuilder<int>(
      future: _getCurrentUserSharedClips(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final currentUserClips = snapshot.data ?? 0;
        final accessLevel = _calculateAccessLevel(currentUserClips);

        // Si no té accés (no ha penjat clips), mostra missatge de bloqueig
        if (accessLevel == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Clips compartits', Icons.video_library),
              const SizedBox(height: 12),
              _buildLockedClipsMessage(profile.sharedClipsCount),
              const SizedBox(height: 24),
            ],
          );
        }

        // Té accés: mostra els clips segons el nivell
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Clips compartits', Icons.video_library),
            const SizedBox(height: 12),
            _buildClipsList(widget.userId, false, accessLevel),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  /// Obté el nombre de clips compartits de l'usuari actual
  Future<int> _getCurrentUserSharedClips() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return 0;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!doc.exists) return 0;
      final data = doc.data();
      return data?['sharedClipsCount'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Calcula el nivell d'accés basat en clips compartits
  /// 0: Cap accés, 1: Accés limitat (1-2 clips), 2: Accés categoria (3-5 clips), 3: Accés total (6+ clips)
  int _calculateAccessLevel(int clipsCount) {
    if (clipsCount >= 6) return 3;
    if (clipsCount >= 3) return 2;
    if (clipsCount >= 1) return 1;
    return 0;
  }

  /// Llista de clips amb StreamBuilder per obtenir-los de Firestore
  Widget _buildClipsList(String userId, bool isOwner, int accessLevel) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('video_clips')
          .where('userId', isEqualTo: userId)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Error al carregar els clips: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final clips = snapshot.data?.docs ?? [];

        if (clips.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.grisPistacho.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.grisPistacho.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Text(
                isOwner
                    ? 'Encara no has compartit cap clip públic'
                    : 'Aquest usuari no ha compartit clips públics',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textBlackLow.withValues(alpha: 0.6),
                ),
              ),
            ),
          );
        }

        // Mostrar els clips
        return Column(
          children: clips.map((doc) {
            final clip = VideoClip.fromFirestore(doc);
            return _buildClipCard(clip);
          }).toList(),
        );
      },
    );
  }

  /// Card individual per a cada clip
  Widget _buildClipCard(VideoClip clip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showClipDetails(clip),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.grisPistacho.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: clip.thumbnailUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          clip.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.play_circle_outline, size: 32),
                        ),
                      )
                    : const Icon(Icons.play_circle_outline, size: 32),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clip.matchInfo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildTag(
                          clip.actionType.displayName,
                          AppTheme.porpraFosc,
                        ),
                        const SizedBox(width: 8),
                        _buildTag(
                          clip.outcome.label,
                          _getOutcomeColor(clip.outcome),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${clip.formattedDuration} · ${clip.formattedSize}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (clip.personalDescription.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        clip.personalDescription,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textBlackLow.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Icona de clip públic
              Icon(
                Icons.public,
                size: 20,
                color: AppTheme.mostassa,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Color _getOutcomeColor(ClipOutcome outcome) {
    switch (outcome) {
      case ClipOutcome.encert:
        return Colors.green.shade700;
      case ClipOutcome.errada:
        return Colors.red.shade700;
      case ClipOutcome.dubte:
        return Colors.orange.shade700;
    }
  }

  void _showClipDetails(VideoClip clip) {
    showDialog(
      context: context,
      builder: (context) => ClipDetailDialog(clip: clip),
    );
  }

  /// Missatge de clips bloquejats
  Widget _buildLockedClipsMessage(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.grisPistacho.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.grisPistacho.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock,
              color: Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count clips compartits',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textBlackLow.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Comparteix els teus clips per veure els d\'altres àrbitres',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textBlackLow.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserNotFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: AppTheme.textBlackLow.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'Usuari no trobat',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textBlackLow,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aquest perfil no existeix o ha estat eliminat',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textBlackLow.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}