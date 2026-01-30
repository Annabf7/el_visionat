import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:async';

import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/features/auth/providers/auth_provider.dart';
import 'package:el_visionat/features/reports/providers/reports_provider.dart';

/// Widget per pujar PDFs d'informes i tests
class PdfUploadButton extends StatefulWidget {
  const PdfUploadButton({super.key});

  @override
  State<PdfUploadButton> createState() => _PdfUploadButtonState();
}

class _PdfUploadButtonState extends State<PdfUploadButton> {
  bool _isUploading = false;

  Future<void> _showUploadDialog() async {
    final selectedType = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pujar PDF'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Quin tipus de document vols pujar?'),
              const SizedBox(height: 20),
              _buildOptionButton(
                context,
                icon: Icons.description_outlined,
                label: 'Informe d\'Arbitratge',
                color: AppTheme.lilaMitja,
                value: 'report',
              ),
              const SizedBox(height: 12),
              _buildOptionButton(
                context,
                icon: Icons.quiz_outlined,
                label: 'Test',
                color: AppTheme.verdeEncert,
                value: 'test',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel·lar',
                style: TextStyle(
                  color: AppTheme.grisPistacho,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (selectedType != null && mounted) {
      await _pickAndUploadPdf(selectedType);
    }
  }

  Widget _buildOptionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required String value,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pop(context, value),
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPdf(String type) async {
    try {
      // Obtenir usuari actual abans de qualsevol async gap
      final auth = context.read<AuthProvider>();
      final userId = auth.currentUserUid;

      if (userId == null) {
        if (!mounted) return;
        _showErrorDialog('Usuari no autenticat');
        return;
      }

      // Seleccionar arxiu PDF
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return; // L'usuari ha cancel·lat
      }

      final file = result.files.first;

      // Validar que és un PDF
      if (file.extension?.toLowerCase() != 'pdf') {
        if (!mounted) return;
        _showErrorDialog('Només es permeten arxius PDF');
        return;
      }

      // Validar mida (màxim 10MB)
      if (file.size > 10 * 1024 * 1024) {
        if (!mounted) return;
        _showErrorDialog('L\'arxiu no pot superar els 10MB');
        return;
      }

      setState(() {
        _isUploading = true;
      });

      // Crear referència a Firebase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${type}_${timestamp}_${file.name}';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('pdfs')
          .child(userId)
          .child(fileName);

      // Pujar arxiu
      UploadTask uploadTask;
      if (file.bytes != null) {
        // Web: usar bytes
        uploadTask = storageRef.putData(
          file.bytes!,
          SettableMetadata(
            contentType: 'application/pdf',
            customMetadata: {
              'type': type,
              'userId': userId,
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          ),
        );
      } else if (file.path != null) {
        // Mobile/Desktop: usar path
        uploadTask = storageRef.putFile(
          File(file.path!),
          SettableMetadata(
            contentType: 'application/pdf',
            customMetadata: {
              'type': type,
              'userId': userId,
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          ),
        );
      } else {
        throw Exception('No s\'ha pogut accedir a l\'arxiu');
      }

      // Monitoritzar progrés de pujada
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        debugPrint('[PdfUpload] Progrés: ${(progress * 100).toStringAsFixed(1)}%');
      });

      // Esperar a que acabi la pujada
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('[PdfUpload] PDF pujat correctament: $downloadUrl');

      if (!mounted) return;

      // Mostrar diàleg de processament IA
      await _showProcessingDialog(type, userId, timestamp);

    } catch (e) {
      debugPrint('[PdfUpload] Error: $e');
      if (!mounted) return;
      _showErrorDialog('Error pujant l\'arxiu: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  /// Mostra un diàleg de processament i espera que el document aparegui a Firestore
  Future<void> _showProcessingDialog(
      String type, String userId, int timestamp) async {
    final collection = type == 'report' ? 'reports' : 'tests';
    final typeLabel = type == 'report' ? 'informe' : 'test';
    StreamSubscription<QuerySnapshot>? subscription;
    Timer? timeoutTimer;
    bool completed = false;

    // Mostrar diàleg
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.lilaMitja),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Processant $typeLabel amb IA...',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Estem analitzant el PDF.\nAixò pot trigar uns segons.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.grisPistacho,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    // Escoltar nous documents a Firestore (creats després del timestamp)
    final startTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    subscription = FirebaseFirestore.instance
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(startTime))
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty && !completed) {
        completed = true;
        debugPrint('[PdfUpload] Document detectat a Firestore!');
        _onProcessingComplete(subscription, timeoutTimer, type, userId);
      }
    });

    // Timeout de 60 segons
    timeoutTimer = Timer(const Duration(seconds: 60), () {
      if (!completed) {
        completed = true;
        debugPrint('[PdfUpload] Timeout - tancant diàleg');
        _onProcessingTimeout(subscription, timeoutTimer, type);
      }
    });
  }

  void _onProcessingComplete(StreamSubscription? subscription, Timer? timer,
      String type, String userId) {
    subscription?.cancel();
    timer?.cancel();

    if (!mounted) return;

    // Tancar diàleg de processament
    Navigator.of(context, rootNavigator: true).pop();

    // Refrescar llista d'informes si estem en la pàgina correcta
    if (type == 'report') {
      try {
        context.read<ReportsProvider>().loadReports(userId);
      } catch (_) {}
    }

    // Mostrar missatge d'èxit
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                type == 'report'
                    ? 'Informe processat correctament!'
                    : 'Test processat correctament!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.verdeEncert,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onProcessingTimeout(StreamSubscription? subscription, Timer? timer,
      String type) {
    subscription?.cancel();
    timer?.cancel();

    if (!mounted) return;

    // Tancar diàleg de processament
    Navigator.of(context, rootNavigator: true).pop();

    // Mostrar missatge informatiu (no és un error, pot trigar més)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                type == 'report'
                    ? 'L\'informe s\'està processant. Apareixerà en breu.'
                    : 'El test s\'està processant. Apareixerà en breu.',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.lilaMitja,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: AppTheme.mostassa),
              const SizedBox(width: 12),
              const Text('Error'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('D\'acord'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: _isUploading ? null : _showUploadDialog,
      icon: _isUploading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.upload_file),
      label: Text(_isUploading ? 'Pujant...' : 'Pujar PDF'),
      backgroundColor: _isUploading ? Colors.grey : AppTheme.porpraFosc,
    );
  }
}
