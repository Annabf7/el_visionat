import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/features/search/providers/search_provider.dart';
import 'package:el_visionat/features/search/models/search_result.dart';
import 'package:el_visionat/features/search/widgets/search_results_overlay.dart';

/// Barra de cerca especial per a Mentoria
class MentoriaSearchBar extends StatefulWidget {
  final Function(RefereeSearchResult) onResultSelected;

  const MentoriaSearchBar({super.key, required this.onResultSelected});

  @override
  State<MentoriaSearchBar> createState() => _MentoriaSearchBarState();
}

class _MentoriaSearchBarState extends State<MentoriaSearchBar> {
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
        width:
            300, // Reduced width for overlay to fit constraints better if needed
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 50),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: SearchResultsOverlay(
                onClose: _closeSearch,
                onResultTap: (result) {
                  widget.onResultSelected(result);
                  _closeSearch();
                },
              ),
            ),
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
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.grisPistacho),
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          style: const TextStyle(color: AppTheme.porpraFosc, fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'Cerca àrbitre per nom...',
            hintStyle: TextStyle(color: AppTheme.porpraFosc),
            prefixIcon: Icon(Icons.search, color: AppTheme.porpraFosc),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) {
            context.read<SearchProvider>().updateSearch(value);
            // Assegurar que l'overlay es mostra
            if (_overlayEntry == null && _focusNode.hasFocus) {
              _showOverlay();
            }
          },
        ),
      ),
    );
  }
}
