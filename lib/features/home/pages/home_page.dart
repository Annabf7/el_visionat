import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:el_visionat/core/navigation/side_navigation_menu.dart';
import '../widgets/featured_visioning_section.dart';
import '../widgets/user_profile_summary_card.dart';
import 'package:el_visionat/features/voting/index.dart';
import '../providers/home_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenim el Provider per a les dades, assegurant que ja existeix
    final provider = context.watch<HomeProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 900;

        // 1. Scaffold principal
        return Scaffold(
          // L'AppBar només es mostra en mòbil (layout estret)
          appBar: isLargeScreen
              ? null
              : AppBar(
                  title: Text(
                    'El Visionat',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                ),

          // El Drawer (menú lateral en mode mòbil)
          drawer: isLargeScreen ? null : const SideNavigationMenu(),

          // El cos del Scaffold s'adapta
          body: isLargeScreen
              ? _buildWideLayout(context, provider)
              : _buildNarrowLayout(context, provider),
        );
      },
    );
  }

  // --- Layout Ample (Web/Tablet) ---
  Widget _buildWideLayout(BuildContext context, HomeProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Columna 1: Menú Lateral (Amplada fixa de 288px)
        const SizedBox(
          width: 288,
          child: SideNavigationMenu(), // Ara el Spacer funciona
        ),

        // Columna 2: Contingut Principal (Expandeix a la resta d'espai)
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopSearchRow(context),
                  const SizedBox(height: 16),

                  // Fila de Visionat Destacat i Perfil (Layout de la dreta)
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Featured Visioning Section (2/3 de l'espai central)
                      Expanded(flex: 2, child: FeaturedVisioningSection()),
                      SizedBox(width: 16),
                      // User Profile Card (1/3 de l'espai central)
                      Expanded(flex: 1, child: UserProfileSummaryCard()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Secció de Votacions (Full width)
                  const VotingSection(),
                  const SizedBox(height: 500), // Placeholder extra per scroll
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Layout Estret (Mòbil) ---
  Widget _buildNarrowLayout(BuildContext context, HomeProvider provider) {
    return const SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Les targetes s'apilen verticalment en mòbil
            FeaturedVisioningSection(),
            SizedBox(height: 16),
            UserProfileSummaryCard(),
            SizedBox(height: 16),
            VotingSection(),
            SizedBox(height: 500), // Placeholder extra per scroll
          ],
        ),
      ),
    );
  }

  // Widget placeholder per a la barra superior de cerca del layout web
  Widget _buildTopSearchRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          const SizedBox(width: 32),
          Expanded(
            child: Container(
              height: 48,
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: Text(
                  'Barra de Cerca',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Icon(Icons.settings, color: Theme.of(context).colorScheme.onSurface),
        ],
      ),
    );
  }
}
