import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/core/navigation/side_navigation_menu.dart';
import 'package:el_visionat/core/widgets/global_header.dart';
import '../providers/cart_provider.dart';
import '../providers/vestidor_provider.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/product_detail_sheet.dart';

/// Pàgina del carretó de compra
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
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
                        title: 'Carretó',
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
                  title: 'Carretó',
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
    final cart = context.watch<CartProvider>();

    if (cart.isEmpty) {
      return _buildEmptyState(context);
    }

    // CustomScrollView + SliverFillRemaining centra verticalment
    // quan el contingut és més petit que la pantalla, i fa scroll si no hi cap
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Productes + resum dins un recuadre blanc
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.porpraFosc.withValues(alpha: 0.15),
                          width: 2.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...cart.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: CartItemCard(
                                item: item,
                                onQuantityChanged: (qty) =>
                                    cart.updateQuantity(item.syncVariantId, qty),
                                onRemove: () =>
                                    cart.removeItem(item.syncVariantId),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildOrderSummary(context, cart),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Suggerències — fora del ConstrainedBox, més ample
                  _buildSuggestions(context, cart),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.grisPistacho.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.porpraFosc,
                ),
              ),
              Text(
                '${cart.subtotal.toStringAsFixed(2).replaceAll('.', ',')} EUR',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.porpraFosc,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Enviament calculat al següent pas',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppTheme.porpraFosc.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/checkout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.mostassa,
                foregroundColor: AppTheme.porpraFosc,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                elevation: 0,
              ),
              child: const Text('Continuar amb la compra'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(BuildContext context, CartProvider cart) {
    final vestidor = context.watch<VestidorProvider>();
    final products = vestidor.products;

    // Productes que no estan al carretó
    final cartProductIds = cart.items.map((i) => i.syncProductId).toSet();
    final suggestions = products
        .where((p) => !cartProductIds.contains(p.id))
        .take(4)
        .toList();

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const Text(
          'Potser t\'interessa',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            color: AppTheme.mostassa,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 14,
          children: suggestions.map((product) {
            final thumbnailUrl = vestidor.getCustomThumbnail(product);
            return GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ProductDetailSheet(productId: product.id),
                );
              },
              child: SizedBox(
                width: 140,
                height: 200,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.grisPistacho.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: double.infinity,
                            child: thumbnailUrl != null
                                ? Image.network(
                                    thumbnailUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _suggestionPlaceholder(),
                                  )
                                : _suggestionPlaceholder(),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.porpraFosc,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _suggestionPlaceholder() {
    return Container(
      color: AppTheme.grisPistacho.withValues(alpha: 0.06),
      child: const Icon(
        Icons.checkroom_rounded,
        color: AppTheme.grisPistacho,
        size: 32,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: AppTheme.lilaMitja.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 24),
            const Text(
              'El teu carretó és buit',
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
              'Afegeix productes des d\'El Vestidor',
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
    );
  }
}
