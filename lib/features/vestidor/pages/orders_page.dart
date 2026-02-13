import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
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

  static const _heroImageUrl =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Fshopping_iaia.webp?alt=media&token=cb0c04f4-e61f-4ccc-a7d0-622428b0c948';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;

        if (isDesktop) {
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
                        title: 'Històric de compres',
                        showMenuButton: false,
                      ),
                      Expanded(child: _buildContent(context, isDesktop: true)),
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
                  title: 'Històric de compres',
                  showMenuButton: true,
                ),
                Expanded(child: _buildContent(context, isDesktop: false)),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildContent(BuildContext context, {required bool isDesktop}) {
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
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Colors.redAccent,
              ),
            ),
          );
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          if (isDesktop) {
            return Row(
              children: [
                Expanded(flex: 3, child: ClipRect(child: _buildHeroImage())),
                Expanded(flex: 5, child: _buildEmptyState()),
              ],
            );
          }
          return _buildEmptyState();
        }

        if (isDesktop) {
          return _buildDesktopLayout(orders);
        }
        return _buildMobileLayout(orders);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Desktop layout
  // ---------------------------------------------------------------------------

  Widget _buildHeroImage() {
    return CachedNetworkImage(
      imageUrl: _heroImageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.topCenter,
      placeholder: (_, __) => Container(
        color: AppTheme.porpraFosc,
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.mostassa),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        color: AppTheme.porpraFosc,
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            color: AppTheme.grisPistacho,
            size: 48,
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(List<VestidorOrder> orders) {
    return Row(
      children: [
        Expanded(flex: 3, child: ClipRect(child: _buildHeroImage())),
        Expanded(flex: 5, child: _buildTableContent(orders)),
      ],
    );
  }

  Widget _buildTableContent(List<VestidorOrder> orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Títol i subtítol
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Històric de compres',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 26,
                  color: AppTheme.grisPistacho,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Revisa les teves compres i comandes',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppTheme.grisPistacho.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Capçalera de la taula
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: _buildTableHeader(),
        ),
        Divider(
          height: 1,
          indent: 32,
          endIndent: 32,
          color: AppTheme.grisPistacho.withValues(alpha: 0.15),
        ),
        // Files de dades
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            itemCount: orders.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: AppTheme.grisPistacho.withValues(alpha: 0.08),
            ),
            itemBuilder: (context, index) => _buildTableRow(orders[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    const style = TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppTheme.lilaMitja,
      letterSpacing: 0.5,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: const [
          SizedBox(width: 100, child: Text('COMANDA', style: style)),
          SizedBox(width: 48), // thumbnail
          SizedBox(width: 12),
          Expanded(flex: 2, child: Text('DATA', style: style)),
          Expanded(flex: 3, child: Text('ARTICLES', style: style)),
          SizedBox(
            width: 60,
            child: Text('QTY', style: style, textAlign: TextAlign.center),
          ),
          Expanded(flex: 2, child: Text('ESTAT', style: style)),
          SizedBox(
            width: 100,
            child: Text('PREU', style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(VestidorOrder order) {
    final totalQty = order.items.fold<int>(
      0,
      (sum, item) => sum + ((item['quantity'] ?? 1) as int),
    );
    final itemNames = order.items
        .map((item) => (item['name'] ?? '') as String)
        .join(', ');

    // Agafar la primera imageUrl disponible dels items
    final firstImage = order.items
        .map((item) => item['imageUrl'] as String?)
        .firstWhere((url) => url != null && url.isNotEmpty, orElse: () => null);

    return InkWell(
      onTap: () {
        if (order.trackingUrl != null && order.trackingUrl!.isNotEmpty) {
          _launchTrackingUrl(order.trackingUrl!);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            // Order ID
            SizedBox(
              width: 100,
              child: Text(
                '#${order.id.substring(0, min(8, order.id.length))}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mostassa,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Thumbnail
            _buildThumbnail(firstImage),
            const SizedBox(width: 12),
            // Data
            Expanded(
              flex: 2,
              child: Text(
                _formatDate(order.createdAt),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                ),
              ),
            ),
            // Articles
            Expanded(
              flex: 3,
              child: Text(
                itemNames,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // QTY
            SizedBox(
              width: 60,
              child: Text(
                '$totalQty',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                ),
              ),
            ),
            // Estat
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildStatusBadge(order.status, order.statusLabel),
              ),
            ),
            // Preu
            SizedBox(
              width: 100,
              child: Text(
                order.totalFormatted,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(String? imageUrl) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.grisPistacho.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.grisPistacho.withValues(alpha: 0.12),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => const Icon(
                Icons.checkroom_rounded,
                color: AppTheme.mostassa,
                size: 22,
              ),
              errorWidget: (_, __, ___) => const Icon(
                Icons.checkroom_rounded,
                color: AppTheme.mostassa,
                size: 22,
              ),
            )
          : const Icon(
              Icons.checkroom_rounded,
              color: AppTheme.mostassa,
              size: 22,
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mobile layout
  // ---------------------------------------------------------------------------

  Widget _buildMobileLayout(List<VestidorOrder> orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Històric de compres',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.porpraFosc,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Revisa les teves compres i comandes',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppTheme.grisPistacho.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OrderCard(
                order: orders[index],
                onTrackingTap: _launchTrackingUrl,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(width: 0.5, height: 110, color: AppTheme.mostassa),
          Padding(
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
                    color: AppTheme.mostassa,
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
                  icon: const Icon(
                    Icons.checkroom_rounded,
                    color: AppTheme.mostassa,
                  ),
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
        ],
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

  Future<void> _launchTrackingUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// =============================================================================
// Mobile order card
// =============================================================================

class _OrderCard extends StatelessWidget {
  final VestidorOrder order;
  final void Function(String url)? onTrackingTap;

  const _OrderCard({required this.order, this.onTrackingTap});

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
            // Tracking link
            if (order.trackingUrl != null && order.trackingUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => onTrackingTap?.call(order.trackingUrl!),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_shipping_outlined,
                      size: 16,
                      color: AppTheme.mostassa,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Segueix el teu enviament',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mostassa,
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.mostassa.withValues(
                          alpha: 0.5,
                        ),
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
