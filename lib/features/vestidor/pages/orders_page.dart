import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/core/navigation/side_navigation_menu.dart';
import 'package:el_visionat/core/widgets/global_header.dart';
import 'package:el_visionat/features/auth/index.dart';
import '../models/vestidor_order.dart';
import '../services/orders_service.dart';

/// Pàgina d'historial de comandes del vestidor
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 900;

        if (isLargeScreen) {
          return Scaffold(
            key: _scaffoldKey,
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
                        title: 'Les meves comandes',
                        showMenuButton: false,
                      ),
                      Expanded(child: _buildContent(context)),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            key: _scaffoldKey,
            drawer: const SideNavigationMenu(),
            body: Column(
              children: [
                GlobalHeader(
                  scaffoldKey: _scaffoldKey,
                  title: 'Les meves comandes',
                  showMenuButton: true,
                ),
                Expanded(child: _buildContent(context)),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.currentUserUid;

    if (uid == null) {
      return const Center(
        child: Text(
          'Cal estar autenticat',
          style: TextStyle(fontFamily: 'Inter', color: AppTheme.grisPistacho),
        ),
      );
    }

    return StreamBuilder<List<VestidorOrder>>(
      stream: OrdersService.ordersStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.porpraFosc),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error carregant comandes: ${snapshot.error}',
              style: const TextStyle(fontFamily: 'Inter', color: Colors.redAccent),
            ),
          );
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OrderCard(order: orders[index]),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: AppTheme.lilaMitja.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 24),
            const Text(
              'Encara no tens comandes',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.porpraFosc,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Les teves compres apareixeran aquí',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppTheme.grisPistacho.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/vestidor'),
              icon: const Icon(Icons.checkroom_rounded, color: AppTheme.mostassa),
              label: const Text(
                'Anar a la botiga',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mostassa,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Targeta que mostra un resum de la comanda
class _OrderCard extends StatelessWidget {
  final VestidorOrder order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.grisPistacho.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Capçalera: data + status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(order.createdAt),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppTheme.grisPistacho.withValues(alpha: 0.6),
                  ),
                ),
                _buildStatusBadge(order.status, order.statusLabel),
              ],
            ),
            const SizedBox(height: 12),
            // Llista d'articles
            ...order.items.map((item) {
              final name = (item['name'] ?? '') as String;
              final qty = (item['quantity'] ?? 1) as int;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '$name x$qty',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppTheme.porpraFosc,
                  ),
                ),
              );
            }),
            const Divider(height: 20),
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.porpraFosc,
                  ),
                ),
                Text(
                  order.totalFormatted,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.porpraFosc,
                  ),
                ),
              ],
            ),
            // Tracking link si disponible
            if (order.trackingUrl != null && order.trackingUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final uri = Uri.parse(order.trackingUrl!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_shipping_outlined,
                        size: 16, color: AppTheme.mostassa),
                    const SizedBox(width: 6),
                    Text(
                      'Segueix el teu enviament',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mostassa,
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.mostassa.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, String label) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'paid':
      case 'submitted_to_printful':
      case 'in_production':
        bgColor = AppTheme.mostassa.withValues(alpha: 0.12);
        textColor = AppTheme.mostassa;
        break;
      case 'shipped':
        bgColor = AppTheme.lilaMitja.withValues(alpha: 0.12);
        textColor = AppTheme.lilaMitja;
        break;
      case 'delivered':
        bgColor = AppTheme.verdeEncert.withValues(alpha: 0.12);
        textColor = AppTheme.verdeEncert;
        break;
      case 'cancelled':
      case 'failed':
        bgColor = Colors.redAccent.withValues(alpha: 0.1);
        textColor = Colors.redAccent;
        break;
      default:
        bgColor = AppTheme.grisPistacho.withValues(alpha: 0.1);
        textColor = AppTheme.grisPistacho;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year;
    return '$d/$m/$y';
  }
}
