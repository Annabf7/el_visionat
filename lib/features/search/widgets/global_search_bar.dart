import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../providers/search_provider.dart';
import 'search_results_overlay.dart';

/// Barra de cerca global amb overlay de resultats
class GlobalSearchBar extends StatefulWidget {
  const GlobalSearchBar({super.key});

  @override
  State<GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends State<GlobalSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      context.read<SearchProvider>().startSearch();
      _showOverlay();
    } else {
      // Petit delay per permetre clicar els resultats
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_focusNode.hasFocus && mounted) {
          _removeOverlay();
          context.read<SearchProvider>().closeSearch();
        }
      });
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(-50, 45),
          child: SearchResultsOverlay(
            onClose: _closeSearch,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _closeSearch() {
    _controller.clear();
    _focusNode.unfocus();
    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          style: const TextStyle(color: AppTheme.white, fontSize: 14),
          onChanged: (value) {
            context.read<SearchProvider>().updateSearch(value);
            // Assegurar que l'overlay es mostra
            if (_overlayEntry == null && _focusNode.hasFocus) {
              _showOverlay();
            } else {
              _overlayEntry?.markNeedsBuild();
            }
          },
          decoration: InputDecoration(
            hintText: 'Cerca àrbitres...',
            hintStyle: TextStyle(
              color: AppTheme.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: AppTheme.white.withValues(alpha: 0.7),
              size: 20,
            ),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close,
                      color: AppTheme.white.withValues(alpha: 0.7),
                      size: 18,
                    ),
                    onPressed: () {
                      _controller.clear();
                      context.read<SearchProvider>().updateSearch('');
                      _overlayEntry?.markNeedsBuild();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
          ),
        ),
      ),
    );
  }
}
