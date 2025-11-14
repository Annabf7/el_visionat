import 'package:el_visionat/features/auth/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_theme.dart';

class SideNavigationMenu extends StatelessWidget {
  const SideNavigationMenu({super.key});

  // La URL del logo que vam obtenir de Firebase Storage
  final String logoUrl =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/xiulet.svg?alt=media&token=bfac6951-619d-4c2d-962b-ea4a301843ed';

  void _handleProfileTap(BuildContext context) {
    // Navigate to profile; RequireAuth will redirect unauthenticated users.
    Navigator.pushNamed(context, '/profile');
  }

  @override
  Widget build(BuildContext context) {
    // use AppTheme for fixed sidebar colors

    return Container(
      width: 288,
      color: AppTheme.mostassa,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Transform.rotate(
                  angle: -2 * math.pi / 180.0,
                  child: SvgPicture.network(
                    logoUrl,
                    height: 80,
                    placeholderBuilder: (BuildContext context) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'EL VISIONAT',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.grisBody,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (ctx) {
                final current = ctx.watch<NavigationProvider>().currentRoute;

                bool isActive(String route) =>
                    current == route ||
                    (route == '/home' &&
                        (current == '/' || current == '/home'));

                return ListView(
                  children: [
                    _NavigationItem(
                      icon: Icons.home,
                      text: 'Inici',
                      isSelected: isActive('/home'),
                      onTap: () => Navigator.pushNamed(ctx, '/home'),
                    ),
                    _NavigationItem(
                      icon: Icons.videocam,
                      text: 'Visionats setmanals',
                      isSelected: isActive('/visionat'),
                      onTap: () => Navigator.pushNamed(ctx, '/visionat'),
                    ),
                    _NavigationItem(
                      icon: Icons.science,
                      text: 'El Laboratori Arbitral',
                    ),
                    _NavigationItem(
                      icon: Icons.fitness_center,
                      text: 'Condició Física',
                    ),
                    _NavigationItem(icon: Icons.people, text: 'Mentoria'),
                    _NavigationItem(
                      icon: Icons.emoji_events,
                      text: 'Supercopa Officiating Crew',
                    ),
                    _NavigationItem(icon: Icons.tv, text: 'ACB a Tv3'),
                    _NavigationItem(
                      icon: Icons.group_work,
                      text: 'Xarxa Arbitral',
                    ),
                    _NavigationItem(
                      icon: Icons.shopping_bag,
                      text: 'Merchandising',
                    ),
                  ],
                );
              },
            ),
          ),
          _NavigationItem(
            icon: Icons.person,
            text: 'Perfil i configuració',
            onTap: () => _handleProfileTap(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Pàgina de perfil de marcador de posició per a usuaris que han iniciat sessió.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    debugPrint(
      'ProfilePage.build — currentRoute=/profile, isAuthenticated=${authProvider.isAuthenticated}',
    );
    assert(
      authProvider.isAuthenticated,
      'ProfilePage built without authenticated user',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('El Meu Perfil')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Has iniciat sessió com: \n${authProvider.currentUserEmail ?? 'Usuari desconegut'}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (!context.mounted) return;
                final auth = context.read<AuthProvider>();
                final navigator = Navigator.of(context);
                await auth.signOut();
                if (!context.mounted) return;
                // Ensure explicit navigation to login to clear any existing
                // navigation stack and avoid landing on a stale protected page.
                navigator.pushNamedAndRemoveUntil('/login', (r) => false);
              },
              child: const Text('Tancar Sessió'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isSelected;
  final VoidCallback? onTap;
  const _NavigationItem({
    required this.icon,
    required this.text,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final backgroundColor = isSelected
        ? AppTheme.grisPistacho
        : Colors.transparent;
    final itemColor = isSelected ? AppTheme.porpraFosc : AppTheme.textBlackLow;

    // icon
    final Widget iconWidget = Icon(icon, color: itemColor);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(31),
                      offset: const Offset(0, 6),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              iconWidget,
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge?.copyWith(color: itemColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
