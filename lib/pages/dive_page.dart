import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/scheduler.dart';
import 'dart:collection';

import '../image/fish_sprite.dart';
import '../image/image_url_cache.dart';
import 'biota_info_sheet.dart';
import 'biota_list_page.dart';
import '../class_service/quest_service.dart';

final supabase = Supabase.instance.client;

class DivePage extends StatefulWidget {
  const DivePage({super.key});

  @override
  State<DivePage> createState() => _DivePageState();
}

class _DivePageState extends State<DivePage> with TickerProviderStateMixin {
  // ==== CONFIG ====
  static const String bucketName = 'aquaverse';
  static const double pxPerMeter = 12.0;
  static const double dragSensitivity = 2.8;

  // Anti overlap config
  static const double depthBandMeters = 4.0; // grouping per 4m
  static const double minGapFactor = 0.85; // min gap relatif ukuran ikan

  double _depth = 0;
  double _maxDepth = 200;

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _biota = [];

  // swimmers identity stabil
  final Map<int, _Swimmer> _swimmersById = {};
  bool _swimmersReady = false;

  // band index -> list swimmer ids (stabil)
  final Map<int, List<int>> _bands = {};

  late final Ticker _ticker;
  Duration _last = Duration.zero;

  // jangan setState tiap frame
  final ValueNotifier<int> _frameTick = ValueNotifier<int>(0);

  // selected
  int? _selectedId;
  bool _tapLock = false;

  // --- SCANNER STATE ---
  late final AnimationController _scanCtrl;
  int? _scanningId;
  bool _isScanning = false;
  final Set<int> _scannedIds = <int>{};

  @override
  void initState() {
    super.initState();

    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _loadDiveData();

    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      if (_last == Duration.zero) {
        _last = elapsed;
        return;
      }
      final dt = (elapsed - _last).inMilliseconds / 1000.0;
      _last = elapsed;
      _step(dt);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scanCtrl.dispose();
    _frameTick.dispose();
    super.dispose();
  }

  static DateTime? _parseUpdatedAt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  static String withVersion(String url, DateTime? updatedAt) {
    final v = updatedAt?.millisecondsSinceEpoch;
    if (v == null) return url;
    final join = url.contains('?') ? '&' : '?';
    return '$url${join}v=$v';
  }

