import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/features/visionat/models/personal_analysis.dart';
import '../models/video_clip_model.dart';

/// Diàleg per afegir un nou clip de videoinforme
class AddClipDialog extends StatefulWidget {
  const AddClipDialog({super.key});

  @override
  State<AddClipDialog> createState() => _AddClipDialogState();
}

class _AddClipDialogState extends State<AddClipDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _matchInfoController = TextEditingController();
  final _matchCategoryController = TextEditingController();
  final _personalDescriptionController = TextEditingController();
  final _technicalFeedbackController = TextEditingController();
  final _learningNotesController = TextEditingController();

  // State
  XFile? _selectedVideo;
  DateTime? _matchDate;
  AnalysisTag _actionType = AnalysisTag.faltaPersonal;
  ClipOutcome _outcome = ClipOutcome.dubte;
  bool _isPublic = true;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _errorMessage;
  int? _videoDuration;
  int? _videoSize;

  @override
  void dispose() {
    _matchInfoController.dispose();
    _matchCategoryController.dispose();
    _personalDescriptionController.dispose();
    _technicalFeedbackController.dispose();
    _learningNotesController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    try {
      final video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(
          seconds: VideoClipLimits.maxDurationSeconds,
        ),
      );

      if (video == null) return;

      // Verificar mida
      final bytes = await video.readAsBytes();
      if (bytes.length > VideoClipLimits.maxFileSizeBytes) {
        setState(() {
          _errorMessage =
              'El vídeo és massa gran (màx ${VideoClipLimits.maxFileSizeBytes ~/ (1024 * 1024)}MB). Es comprimirà automàticament.';
        });
      }

      // Obtenir durada amb video_compress
      final info = await VideoCompress.getMediaInfo(video.path);

      setState(() {
        _selectedVideo = video;
        _videoDuration = (info.duration ?? 0) ~/ 1000; // ms a segons
        _videoSize = bytes.length;
        _errorMessage = null;
      });

      // Validar durada
      if (_videoDuration != null &&
          _videoDuration! > VideoClipLimits.maxDurationSeconds) {
        setState(() {
          _errorMessage =
              'El vídeo és massa llarg (${_videoDuration}s). Màxim ${VideoClipLimits.maxDurationSeconds}s.';
          _selectedVideo = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error seleccionant vídeo: $e';
      });
    }
  }

  Future<void> _uploadClip() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVideo == null) {
      setState(() => _errorMessage = 'Has de seleccionar un vídeo');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _errorMessage = null;
    });

    try {
      // 1. Comprimir vídeo si és necessari
      String videoPath = _selectedVideo!.path;
      int finalSize = _videoSize ?? 0;

      if (finalSize > VideoClipLimits.maxFileSizeBytes) {
        setState(() => _errorMessage = 'Comprimint vídeo...');

        final compressed = await VideoCompress.compressVideo(
          _selectedVideo!.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
        );

        if (compressed?.file != null) {
          videoPath = compressed!.file!.path;
          finalSize = await compressed.file!.length();
        }
      }

      // 2. Pujar a Firebase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'clip_${user.uid}_$timestamp.mp4';
      final storageRef = FirebaseStorage.instance.ref().child(
        'video_clips/${user.uid}/$fileName',
      );

      final uploadTask = storageRef.putData(
        await XFile(videoPath).readAsBytes(),
        SettableMetadata(contentType: 'video/mp4'),
      );

      uploadTask.snapshotEvents.listen((event) {
        setState(() {
          _uploadProgress = event.bytesTransferred / event.totalBytes;
        });
      });

      await uploadTask;
      final videoUrl = await storageRef.getDownloadURL();

      // 3. Crear document a Firestore
      final clipData = {
        'userId': user.uid,
        'matchInfo': _matchInfoController.text.trim(),
        'matchCategory': _matchCategoryController.text.trim().isNotEmpty
            ? _matchCategoryController.text.trim()
            : null,
        'matchDate': _matchDate != null
            ? Timestamp.fromDate(_matchDate!)
            : null,
        'videoUrl': videoUrl,
        'durationSeconds': _videoDuration ?? 0,
        'fileSizeBytes': finalSize,
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
        'viewCount': 0,
        'helpfulCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('video_clips').add(clipData);

      // 4. Actualitzar comptador si és públic
      if (_isPublic) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'sharedClipsCount': FieldValue.increment(1)});
      }

      if (mounted) {
        Navigator.of(context).pop('success');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error pujant clip: $e';
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final content = Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header amb gradient subtil
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.porpraFosc.withValues(alpha: 0.03),
                    AppTheme.mostassa.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.mostassa.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.video_library_outlined,
                      color: AppTheme.porpraFosc,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nou clip de videoinforme',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.porpraFosc,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Comparteix un moment clau del teu partit',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.grisBody.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppTheme.grisBody.withValues(alpha: 0.6),
                    ),
                    onPressed: _isUploading
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.grisPistacho.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contingut scrollable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selector de vídeo
                    _buildVideoSelector(),
                    const SizedBox(height: 28),

                    // Informació del partit
                    _buildSectionHeader(
                      'Informació del partit',
                      Icons.sports_soccer_outlined,
                      AppTheme.mostassa,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _matchInfoController,
                      label: 'Partit',
                      hint: 'Ex: FC Barcelona vs Real Madrid - Jornada 5',
                      icon: Icons.stadium_outlined,
                      isRequired: true,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _matchCategoryController,
                            label: 'Categoria',
                            hint: 'Ex: Primera Catalana',
                            icon: Icons.category_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDatePicker()),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Classificació
                    _buildSectionHeader(
                      'Classificació de l\'acció',
                      Icons.label_outline_rounded,
                      AppTheme.lilaMitja,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _buildActionTypeDropdown()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildOutcomeDropdown()),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Anàlisi
                    _buildSectionHeader(
                      'La teva anàlisi',
                      Icons.psychology_outlined,
                      AppTheme.porpraFosc,
                    ),
                    const SizedBox(height: 14),
                    _buildTextArea(
                      controller: _personalDescriptionController,
                      label: 'Descripció personal',
                      hint: 'Què vaig veure i per què vaig decidir...',
                      icon: Icons.edit_outlined,
                      maxLines: 3,
                      maxLength: VideoClipLimits.maxDescriptionLength,
                      isRequired: true,
                    ),
                    const SizedBox(height: 12),
                    _buildTextArea(
                      controller: _technicalFeedbackController,
                      label: 'Feedback tècnic',
                      hint: 'El tècnic va dir que...',
                      icon: Icons.record_voice_over_outlined,
                      maxLines: 2,
                      maxLength: VideoClipLimits.maxFeedbackLength,
                    ),
                    const SizedBox(height: 12),
                    _buildTextArea(
                      controller: _learningNotesController,
                      label: 'Reflexió / Aprenentatge',
                      hint: 'El que n\'he tret és...',
                      icon: Icons.lightbulb_outline,
                      maxLines: 2,
                      maxLength: VideoClipLimits.maxLearningNotesLength,
                    ),

                    const SizedBox(height: 28),

                    // Visibilitat
                    _buildSectionHeader(
                      'Visibilitat',
                      Icons.visibility_outlined,
                      AppTheme.grisBody,
                    ),
                    const SizedBox(height: 14),
                    _buildVisibilityToggle(),

                    // Error
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 20),
                      _buildErrorMessage(),
                    ],

                    // Barra de progrés
                    if (_isUploading) ...[
                      const SizedBox(height: 20),
                      _buildProgressIndicator(),
                    ],

                    const SizedBox(height: 28),

                    // Botons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (isMobile) {
      return Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: SafeArea(
            child: Center(
              child: Padding(padding: const EdgeInsets.all(16), child: content),
            ),
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 750),
        child: content,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: AppTheme.porpraFosc),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        hintStyle: TextStyle(
          color: AppTheme.grisBody.withValues(alpha: 0.4),
          fontSize: 13,
        ),
        labelStyle: TextStyle(
          color: AppTheme.grisBody.withValues(alpha: 0.7),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          size: 20,
          color: AppTheme.grisBody.withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: AppTheme.grisPistacho.withValues(alpha: 0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.grisPistacho.withValues(alpha: 0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.grisPistacho.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.lilaMitja, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: isRequired
          ? (v) => v?.trim().isEmpty == true ? 'Camp obligatori' : null
          : null,
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 3,
    int? maxLength,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 14, color: AppTheme.porpraFosc),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        hintStyle: TextStyle(
          color: AppTheme.grisBody.withValues(alpha: 0.4),
          fontSize: 13,
        ),
        labelStyle: TextStyle(
          color: AppTheme.grisBody.withValues(alpha: 0.7),
          fontSize: 14,
        ),
        alignLabelWithHint: true,
        prefixIcon: Padding(
          padding: EdgeInsets.only(top: 2, bottom: (maxLines - 1) * 20.0),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.grisBody.withValues(alpha: 0.5),
          ),
        ),
        filled: true,
        fillColor: AppTheme.grisPistacho.withValues(alpha: 0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.grisPistacho.withValues(alpha: 0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.grisPistacho.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.lilaMitja, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        counterStyle: TextStyle(
          color: AppTheme.grisBody.withValues(alpha: 0.5),
          fontSize: 11,
        ),
      ),
      validator: isRequired
          ? (v) => v?.trim().isEmpty == true ? 'Camp obligatori' : null
          : null,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.grisPistacho.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.grisPistacho.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: AppTheme.grisBody.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.grisBody.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _matchDate != null
                        ? '${_matchDate!.day}/${_matchDate!.month}/${_matchDate!.year}'
                        : 'Seleccionar',
                    style: TextStyle(
                      fontSize: 14,
                      color: _matchDate != null
                          ? AppTheme.porpraFosc
                          : AppTheme.grisBody.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTypeDropdown() {
    return InkWell(
      onTap: _showActionTypeSelector,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.lilaMitja.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lilaMitja.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _getCategoryColor(
                  _actionType.category,
                ).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _getCategoryIcon(_actionType.category),
                size: 16,
                color: _getCategoryColor(_actionType.category),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tipus d\'acció *',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.grisBody.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _actionType.displayName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.porpraFosc,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.lilaMitja.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppTheme.lilaMitja,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActionTypeSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ActionTypeSelectorSheet(
        selectedType: _actionType,
        onSelected: (type) {
          setState(() => _actionType = type);
          Navigator.pop(context);
        },
      ),
    );
  }

  Color _getCategoryColor(AnalysisCategory category) {
    switch (category) {
      case AnalysisCategory.faltes:
        return AppTheme.lilaMitja;
      case AnalysisCategory.violacions:
        return const Color(0xFFDC2626);
      case AnalysisCategory.gestioControl:
        return AppTheme.mostassa;
      case AnalysisCategory.posicionament:
        return const Color(0xFF16A34A);
      case AnalysisCategory.serveiRapid:
        return const Color(0xFF0EA5E9);
    }
  }

  IconData _getCategoryIcon(AnalysisCategory category) {
    switch (category) {
      case AnalysisCategory.faltes:
        return Icons.back_hand_outlined;
      case AnalysisCategory.violacions:
        return Icons.rule_outlined;
      case AnalysisCategory.gestioControl:
        return Icons.settings_outlined;
      case AnalysisCategory.posicionament:
        return Icons.place_outlined;
      case AnalysisCategory.serveiRapid:
        return Icons.speed_outlined;
    }
  }

  Widget _buildOutcomeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getOutcomeColor(_outcome).withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: _getOutcomeColor(_outcome).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<ClipOutcome>(
        initialValue: _outcome,
        decoration: InputDecoration(
          labelText: 'Resultat *',
          labelStyle: TextStyle(
            color: _getOutcomeColor(_outcome),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        dropdownColor: Colors.white,
        style: TextStyle(
          fontSize: 13,
          color: AppTheme.porpraFosc,
          fontWeight: FontWeight.w500,
        ),
        icon: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _getOutcomeColor(_outcome).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _getOutcomeColor(_outcome),
            size: 18,
          ),
        ),
        isExpanded: true,
        items: ClipOutcome.values.map((outcome) {
          return DropdownMenuItem(
            value: outcome,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getOutcomeColor(outcome),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(outcome.label, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (v) => setState(() => _outcome = v!),
      ),
    );
  }

  Color _getOutcomeColor(ClipOutcome outcome) {
    switch (outcome) {
      case ClipOutcome.encert:
        return const Color(0xFF16A34A); // Verd
      case ClipOutcome.errada:
        return const Color(0xFFDC2626); // Vermell
      case ClipOutcome.dubte:
        return AppTheme.mostassa; // Mostassa/Groc
    }
  }

  Widget _buildVideoSelector() {
    return InkWell(
      onTap: _isUploading ? null : _pickVideo,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: _selectedVideo != null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.mostassa.withValues(alpha: 0.08),
                    AppTheme.mostassa.withValues(alpha: 0.15),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.grisPistacho.withValues(alpha: 0.15),
                    AppTheme.grisPistacho.withValues(alpha: 0.25),
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selectedVideo != null
                ? AppTheme.mostassa.withValues(alpha: 0.4)
                : AppTheme.grisPistacho.withValues(alpha: 0.6),
            width: _selectedVideo != null ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _selectedVideo != null
                    ? AppTheme.mostassa.withValues(alpha: 0.2)
                    : AppTheme.grisBody.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _selectedVideo != null
                    ? Icons.check_circle_outline_rounded
                    : Icons.video_library_outlined,
                size: 36,
                color: _selectedVideo != null
                    ? AppTheme.mostassa
                    : AppTheme.grisBody.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedVideo != null
                  ? 'Vídeo seleccionat'
                  : 'Toca per seleccionar un vídeo',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: _selectedVideo != null
                    ? AppTheme.porpraFosc
                    : AppTheme.grisBody.withValues(alpha: 0.7),
              ),
            ),
            if (_selectedVideo != null && _videoDuration != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.mostassa.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_videoDuration}s · ${(_videoSize ?? 0) ~/ (1024 * 1024)} MB',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.porpraFosc,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppTheme.grisBody.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 6),
                Text(
                  'Màx ${VideoClipLimits.maxDurationSeconds}s · ${VideoClipLimits.maxFileSizeBytes ~/ (1024 * 1024)}MB',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.grisBody.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityToggle() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: _isPublic
            ? AppTheme.mostassa.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isPublic
              ? AppTheme.mostassa.withValues(alpha: 0.3)
              : AppTheme.grisPistacho.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isPublic
                  ? AppTheme.mostassa.withValues(alpha: 0.15)
                  : AppTheme.grisPistacho.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
              size: 18,
              color: _isPublic ? AppTheme.mostassa : AppTheme.grisBody,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPublic ? 'Compartir amb la comunitat' : 'Només per mi',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _isPublic ? AppTheme.porpraFosc : AppTheme.grisBody,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isPublic
                      ? 'Els companys podran veure\'l segons el seu nivell'
                      : 'Només tu podràs veure aquest clip',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.grisBody.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
              activeTrackColor: AppTheme.mostassa.withValues(alpha: 0.4),
              activeThumbColor: AppTheme.mostassa,
              inactiveTrackColor: AppTheme.grisPistacho.withValues(alpha: 0.5),
              inactiveThumbColor: Colors.white,
              trackOutlineColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppTheme.mostassa.withValues(alpha: 0.2);
                }
                return AppTheme.grisPistacho;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFDC2626),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lilaClar.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lilaMitja.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.lilaMitja),
                  backgroundColor: AppTheme.lilaClar.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Pujant clip...',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.porpraFosc,
                ),
              ),
              const Spacer(),
              Text(
                '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.lilaMitja,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: AppTheme.lilaClar.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation(AppTheme.lilaMitja),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.grisBody,
              side: BorderSide(
                color: AppTheme.grisPistacho.withValues(alpha: 0.8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Cancel·lar',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _isUploading ? null : _uploadClip,
            icon: _isUploading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.cloud_upload_outlined, size: 20),
            label: Text(
              _isUploading ? 'Pujant...' : 'Pujar clip',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.porpraFosc,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _matchDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ca', 'ES'),
      cancelText: 'Cancel·lar',
      confirmText: 'Acceptar',
      helpText: 'Selecciona la data',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.mostassa,
              onPrimary: AppTheme.porpraFosc,
              surface: AppTheme.grisBody,
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.mostassa,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppTheme.grisBody,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _matchDate = picked);
    }
  }
}

