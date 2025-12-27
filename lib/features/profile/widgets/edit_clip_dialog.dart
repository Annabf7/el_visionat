import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/features/visionat/models/personal_analysis.dart';
import '../models/video_clip_model.dart';

/// Diàleg per editar un clip existent
/// Permet modificar metadades i afegir/canviar thumbnail
class EditClipDialog extends StatefulWidget {
  final VideoClip clip;

  const EditClipDialog({
    super.key,
    required this.clip,
  });

  @override
  State<EditClipDialog> createState() => _EditClipDialogState();
}

class _EditClipDialogState extends State<EditClipDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _matchInfoController;
  late final TextEditingController _matchCategoryController;
  late final TextEditingController _personalDescriptionController;
  late final TextEditingController _technicalFeedbackController;
  late final TextEditingController _learningNotesController;

  // State
  XFile? _newThumbnail; // Nova imatge de thumbnail
  late DateTime? _matchDate;
  late AnalysisTag _actionType;
  late ClipOutcome _outcome;
  late bool _isPublic;
  bool _isUpdating = false;
  double _uploadProgress = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Inicialitzar controllers amb les dades existents
    _matchInfoController = TextEditingController(text: widget.clip.matchInfo);
    _matchCategoryController = TextEditingController(text: widget.clip.matchCategory ?? '');
    _personalDescriptionController = TextEditingController(text: widget.clip.personalDescription);
    _technicalFeedbackController = TextEditingController(text: widget.clip.technicalFeedback ?? '');
    _learningNotesController = TextEditingController(text: widget.clip.learningNotes ?? '');

    _matchDate = widget.clip.matchDate;
    _actionType = widget.clip.actionType;
    _outcome = widget.clip.outcome;
    _isPublic = widget.clip.isPublic;
  }

  @override
  void dispose() {
    _matchInfoController.dispose();
    _matchCategoryController.dispose();
    _personalDescriptionController.dispose();
    _technicalFeedbackController.dispose();
    _learningNotesController.dispose();
    super.dispose();
  }

  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 720,
        imageQuality: 85,
      );

      if (image == null) return;

      // Verificar mida (màx 2MB per thumbnails)
      final bytes = await image.readAsBytes();
      final fileSizeMB = bytes.length / (1024 * 1024);

      if (fileSizeMB > 2) {
        setState(() {
          _errorMessage = 'La imatge és massa gran (${fileSizeMB.toStringAsFixed(1)}MB). Màxim 2MB.';
        });
        return;
      }

      setState(() {
        _newThumbnail = image;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error seleccionant thumbnail: $e';
      });
    }
  }

  Future<void> _updateClip() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUpdating = true;
      _uploadProgress = 0;
      _errorMessage = null;
    });

    try {
      String? newThumbnailUrl;

      // Pujar nou thumbnail si n'hi ha
      if (_newThumbnail != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final thumbnailFileName = 'thumbnail_${widget.clip.userId}_$timestamp.jpg';
        final thumbnailRef = FirebaseStorage.instance.ref().child(
          'video_clips/${widget.clip.userId}/thumbnails/$thumbnailFileName',
        );

        setState(() {
          _uploadProgress = 0.5;
        });

        final thumbnailUpload = thumbnailRef.putData(
          await _newThumbnail!.readAsBytes(),
          SettableMetadata(contentType: 'image/jpeg'),
        );

        thumbnailUpload.snapshotEvents.listen((event) {
          setState(() {
            _uploadProgress = 0.5 + (event.bytesTransferred / event.totalBytes * 0.5);
          });
        });

        await thumbnailUpload;
        newThumbnailUrl = await thumbnailRef.getDownloadURL();
      }

      // Actualitzar document a Firestore
      final updateData = <String, dynamic>{
        'matchInfo': _matchInfoController.text.trim(),
        'matchCategory': _matchCategoryController.text.trim().isNotEmpty
            ? _matchCategoryController.text.trim()
            : null,
        'matchDate': _matchDate != null ? Timestamp.fromDate(_matchDate!) : null,
        if (newThumbnailUrl != null) 'thumbnailUrl': newThumbnailUrl,
        'actionType': _actionType.value,
        'outcome': _outcome.value,
        'personalDescription': _personalDescriptionController.text.trim(),
        'technicalFeedback': _technicalFeedbackController.text.trim().isNotEmpty
            ? _technicalFeedbackController.text.trim()
            : null,
        'learningNotes': _learningNotesController.text.trim().isNotEmpty
            ? _learningNotesController.text.trim()
            : null,
        'isPublic': _isPublic,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('video_clips')
          .doc(widget.clip.id)
          .update(updateData);

      debugPrint('✅ Clip actualitzat correctament');

      if (mounted) {
        Navigator.of(context).pop('success');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error actualitzant clip: $e';
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 700,
          maxHeight: 800,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),

            // Contingut scrollable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selector de thumbnail
                      _buildThumbnailSelector(),
                      const SizedBox(height: 24),

                      // Informació del partit
                      _buildTextField(
                        controller: _matchInfoController,
                        label: 'Partit',
                        hint: 'Ex: FC Barcelona vs Real Madrid',
                        icon: Icons.stadium_outlined,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _matchCategoryController,
                        label: 'Categoria',
                        hint: 'Ex: Primera Catalana',
                        icon: Icons.category_outlined,
                      ),
                      const SizedBox(height: 16),

                      // Tipus d'acció
                      _buildDropdown(
                        label: 'Tipus d\'acció',
                        value: _actionType,
                        items: AnalysisTag.values,
                        onChanged: (value) => setState(() => _actionType = value!),
                        displayName: (tag) => tag.displayName,
                      ),
                      const SizedBox(height: 16),

                      // Resultat
                      _buildDropdown(
                        label: 'Resultat',
                        value: _outcome,
                        items: ClipOutcome.values,
                        onChanged: (value) => setState(() => _outcome = value!),
                        displayName: (outcome) => outcome.label,
                      ),
                      const SizedBox(height: 16),

                      // Descripció personal
                      _buildTextField(
                        controller: _personalDescriptionController,
                        label: 'Descripció personal',
                        hint: 'Explica breument la situació...',
                        icon: Icons.description_outlined,
                        maxLines: 3,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

                      // Feedback tècnic
                      _buildTextField(
                        controller: _technicalFeedbackController,
                        label: 'Feedback del tècnic',
                        hint: 'Què va dir el teu tècnic?',
                        icon: Icons.feedback_outlined,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Notes d'aprenentatge
                      _buildTextField(
                        controller: _learningNotesController,
                        label: 'Reflexió i aprenentatge',
                        hint: 'Què has après d\'aquesta situació?',
                        icon: Icons.lightbulb_outlined,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),

                      // Visibilitat
                      _buildVisibilityToggle(),
                      const SizedBox(height: 16),

                      // Errors
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Progress bar
                      if (_isUpdating) ...[
                        LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: AppTheme.grisPistacho.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.mostassa),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Actualitzant clip... ${(_uploadProgress * 100).toInt()}%',
                          style: const TextStyle(fontSize: 12, color: AppTheme.grisBody),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Botons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isUpdating ? null : () => Navigator.pop(context),
                              child: const Text('Cancel·lar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _isUpdating ? null : _updateClip,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.mostassa,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Guardar canvis'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.grisPistacho.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.mostassa.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit, color: AppTheme.porpraFosc),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editar clip',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textBlackLow,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Modifica les dades del teu clip',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.grisBody,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isUpdating ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            color: AppTheme.textBlackLow,
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.grisPistacho.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _newThumbnail != null
              ? AppTheme.mostassa.withValues(alpha: 0.4)
              : AppTheme.grisPistacho.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.image_outlined,
                size: 20,
                color: AppTheme.porpraFosc.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                _newThumbnail != null ? 'Nou thumbnail' : 'Thumbnail actual',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textBlackLow.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_newThumbnail != null) ...[
            // Previsualització del NOU thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: FutureBuilder<Uint8List>(
                    future: _newThumbnail!.readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Image.memory(
                          snapshot.data!,
                          width: double.infinity,
                          height: 120,
                          fit: BoxFit.cover,
                        );
                      }
                      return Container(
                        width: double.infinity,
                        height: 120,
                        color: AppTheme.grisPistacho.withValues(alpha: 0.3),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: _isUpdating ? null : () => setState(() => _newThumbnail = null),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (widget.clip.thumbnailUrl != null) ...[
            // Mostrar thumbnail ACTUAL
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.clip.thumbnailUrl!,
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: AppTheme.grisPistacho.withValues(alpha: 0.3),
                  child: const Center(child: Icon(Icons.broken_image, size: 32)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isUpdating ? null : _pickThumbnail,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Canviar thumbnail'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.porpraFosc,
              ),
            ),
          ] else ...[
            // No hi ha thumbnail, oferir afegir-ne un
            OutlinedButton.icon(
              onPressed: _isUpdating ? null : _pickThumbnail,
              icon: const Icon(Icons.add_photo_alternate, size: 18),
              label: const Text('Afegir thumbnail'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.porpraFosc,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_isUpdating,
      maxLines: maxLines,
      style: const TextStyle(
        color: AppTheme.textBlackLow,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: AppTheme.grisPistacho.withValues(alpha: 0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.grisPistacho.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.grisPistacho.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.lilaMitja, width: 1.5),
        ),
      ),
      validator: isRequired ? (v) => v?.trim().isEmpty == true ? 'Camp obligatori' : null : null,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) displayName,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppTheme.grisPistacho.withValues(alpha: 0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.grisPistacho.withValues(alpha: 0.5)),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(displayName(item)),
        );
      }).toList(),
      onChanged: _isUpdating ? null : onChanged,
    );
  }

  Widget _buildVisibilityToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isPublic
            ? AppTheme.mostassa.withValues(alpha: 0.08)
            : AppTheme.grisPistacho.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isPublic
              ? AppTheme.mostassa.withValues(alpha: 0.3)
              : AppTheme.grisPistacho.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isPublic ? Icons.public : Icons.lock,
            color: _isPublic ? AppTheme.mostassa : AppTheme.grisBody,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPublic ? 'Públic' : 'Privat',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _isPublic
                      ? 'Visible per tots els companys'
                      : 'Només visible per tu',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.grisBody.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPublic,
            onChanged: _isUpdating ? null : (value) => setState(() => _isPublic = value),
            activeTrackColor: AppTheme.mostassa,
          ),
        ],
      ),
    );
  }
}