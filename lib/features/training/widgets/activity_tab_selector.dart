import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_controller.dart';

const Color mostassa = Color(0xFFFFC107); // Mostassa (amber)

/// Widget que mostra les pestanyes per seleccionar l'activitat actual.
/// Mostra fletxes als costats quan hi ha més activitats fora de la vista.
class ActivityTabSelector extends StatefulWidget {
  const ActivityTabSelector({super.key});

  @override
  State<ActivityTabSelector> createState() => _ActivityTabSelectorState();
}

class _ActivityTabSelectorState extends State<ActivityTabSelector> {
  final ScrollController _scrollController = ScrollController();
  bool _showRightArrow = false;
  bool _showLeftArrow = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkOverflow);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
  }

  void _checkOverflow() {
    if (!mounted || !_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final shouldShowRight = maxScroll > 0 && currentScroll < maxScroll - 1;
    final shouldShowLeft = currentScroll > 1;
    if (shouldShowRight != _showRightArrow ||
        shouldShowLeft != _showLeftArrow) {
      setState(() {
        _showRightArrow = shouldShowRight;
        _showLeftArrow = shouldShowLeft;
      });
    }
  }

  void _scrollRight() {
    final target = (_scrollController.offset + 150).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollLeft() {
    final target = (_scrollController.offset - 150).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkOverflow);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityControllerProvider>(
      builder: (context, controller, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());

        return SizedBox(
          height: 52,
          child: Stack(
            children: [
              // Llista horitzontal de pestanyes
              SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: List.generate(controller.activities.length, (i) {
                    final isSelected = controller.selectedActivityIndex == i;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => controller.selectActivity(i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected
                                ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.12)
                                : Colors.transparent,
                          ),
                          child: Text(
                            'Activitat ${i + 1}',
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              fontSize: 15,
                              color: isSelected
                                  ? mostassa
                                  : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Fletxa esquerra amb gradient
              if (_showLeftArrow)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _scrollLeft,
                    child: Container(
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            Theme.of(context).cardColor.withValues(alpha: 0),
                            Theme.of(context).cardColor,
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: mostassa,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),

              // Fletxa dreta amb gradient
              if (_showRightArrow)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _scrollRight,
                    child: Container(
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Theme.of(context).cardColor.withValues(alpha: 0),
                            Theme.of(context).cardColor,
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: mostassa,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
