import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:submit_me/services/supabase_service.dart';

/// The "Public Assets" tab.
/// Displays assets shared across all authenticated students.
/// Retrieves records from `public.assets`.
///
/// NOTE: In accordance with privacy requirements, uploader names, emails,
/// and user IDs are NOT displayed here.
class PublicAssetsPage extends StatefulWidget {
  const PublicAssetsPage({super.key});

  @override
  State<PublicAssetsPage> createState() => PublicAssetsPageState();
}

class PublicAssetsPageState extends State<PublicAssetsPage> {
  List<Map<String, dynamic>> _publicAssets = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPublicAssets();
  }

  /// Public method to refresh public assets from outside (e.g. after upload)
  void refreshList() {
    _fetchPublicAssets();
  }

  /// Queries Supabase for shared assets across all authenticated users.
  Future<void> _fetchPublicAssets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await SupabaseService.getPublicAssets();
      if (mounted) {
        setState(() {
          _publicAssets = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load public assets: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Securely opens or downloads the file using a temporary signed URL (valid for 60 seconds).
  Future<void> _openFile(String? storagePath) async {
    if (storagePath == null || storagePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File path is missing.')),
      );
      return;
    }

    try {
      final signedUrl = await SupabaseService.getSignedUrl(storagePath);
      final uri = Uri.parse(signedUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch URL in browser.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open file: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Helper function to format timestamp strings (e.g. 2026-11-14T19:30:00Z)
  String _formatDate(dynamic dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final dateTime = DateTime.parse(dateString.toString()).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final month = months[dateTime.month - 1];
      final day = dateTime.day.toString().padLeft(2, '0');
      final year = dateTime.year.toString();
      return '$month $day, $year';
    } catch (_) {
      return dateString.toString();
    }
  }

  /// Returns an appropriate icon based on the file type.
  IconData _getFileIcon(String? fileType) {
    final type = fileType?.toLowerCase() ?? '';
    if (type.contains('pdf')) {
      return Icons.picture_as_pdf_rounded;
    } else if (type.contains('png') ||
        type.contains('jpg') ||
        type.contains('jpeg') ||
        type.contains('image')) {
      return Icons.image_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  /// Returns an accent color for the file icon.
  Color _getFileColor(String? fileType) {
    final type = fileType?.toLowerCase() ?? '';
    if (type.contains('pdf')) {
      return Colors.red.shade700;
    } else if (type.contains('png') ||
        type.contains('jpg') ||
        type.contains('jpeg') ||
        type.contains('image')) {
      return Colors.teal.shade700;
    }
    return const Color(0xFF565B61);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Loading State
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // 2. Error State with Retry Button
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 52, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: _fetchPublicAssets,
              ),
            ],
          ),
        ),
      );
    }

    // 3. Empty State (No shared assets uploaded yet)
    if (_publicAssets.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchPublicAssets,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.public_off_outlined,
                          size: 72,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No public assets shared yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Study materials and notes shared by students\nwill appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 18),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                          onPressed: _fetchPublicAssets,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    // 4. Populated Public Assets List
    return RefreshIndicator(
      onRefresh: _fetchPublicAssets,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: _publicAssets.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final asset = _publicAssets[index];
              final topicName = asset['topic_name'] ?? 'Untitled Topic';
              final fileName = asset['file_name'] ?? 'Unknown File';
              final fileType = asset['file_type'] ?? 'unknown';
              final uploadDate = _formatDate(asset['created_at']);
              final storagePath = asset['file_path'];

              return Card(
                color: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  onTap: () => _openFile(storagePath),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getFileColor(fileType).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getFileIcon(fileType),
                      color: _getFileColor(fileType),
                      size: 28,
                    ),
                  ),
                  title: Text(
                    topicName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.description_outlined,
                                size: 14, color: Colors.black45),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                fileName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                fileType.toString().toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.calendar_today_outlined,
                                size: 12, color: Colors.black45),
                            const SizedBox(width: 4),
                            Text(
                              uploadDate,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: 'Open / Download',
                    icon: const Icon(
                      Icons.open_in_new_rounded,
                      color: Color.fromARGB(255, 70, 136, 216),
                    ),
                    onPressed: () => _openFile(storagePath),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
