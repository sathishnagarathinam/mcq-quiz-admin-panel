import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../core/models/exam_hub_models.dart';

class PDFViewerScreen extends StatefulWidget {
  final FileAttachment attachment;
  final String title;

  const PDFViewerScreen({
    super.key,
    required this.attachment,
    required this.title,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  String? _localPath;
  bool _isLoading = true;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 0;
  dynamic _pdfController;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _downloadAndDisplayPDF();
  }

  Future<void> _downloadAndDisplayPDF() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get the app's document directory
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${widget.attachment.name}');

      // Check if file already exists
      if (await file.exists()) {
        setState(() {
          _localPath = file.path;
          _isLoading = false;
        });
        return;
      }

      // Download the PDF file with progress tracking
      final request = http.Request('GET', Uri.parse(widget.attachment.url));
      final response = await request.send();

      if (response.statusCode == 200) {
        final contentLength = response.contentLength ?? widget.attachment.size;
        var downloadedBytes = 0;

        final sink = file.openWrite();

        await response.stream.listen(
          (chunk) {
            downloadedBytes += chunk.length;
            sink.add(chunk);

            // Update progress if we know the total size
            if (contentLength > 0) {
              final progress = downloadedBytes / contentLength;
              if (mounted) {
                setState(() {
                  _downloadProgress = progress;
                });
              }
            }
          },
          onDone: () async {
            await sink.close();
            if (mounted) {
              setState(() {
                _localPath = file.path;
                _isLoading = false;
                _downloadProgress = 0.0;
              });
            }
          },
          onError: (error) async {
            await sink.close();
            if (mounted) {
              setState(() {
                _error = 'Download failed: $error';
                _isLoading = false;
                _downloadProgress = 0.0;
              });
            }
          },
        ).asFuture();
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _downloadProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_downloadProgress > 0.0) ...[
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: _downloadProgress,
                  backgroundColor: Colors.grey[300],
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Downloading... ${(_downloadProgress * 100).toInt()}%',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ] else ...[
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
              const SizedBox(height: 16),
              Text(
                'Preparing PDF...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              widget.attachment.originalName,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              _formatFileSize(widget.attachment.size),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load PDF',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _downloadAndDisplayPDF,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    if (_localPath == null) {
      return const Center(
        child: Text('No PDF to display'),
      );
    }

    return PDFView(
      filePath: _localPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: false,
      pageFling: true,
      pageSnap: true,
      defaultPage: _currentPage,
      // fitPolicy: FitPolicy.BOTH, // Removed due to compatibility issues
      preventLinkNavigation: false,
      onRender: (pages) {
        setState(() {
          _totalPages = pages ?? 0;
        });
      },
      onViewCreated: (dynamic pdfViewController) {
        _pdfController = pdfViewController;
      },
      onLinkHandler: (String? uri) {
        // Handle link clicks if needed
      },
      onError: (error) {
        setState(() {
          _error = error.toString();
        });
      },
      onPageError: (page, error) {
        setState(() {
          _error = 'Error on page $page: $error';
        });
      },
      onPageChanged: (int? page, int? total) {
        setState(() {
          _currentPage = page ?? 0;
          _totalPages = total ?? 0;
        });
      },
    );
  }

  Widget _buildBottomBar() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: _currentPage > 0 ? _goToPreviousPage : null,
            icon: const Icon(Icons.chevron_left),
            iconSize: 32,
            color: _currentPage > 0 ? const Color(0xFF6366F1) : Colors.grey,
          ),
          Expanded(
            child: Slider(
              value: _currentPage.toDouble(),
              min: 0,
              max: (_totalPages - 1).toDouble(),
              divisions: _totalPages > 1 ? _totalPages - 1 : 1,
              activeColor: const Color(0xFF6366F1),
              inactiveColor: Colors.grey[300],
              onChanged: (value) {
                _goToPage(value.round());
              },
            ),
          ),
          IconButton(
            onPressed: _currentPage < _totalPages - 1 ? _goToNextPage : null,
            icon: const Icon(Icons.chevron_right),
            iconSize: 32,
            color: _currentPage < _totalPages - 1
                ? const Color(0xFF6366F1)
                : Colors.grey,
          ),
        ],
      ),
    );
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _goToPage(_currentPage - 1);
    }
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages - 1) {
      _goToPage(_currentPage + 1);
    }
  }

  void _goToPage(int page) {
    _pdfController?.setPage(page);
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${suffixes[i]}';
  }

  @override
  void dispose() {
    // Clean up the downloaded file if needed
    if (_localPath != null) {
      final file = File(_localPath!);
      if (file.existsSync()) {
        file.delete().catchError((e) {
          // Ignore deletion errors
          return file;
        });
      }
    }
    super.dispose();
  }
}
