import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routing/app_router.dart';

/// Import screen for picking audio / video files.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final isNative = !kIsWeb;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Files'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.library),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Supported: MP3, FLAC, ALAC (m4a/aac), WAV'
                      '${isNative ? '\nVideo (MP4, MKV, AVI, MOV) – audio will be extracted.' : ''}',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Import button
            Center(
              child: _isImporting
                  ? Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Importing & extracting metadata...',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _ImportCard(
                          icon: Icons.audio_file_rounded,
                          title: 'Select Audio Files',
                          subtitle: 'MP3, FLAC, ALAC, WAV',
                          onTap: () => _startImport(),
                        ),
                        if (isNative) ...[
                          const SizedBox(height: 16),
                          _ImportCard(
                            icon: Icons.video_file_rounded,
                            title: 'Select Video Files',
                            subtitle: 'Audio will be extracted via FFmpeg',
                            onTap: () => _startImport(),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startImport() async {
    setState(() => _isImporting = true);
    await ref.read(songsProvider.notifier).importFiles();
    if (!mounted) return;
    setState(() => _isImporting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import complete! Songs added to your library.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.go(AppRoutes.library);
  }
}

class _ImportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ImportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.15),
              AppTheme.surfaceElevated,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 40),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppTheme.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }
}
