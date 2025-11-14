import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_theme.dart';
import 'tag_selector/index.dart';

class AddHighlightCard extends StatefulWidget {
  final Function(String minutage, String tag, String title, String comment)?
  onHighlightAdded;

  const AddHighlightCard({super.key, this.onHighlightAdded});

  @override
  State<AddHighlightCard> createState() => _AddHighlightCardState();
}

class _AddHighlightCardState extends State<AddHighlightCard> {
  final _minutageController = TextEditingController();
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();
  String? _selectedTag;

  @override
  void dispose() {
    _minutageController.dispose();
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _addHighlight() {
    if (_minutageController.text.isNotEmpty &&
        _selectedTag != null &&
        _titleController.text.isNotEmpty) {
      // Cridar el callback per enviar la informació cap amunt
      widget.onHighlightAdded?.call(
        _minutageController.text,
        _selectedTag!,
        _titleController.text,
        _commentController.text,
      );

      // Neteja els camps
      _minutageController.clear();
      _titleController.clear();
      _commentController.clear();
      setState(() {
        _selectedTag = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Jugada afegida al minutatge!'),
          backgroundColor: AppTheme.lilaMitja,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openTagSelector() async {
    final selectedTag = await showTagSelector(
      context,
      initialTag: _selectedTag,
    );

    if (selectedTag != null) {
      setState(() {
        _selectedTag = selectedTag;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.porpraFosc.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.mostassa,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.add_box,
                  color: AppTheme.porpraFosc,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Afegeix una jugada destacada',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.porpraFosc,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Minutatge
          Row(
            children: [
              Icon(Icons.access_time, color: AppTheme.lilaMitja, size: 18),
              const SizedBox(width: 8),
              Text(
                'Minutatge',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.porpraFosc,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 100,
            child: TextField(
              controller: _minutageController,
              decoration: InputDecoration(
                hintText: 'mm:ss',
                hintStyle: TextStyle(
                  color: AppTheme.grisBody.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: AppTheme.lilaMitja),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: AppTheme.lilaMitja, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                LengthLimitingTextInputFormatter(5),
              ],
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: AppTheme.porpraFosc,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tag Selector
          Row(
            children: [
              Icon(Icons.label, color: AppTheme.lilaMitja, size: 18),
              const SizedBox(width: 8),
              Text(
                'Tipus de jugada',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.porpraFosc,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openTagSelector,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.lilaMitja),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedTag ?? 'Selecciona una categoria...',
                        style: TextStyle(
                          color: _selectedTag != null
                              ? AppTheme.porpraFosc
                              : AppTheme.grisBody.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: _selectedTag != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.porpraFosc,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Títol de la jugada
          Row(
            children: [
              Icon(Icons.title, color: AppTheme.lilaMitja, size: 18),
              const SizedBox(width: 8),
              Text(
                'Títol de la jugada',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.porpraFosc,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Descripció breu de la jugada...',
              hintStyle: TextStyle(
                color: AppTheme.grisBody.withValues(alpha: 0.7),
                fontSize: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: AppTheme.lilaMitja),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: AppTheme.lilaMitja, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            maxLength: 50,
            style: TextStyle(
              color: AppTheme.porpraFosc,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // Comentari opcional
          Row(
            children: [
              Icon(Icons.comment, color: AppTheme.lilaMitja, size: 18),
              const SizedBox(width: 8),
              Text(
                'Comentari (opcional)',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.porpraFosc,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Afegeix detalls sobre la situació...',
              hintStyle: TextStyle(
                color: AppTheme.grisBody.withValues(alpha: 0.7),
                fontSize: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: AppTheme.lilaMitja),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: AppTheme.lilaMitja, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            maxLines: 2,
            maxLength: 120,
            style: TextStyle(
              color: AppTheme.porpraFosc,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),

          // Botó d'afegir
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addHighlight,
              icon: const Icon(Icons.add_circle, size: 16),
              label: const Text(
                'Afegir a minutatge',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.porpraFosc,
                foregroundColor: AppTheme.grisPistacho,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
