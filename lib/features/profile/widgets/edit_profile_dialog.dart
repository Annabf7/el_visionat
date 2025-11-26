import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

class EditProfileDialog extends StatefulWidget {
  final String initialCategory;
  final int initialStartYear;
  final VoidCallback? onChangeHeaderImage;
  final VoidCallback? onChangePortraitImage;
  final Function(String category, int startYear) onSave;

  const EditProfileDialog({
    super.key,
    required this.initialCategory,
    required this.initialStartYear,
    this.onChangeHeaderImage,
    this.onChangePortraitImage,
    required this.onSave,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late String _category;
  late int _startYear;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _startYear = widget.initialStartYear;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final currentYear = DateTime.now().year;
    final dialogContent = Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Editar perfil',
              style: TextStyle(
                fontFamily: 'Geist',
                color: AppTheme.porpraFosc,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: widget.onChangeHeaderImage,
              icon: const Icon(Icons.photo, color: AppTheme.porpraFosc),
              label: const Text(
                'Canviar imatge de capçalera',
                style: TextStyle(
                  color: AppTheme.porpraFosc,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.grisBody.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: AppTheme.porpraFosc,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: widget.onChangePortraitImage,
              icon: const Icon(Icons.photo, color: AppTheme.porpraFosc),
              label: const Text(
                'Canviar imatge de perfil',
                style: TextStyle(
                  color: AppTheme.porpraFosc,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.grisBody.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: AppTheme.porpraFosc,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Categoria arbitral',
                labelStyle: TextStyle(
                  color: AppTheme.textBlackLow,
                  fontFamily: 'Inter',
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.porpraFosc),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.porpraFosc, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              style: const TextStyle(
                color: AppTheme.porpraFosc,
                fontFamily: 'Inter',
              ),
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: widget.initialStartYear.toString(),
              decoration: const InputDecoration(
                labelText: 'Any d\'inici',
                labelStyle: TextStyle(
                  color: AppTheme.textBlackLow,
                  fontFamily: 'Inter',
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.porpraFosc),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.porpraFosc, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: AppTheme.porpraFosc,
                fontFamily: 'Inter',
              ),
              validator: (v) {
                final parsed = int.tryParse(v ?? '');
                if (parsed == null) return 'Introdueix un any vàlid';
                if (parsed > currentYear) return 'L\'any no pot ser futur';
                return null;
              },
              onChanged: (v) {
                final parsed = int.tryParse(v);
                if (parsed != null) setState(() => _startYear = parsed);
              },
            ),
            const SizedBox(height: 32),
            const Divider(height: 1, thickness: 1, color: Color(0x11000000)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? true) {
                  widget.onSave(_category, _startYear);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.mostassa,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
              child: const Text('Guardar canvis'),
            ),
          ],
        ),
      ),
    );

    if (isMobile) {
      return FractionallySizedBox(
        heightFactor: 0.95,
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SafeArea(child: dialogContent),
        ),
      );
    } else {
      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(24),
        child: dialogContent,
      );
    }
  }
}
