import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:el_visionat/core/navigation/side_navigation_menu.dart';
import 'package:el_visionat/core/widgets/global_header.dart';
import '../widgets/featured_visioning_section.dart';
import '../widgets/user_profile_summary_card.dart';
import 'package:el_visionat/features/visionat/widgets/match_details_card.dart';
import 'package:el_visionat/features/visionat/models/match_models.dart';
import 'package:el_visionat/features/voting/index.dart';
import '../providers/home_provider.dart';
import 'package:el_visionat/features/training/index.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // Obtenim el Provider per a les dades, assegurant que ja existeix
    final provider = context.watch<HomeProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 900;

        if (isLargeScreen) {
          // Layout desktop: Menú lateral ocupa tota l'alçada
          return Scaffold(
            key: _scaffoldKey,
            body: Row(
              children: [
                // Menú lateral amb alçada completa (inclou l'espai del header)
                SizedBox(
                  width: 288,
                  height: double.infinity,
                  child: const SideNavigationMenu(),
                ),

                // Columna dreta amb GlobalHeader + contingut
                Expanded(
                  child: Column(
                    children: [
                      // GlobalHeader només per l'amplada restant
                      GlobalHeader(
                        scaffoldKey: _scaffoldKey,
                        title: 'El Visionat',
                        showMenuButton: false,
                      ),

                      // Contingut principal
                      Expanded(
                        child: _buildWideLayoutContent(context, provider),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // Layout mòbil: comportament tradicional
          return Scaffold(
            key: _scaffoldKey,
            drawer: const SideNavigationMenu(),
            body: Column(
              children: [
                // GlobalHeader amb icona hamburguesa
                GlobalHeader(
                  scaffoldKey: _scaffoldKey,
                  title: 'El Visionat',
                  showMenuButton: true,
                ),

                // Contingut principal
                Expanded(child: _buildNarrowLayout(context, provider)),
              ],
            ),
          );
        }
      },
    );
  }

  // --- Contingut del Layout Desktop (sense menú lateral) ---
  Widget _buildWideLayoutContent(BuildContext context, HomeProvider provider) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila de Visionat Destacat i Perfil/Detalls
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Featured Visioning Section (esquerra, més ample)
                const Expanded(flex: 3, child: FeaturedVisioningSection()),
                const SizedBox(width: 16),
                // Perfil i Detalls (dreta, molt més estret)
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        padding: const EdgeInsets.all(0),
                        child: const UserProfileSummaryCard(),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        padding: const EdgeInsets.all(0),
                        child: MatchDetailsCard(
                          details: MatchDetails(
                            refereeName: 'Joan Garcia',
                            league: 'Lliga Catalana',
                            matchday: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Fila: Votacions i Activitats de formació, 50% - 50%
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Secció de Votacions (esquerra)
                const Expanded(
                  flex: 1,
                  child: VotingSection(),
                ),
                const SizedBox(width: 16),
                // Activitats de formació (dreta)
                Expanded(
                  flex: 1,
                  child: ChangeNotifierProvider(
                    create: (_) => ActivityControllerProvider(activities: mockActivities),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.school_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Activitats de formació',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Autoavaluació interactiva: mira el vídeo, respon les preguntes i comprova el teu progrés!',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 20),
                            TrainingActivitiesWidget(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 500), // Placeholder extra per scroll
          ],
        ),
      ),
    );
  }

  // --- Layout Estret (Mòbil) ---
  Widget _buildNarrowLayout(BuildContext context, HomeProvider provider) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Les targetes s'apilen verticalment en mòbil
            const FeaturedVisioningSection(),
            const SizedBox(height: 16),
            const UserProfileSummaryCard(),
            const SizedBox(height: 16),
            MatchDetailsCard(
              details: MatchDetails(
                refereeName: 'Joan Garcia',
                league: 'Lliga Catalana',
                matchday: 14,
              ),
            ),
            const SizedBox(height: 16),
            const VotingSection(),
            const SizedBox(height: 16),
            // --- Activitats de formació ---
            ChangeNotifierProvider(
              create: (_) =>
                  ActivityControllerProvider(activities: mockActivities),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.school_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Activitats de formació',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Autoavaluació interactiva: mira el vídeo, respon les preguntes i comprova el teu progrés!',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      TrainingActivitiesWidget(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 500), // Placeholder extra per scroll
          ],
        ),
      ),
    );
  }
}
