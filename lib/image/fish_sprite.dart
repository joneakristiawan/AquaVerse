import 'package:flutter/material.dart';
import 'image_url_cache.dart';

class FishSprite extends StatefulWidget {
  /// Dari DB: "clownfish.png" / atau "biota/clownfish.png"
  final String storagePath;

  /// Cache-busting (ambil dari updated_at kolom biota)
  final DateTime? updatedAt;

  /// Bucket supabase storage
  final String bucket;

  /// Ukuran window (1 frame)
  final double width;
  final double height;

  /// Durasi loop 4 frame (2x2)
  final Duration duration;

  /// Mirror horizontal
  final bool flipX;

  /// Kalau false, hanya frame 0
  final bool animate;

  const FishSprite({
    super.key,
    required this.storagePath,
    this.updatedAt,
    this.bucket = 'aquaverse',
    this.width = 72,
    this.height = 48,
    this.duration = const Duration(milliseconds: 600),
    this.flipX = false,
    this.animate = true,
  });

  @override
  State<FishSprite> createState() => _FishSpriteState();
}

class _FishSpriteState extends State<FishSprite> with TickerProviderStateMixin {
  AnimationController? _controller;
  String _url = '';

  @override
  void initState() {
    super.initState();
    _syncController();
    _buildUrl();
  }

  @override
  void didUpdateWidget(covariant FishSprite oldWidget) {
    super.didUpdateWidget(oldWidget);

    // URL berubah kalau path/bucket/updatedAt berubah
    if (oldWidget.storagePath != widget.storagePath ||
        oldWidget.bucket != widget.bucket ||
        oldWidget.updatedAt != widget.updatedAt) {
      _buildUrl();
    }

    // Controller berubah kalau animate/duration berubah
    if (oldWidget.animate != widget.animate ||
        oldWidget.duration != widget.duration) {
      _syncController();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _syncController() {
    // selalu dispose dulu sebelum bikin baru
    _controller?.stop();
    _controller?.dispose();
    _controller = null;

    if (!widget.animate) return;

    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  String _normalizePath(String raw) {
    final p = raw.trim();
    if (p.isEmpty) return '';
    if (!p.contains('/')) return 'biota/$p';
    return p;
  }

  String _withVersion(String url) {
    final v = widget.updatedAt?.millisecondsSinceEpoch;
    if (v == null) return url;
    final join = url.contains('?') ? '&' : '?';
    return '$url${join}v=$v';
  }

  void _buildUrl() {
    final spritePath = _normalizePath(widget.storagePath);
    if (spritePath.isEmpty) {
      _url = '';
      return;
    }

    final baseUrl = ImageUrlCache.publicUrl(
      bucket: widget.bucket,
      path: spritePath,
    );

    _url = _withVersion(baseUrl);

    // precache biar muncul cepat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _url.isEmpty) return;
      precacheImage(NetworkImage(_url), context);
    });
  }

  int _currentFrame() {
    if (!widget.animate || _controller == null) return 0;
    return (_controller!.value * 4).floor() % 4;
  }

  @override
  Widget build(BuildContext context) {
    if (_url.isEmpty) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(child: Icon(Icons.image, size: 18)),
      );
    }

    final child = SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRect(
        child: (widget.animate && _controller != null)
            ? AnimatedBuilder(
                animation: _controller!,
                builder: (_, __) => _buildFrame(_currentFrame()),
              )
            : _buildFrame(0),
      ),
    );

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scale(widget.flipX ? -1.0 : 1.0, 1.0),
      child: child,
    );
  }

  Widget _buildFrame(int frame) {
    // 2x2 sheet: frame 0..3
    final xPos = (frame == 1 || frame == 3) ? -widget.width : 0.0;
    final yPos = (frame == 2 || frame == 3) ? -widget.height : 0.0;

    return Stack(
      children: [
        Positioned(
          left: xPos,
          top: yPos,
          width: widget.width * 2,
          height: widget.height * 2,
          child: Image.network(
            _url,
            fit: BoxFit.fill,
            gaplessPlayback: true,
            filterQuality: FilterQuality.none,

            // decode lebih ringan
            cacheWidth: (widget.width * 2).round(),
            cacheHeight: (widget.height * 2).round(),

            errorBuilder: (_, __, ___) =>
                const Center(child: Icon(Icons.broken_image)),
          ),
        ),
      ],
    );
  }
}
