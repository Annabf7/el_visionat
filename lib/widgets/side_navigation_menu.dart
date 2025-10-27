import 'package:el_visionat/providers/auth_provider.dart';
import 'package:el_visionat/screens/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class SideNavigationMenu extends StatelessWidget {
  const SideNavigationMenu({super.key});

  // La URL del logo que vam obtenir de Firebase Storage
  final String logoUrl =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/xiulet.svg?alt=media&token=bfac6951-619d-4c2d-962b-ea4a301843ed';

  void _handleProfileTap(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // L'usuari no ha iniciat sessió, reseteja l'estat i navega a LoginPage
      context.read<AuthProvider>().reset();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      // L'usuari ha iniciat sessió, navega a una pàgina de perfil
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 288,
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 48, 32, 0),
            child: SvgPicture.network(
              logoUrl,
              height: 90,
              placeholderBuilder: (BuildContext context) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: const [
                _NavigationItem(
                  icon: Icons.home,
                  text: 'Inici',
                  isSelected: true,
                ),
                _NavigationItem(
                  icon: Icons.videocam,
                  text: 'Visionats setmanals',
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
                _NavigationItem(icon: Icons.group_work, text: 'Xarxa Arbitral'),
                _NavigationItem(
                  icon: Icons.shopping_bag,
                  text: 'Merchandising',
                ),
              ],
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
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('El Meu Perfil'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Has iniciat sessió com: \n${user?.email ?? 'Usuari desconegut'}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                // Tanquem la pàgina de perfil per tornar a la HomePage
                if (context.mounted) {
                  Navigator.pop(context);
                }
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final backgroundColor =
        isSelected ? colorScheme.primary.withAlpha(51) : Colors.transparent;
    final itemColor = isSelected ? colorScheme.primary : colorScheme.onSurface;

    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: itemColor),
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