/// Widget per seleccionar el tipus d'acció amb categories
/// Reutilitza AnalysisCategory i AnalysisTag del model d'anàlisi personal
class _ActionTypeSelectorSheet extends StatefulWidget {
  final AnalysisTag selectedType;
  final ValueChanged<AnalysisTag> onSelected;

  const _ActionTypeSelectorSheet({
    required this.selectedType,
    required this.onSelected,
  });

  @override
  State<_ActionTypeSelectorSheet> createState() =>
      _ActionTypeSelectorSheetState();
}

class _ActionTypeSelectorSheetState extends State<_ActionTypeSelectorSheet> {
  AnalysisCategory? _expandedCategory;

  @override
  void initState() {
    super.initState();
    _expandedCategory = widget.selectedType.category;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.grisPistacho,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.lilaMitja.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.category_outlined,
                    color: AppTheme.lilaMitja,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Selecciona tipus d\'acció',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.porpraFosc,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppTheme.grisBody.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Categories
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: AnalysisCategory.values.map((category) {
                  final types = AnalysisTag.getTagsByCategory(category);
                  final isExpanded = _expandedCategory == category;
                  final hasSelected = widget.selectedType.category == category;

                  return Column(
                    children: [
                      // Category header
                      InkWell(
                        onTap: () {
                          setState(() {
                            _expandedCategory = isExpanded ? null : category;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          color: hasSelected
                              ? _getCategoryColor(
                                  category,
                                ).withValues(alpha: 0.05)
                              : null,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(
                                    category,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getCategoryIcon(category),
                                  size: 18,
                                  color: _getCategoryColor(category),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.displayName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.porpraFosc,
                                      ),
                                    ),
                                    Text(
                                      '${types.length} opcions',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.grisBody.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: AppTheme.grisBody.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Types list (expanded)
                      if (isExpanded)
                        Container(
                          color: AppTheme.grisPistacho.withValues(alpha: 0.1),
                          child: Column(
                            children: types.map((type) {
                              final isSelected = widget.selectedType == type;
                              return InkWell(
                                onTap: () => widget.onSelected(type),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _getCategoryColor(
                                            category,
                                          ).withValues(alpha: 0.1)
                                        : null,
                                    border: Border(
                                      left: BorderSide(
                                        color: isSelected
                                            ? _getCategoryColor(category)
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 44),
                                      Expanded(
                                        child: Text(
                                          type.displayName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isSelected
                                                ? _getCategoryColor(category)
                                                : AppTheme.porpraFosc,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 20,
                                          color: _getCategoryColor(category),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(AnalysisCategory category) {
    switch (category) {
      case AnalysisCategory.faltes:
        return AppTheme.lilaMitja;
      case AnalysisCategory.violacions:
        return const Color(0xFFDC2626);
      case AnalysisCategory.gestioControl:
        return AppTheme.mostassa;
      case AnalysisCategory.posicionament:
        return const Color(0xFF16A34A);
      case AnalysisCategory.serveiRapid:
        return const Color(0xFF0EA5E9);
    }
  }

  IconData _getCategoryIcon(AnalysisCategory category) {
    switch (category) {
      case AnalysisCategory.faltes:
        return Icons.back_hand_outlined;
      case AnalysisCategory.violacions:
        return Icons.rule_outlined;
      case AnalysisCategory.gestioControl:
        return Icons.settings_outlined;
      case AnalysisCategory.posicionament:
        return Icons.place_outlined;
      case AnalysisCategory.serveiRapid:
        return Icons.speed_outlined;
    }
  }
}
