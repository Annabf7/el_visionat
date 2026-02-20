import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/core/widgets/global_header.dart';
import 'package:el_visionat/core/navigation/side_navigation_menu.dart';
import 'package:el_visionat/features/profile/models/profile_model.dart';
import '../models/clip_model.dart';
import '../widgets/featured_clips_section.dart';
import '../widgets/jugada_flash_section.dart';
import '../widgets/laboratori_hero_header.dart';
import '../widgets/progress_card.dart';
import '../widgets/weekly_training_card.dart';
import '../widgets/monthly_battle_card.dart';

/// Pàgina principal del Laboratori Arbitral
/// Replica l'estètica de Neurovisionat però adaptada al nou contingut
class LaboratoriArbitralPage extends StatefulWidget {
  const LaboratoriArbitralPage({super.key});

  @override
  State<LaboratoriArbitralPage> createState() => _LaboratoriArbitralPageState();
}

class _LaboratoriArbitralPageState extends State<LaboratoriArbitralPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<ProfileModel?> _profileFuture;

  // Imatges de capçalera segons gènere
  static const String _headerMan =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/EL%20laboratori%20arbitral%2Freglament_men.webp?alt=media&token=49cd02ba-3e6e-46eb-b429-6e501c1a255e';
  static const String _headerWoman =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/EL%20laboratori%20arbitral%2Freglamen_woman.webp?alt=media&token=346adb03-e4bf-4c2b-a97c-2e6203688bb8';

  static const String _defaultThumbnail =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/EL%20laboratori%20arbitral%2Freglamen_woman.webp?alt=media&token=346adb03-e4bf-4c2b-a97c-2e6203688bb8';

  // Llista de clips
  static const List<ClipModel> _clips = [
    ClipModel(
      title: 'Partnering & Game-Management ',
      subtitle: 'Tip: Technical Fouls',
      url: 'https://www.instagram.com/reel/DUYo6s8EdC-/',
      isInstagram: true,
      thumbnailUrl:
          'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/EL%20laboratori%20arbitral%2Fcrown%20refs.webp?alt=media&token=ba451b92-a13d-472a-842e-67b34bae295e',
    ),
    ClipModel(
      title:
          "Secretos de un árbitro sin censura: sueldo, agresiones y soledad | Alberto Baena",
      subtitle: "Cómo es la vida de un árbitro professional",
      url: 'https://youtu.be/R4uMNw111HA?si=horUdd3GCXIQzS1d',
    ),
    ClipModel(
      title: "Àrbitres amb Micro: Supercopa '25",
      subtitle: "Comunicació i gestió de partits d'alta tensió",
      url: 'https://youtu.be/lmka0zdKWQM?si=I4R2Zm8imVilnjQn',
    ),
    ClipModel(
      title: "Àrbitres amb Micro: Playoff Final",
      subtitle: "Comunicació i gestió de partits d'alta tensió",
      url: 'https://youtu.be/P4_IoObf91E?si=o_wbwrSUgTx7KU4r',
    ),
    ClipModel(
      title: 'Calling the Shots: The Anne Panther Story',
      subtitle: 'The Insider Documentary · Euroleague Basketball',
      url: 'https://youtu.be/cmiFlkJBTtQ?si=iIpRN8PAR7a0Q9QN',
    ),
  ];

  // Jugades Flash FCBQ 2025-2026
  static const List<ClipModel> _jugadesFlash = [
    ClipModel(
      title: 'Jugada Flash #1',
      subtitle: 'Temporada 2025-2026',
      url: 'https://www.instagram.com/p/DPTnNAUCG3J/',
      isInstagram: true,
    ),
    ClipModel(
      title: 'Jugada Flash #2',
      subtitle: 'Temporada 2025-2026',
      url: 'https://www.instagram.com/p/DPlVKxSCLaa/',
      isInstagram: true,
    ),
    ClipModel(
      title: 'Jugada Flash #3',
      subtitle: 'Temporada 2025-2026',
      url: 'https://www.instagram.com/p/DP3UmW6CEXO/',
      isInstagram: true,
    ),
    ClipModel(
      title: 'Jugada Flash #4',
      subtitle: 'Temporada 2025-2026',
      url: 'https://www.instagram.com/p/DQbnWXuCBE1/',
      isInstagram: true,
    ),
    ClipModel(
      title: 'Jugada Flash #5',
      subtitle: 'Temporada 2025-2026',
      url: 'https://www.instagram.com/p/DQubHQ3iL3k/',
      isInstagram: true,
    ),
    ClipModel(
      title: 'Jugada Flash #6',
      subtitle: 'Temporada 2025-2026',
      url: 'https://www.instagram.com/p/DQ__bAyiHmQ/',
      isInstagram: true,
    ),
    ClipModel(
      title: 'Jugada Flash #7',
      subtitle: 'Temporada 2025-2026',
      url: 'https://www.instagram.com/p/DRR3FOHCPvW/',
      isInstagram: true,
    ),
    ClipModel(
      title: 'Jugada Flash #8',
      subtitle: 'Temporada 2025-2026',
      url: 'https://www.instagram.com/p/DRj9MuhiOZl/',
      isInstagram: true,
    ),
    ClipModel(
      title: 'Jugada Flash #9',
      subtitle: 'Temporada 2025-2026',
      url: 'https://www.instagram.com/p/DR16LctiPEK/',
      isInstagram: true,
    ),
    ClipModel(
      title: 'Jugada Flash #10',
      subtitle: 'Temporada 2025-2026',
      url: 'https://www.instagram.com/p/DSH2lmeiF3k/',
      isInstagram: true,
    ),
    ClipModel(
      title: 'Jugada Flash #11',
      subtitle: 'Temporada 2025-2026',
      url: 'https://www.instagram.com/p/DSanZewCNha/',
      isInstagram: true,
    ),
    ClipModel(
      title: 'Jugada Flash #12',
      subtitle: 'Temporada 2025-2026',
      url: 'https://www.instagram.com/p/DTAreVHjOAM/',
      isInstagram: true,
    ),
    ClipModel(
      title: 'Jugada Flash #13',
      subtitle: 'Temporada 2025-2026',
      url: 'https://www.instagram.com/p/DTQDjEAiM_1/',
      isInstagram: true,
    ),
    ClipModel(
      title: 'Jugada Flash #14',
      subtitle: 'Temporada 2025-2026',
      url: 'https://www.instagram.com/p/DTikpnoCLvI/',
      isInstagram: true,
    ),
    ClipModel(
      title: 'Jugada Flash #15',
      subtitle: 'Temporada 2025-2026',
      url: 'https://www.instagram.com/p/DT0VP0MiEzv/',
      isInstagram: true,
    ),
    ClipModel(
      title: 'Jugada Flash #16',
      subtitle: 'Temporada 2025-2026',
      url: 'https://www.instagram.com/p/DUYwsO8iAcd/',
      isInstagram: true,
    ),
    ClipModel(
      title: 'Jugada Flash #17',
      subtitle: 'Temporada 2025-2026',
      url: 'https://www.instagram.com/p/DUqmiPLCBBB/',
      isInstagram: true,
    ),
    ClipModel(
      title: 'Jugada Flash #18',
      subtitle: 'Temporada 2025-2026',
      url: 'https://www.instagram.com/p/DU8I_2XiACm/',
      isInstagram: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchUserProfile();
  }

  Future<ProfileModel?> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return ProfileModel.fromMap(doc.data()!);
      }
    } catch (e) {
      debugPrint('Error fetching user profile: \$e');
    }
    return null;
  }

  String _resolveHeaderAsset(String? gender) {
    if (gender == 'male') {
      return _headerMan;
    }
    // Per defecte dona o si no està especificat
    return _headerWoman;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 900;

        if (isLargeScreen) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppTheme.grisBody,
            body: Row(
              children: [
                const SizedBox(
                  width: 288,
                  height: double.infinity,
                  child: SideNavigationMenu(),
                ),
                Expanded(
                  child: Column(
                    children: [
                      GlobalHeader(
                        scaffoldKey: _scaffoldKey,
                        title: 'Laboratori Arbitral',
                        showMenuButton: false,
                      ),
                      Expanded(child: _buildBody(context, isLargeScreen: true)),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppTheme.grisBody,
            drawer: const SideNavigationMenu(),
            body: Column(
              children: [
                GlobalHeader(
                  scaffoldKey: _scaffoldKey,
                  title: 'Laboratori Arbitral',
                  showMenuButton: true,
                ),
                Expanded(child: _buildBody(context, isLargeScreen: false)),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildBody(BuildContext context, {required bool isLargeScreen}) {
    return FutureBuilder<ProfileModel?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        // Mentre carrega, mostrem un loader o layout per defecte
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.mostassa),
          );
        }

        final profile = snapshot.data;
        final gender = profile?.gender;
        final headerImage = _resolveHeaderAsset(gender);

        if (isLargeScreen) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // Header full width
                LaboratoriHeroHeader(
                  gender: gender,
                  fallbackImageUrl: headerImage,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Laboratori Arbitral',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AppTheme.grisPistacho,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                    color: Colors.black.withValues(alpha: 0.5),
                                  ),
                                ],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Formació reglamentària i anàlisi de clips i Reels rellevants del món arbitral.',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.grisPistacho,
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Contingut amb padding
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FeaturedClipsSection(
                                clips: _clips,
                                defaultThumbnail: _defaultThumbnail,
                              ),
                              const SizedBox(height: 32),
                              JugadaFlashSection(jugades: _jugadesFlash),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const ProgressCard(),
                              const SizedBox(height: 16),
                              const WeeklyTrainingCard(),
                              const SizedBox(height: 16),
                              const MonthlyBattleCard(),
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

        // Mobile layout
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LaboratoriHeroHeader(
                gender: gender,
                fallbackImageUrl: headerImage,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Laboratori Arbitral',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                  color: Colors.black.withValues(alpha: 0.5),
                                ),
                              ],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Formació reglamentària i anàlisi de clips i Reels rellevants del món arbitral.',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w400,
                            ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    FeaturedClipsSection(
                      clips: _clips,
                      defaultThumbnail: _defaultThumbnail,
                    ),
                    const SizedBox(height: 32),
                    JugadaFlashSection(jugades: _jugadesFlash),
                    const SizedBox(height: 16),
                    const ProgressCard(),
                    const SizedBox(height: 16),
                    const WeeklyTrainingCard(),
                    const SizedBox(height: 16),
                    const MonthlyBattleCard(),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
