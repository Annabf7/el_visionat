import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/core/navigation/side_navigation_menu.dart';
import 'package:el_visionat/core/widgets/global_header.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../providers/vestidor_provider.dart';
import '../widgets/vestidor_hero.dart';
import '../widgets/product_card.dart';
import '../widgets/product_detail_sheet.dart';

class VestidorPage extends StatefulWidget {
  const VestidorPage({super.key});

  @override
  State<VestidorPage> createState() => _VestidorPageState();
}

class _VestidorPageState extends State<VestidorPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VestidorProvider>().loadProducts();
    });
  }

  void _showProductDetail(BuildContext context, int productId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailSheet(productId: productId),
    );
  }

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
                SizedBox(
                  width: 288,
                  height: double.infinity,
                  child: const SideNavigationMenu(),
                ),
                Expanded(
                  child: Column(
                    children: [
                      GlobalHeader(
                        scaffoldKey: _scaffoldKey,
                        title: 'El Vestidor',
                        showMenuButton: false,
                      ),
                      Expanded(
                        child: _buildContent(context, isLargeScreen: true),
                      ),
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
                  title: 'El Vestidor',
                  showMenuButton: true,
                ),
                Expanded(
                  child: _buildContent(context, isLargeScreen: false),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildContent(BuildContext context, {required bool isLargeScreen}) {
    final provider = context.watch<VestidorProvider>();

    return RefreshIndicator(
      color: AppTheme.mostassa,
      onRefresh: () => provider.loadProducts(refresh: true),
      child: CustomScrollView(
        slivers: [
          // Hero section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: VestidorHero(totalProducts: provider.totalProducts),
            ),
          ),

          // Estat de càrrega inicial
          if (provider.isLoadingProducts && provider.products.isEmpty)
            SliverToBoxAdapter(
              child: _buildSkeletonGrid(isLargeScreen),
            )
          // Estat d'error
          else if (provider.hasError && provider.products.isEmpty)
            SliverToBoxAdapter(child: _buildErrorState(provider.error!))
          // Estat buit
          else if (!provider.isLoadingProducts && provider.products.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState())
          // Graella de productes
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isLargeScreen ? 4 : 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = provider.products[index];
                    return ProductCard(
                      product: product,
                      onTap: () => _showProductDetail(context, product.id),
                    );
                  },
                  childCount: provider.products.length,
                ),
              ),
            ),

          // Botó per carregar més
          if (provider.hasMoreProducts && !provider.isLoadingProducts)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () => provider.loadProducts(),
                    icon: const Icon(
                      Icons.expand_more_rounded,
                      color: AppTheme.mostassa,
                    ),
                    label: const Text(
                      'Carregar m\u00e9s productes',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mostassa,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Indicador de càrrega al final
          if (provider.isLoadingProducts && provider.products.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.mostassa,
                    ),
                  ),
                ),
              ),
            ),

          // Padding final
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  /// Graella esquelet per l'estat de càrrega
  Widget _buildSkeletonGrid(bool isLargeScreen) {
    final count = isLargeScreen ? 8 : 4;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isLargeScreen ? 4 : 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemCount: count,
        itemBuilder: (_, __) => Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.grisBody.withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.grisBody.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 10,
                        width: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.grisBody.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Estat d'error amb botó de reintentar
  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 64,
            color: AppTheme.mostassa,
          ),
          const SizedBox(height: 16),
          const Text(
            'No s\'han pogut carregar els productes',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.porpraFosc,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppTheme.grisPistacho.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                context.read<VestidorProvider>().loadProducts(refresh: true),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Torna a provar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.mostassa,
              foregroundColor: AppTheme.porpraFosc,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Estat buit (sense productes)
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: AppTheme.lilaMitja.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Encara no hi ha productes a la botiga',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.porpraFosc,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Els productes apareixeran aqu\u00ed quan estiguin disponibles',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppTheme.grisPistacho.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
