import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:el_visionat/core/navigation/side_navigation_menu.dart';
import 'package:el_visionat/core/widgets/global_header.dart';
import '../widgets/featured_visioning_section.dart';
import '../widgets/referee_team_card.dart';
import 'package:el_visionat/features/voting/index.dart';
import '../providers/home_provider.dart';
import 'package:el_visionat/features/training/index.dart';
import 'package:el_visionat/features/auth/providers/auth_provider.dart';
import 'package:el_visionat/features/notifications/providers/notification_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    // Inicialitzar NotificationProvider després que el widget estigui creat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final notificationProvider = context.read<NotificationProvider>();

      if (auth.isAuthenticated && auth.currentUserUid != null) {
        debugPrint(
          '[HomePage] Inicialitzant NotificationProvider amb UID: ${auth.currentUserUid}',
        );
        notificationProvider.initialize(auth.currentUserUid!);
      } else {
        debugPrint(
          '[HomePage] Usuari no autenticat, no s\'inicialitza NotificationProvider',
        );
      }
    });
  }

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
            // Fila de Visionat Destacat i Perfil/Detalls - Ocupa tota l'alçada disponible
            LayoutBuilder(
              builder: (context, constraints) {
                // Calculem l'alçada disponible (alçada de la pantalla - header - padding)
                final screenHeight = MediaQuery.of(context).size.height;
                final availableHeight =
                    screenHeight - 80 - 32; // 80 = header aprox, 32 = padding

                return SizedBox(
                  height: availableHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Featured Visioning Section (esquerra, més ample)
                      const Expanded(
                        flex: 3,
                        child: FeaturedVisioningSection(),
                      ),
                      const SizedBox(width: 16),
                      // Equip Arbitral i Detalls (dreta, molt més estret)
                      Expanded(
                        flex: 1,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 400,
                                ),
                                padding: const EdgeInsets.all(0),
                                child: const RefereeTeamCard(),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 400,
                                ),
                                padding: const EdgeInsets.all(0),
                                child: const WeeklyFocusCard(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Fila: Votacions i Activitats de formació, 50% - 50%
            // Amb alçada fixa i scroll vertical per mantenir equilibri visual
            SizedBox(
              height: 1000, // Alçada fixa per ambdues columnes
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Secció de Votacions (esquerra) amb scroll
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(child: const VotingSection()),
                  ),
                  const SizedBox(width: 16),
                  // Activitats de formació (dreta) amb scroll
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: ChangeNotifierProvider(
                        create: (_) => ActivityControllerProvider(
                          activities: mockActivities,
                        ),
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
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        'Activitats de formació',
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32), // Padding final professional
          ],
        ),
      ),
    );
  }

  // --- Layout Estret (Mòbil) ---
  Widget _buildNarrowLayout(BuildContext context, HomeProvider provider) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // FeaturedVisioningSection sense padding
          const FeaturedVisioningSection(),
          const SizedBox(height: 16),
          // La resta de widgets amb padding lateral
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const RefereeTeamCard(),
                const SizedBox(height: 16),
                const WeeklyFocusCard(),
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
                              Flexible(
                                child: Text(
                                  'Activitats de formació',
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
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
                const SizedBox(height: 32), // Padding final professional
              ],
            ),
          ),
        ],
      ),
    );
  }
}
