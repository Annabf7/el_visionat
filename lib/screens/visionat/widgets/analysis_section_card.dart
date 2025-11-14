import 'package:flutter/material.dart';
import '../../../models/collective_comment.dart';
import '../../../theme/app_theme.dart';

class AnalysisSectionCard extends StatefulWidget {
  final String personalAnalysisText;
  final ValueChanged<String> onPersonalAnalysisChanged;
  final VoidCallback onPersonalAnalysisSave;
  final List<CollectiveComment> collectiveComments;
  final VoidCallback onViewAllComments;

  const AnalysisSectionCard({
    super.key,
    required this.personalAnalysisText,
    required this.onPersonalAnalysisChanged,
    required this.onPersonalAnalysisSave,
    required this.collectiveComments,
    required this.onViewAllComments,
  });

  @override
  State<AnalysisSectionCard> createState() => _AnalysisSectionCardState();
}

class _AnalysisSectionCardState extends State<AnalysisSectionCard> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.personalAnalysisText);
  }

  @override
  void didUpdateWidget(AnalysisSectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.personalAnalysisText != widget.personalAnalysisText) {
      _controller.text = widget.personalAnalysisText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    widget.onPersonalAnalysisSave();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Anàlisi personal guardada'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return 'fa ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'fa ${difference.inHours}h';
    } else {
      return 'fa ${difference.inDays} dies';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        top: 24,
      ), // Separació més marcada del widget superior
      decoration: BoxDecoration(
        // Gradient suau vertical amb tons corporatius
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.porpraFosc.withValues(alpha: 0.05),
            AppTheme.lilaMitja.withValues(alpha: 0.08),
          ],
        ),
        // Borde subtil amb color mostassa corporatiu
        border: Border.all(
          color: AppTheme.mostassa.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20), // Radi de cantonades més gran
        // Ombra més profunda i difosa
        boxShadow: [
          BoxShadow(
            color: AppTheme.porpraFosc.withValues(alpha: 0.15),
            offset: const Offset(0, 6),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          // Capçalera visual amb barra superior
          border: Border(
            top: BorderSide(
              color: AppTheme.mostassa.withValues(alpha: 0.6),
              width: 6,
            ),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28), // Padding més generós
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECCIÓ A: Anàlisi personal
              Text(
                'Anàlisi personal',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Les teves notes quedaran guardades al teu perfil i només tu les podràs veure.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.white),
              ),
              const SizedBox(height: 16),

              // Text Field per anàlisi personal
              TextField(
                controller: _controller,
                onChanged: widget.onPersonalAnalysisChanged,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Escriu les teves notes sobre el partit...',
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppTheme.porpraFosc,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
              ),
              const SizedBox(height: 12),

              // Botó guardar
              Align(
                alignment: Alignment.centerRight,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWideScreen = constraints.maxWidth >= 600;
                    final fontSize = isWideScreen ? 12.0 : 11.0;
                    final iconSize = isWideScreen ? 14.0 : 13.0;
                    final horizontalPadding = isWideScreen ? 16.0 : 14.0;
                    final verticalPadding = isWideScreen ? 8.0 : 7.0;

                    return ElevatedButton.icon(
                      onPressed: _handleSave,
                      icon: Icon(Icons.save, size: iconSize),
                      label: Text(
                        'Guardar',
                        style: TextStyle(fontSize: fontSize),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.white,
                        foregroundColor: AppTheme.porpraFosc,
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Divider suau
              Divider(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
                thickness: 1,
              ),

              const SizedBox(height: 24),

              // SECCIÓ B: Anàlisi col·lectiva
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anàlisi col·lectiva',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Aportacions del grup',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.white),
                      ),
                    ],
                  ),
                  // Comptador de comentaris
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.lilaMitja.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.lilaMitja),
                    ),
                    child: Text(
                      '${widget.collectiveComments.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Comentaris recents (màxim 3)
              if (widget.collectiveComments.isNotEmpty) ...[
                ...widget.collectiveComments
                    .take(3)
                    .map(
                      (comment) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: comment.anonymous
                                      ? AppTheme.mostassa.withValues(alpha: 1)
                                      : AppTheme.mostassa.withValues(alpha: 1),
                                  child: Icon(
                                    comment.anonymous
                                        ? Icons.person_outline
                                        : Icons.person,
                                    size: 14,
                                    color: comment.anonymous
                                        ? AppTheme.porpraFosc
                                        : AppTheme.porpraFosc,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    comment.displayName,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                  ),
                                ),
                                Text(
                                  _formatTimeAgo(comment.createdAt),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              comment.text,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Encara no hi ha comentaris col·lectius',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Botó "Veure comentaris"
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: widget.onViewAllComments,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Veure comentaris'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
