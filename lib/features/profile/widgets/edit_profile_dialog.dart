import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      _loadingInitial = false;
    });
  }

  Future<String?> _handleImageChange({
    required String userId,
    required bool isHeader,
  }) async {
    final picker = ImagePicker();
    final navigator = Navigator.of(context);
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

      dialogNavigator.pop();
      navigator.pop(isHeader ? 'header_success' : 'portrait_success');

      return url;
    } catch (e) {
      if (!mounted) return null;

      dialogNavigator.pop();
      navigator.pop('error');

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
            const SizedBox(height: 12),
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
              initialValue: _startYear.toString(),
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

// Exemple de càlcul d'anys arbitrats i guardar-los a Firestore:
// final anysArbitrats = DateTime.now().year - startYear;
// await FirebaseFirestore.instance.collection('users').doc(userId).update({'anysArbitrats': anysArbitrats});
