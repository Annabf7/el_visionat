import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/features/auth/providers/auth_provider.dart';
import 'package:el_visionat/features/notifications/providers/notification_provider.dart';
import 'package:el_visionat/features/vestidor/providers/cart_provider.dart';
import 'package:el_visionat/features/notifications/widgets/notification_badge.dart';
import 'package:el_visionat/features/notifications/widgets/notification_dropdown.dart';
import 'package:el_visionat/features/search/widgets/global_search_bar.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

/// Header global reutilitzable per a tota l'aplicació
/// Inclou menú hamburguesa, cerca, perfil, notificacions i menú desplegable de configuració
class GlobalHeader extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final String title;
  final bool showSearch;
  final bool showMenuButton;

  const GlobalHeader({
    super.key,
    this.scaffoldKey,
    this.title = 'El Visionat',
    this.showSearch = true,
    this.showMenuButton = true,
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

  void _showNotificationsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle per arrossegar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.grisPistacho.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Dropdown de notificacions
            const Expanded(
              child: NotificationDropdown(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.porpraFosc,
      elevation: 0,
      leading: showMenuButton
          ? IconButton(
              onPressed: () => scaffoldKey?.currentState?.openDrawer(),
              icon: const Icon(Icons.menu, color: AppTheme.white),
            )
          : null,
      automaticallyImplyLeading: showMenuButton,
      title: showSearch
          ? const GlobalSearchBar()
          : Text(
              title,
              style: const TextStyle(
                color: AppTheme.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
      actions: [
        // Botó Perfil (només en desktop)
        LayoutBuilder(
          builder: (context, constraints) {
            // Només mostrar en pantalles grans (desktop)
            if (MediaQuery.of(context).size.width > 900) {
              return TextButton(
                onPressed: () => Navigator.pushNamed(context, '/profile'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text(
                  'Perfil',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              );
            }
            return const SizedBox.shrink(); // No mostrar res en mòbil
          },
        ),

        // Icona de designacions
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/designations'),
          icon: const Icon(Icons.euro_outlined, color: AppTheme.mostassa),
          tooltip: 'Designacions',
        ),

        // Icona carretó (només si hi ha items)
        Consumer<CartProvider>(
          builder: (context, cart, _) {
            if (cart.isEmpty) return const SizedBox.shrink();
            return IconButton(
              onPressed: () => Navigator.pushNamed(context, '/cart'),
              icon: NotificationBadge(
                count: cart.itemCount,
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: AppTheme.white,
                ),
              ),
              tooltip: 'Carretó',
            );
          },
        ),

        // Icona campana (notificacions)
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            final isMobile = MediaQuery.of(context).size.width < 600;

            if (isMobile) {
              // Mobile: Clic directe per obrir modal
              return IconButton(
                onPressed: () => _showNotificationsModal(context),
                icon: NotificationBadge(
                  count: notificationProvider.unreadCount,
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppTheme.white,
                  ),
                ),
              );
            } else {
              // Desktop: Hover per mostrar dropdown
              return PopupMenuButton(
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.transparent,
                elevation: 0,
                padding: EdgeInsets.zero,
                icon: NotificationBadge(
                  count: notificationProvider.unreadCount,
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppTheme.white,
                  ),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    padding: EdgeInsets.zero,
                    child: const NotificationDropdown(),
                  ),
                ],
              );
            }
          },
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
                Navigator.pushNamed(context, '/designations');
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
                    'Designacions',
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
