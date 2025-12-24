import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Widget per mostrar una previsualització de la imatge i el nom d'arxiu amb extensió i estil professional
class _ImagePreviewWithName extends StatelessWidget {
  final String imageUrl;
  final String? label;
  final VoidCallback? onRemove;
  const _ImagePreviewWithName({
    required this.imageUrl,
    this.label,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // Mostra només el nom original (label) si existeix
    String displayName = label ?? '';
    if (displayName.toLowerCase().startsWith('scaled_')) {
      displayName = displayName.substring(7);
    }
    if (displayName.trim().isEmpty) {
      displayName = 'Imatge sense nom';
    }
    return Tooltip(
      message: displayName,
      waitDuration: const Duration(milliseconds: 300),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey.shade300, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
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
                      size: 32,
                    ),
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                  ),
                ),
              ),
              if (onRemove != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Text(
                displayName,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                  letterSpacing: 0.1,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ),
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
  String? _headerOriginalName;
  String? _portraitOriginalName;
  bool _loadingInitial = true;
  final _formKey = GlobalKey<FormState>();

  // La configuració de l'emulador de Storage es gestiona a main.dart

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
      // Si ja comença per "Categoria", no fer res
      if (!widget.initialCategory.toLowerCase().startsWith('categoria')) {
        // Ex: "C1 Barcelona" → "Categoria C1 - RT Barcelona"
        final regExp = RegExp(r'([A-Z0-9]+)\s+(.+)', caseSensitive: false);
        final match = regExp.firstMatch(widget.initialCategory);
        if (match != null) {
          final code = match.group(1);
          final region = match.group(2);
          derivedCategory = 'Categoria $code - RT $region';
        }
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
      _headerOriginalName = (data != null && data['headerOriginalName'] != null)
          ? data['headerOriginalName'] as String
          : null;
      _portraitOriginalName =
          (data != null && data['portraitOriginalName'] != null)
          ? data['portraitOriginalName'] as String
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
    String? errorMessage;

    // 1. Primer seleccionem la imatge SENSE mostrar el diàleg de càrrega
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (!mounted || pickedFile == null) {
      return null;
    }

    // 2. Ara mostrem el diàleg de càrrega
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                isHeader
                    ? 'Pujant imatge de capçalera...'
                    : 'Pujant imatge de perfil...',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final file = pickedFile;
      // Determinar extensió real del fitxer
      final originalName = file.name;
      String ext = 'jpg';
      if (originalName.contains('.')) {
        ext = originalName.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) {
          ext = 'jpg';
        }
      }

      final path = isHeader
          ? 'profile_images/$userId/header.$ext'
          : 'profile_images/$userId/portrait.$ext';
      final storageRef = FirebaseStorage.instance.ref().child(path);

      debugPrint('📸 Llegint bytes de la imatge: $originalName');

      // Llegim els bytes
      final bytes = await file.readAsBytes();
      debugPrint(
        '📸 Bytes llegits: ${bytes.length} bytes (${(bytes.length / 1024).toStringAsFixed(1)} KB)',
      );

      // Determinar content type
      String contentType = 'image/jpeg';
      if (ext == 'png') contentType = 'image/png';
      if (ext == 'webp') contentType = 'image/webp';
      if (ext == 'gif') contentType = 'image/gif';

      debugPrint('📸 Pujant a: $path amb contentType: $contentType');

      // Pujar amb metadata
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {'uploadedBy': userId, 'originalName': originalName},
      );

      TaskSnapshot snapshot;

      if (kIsWeb) {
        // A web, usar putString amb base64 funciona millor
        debugPrint('📸 Usant putString (base64) per web...');
        final base64Data = base64Encode(bytes);
        final uploadTask = storageRef.putString(
          base64Data,
          format: PutStringFormat.base64,
          metadata: metadata,
        );

        // Escoltar progrés
        uploadTask.snapshotEvents.listen(
          (event) {
            final progress = event.bytesTransferred / event.totalBytes;
            debugPrint('📸 Progrés: ${(progress * 100).toStringAsFixed(1)}%');
          },
          onError: (e) {
            debugPrint('📸 Error en stream: $e');
          },
        );

        snapshot = await uploadTask;
      } else {
        // A mòbil/desktop, putData funciona bé
        debugPrint('📸 Usant putData per mòbil/desktop...');
        final uploadTask = storageRef.putData(bytes, metadata);

        uploadTask.snapshotEvents.listen((event) {
          final progress = event.bytesTransferred / event.totalBytes;
          debugPrint('📸 Progrés: ${(progress * 100).toStringAsFixed(1)}%');
        });

        snapshot = await uploadTask;
      }

      debugPrint('📸 Pujada completada! State: ${snapshot.state}');

      if (snapshot.state != TaskState.success) {
        throw Exception('La pujada no s\'ha completat correctament');
      }

      final url = await storageRef.getDownloadURL();
      debugPrint('📸 URL obtinguda: $url');

      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);
      await userDoc.update({
        isHeader ? 'headerImageUrl' : 'portraitImageUrl': url,
        isHeader ? 'headerOriginalName' : 'portraitOriginalName': originalName,
      });
      debugPrint('📸 Firestore actualitzat!');

      if (!mounted) return null;

      setState(() {
        if (isHeader) {
          _headerImageUrl = url;
          _headerOriginalName = originalName;
        } else {
          _portraitImageUrl = url;
          _portraitOriginalName = originalName;
        }
      });

      dialogNavigator.pop();
      return url;
    } catch (e, stackTrace) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('❌ Error pujant imatge: $e');
      debugPrint('❌ StackTrace: $stackTrace');

      if (!mounted) return null;

      dialogNavigator.pop();

      // Mostrar error a l'usuari
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
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
                  label: _headerOriginalName,
                  onRemove: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;
                    // Remove from Firestore and Storage
                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .update({
                            'headerImageUrl': FieldValue.delete(),
                            'headerOriginalName': FieldValue.delete(),
                          });
                      final ext = 'webp';
                      final path = 'profile_images/${user.uid}/header.$ext';
                      await FirebaseStorage.instance.ref().child(path).delete();
                    } catch (_) {}
                    if (!mounted) return;
                    setState(() {
                      _headerImageUrl = null;
                      _headerOriginalName = null;
                    });
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: Text(
                "Format recomanat: JPG, PNG o WebP. Mida mínima: 1200x300px. Proporció horitzontal (4:1). Per un resultat professional, elimina el fons de la imatge i utilitza un fons blanc trencat (#F8F9FA). Pots fer-ho gratuïtament a ",
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textBlackLow,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () async {
                    final url = Uri.parse('https://www.remove.bg/');
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  },
                  child: Text(
                    'remove.bg',
                    style: TextStyle(
                      color: AppTheme.porpraFosc,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      fontSize: 13,
                      fontFamily: 'Inter',
                    ),
                  ),
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
                  label: _portraitOriginalName ?? 'Imatge de perfil',
                  onRemove: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;
                    // Remove from Firestore and Storage
                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .update({
                            'portraitImageUrl': FieldValue.delete(),
                            'portraitOriginalName': FieldValue.delete(),
                          });
                      final ext = 'webp';
                      final path = 'profile_images/${user.uid}/portrait.$ext';
                      await FirebaseStorage.instance.ref().child(path).delete();
                    } catch (_) {}
                    if (!mounted) return;
                    setState(() {
                      _portraitImageUrl = null;
                      _portraitOriginalName = null;
                    });
                  },
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
