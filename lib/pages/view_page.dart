import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PdfViewerPage extends StatefulWidget {
  final String path;

  const PdfViewerPage({required this.path});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late PdfViewerController _controller;
  bool _isScrollingUp = false;
  bool _isScrollingDown = false;

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
  }

  void _startScroll({required bool down}) async {
    const duration = Duration(milliseconds: 16); // ~60fps
    const speed = 20.0;

    while ((down && _isScrollingDown) || (!down && _isScrollingUp)) {
      double currentOffset = _controller.scrollOffset.dy;
      double newOffset = currentOffset + (down ? speed : -speed);

      _controller.jumpTo(yOffset: newOffset.clamp(0.0, double.infinity));
      await Future.delayed(duration);
    }
  }

  void _scrollUpPress() {
    _isScrollingUp = true;
    _startScroll(down: false);
  }

  void _scrollDownPress() {
    _isScrollingDown = true;
    _startScroll(down: true);
  }

  void _stopScroll() {
    _isScrollingUp = false;
    _isScrollingDown = false;
  }

  void _scrollToTop() {
    _controller.jumpTo(yOffset: 0);
  }

  @override
  void dispose() {
    _isScrollingUp = false;
    _isScrollingDown = false;
    super.dispose();
  }

  void _onPageChanged(PdfPageChangedDetails details) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastPage_${widget.path}', details.newPageNumber);
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) async {
    final prefs = await SharedPreferences.getInstance();
    final lastPage = prefs.getInt('lastPage_${widget.path}');
    if (lastPage != null &&
        lastPage > 0 &&
        lastPage <= details.document.pages.count) {
      _controller.jumpToPage(lastPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.path.split('/').last.replaceAll(RegExp(r'[_\-\+]'), ' '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.pixels <= 0 &&
                  notification is OverscrollNotification &&
                  notification.overscroll < 0) {
                // Tampilkan loading dan refresh data
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      Center(child: CircularProgressIndicator()),
                );
                // Simulasi refresh, misal reload dokumen
                Future.delayed(Duration(seconds: 1), () {
                  Navigator.of(context).pop(); // tutup loading
                  setState(
                      () {}); // reload widget, bisa diganti dengan fungsi refresh lain
                });
              }
              return false;
            },
            child: SfPdfViewer.file(
              File(widget.path),
              controller: _controller,
              scrollDirection: PdfScrollDirection.vertical,
              onPageChanged: _onPageChanged,
              onDocumentLoaded: _onDocumentLoaded,
            ),
          ),
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height / 2 - 200,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'scroll-top',
                  onPressed: _scrollToTop,
                  mini: true,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.vertical_align_top),
                ),
                SizedBox(height: 12),
                GestureDetector(
                  onTapDown: (_) => _scrollUpPress(),
                  onTapUp: (_) => _stopScroll(),
                  onTapCancel: () => _stopScroll(),
                  child: FloatingActionButton(
                    heroTag: 'scroll-up',
                    mini: true,
                    child: Icon(Icons.arrow_upward),
                    onPressed: null, // disable normal press
                  ),
                ),
                SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'close',
                  onPressed: () => Navigator.pop(context),
                  mini: true,
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.close),
                ),
                SizedBox(height: 12),
                GestureDetector(
                  onTapDown: (_) => _scrollDownPress(),
                  onTapUp: (_) => _stopScroll(),
                  onTapCancel: () => _stopScroll(),
                  child: FloatingActionButton(
                    heroTag: 'scroll-down',
                    mini: true,
                    child: Icon(Icons.arrow_downward),
                    onPressed: null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
