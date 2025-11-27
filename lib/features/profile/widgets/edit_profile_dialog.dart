import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Widget per mostrar una previsualització de la imatge i el nom d'arxiu amb extensió i estil professional
class _ImagePreviewWithName extends StatelessWidget {
  final String imageUrl;
  final String? label;
  const _ImagePreviewWithName({required this.imageUrl, this.label});

  @override
  Widget build(BuildContext context) {
    final fileName = imageUrl.split('/').last;
    final dotIdx = fileName.lastIndexOf('.');
    final base = dotIdx > 0 ? fileName.substring(0, dotIdx) : fileName;
    final ext = dotIdx > 0 ? fileName.substring(dotIdx) : '';
    return Tooltip(
      message: fileName,
      waitDuration: const Duration(milliseconds: 300),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                  size: 28,
                ),
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: base,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textBlackLow,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),
                  TextSpan(
                    text: ext,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.porpraFosc,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 8),
            Text(
              label!,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textBlackLow,
                fontStyle: FontStyle.italic,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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
  String? _headerImageUrl;
  String? _portraitImageUrl;
  bool _loadingInitial = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Connecta Firebase Storage a l'emulador només en mode debug
    assert(() {
      try {
        FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
      } catch (_) {
        // Ja pot estar connectat, ignora errors
      }
      return true;
    }());
  }

  @override
  void initState() {
    super.initState();
    _initProfileFields();
  }

  Future<void> _initProfileFields() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _category = widget.initialCategory;
        _startYear = widget.initialStartYear;
        _headerImageUrl = null;
        _portraitImageUrl = null;
        _loadingInitial = false;
      });
      return;
    }
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = userDoc.data();
    // Deriva refereeCategory si no existeix
    String derivedCategory = widget.initialCategory;
    if ((data == null || data['refereeCategory'] == null)) {
      // Ex: "C1 Barcelona" → "Categoria C1 - RT Barcelona"
      final regExp = RegExp(r'([A-Z0-9]+)\s+(.+)', caseSensitive: false);
      final match = regExp.firstMatch(widget.initialCategory);
      if (match != null) {
        final code = match.group(1);
        final region = match.group(2);
        derivedCategory = 'Categoria $code - RT $region';
      }
    } else if (data['refereeCategory'] != null) {
      derivedCategory = data['refereeCategory'] as String;
    }
    setState(() {
      _category = derivedCategory;
      _startYear = (data != null && data['startYear'] != null)
          ? (data['startYear'] as int)
          : widget.initialStartYear;
      _headerImageUrl = (data != null && data['headerImageUrl'] != null)
          ? data['headerImageUrl'] as String
          : null;
      _portraitImageUrl = (data != null && data['portraitImageUrl'] != null)
          ? data['portraitImageUrl'] as String
          : null;
      _loadingInitial = false;
    });
  }

  Future<String?> _handleImageChange({
    required String userId,
    required bool isHeader,
  }) async {
    final picker = ImagePicker();
    final dialogNavigator = Navigator.of(context, rootNavigator: true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (!mounted || pickedFile == null) {
      if (mounted) dialogNavigator.pop();
      return null;
    }

    try {
      final file = pickedFile;
      final ext = 'webp';
      final path = isHeader
          ? 'profile_images/$userId/header.$ext'
          : 'profile_images/$userId/portrait.$ext';
      final storageRef = FirebaseStorage.instance.ref().child(path);
      await storageRef.putData(await file.readAsBytes());
      final url = await storageRef.getDownloadURL();

      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);
      await userDoc.update({
        isHeader ? 'headerImageUrl' : 'portraitImageUrl': url,
      });

      if (!mounted) return null;

      setState(() {
        if (isHeader) {
          _headerImageUrl = url;
        } else {
          _portraitImageUrl = url;
        }
      });

      dialogNavigator.pop();
      // NO tanquem el diàleg ni fem navigator.pop aquí!
      return url;
    } catch (e) {
      if (!mounted) return null;

      dialogNavigator.pop();
      // NO tanquem el diàleg ni fem navigator.pop aquí!
      return null;
    }
  }

  Future<void> _onChangeHeaderImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _handleImageChange(userId: user.uid, isHeader: true);
    // El feedback es mostrarà des del widget pare
  }

  Future<void> _onChangePortraitImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _handleImageChange(userId: user.uid, isHeader: false);
    // El feedback es mostrarà des del widget pare
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final currentYear = DateTime.now().year;
    if (_loadingInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    final dialogContent = Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.porpraFosc),
                  tooltip: 'Tancar',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Botó i info imatge capçalera
            TextButton.icon(
              onPressed: _onChangeHeaderImage,
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
            if (_headerImageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2),
                child: _ImagePreviewWithName(
                  imageUrl: _headerImageUrl!,
                  label: 'Imatge de capçalera',
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: Text(
                "Format recomanat: JPG, PNG o WebP. Mida mínima: 1200x300px. Proporció horitzontal (4:1). Per un resultat professional, elimina el fons de la imatge i utilitza un fons blanc trencat (#F8F9FA). Pots fer-ho gratuïtament a remove.bg.",
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textBlackLow,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Botó i info imatge perfil
            TextButton.icon(
              onPressed: _onChangePortraitImage,
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
            if (_portraitImageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2),
                child: _ImagePreviewWithName(
                  imageUrl: _portraitImageUrl!,
                  label: 'Imatge de perfil',
                ),
              ),

            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: Text(
                "Format recomanat: JPG, PNG o WebP. Mida mínima: 400x400px. Fons clar i rostre centrat.",
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textBlackLow,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              initialValue: _category
                  .replaceFirst(
                    RegExp(r'^(Categoria\s*-?\s*)?', caseSensitive: false),
                    '',
                  )
                  .replaceFirst(RegExp(r'^RT\s*', caseSensitive: false), '')
                  .trim(),
              decoration: InputDecoration(
                labelText: 'Categoria arbitral',
                labelStyle: const TextStyle(
                  color: AppTheme.porpraFosc,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
                border: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.porpraFosc,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.porpraFosc,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.porpraFosc, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                disabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.porpraFosc,
                    width: 1.5,
                  ),
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
              initialValue: _startYear.toString(),
              decoration: InputDecoration(
                labelText: "Any d'inici",
                labelStyle: const TextStyle(
                  color: AppTheme.porpraFosc,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
                border: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.porpraFosc,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.porpraFosc,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.porpraFosc, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                disabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.porpraFosc,
                    width: 1.5,
                  ),
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
                if (parsed < 1950) return 'L\'any ha de ser ≥ 1950';
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
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? true) {
                  final navigator = Navigator.of(context);
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      throw Exception('No s\'ha trobat l\'usuari.');
                    }
                    final userId = user.uid;
                    final anysArbitrats = DateTime.now().year - _startYear;
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .set({
                          'refereeCategory':
                              _category, // Només aquest camp editable
                          'startYear': _startYear,
                          'anysArbitrats': anysArbitrats,
                        }, SetOptions(merge: true));
                    if (!mounted) return;
                    navigator.pop(
                      'profile_success',
                    ); // Retorna resultat al pare
                  } catch (e) {
                    if (!mounted) return;
                    navigator.pop('error');
                  }
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
      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 380,
            minWidth: 0,
            minHeight: 0,
          ),
          child: SingleChildScrollView(child: dialogContent),
        ),
      );
    } else {
      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 320, vertical: 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: dialogContent,
        ),
      );
    }
  }
}
