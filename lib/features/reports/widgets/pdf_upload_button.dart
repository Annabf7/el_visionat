import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/features/auth/providers/auth_provider.dart';

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
                label: 'Test (Teòric o Físic)',
                color: const Color(0xFF50C878),
                value: 'test',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel·lar'),
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

      // Monitoritzar progrés
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        debugPrint('[PdfUpload] Progrés: ${(progress * 100).toStringAsFixed(1)}%');
      });

      // Esperar a que acabi la pujada
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('[PdfUpload] PDF pujat correctament: $downloadUrl');

      if (!mounted) return;

      // Mostrar missatge d'èxit
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'PDF pujat correctament',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'S\'està processant amb IA...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF50C878),
          duration: const Duration(seconds: 4),
        ),
      );

      // TODO: Cridar Cloud Function per processar el PDF
      // await _triggerPdfProcessing(downloadUrl, type, userId);

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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.orange.shade700),
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
