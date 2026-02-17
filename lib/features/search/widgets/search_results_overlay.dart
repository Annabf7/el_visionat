import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../providers/search_provider.dart';
import '../models/search_result.dart';

/// Overlay que mostra els resultats de cerca sota la barra de cerca
class SearchResultsOverlay extends StatelessWidget {
  final VoidCallback onClose;
  final Function(RefereeSearchResult)? onResultTap;

  const SearchResultsOverlay({
    super.key,
    required this.onClose,
    this.onResultTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        if (!searchProvider.isSearching) {
          return const SizedBox.shrink();
        }

        return Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 400),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildContent(context, searchProvider),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, SearchProvider searchProvider) {
    // Carregant
    if (searchProvider.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                'Carregant àrbitres...',
                style: TextStyle(color: AppTheme.grisPistacho, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Query massa curt
    if (searchProvider.query.trim().length < 2) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 48,
              color: AppTheme.porpraFosc.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Escriu almenys 2 caràcters per cercar',
              style: TextStyle(color: AppTheme.porpraFosc, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Sense resultats
    if (!searchProvider.hasResults) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search,
              size: 48,
              color: AppTheme.grisPistacho.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Cap resultat per "${searchProvider.query}"',
              style: const TextStyle(
                color: AppTheme.grisPistacho,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Llista de resultats
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: searchProvider.results.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: AppTheme.grisPistacho.withValues(alpha: 0.2),
      ),
      itemBuilder: (context, index) {
        final result = searchProvider.results[index];
        return _RefereeResultTile(
          result: result,
          onTap: () => _onResultTap(context, result),
        );
      },
    );
  }

  void _onResultTap(BuildContext context, RefereeSearchResult result) {
    if (onResultTap != null) {
      context.read<SearchProvider>().closeSearch();
      onClose();
      onResultTap!(result);
      return;
    }

    // Tancar la cerca
    context.read<SearchProvider>().closeSearch();
    onClose();

    // Navegar al perfil
    if (result.hasAccount && result.userId != null) {
      // Té compte: navegar al perfil complet
      Navigator.pushNamed(context, '/user-profile', arguments: result.userId);
    } else {
      // No té compte: mostrar perfil bàsic del registre
      _showBasicProfileDialog(context, result);
    }
  }

  void _showBasicProfileDialog(
    BuildContext context,
    RefereeSearchResult result,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.porpraFosc.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: AppTheme.porpraFosc,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                result.fullName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              Icons.badge_outlined,
              'Llicència',
              '#${result.llissenciaId}',
            ),
            const SizedBox(height: 12),
            if (result.categoriaRrtt != null) ...[
              _buildInfoRow(
                Icons.category_outlined,
                'Categoria',
                result.categoriaRrtt!,
              ),
              const SizedBox(height: 12),
            ],
            const Divider(),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.grisPistacho.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.grisPistacho.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.grisPistacho,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Aquest àrbitre encara no té compte a El Visionat',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.grisPistacho,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: AppTheme.grisPistacho),
            child: const Text('Tancar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.grisPistacho),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 14, color: AppTheme.grisPistacho),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.grisPistacho,
          ),
        ),
      ],
    );
  }
}

/// Tile individual per a cada resultat d'àrbitre
class _RefereeResultTile extends StatelessWidget {
  final RefereeSearchResult result;
  final VoidCallback onTap;

  const _RefereeResultTile({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: result.hasAccount
                    ? AppTheme.porpraFosc.withValues(alpha: 0.1)
                    : AppTheme.textBlackLow.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                result.hasAccount ? Icons.person : Icons.person_outline,
                color: result.hasAccount
                    ? AppTheme.porpraFosc
                    : AppTheme.textBlackLow,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.fullName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textBlackLow,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '#${result.llissenciaId}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textBlackLow,
                        ),
                      ),
                      if (result.categoriaRrtt != null) ...[
                        const Text(
                          ' · ',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textBlackLow,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            result.categoriaRrtt!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textBlackLow,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Indicador de compte
            if (result.hasAccount)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.verdeEncert.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 14, color: AppTheme.verdeEncert),
                    SizedBox(width: 4),
                    Text(
                      'Perfil',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.verdeEncert,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: AppTheme.grisPistacho.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