  Future<void> _loadDiveData() async {
    setState(() {
      _loading = true;
      _error = null;

      _selectedId = null;
      _scannedIds.clear();
      _isScanning = false;
      _scanningId = null;

      _swimmersById.clear();
      _bands.clear();
      _swimmersReady = false;
    });

    try {
      final res = await supabase
          .from('biota')
          .select('id,nama,depth_meters,image_path,updated_at, size_scale')
          .order('depth_meters', ascending: true)
          .limit(800);

      final items = List<Map<String, dynamic>>.from(res);
      _biota = items;

      double maxD = 200;
      for (final b in items) {
        final d = (b['depth_meters'] as num?)?.toDouble() ?? 0.0;
        if (d > maxD) maxD = d;
      }
      _maxDepth = maxD;

      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final size = MediaQuery.sizeOf(context);
        _buildSwimmersOnce(size);
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _bandOfDepth(double meters) => (meters / depthBandMeters).floor();

  void _buildSwimmersOnce(Size size) {
    if (_swimmersReady) return;
    if (_biota.isEmpty) return;

    final w = size.width;
    final rnd = math.Random(42);

    // 1) build swimmers
    for (final b in _biota) {
      final id = (b['id'] as int?) ?? 0;
      if (id == 0) continue;

      final updatedAt = _parseUpdatedAt(b['updated_at']);
      final s = _Swimmer.fromRow(b, updatedAt: updatedAt);

      // band
      s.band = _bandOfDepth(s.depthMeters);

      _swimmersById[id] = s;
      (_bands[s.band] ??= []).add(id);
    }

    // 2) spawn X anti numpuk per band
    for (final entry in _bands.entries) {
      final ids = entry.value..sort();
      final n = ids.length;
      if (n == 0) continue;

      final step = w / (n + 0.6);
      for (int i = 0; i < n; i++) {
        final id = ids[i];
        final s = _swimmersById[id]!;
        final jitter = (rnd.nextDouble() - 0.5) * step * 0.22;
        s.x = ((i + 1) * step + jitter).clamp(0.0, w);

        if (rnd.nextBool()) {
          s.vx = s.vx.abs();
        } else {
          s.vx = -s.vx.abs();
        }
      }
    }

    setState(() => _swimmersReady = true);
  }

  void _applySeparation(Size size) {
    final w = size.width;
    for (final entry in _bands.entries) {
      final ids = entry.value;
      if (ids.length < 2) continue;

      ids.sort((a, b) => _swimmersById[a]!.x.compareTo(_swimmersById[b]!.x));

      for (int i = 0; i < ids.length - 1; i++) {
        final a = _swimmersById[ids[i]]!;
        final b = _swimmersById[ids[i + 1]]!;

        final base = 110.0;
        final aw = base * a.sizeScale;
        final bw = base * b.sizeScale;

        final minGap = (aw + bw) * 0.5 * minGapFactor;

        final dx = b.x - a.x;
        if (dx >= minGap) continue;

        final overlap = (minGap - dx);
        a.x = (a.x - overlap * 0.5).clamp(0.0, w);
        b.x = (b.x + overlap * 0.5).clamp(0.0, w);

        final toward = (a.vx > 0 && b.vx < 0);
        if (toward) {
          a.vx = -a.vx.abs();
          b.vx = b.vx.abs();
        }
      }
    }
  }

  void _step(double dt) {
    if (!_swimmersReady) {
      _frameTick.value++;
      return;
    }

    final size = MediaQuery.sizeOf(context);
    final w = size.width;

    for (final s in _swimmersById.values) {
      s.x += s.vx * dt;

      if (s.x < 0) {
        s.x = 0;
        s.vx = s.vx.abs();
      } else if (s.x > w) {
        s.x = w;
        s.vx = -s.vx.abs();
      }

      s.bobPhase += dt * s.bobSpeed;
      s.yOffset = math.sin(s.bobPhase) * s.bobAmp;
    }

    _applySeparation(size);

    _frameTick.value++;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final deltaDepth = (d.delta.dy * dragSensitivity) / pxPerMeter;
    final newDepth = (_depth - deltaDepth).clamp(0.0, _maxDepth);
    if (newDepth != _depth) {
      setState(() => _depth = newDepth);
    }
  }

  Map<String, dynamic>? _rowById(int id) {
    for (final r in _biota) {
      if ((r['id'] as int?) == id) return r;
    }
    return null;
  }

  _Swimmer? _swimmerById(int id) => _swimmersById[id];

  Rect? _fishRectFor(_Swimmer swimmer, Size size, bool isLandscape) {
    final anchorY =
        (swimmer.depthMeters - _depth) * pxPerMeter + size.height * 0.18;

    final base = isLandscape ? 105.0 : 90.0;
    final fishW = base * swimmer.sizeScale;
    final fishH = fishW * 0.70;

    final left = swimmer.x - fishW / 2;
    final top = anchorY + swimmer.yOffset - fishH / 2;
    return Rect.fromLTWH(left, top, fishW, fishH);
  }

  void _openBiotaRealCard(Map<String, dynamic> row) {
    final id = row['id'] as int?;
    if (id == null) return;

    if (_tapLock) return;
    _tapLock = true;
    Future.delayed(const Duration(milliseconds: 180), () => _tapLock = false);

    setState(() => _selectedId = id);

    showGeneralDialog(
      context: context,
      barrierLabel: 'biota-real',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.28),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) {
        return _BiotaRealOverlaySheet(
          bucketName: bucketName,
          row: row,
          onClose: () {
            Navigator.of(context, rootNavigator: true).pop();
            setState(() => _selectedId = null);
          },
          onOpenDetail: () {
            final id = row['id'] as int?;
            if (id == null) return;

            // 1) tutup preview dulu
            Navigator.of(context, rootNavigator: true).pop();
            setState(() => _selectedId = null);

            // 2) buka detail setelah dialog ketutup
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              BiotaInfoSheet.show(context, biotaId: id);
            });
          },
        );
      },
      transitionBuilder: (_, anim, __, child) {
        final t = Curves.easeOutCubic.transform(anim.value);
        return Transform.scale(
          scale: 0.98 + 0.02 * t,
          child: Opacity(opacity: t, child: child),
        );
      },
    );
  }

  void _onFishTap(Map<String, dynamic> row) {
    final id = row['id'] as int?;
    if (id == null) return;

    if (_tapLock) return;
    _tapLock = true;
    Future.delayed(const Duration(milliseconds: 180), () => _tapLock = false);

    if (_selectedId == id && _scannedIds.contains(id) && !_isScanning) {
      _openBiotaRealCard(row);
      return;
    }

    setState(() {
      _selectedId = id;
      _scanningId = id;
      _isScanning = true;
      _scannedIds.remove(id);
    });

    _scanCtrl
      ..stop()
      ..reset()
      ..repeat();

    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      if (_scanningId != id) return;

      _scanCtrl.stop();
      setState(() {
        _isScanning = false;
        if (!_scannedIds.contains(id)){
          _scannedIds.add(id);
          QuestService().trackScanFish();
        }
      });
    });
  }

  void _clearSelection() {
    if (_selectedId == null) return;
    if (_isScanning) return;
    setState(() {
      _selectedId = null;
      _scanningId = null;
    });
  }

  String _getZoneName(double depth) {
    if (depth < 200) return "Sunlight Zone";
    if (depth < 1000) return "Twilight Zone";
    return "Midnight Zone";
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    final sunOpacity = (1.0 - (_depth / 150)).clamp(0.0, 0.3);

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_error != null)
            ? _ErrorView(error: _error!, onRetry: _loadDiveData)
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: _onDragUpdate,
                onTap: _clearSelection,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: _OceanBackground(depth: _depth),
                      ),
                    ),

                    // God Rays (Efek cahaya matahari di atas)
                    if (_depth < 150)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: sunOpacity,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white54,
                                    Colors.transparent,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Bubble Effect
                    const Positioned.fill(
                      child: IgnorePointer(child: BubbleEffect()),
                    ),

                    AnimatedBuilder(
                      animation: _frameTick,
                      builder: (_, __) {
                        return RepaintBoundary(
                          child: _SwimLayer(
                            biota: _biota,
                            swimmersById: _swimmersById,
                            depth: _depth,
                            isLandscape: isLandscape,
                            onSelect: _onFishTap,
                          ),
                        );
                      },
                    ),

                    AnimatedBuilder(
                      animation: Listenable.merge([_frameTick, _scanCtrl]),
                      builder: (_, __) {
                        if (_selectedId == null) return const SizedBox.shrink();
                        final id = _selectedId!;
                        final swimmer = _swimmerById(id);
                        if (swimmer == null) return const SizedBox.shrink();

                        final rect = _fishRectFor(swimmer, size, isLandscape);
                        if (rect == null) return const SizedBox.shrink();

                        const extra = 220.0;
                        if (rect.bottom < -extra ||
                            rect.top > size.height + extra) {
                          return const SizedBox.shrink();
                        }

                        final row = _rowById(id) ?? const <String, dynamic>{};
                        final name = (row['nama'] ?? 'Unknown').toString();

                        return _ScanOverlay(
                          fishRect: rect,
                          label: name,
                          progress: _scanCtrl.value,
                          isScanning: _isScanning && _scanningId == id,
                          isScanned: _scannedIds.contains(id),
                          onOpenDetail: () {
                            if (_isScanning) return;
                            final row2 = _rowById(id);
                            if (row2 == null) return;
                            _openBiotaRealCard(row2);
                          },
                        );
                      },
                    ),

                    _DiveHud(
                      depth: _depth,
                      maxDepth: _maxDepth,
                      onBack: () => Navigator.pop(context),
                    ),

                    // Info Zona Laut
                    Positioned(
                      left: 20,
                      top: 80,
                      child: IgnorePointer(
                        child: Text(
                          _getZoneName(_depth),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),

                    // Scrollbar Kustom
                    _DepthScroller(
                      depth: _depth,
                      maxDepth: _maxDepth,
                      onChanged: (newDepth) {
                        setState(() => _depth = newDepth);
                      },
                    ),

                    // Tombol ke Logbook (BiotaListPage)
                    Positioned(
                      bottom: 30,
                      left: 20,
                      child: FloatingActionButton.extended(
                        heroTag: 'dive_to_logbook',
                        backgroundColor: Colors.white.withOpacity(0.15),
                        label: const Text(
                          "Logbook",
                          style: TextStyle(color: Colors.white),
                        ),
                        icon: const Icon(Icons.menu_book, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BiotaListPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SwimLayer extends StatelessWidget {
  final List<Map<String, dynamic>> biota;
  final Map<int, _Swimmer> swimmersById;
  final double depth;
  final bool isLandscape;
  final void Function(Map<String, dynamic> row) onSelect;

  const _SwimLayer({
    required this.biota,
    required this.swimmersById,
    required this.depth,
    required this.isLandscape,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final byId = HashMap<int, Map<String, dynamic>>();
    for (final b in biota) {
      final id = b['id'] as int?;
      if (id != null) byId[id] = b;
    }

    const viewportPadding = 300.0;
    final base = isLandscape ? 125.0 : 110.0;

    final visible = <_VisibleFish>[];

    for (final entry in swimmersById.entries) {
      final id = entry.key;
      final s = entry.value;

      final row = byId[id];
      if (row == null) continue;
      if (s.storagePath.isEmpty) continue;

      final fishW = base * s.sizeScale;
      final fishH = fishW * 0.70;

      final anchorY =
          (s.depthMeters - depth) * _DivePageState.pxPerMeter +
          size.height * 0.18;
      final y = anchorY + s.yOffset - fishH / 2;

      if (y < -viewportPadding || y > size.height + viewportPadding) continue;

      visible.add(
        _VisibleFish(
          id: id,
          row: row,
          swimmer: s,
          top: y,
          fishW: fishW,
          fishH: fishH,
        ),
      );
    }

    visible.sort((a, b) => a.swimmer.scale.compareTo(b.swimmer.scale));

    return Stack(
      children: visible.map((v) {
        final s = v.swimmer;
        final opacityBase = 1.0;

        double fade = 1.0;
        const fadeDist = 90.0;
        if (v.top < 0) fade = (1 - (-v.top / fadeDist)).clamp(0.0, 1.0);
        if (v.top > size.height - v.fishH) {
          final over = v.top - (size.height - v.fishH);
          fade = (1 - (over / fadeDist)).clamp(0.0, 1.0);
        }
        final opacity = (opacityBase * fade).clamp(0.0, 1.0).toDouble();

        return Positioned(
          key: ValueKey('fish_${v.id}'),
          left: s.x - v.fishW / 2,
          top: v.top,
          child: Opacity(
            opacity: opacity,
            child: GestureDetector(
              onTap: () => onSelect(v.row),
              child: FishSprite(
                storagePath: s.storagePath,
                bucket: _DivePageState.bucketName,
                updatedAt: s.updatedAt,
                width: v.fishW,
                height: v.fishH,
                duration: s.spriteDuration,
                flipX: s.vx > 0,
                animate: true,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _VisibleFish {
  final int id;
  final Map<String, dynamic> row;
  final _Swimmer swimmer;
  final double top;
  final double fishW;
  final double fishH;

  _VisibleFish({
    required this.id,
    required this.row,
    required this.swimmer,
    required this.top,
    required this.fishW,
    required this.fishH,
  });
}

class _Swimmer {
  final int id;
  String storagePath;
  double depthMeters;
  DateTime? updatedAt;

  // ukuran manual dari DB
  final double sizeScale;

  int band = 0;

  double x;
  double yOffset;
  double vx;

  final double bobAmp;
  final double bobSpeed;
  double bobPhase;

  final double z;
  final double scale;

  final Duration spriteDuration;

  _Swimmer({
    required this.id,
    required this.storagePath,
    required this.depthMeters,
    required this.updatedAt,
    required this.sizeScale,
    required this.x,
    required this.yOffset,
    required this.vx,
    required this.bobAmp,
    required this.bobSpeed,
    required this.bobPhase,
    required this.z,
    required this.scale,
    required this.spriteDuration,
  });

  factory _Swimmer.fromRow(Map<String, dynamic> b, {DateTime? updatedAt}) {
    final id = (b['id'] as int?) ?? 0;
    final rnd = math.Random(id * 9973);

    final depth = (b['depth_meters'] as num?)?.toDouble() ?? 0.0;

    final raw = (b['image_path'] ?? '').toString().trim();
    final filename = raw.split('/').last;
    final path = filename.isEmpty ? '' : 'biota/$filename';

    // === SIZE SCALE PROPORSIONAL (untuk semua biota) ===
    // Ambil dari DB. Anggap ini "rating ukuran" (bebas kamu isi).
    // Kita dukung 2 skenario umum:
    // - kalau kamu isi 0..1 (float), langsung dipakai sebagai ratio
    // - kalau kamu isi 1..5 / 1..10 (int), kita normalize ke 0..1
    final rawDb = (b['size_scale'] as num?)?.toDouble();

    double t;
    if (rawDb == null) {
      t = 0.5; // default tengah
    } else if (rawDb <= 1.2) {
      // asumsi sudah 0..1-ish
      t = rawDb.clamp(0.0, 1.0);
    } else if (rawDb <= 5.0) {
      // asumsi 1..5
      t = ((rawDb - 1.0) / 4.0).clamp(0.0, 1.0);
    } else if (rawDb <= 10.0) {
      // asumsi 1..10
      t = ((rawDb - 1.0) / 9.0).clamp(0.0, 1.0);
    } else {
      // kalau ada yang aneh (mis. 50), clamp aja biar aman
      t = 1.0;
    }

    // Map t (0..1) ke skala aman. Ini bikin semua biota "berbeda",
    // tapi ga ada yang kegedean / kekecilan ekstrem.
    // Kamu bisa tweak range ini:
    // const minSize = 0.82;
    // const maxSize = 1.18;
    // ambil score dari DB (2..10)
    final sizeScore = (b['size_scale'] as num?)?.toDouble() ?? 5.0;

    // clamp biar aman kalau ada data nyasar
    final s = sizeScore.clamp(1.0, 10.0);

    // map 1..10 -> 0.70..1.35 (aman, beda terasa)
    double mappedScale(double v) {
      // normalize 1..10 => 0..1
      final t = (v - 1.0) / 9.0;
      // ease biar kecil gak kegedean, gede gak ekstrem
      final eased = t * t * (3 - 2 * t); // smoothstep
      return 0.55 + (1.35 - 0.55) * eased;
    }

    final sizeScale = mappedScale(s);

    // === z dimatiin biar gak ada efek jauh-dekat aneh ===
    final z = 1.0;
    final scale = 1.0; // base scale tetap 1 (biar gak dobel efek)

    // speed tidak tergantung ukuran biar semua enak
    final baseSpeed = 22 + rnd.nextDouble() * 22;
    final vx = (rnd.nextBool() ? 1 : -1) * baseSpeed;

    // bobbing tetap hidup, amp bisa sedikit ikut sizeScale biar natural
    final bobAmp = (5 + rnd.nextDouble() * 12) * (0.85 + 0.3 * t);
    final bobSpeed = 1.2 + rnd.nextDouble() * 1.8;
    final bobPhase = rnd.nextDouble() * math.pi * 2;

    final spriteMs = 550 + rnd.nextInt(450);

    return _Swimmer(
      id: id,
      storagePath: path,
      depthMeters: depth,
      updatedAt: updatedAt,
      sizeScale: sizeScale,
      x: 0,
      yOffset: 0,
      vx: vx,
      bobAmp: bobAmp,
      bobSpeed: bobSpeed,
      bobPhase: bobPhase,
      z: z,
      scale: scale,
      spriteDuration: Duration(milliseconds: spriteMs),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  final Rect fishRect;
  final String label;
  final double progress;
  final bool isScanning;
  final bool isScanned;
  final VoidCallback onOpenDetail;

  const _ScanOverlay({
    required this.fishRect,
    required this.label,
    required this.progress,
    required this.isScanning,
    required this.isScanned,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final center = fishRect.center;

    final labelTop = (fishRect.top - 46).clamp(8.0, double.infinity);
    final placeBelow = labelTop == 8.0 && fishRect.top < 54;

    final chipTop = placeBelow ? (fishRect.bottom + 10) : labelTop;
    final chipLeft = (center.dx - 110).clamp(
      12.0,
      MediaQuery.sizeOf(context).width - 232,
    );

    return Stack(
      children: [
        Positioned(
          left: center.dx - 80,
          top: center.dy - 80,
          child: IgnorePointer(
            child: SizedBox(
              width: 160,
              height: 160,
              child: CustomPaint(
                painter: _ScanPainter(
                  progress: progress,
                  active: isScanning,
                  done: isScanned,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: chipLeft.toDouble(),
          top: chipTop.toDouble(),
          child: _GlassChip(
            title: label,
            subtitle: isScanning
                ? 'Scanning...'
                : (isScanned ? 'Tap untuk detail' : 'Tap untuk scan'),
            trailing: isScanned
                ? IconButton(
                    onPressed: onOpenDetail,
                    icon: const Icon(Icons.info_outline),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 18,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _ScanPainter extends CustomPainter {
  final double progress;
  final bool active;
  final bool done;

  _ScanPainter({
    required this.progress,
    required this.active,
    required this.done,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseR = math.min(size.width, size.height) / 2;
    final p = progress.clamp(0.0, 1.0);

    final r1 = baseR * (0.55 + 0.25 * p);
    final a1 = active ? (0.55 - 0.25 * p) : (done ? 0.55 : 0.0);

    final r2 = baseR * (0.35 + 0.45 * p);
    final a2 = active ? (0.30 - 0.20 * p) : 0.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    if (a1 > 0) {
      paint.color = Colors.white.withOpacity(a1.clamp(0.0, 1.0));
      canvas.drawCircle(center, r1, paint);
    }
    if (a2 > 0) {
      paint.strokeWidth = 2;
      paint.color = Colors.white.withOpacity(a2.clamp(0.0, 1.0));
      canvas.drawCircle(center, r2, paint);
    }

    if (active || done) {
      final crossPaint = Paint()
        ..color = Colors.white.withOpacity(active ? 0.65 : 0.55)
        ..strokeWidth = 2;

      canvas.drawLine(
        Offset(center.dx - 16, center.dy),
        Offset(center.dx + 16, center.dy),
        crossPaint,
      );
      canvas.drawLine(
        Offset(center.dx, center.dy - 16),
        Offset(center.dx, center.dy + 16),
        crossPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScanPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.active != active ||
        oldDelegate.done != done;
  }
}

class _GlassChip extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _GlassChip({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 220,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                IconTheme(
                  data: const IconThemeData(color: Colors.white),
                  child: trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error:\n$error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiveHud extends StatelessWidget {
  final double depth;
  final double maxDepth;
  final VoidCallback onBack;

  const _DiveHud({
    required this.depth,
    required this.maxDepth,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (depth / maxDepth).clamp(0.0, 1.0);

    return Positioned(
      left: 12,
      right: 12,
      top: 10,
      child: Row(
        children: [
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 12,
                backgroundColor: Colors.white.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(
                  Colors.white.withOpacity(0.55),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.20),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Text(
              '${depth.toStringAsFixed(0)} m',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepthScroller extends StatelessWidget {
  final double depth;
  final double maxDepth;
  final ValueChanged<double> onChanged;

  const _DepthScroller({
    required this.depth,
    required this.maxDepth,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Tinggi track scrollbar (misal 60% dari tinggi layar)
    final scrollTrackHeight = size.height * 0.6;
    final topOffset = size.height * 0.2; // Jarak dari atas

    // Hitung posisi kotak berdasarkan persentase depth
    final pct = (depth / maxDepth).clamp(0.0, 1.0);
    final knobPos = topOffset + (pct * scrollTrackHeight);

    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      width: 80, // Area sensitif sentuhan di kanan
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (details) {
          // Logika scrollbar biasa: posisi sentuhan menentukan nilai
          final localY = details.localPosition.dy - topOffset;
          final newPct = (localY / scrollTrackHeight).clamp(0.0, 1.0);
          onChanged(newPct * maxDepth);
        },
        child: Stack(
          children: [
            // Track Line (Garis tipis scrollbar)
            Positioned(
              right: 15,
              top: topOffset,
              height: scrollTrackHeight,
              width: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),

            // Knob / Kotak Angka
            Positioned(
              right: 10,
              top: knobPos - 20, // 20 adalah setengah tinggi kotak agar center
              child: _GlassDepthKnob(depth: depth),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassDepthKnob extends StatelessWidget {
  final double depth;
  const _GlassDepthKnob({required this.depth});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: 50,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                depth.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                'm',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OceanBackground extends StatelessWidget {
  final double depth;
  const _OceanBackground({required this.depth});

  @override
  Widget build(BuildContext context) {
    final t = (depth / 200).clamp(0.0, 1.0);
    final top = Color.lerp(
      const Color(0xFF0EA5E9),
      const Color(0xFF0B1020),
      t,
    )!;
    final bot = Color.lerp(
      const Color(0xFF083344),
      const Color(0xFF05070E),
      t,
    )!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [top, bot],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class BubbleEffect extends StatefulWidget {
  const BubbleEffect({super.key});
  @override
  State<BubbleEffect> createState() => _BubbleEffectState();
}

class _BubbleEffectState extends State<BubbleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<math.Point> _bubbles = List.generate(
    20,
    (_) => math.Point(math.Random().nextDouble(), math.Random().nextDouble()),
  );

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Stack(
        children: _bubbles.map((p) {
          final y = ((p.y - _ctrl.value) * size.height) % size.height;
          return Positioned(
            left: p.x * size.width,
            top: y,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BiotaRealOverlaySheet extends StatelessWidget {
  final String bucketName;
  final Map<String, dynamic> row;
  final VoidCallback onClose;
  final VoidCallback onOpenDetail;

  const _BiotaRealOverlaySheet({
    required this.bucketName,
    required this.row,
    required this.onClose,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final filename = (row['image_path'] ?? '')
        .toString()
        .trim()
        .split('/')
        .last;
    final updatedAt = DateTime.tryParse((row['updated_at'] ?? '').toString());

    final imgUrl = filename.isEmpty
        ? null
        : _DivePageState.withVersion(
            ImageUrlCache.publicUrl(
              bucket: bucketName,
              path: 'biota_real/$filename',
            ),
            updatedAt,
          );

    final name = (row['nama'] ?? 'Unknown').toString();

    final w = MediaQuery.sizeOf(context).width;
    final cardW = w.clamp(0.0, 420.0);

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: ConstrainedBox(
            constraints: BoxConstraints.tightFor(width: cardW),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.blueAccent,
                                decorationThickness: 1,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: onClose,
                            icon: const Icon(Icons.close),
                            color: Colors.white,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (imgUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: Image.network(
                              imgUrl,
                              fit: BoxFit.cover,
                              cacheWidth: 1200,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.white.withOpacity(0.08),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onOpenDetail,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.white.withOpacity(0.18),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.22),
                              ),
                            ),
                          ),
                          child: const Text(
                            'Lihat informasi',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
