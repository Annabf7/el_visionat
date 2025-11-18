import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/features/auth/providers/auth_provider.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

/// Header global reutilitzable per a tota l'aplicació
/// Inclou menú hamburguesa, cerca, perfil, notificacions i menú desplegable de configuració
class GlobalHeader extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final String title;
  final bool showSearch;

  const GlobalHeader({
    super.key,
    this.scaffoldKey,
    this.title = 'El Visionat',
    this.showSearch = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _handleLogout(BuildContext context) async {
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.signOut();

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      debugPrint('Error durant logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.porpraFosc,
      elevation: 0,
      leading: IconButton(
        onPressed: () => scaffoldKey?.currentState?.openDrawer(),
        icon: const Icon(Icons.menu, color: AppTheme.white),
      ),
      title: showSearch
          ? Container(
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                style: const TextStyle(color: AppTheme.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cerca partits, àrbitres, situacions...',
                  hintStyle: TextStyle(
                    color: AppTheme.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppTheme.white.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            )
          : Text(
              title,
              style: const TextStyle(
                color: AppTheme.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
      actions: [
        // Botó Perfil
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/profile'),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: const Text(
            'Perfil',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),

        // Icona campana (notificacions)
        IconButton(
          onPressed: () {
            // TODO: Implementar notificacions
            debugPrint('Notificacions');
          },
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined, color: AppTheme.white),
              // Punt roig per indicar notificacions noves
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Menú desplegable de configuració
        PopupMenuButton<String>(
          icon: const Icon(Icons.settings, color: AppTheme.white),
          color: AppTheme.textBlackLow,
          offset: const Offset(0, 40),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                Navigator.pushNamed(context, '/profile');
                break;
              case 'history':
                debugPrint('historial placeholder');
                break;
              case 'accounting':
                Navigator.pushNamed(context, '/accounting');
                break;
              case 'logout':
                _handleLogout(context);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: AppTheme.white, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Perfil',
                    style: TextStyle(color: AppTheme.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'history',
              child: Row(
                children: [
                  Icon(Icons.history, color: AppTheme.white, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Historial de compra',
                    style: TextStyle(color: AppTheme.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'accounting',
              child: Row(
                children: [
                  Icon(Icons.account_balance, color: AppTheme.white, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Comptabilitat',
                    style: TextStyle(color: AppTheme.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red[300], size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Log Out',
                    style: TextStyle(color: Colors.red[300], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(width: 8),
      ],
    );
  }
}
