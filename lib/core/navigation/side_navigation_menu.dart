import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:el_visionat/core/navigation/navigation_provider.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/features/auth/providers/auth_provider.dart';

class SideNavigationMenu extends StatelessWidget {
  const SideNavigationMenu({super.key});

  // La URL del logo que obtenim de Firebase Storage
  final String logoUrl =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/foreground.png?alt=media&token=2ce5c7b4-1e03-43a0-8393-0e13da09135b';

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
                  child: Image.network(
                    logoUrl,
                    height: 80,
                    cacheHeight: 240,
                    filterQuality: FilterQuality.high,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
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
                final authProvider = ctx.watch<AuthProvider>();
                final isMentor = authProvider.userProfile?.isMentor ?? false;

                bool isActive(String route) =>
                    current == route ||
                    (route == '/home' &&
                        (current == '/' || current == '/home'));

                final items = <Widget>[
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
                    icon: Icons.assessment,
                    text: 'Informes + Test',
                    isSelected: isActive('/reports'),
                    onTap: () => Navigator.pushNamed(ctx, '/reports'),
                  ),
                  _NavigationItem(
                    icon: Icons.assignment,
                    text: 'Les meves designacions',
                    isSelected: isActive('/designations'),
                    onTap: () => Navigator.pushNamed(ctx, '/designations'),
                  ),
                  _NavigationItem(
                    icon: Icons.checklist,
                    text: "Gestiona't",
                    isSelected: isActive('/gestiona-t'),
                    onTap: () => Navigator.pushNamed(ctx, '/gestiona-t'),
                  ),
                  _NavigationItem(
                    icon: Icons.science,
                    text: 'El Laboratori Arbitral',
                    isSelected: isActive('/laboratori'),
                    onTap: () => Navigator.pushNamed(ctx, '/laboratori'),
                  ),
                  _NavigationItem(
                    icon: Icons.psychology,
                    text: 'Neurovisionat',
                    isSelected: isActive('/neurovisionat'),
                    onTap: () => Navigator.pushNamed(ctx, '/neurovisionat'),
                  ),
                  if (isMentor)
                    _NavigationItem(
                      icon: Icons.people,
                      text: 'Mentoria',
                      isSelected: isActive('/mentoria'),
                      onTap: () => Navigator.pushNamed(ctx, '/mentoria'),
                    ),
                  _NavigationItem(
                    icon: Icons.checkroom,
                    text: 'El vestidor',
                    isSelected: isActive('/vestidor'),
                    onTap: () => Navigator.pushNamed(ctx, '/vestidor'),
                  ),
                ];

                return LayoutBuilder(
                  builder: (context, constraints) {
                    // ~64px per ítem (margin 16 + padding 24 + contingut 24)
                    final minHeight = items.length * 64.0;
                    if (constraints.maxHeight >= minHeight) {
                      // Desktop: distribució equitativa
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: items,
                      );
                    }
                    // Mòbil: scroll vertical
                    return ListView(children: items);
                  },
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
          // Micro-text de marca (només desktop)
          _DesktopBrandFooter(),
        ],
      ),
    );
  }
}

class _DesktopBrandFooter extends StatelessWidget {
  const _DesktopBrandFooter();

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    if (!isDesktop) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 32, right: 16, top: 8),
      child: Row(
        children: [
          const Spacer(),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text(
                '© 2025 · El Visionat',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  letterSpacing: 0.1,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Desenvolupat per ABorrasdesign',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.black45,
                  letterSpacing: 0.1,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
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
                      color: Colors.black.withValues(alpha: 0.12),
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
