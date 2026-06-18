import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:open_filex/open_filex.dart';

enum UpdateState { idle, downloading, verifying, installing, failed }

class UpdateDialog extends StatefulWidget {
  final String versionName;
  final int versionCode;
  final String downloadUrl;
  final String sha256;
  final int size;
  final List<String> releaseNotes;
  final bool forceUpdate;

  const UpdateDialog({
    super.key,
    required this.versionName,
    required this.versionCode,
    required this.downloadUrl,
    required this.sha256,
    required this.size,
    required this.releaseNotes,
    required this.forceUpdate,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  UpdateState _state = UpdateState.idle;
  double _progress = 0.0;
  String _downloadedBytesStr = '';
  String? _errorMessage;
  CancelToken? _cancelToken;

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return 'Unknown size';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  Future<void> _startDownload() async {
    setState(() {
      _state = UpdateState.downloading;
      _progress = 0.0;
      _downloadedBytesStr = '';
      _errorMessage = null;
      _cancelToken = CancelToken();
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/temp_update.apk';
      final file = File(filePath);

      // Clean up previous file if any
      if (await file.exists()) {
        await file.delete();
      }

      final dio = Dio();
      await dio.download(
        widget.downloadUrl,
        filePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
              final recMb = (received / (1024 * 1024)).toStringAsFixed(1);
              final totMb = (total / (1024 * 1024)).toStringAsFixed(1);
              _downloadedBytesStr = '$recMb MB / $totMb MB';
            });
          } else {
            setState(() {
              final recMb = (received / (1024 * 1024)).toStringAsFixed(1);
              _downloadedBytesStr = '$recMb MB';
            });
          }
        },
      );

      // Verify checksum
      setState(() {
        _state = UpdateState.verifying;
      });

      final fileBytes = await file.readAsBytes();
      final calculatedHash = sha256.convert(fileBytes).toString();

      if (calculatedHash.toLowerCase() != widget.sha256.toLowerCase()) {
        await file.delete();
        throw Exception(
          'Integrity check failed.\nThe downloaded file might be corrupted.\nExpected: ${widget.sha256.substring(0, 8)}...\nActual: ${calculatedHash.substring(0, 8)}...',
        );
      }

      // Launch native installer
      setState(() {
        _state = UpdateState.installing;
      });

      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        throw Exception('Failed to launch system installer: ${result.message}');
      }

      // If installer launched, reset to idle so if they cancel they can click install again
      setState(() {
        _state = UpdateState.idle;
      });
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        setState(() {
          _state = UpdateState.idle;
        });
        return;
      }

      setState(() {
        _state = UpdateState.failed;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel();
    setState(() {
      _state = UpdateState.idle;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Prevent dismissing using system back button during forced updates
    return PopScope(
      canPop: !widget.forceUpdate && _state != UpdateState.downloading,
      child: AlertDialog(
        backgroundColor: const Color(0xFF131924), // Sleek Slate Navy Card
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x1AFFFFFF), width: 1.5),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        title: Row(
          children: [
            const Icon(
              Icons.system_update,
              color: Color(0xFF3B82F6), // Vibrant Blue Accent
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.forceUpdate ? 'Required Update' : 'New Update Available',
                style: const TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Version ${widget.versionName} (${_formatSize(widget.size)})',
                style: const TextStyle(
                  color: Color(0xFF94A3B8), // Muted text
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              if (_state == UpdateState.idle) ...[
                if (widget.releaseNotes.isNotEmpty) ...[
                  const Text(
                    "What's New:",
                    style: TextStyle(
                      color: Color(0xFFF8FAFC),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: const Color(0xFF090D16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x1AFFFFFF)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.releaseNotes
                            .map((note) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '• ',
                                        style: TextStyle(
                                          color: Color(0xFF3B82F6),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          note,
                                          style: const TextStyle(
                                            color: Color(0xFFE2E8F0),
                                            fontSize: 12,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const Text(
                  'Would you like to download and install this update now?',
                  style: TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 13,
                  ),
                ),
              ] else if (_state == UpdateState.downloading) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: const Color(0xFF090D16),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Downloading... ${(_progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _downloadedBytesStr,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ] else if (_state == UpdateState.verifying) ...[
                const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF818CF8)),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Verifying file integrity...',
                      style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13),
                    ),
                  ],
                ),
              ] else if (_state == UpdateState.installing) ...[
                const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Launching package installer...',
                      style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13),
                    ),
                  ],
                ),
              ] else if (_state == UpdateState.failed) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x1AEF4444), // Muted red highlight
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x33EF4444)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage ?? 'An unknown error occurred during download.',
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: _buildActions(context),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    if (_state == UpdateState.downloading) {
      // Allow cancelling during non-forced downloads
      if (!widget.forceUpdate) {
        return [
          TextButton(
            onPressed: _cancelDownload,
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
        ];
      }
      return []; // No actions visible during forced download progress
    }

    if (_state == UpdateState.verifying || _state == UpdateState.installing) {
      return []; // No actions visible during installer loading/verifying
    }

    if (_state == UpdateState.failed) {
      return [
        if (!widget.forceUpdate)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Dismiss',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
        ElevatedButton(
          onPressed: _startDownload,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Retry'),
        ),
      ];
    }

    // Idle state
    return [
      if (!widget.forceUpdate)
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Later',
            style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
          ),
        ),
      ElevatedButton(
        onPressed: _startDownload,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          elevation: 2,
        ),
        child: const Text(
          'Update Now',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    ];
  }
}
