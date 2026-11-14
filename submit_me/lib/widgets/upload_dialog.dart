import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:submit_me/services/supabase_service.dart';

/// Modal dialog for uploading notes, assignments, and lab works to SubmitME.
/// Connects directly to the floating action button (+).
class UploadDialog extends StatefulWidget {
  const UploadDialog({super.key});

  @override
  State<UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends State<UploadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();

  // Selected file details loaded directly into memory for Web compatibility
  Uint8List? _fileBytes;
  String? _fileName;
  String? _fileExtension;
  int _fileSize = 0;

  bool _isUploading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  /// Opens the file picker allowing only PDF, PNG, JPG, and JPEG.
  /// Reads bytes asynchronously for 100% browser compatibility.
  Future<void> _pickFile() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (file != null) {
        // Read file bytes into memory using PlatformFile.readAsBytes()
        final bytes = await file.readAsBytes();
        final size = bytes.length;

        // 1. Validate file size (<= 10 MB)
        if (size > SupabaseService.maxFileSizeBytes) {
          setState(() {
            _fileBytes = null;
            _fileName = null;
            _fileExtension = null;
            _fileSize = 0;
            _errorMessage =
                'File exceeds 10 MB limit (${(size / (1024 * 1024)).toStringAsFixed(1)} MB).';
          });
          return;
        }

        // 2. Validate file extension
        final extension = file.extension?.toLowerCase() ?? '';
        if (!['pdf', 'png', 'jpg', 'jpeg'].contains(extension)) {
          setState(() {
            _fileBytes = null;
            _fileName = null;
            _fileExtension = null;
            _fileSize = 0;
            _errorMessage =
                'Unsupported format (.$extension). Only PDF, PNG, JPG, and JPEG are accepted.';
          });
          return;
        }

        setState(() {
          _fileBytes = bytes;
          _fileName = file.name;
          _fileExtension = extension;
          _fileSize = size;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: $e';
      });
    }
  }

  /// Helper to display human-readable file sizes
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Submits the asset to Supabase Storage and PostgreSQL
  Future<void> _handleUpload() async {
    // 1. Validate form fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Ensure a file has been selected
    if (_fileBytes == null || _fileName == null || _fileExtension == null) {
      setState(() {
        _errorMessage = 'Please select a file to upload.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.uploadAsset(
        topicName: _topicController.text.trim(),
        originalFileName: _fileName!,
        fileType: _fileExtension!,
        fileBytes: _fileBytes!,
      );

      if (mounted) {
        // Return true to indicate successful upload
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString().replaceFirst('Exception: ', '');
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isUploading, // Prevent closing dialog while uploading
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cloud_upload_outlined,
                color: Color.fromARGB(255, 70, 136, 216)),
            SizedBox(width: 10),
            Text('Upload New Asset',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Upload class notes, assignments, or lab works (PDF, PNG, JPG, JPEG up to 10 MB).',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 18),

                  // 1. Topic Name Text Field
                  TextFormField(
                    controller: _topicController,
                    enabled: !_isUploading,
                    decoration: const InputDecoration(
                      labelText: 'Topic Name *',
                      hintText: 'e.g. Physics Chapter 3 Notes',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a topic name.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. File Selection Section
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isUploading ? null : _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      _fileBytes == null ? 'Select File' : 'Change Selected File',
                    ),
                  ),

                  // 3. Display Selected File Information
                  if (_fileBytes != null && _fileName != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _fileExtension == 'pdf'
                                ? Icons.picture_as_pdf
                                : Icons.image,
                            color: const Color.fromARGB(255, 70, 136, 216),
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fileName!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatFileSize(_fileSize),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_isUploading)
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              tooltip: 'Remove',
                              onPressed: () {
                                setState(() {
                                  _fileBytes = null;
                                  _fileName = null;
                                  _fileExtension = null;
                                  _fileSize = 0;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ],

                  // 4. Error Message Banner
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 5. Uploading Progress Indicator
                  if (_isUploading) ...[
                    const SizedBox(height: 20),
                    const Column(
                      children: [
                        LinearProgressIndicator(),
                        SizedBox(height: 8),
                        Text(
                          'Uploading asset to SubmitME... Please wait.',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          // Cancel Button
          TextButton(
            onPressed: _isUploading ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          // Upload Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 70, 136, 216),
              foregroundColor: Colors.white,
            ),
            onPressed: _isUploading ? null : _handleUpload,
            icon: const Icon(Icons.cloud_upload, size: 18),
            label: const Text('Upload'),
          ),
        ],
      ),
    );
  }
}
