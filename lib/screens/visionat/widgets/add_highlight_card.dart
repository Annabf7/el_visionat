import 'package:flutter/material.dart';
import '../../../models/highlight_entry.dart';
import '../../../theme/app_theme.dart';

class AddHighlightCard extends StatefulWidget {
  final Function(HighlightEntry) onAddHighlight;

  const AddHighlightCard({super.key, required this.onAddHighlight});

  @override
  State<AddHighlightCard> createState() => _AddHighlightCardState();
}

class _AddHighlightCardState extends State<AddHighlightCard> {
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Afegir Highlight',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.porpraFosc,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Descripció del highlight',
                hintText: 'Descriu l\'acció...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('AFEGIR HIGHLIGHT'),
                onPressed: _titleController.text.isNotEmpty
                    ? _onAddPressed
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lilaMitja,
                  foregroundColor: AppTheme.grisPistacho,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onAddPressed() {
    if (_titleController.text.isNotEmpty) {
      final newHighlight = HighlightEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: const Duration(minutes: 30),
        title: _titleController.text,
        tag: HighlightTagType.faltaTecnica,
      );

      widget.onAddHighlight(newHighlight);
      _titleController.clear();
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Highlight afegit: ${newHighlight.title}'),
          backgroundColor: AppTheme.lilaMitja,
        ),
      );
    }
  }
}
