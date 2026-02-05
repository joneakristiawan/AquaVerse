import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dive_page.dart';
import 'biota_info_sheet.dart';

final supabase = Supabase.instance.client;

class BiotaListPage extends StatefulWidget {
  const BiotaListPage({super.key});

  @override
  State<BiotaListPage> createState() => _BiotaListPageState();
}

class _BiotaListPageState extends State<BiotaListPage> {
  // ==== STORAGE CONFIG ====
  static const String _bucket = 'aquaverse';
  static const String _realFolder = 'biota_real';

  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _kategori = [];

  bool _loading = true;
  String? _error;

  int? _selectedKategoriId;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _init();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final text = _searchCtrl.text.trim();
      if (text == _keyword) return;
      setState(() => _keyword = text);
      _loadBiota();
    });
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Future.wait([_loadKategori(), _loadBiota()]);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadKategori() async {
    final res = await supabase
        .from('kategori')
        .select('id,nama')
        .order('nama', ascending: true);

    _kategori = List<Map<String, dynamic>>.from(res);
    if (mounted) setState(() {});
  }

  /// ✅ Query list dibuat ringan:
  /// - jangan ambil deskripsi panjang dll
  /// - cukup yang diperlukan untuk list
  Future<void> _loadBiota() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final builder = supabase
          .from('biota')
          .select(
            'id,nama,nama_latin,image_path,depth_meters,kategori_id,kategori(nama)',
          );

      dynamic q = builder;

      if (_selectedKategoriId != null) {
        q = q.eq('kategori_id', _selectedKategoriId);
      }

      if (_keyword.isNotEmpty) {
        q = q.or('nama.ilike.%$_keyword%,nama_latin.ilike.%$_keyword%');
      }

      final res = await q.order('depth_meters', ascending: true).limit(300);
      _items = List<Map<String, dynamic>>.from(res);

      // ✅ precache beberapa thumbnail pertama biar terasa cepat
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx = context;
        for (final b in _items.take(10)) {
          final url = _thumbUrlFromRow(b);
          if (url != null) precacheImage(NetworkImage(url), ctx);
        }
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fileNameFromImagePath(dynamic imagePath) {
    final raw = (imagePath ?? '').toString().trim();
    if (raw.isEmpty) return '';
    return raw
        .split('/')
        .last; // aman kalau DB berisi "clownfish.png" atau "biota/clownfish.png"
    // kamu sekarang pakai "clownfish.png" => aman
  }

  String? _thumbUrlFromRow(Map<String, dynamic> b) {
    final filename = _fileNameFromImagePath(b['image_path']);
    if (filename.isEmpty) return null;
    final path = '$_realFolder/$filename';
    return ImageUrlCache.publicUrl(bucket: _bucket, path: path);
  }

  void _openDetail(int biotaId) {
    // panggil dialog glass yang baru
    BiotaInfoSheet.show(context, biotaId: biotaId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biota Laut'),
        // ✅ refresh dibuang (lebih clean & gak memicu spam reload)
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari biota (nama / latin)...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _keyword.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchCtrl.clear();
                            FocusScope.of(context).unfocus();
                          },
                          icon: const Icon(Icons.close),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            // Filter kategori (chip)
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Semua'),
                      selected: _selectedKategoriId == null,
                      onSelected: (v) {
                        setState(() => _selectedKategoriId = null);
                        _loadBiota();
                      },
                    ),
                  ),
                  ..._kategori.map((k) {
                    final id = k['id'] as int;
                    final nama = (k['nama'] ?? '').toString();
                    final selected = _selectedKategoriId == id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(nama),
                        selected: selected,
                        onSelected: (v) {
                          setState(() => _selectedKategoriId = v ? id : null);
                          _loadBiota();
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DivePage()),
          );
        },
        icon: const Icon(Icons.waves),
        label: const Text('Dive'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error:\n$_error', textAlign: TextAlign.center),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _init,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Data biota kosong.\nIsi dulu di Supabase (Table Editor / SQL).',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final b = _items[i];

        final id = (b['id'] as int?) ?? 0;
        final nama = (b['nama'] ?? '-').toString();
        final latin = (b['nama_latin'] ?? '').toString();
        final depth = b['depth_meters']?.toString() ?? '0';
        final kategoriNama = (b['kategori']?['nama'] ?? '').toString();

        final thumbUrl = _thumbUrlFromRow(b);

        return InkWell(
          onTap: () => _openDetail(id),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Row(
              children: [
                // ✅ Thumbnail: pakai biota_real (lebih relevan), tapi di-decode kecil
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                  child: SizedBox(
                    width: 92,
                    height: 92,
                    child: (thumbUrl == null)
                        ? Container(
                            color: Colors.black12,
                            child: const Icon(Icons.image, size: 28),
                          )
                        : Image.network(
                            thumbUrl,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            filterQuality: FilterQuality.none,

                            // ✅ ini yang bikin decode ringan & cepat
                            cacheWidth: 240,
                            cacheHeight: 240,

                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: Colors.black12,
                                child: const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.black12,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                  ),
                ),

                // Text
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (latin.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            latin,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _Pill(text: '${depth}m'),
                            const SizedBox(width: 8),
                            if (kategoriNama.isNotEmpty)
                              _Pill(text: kategoriNama),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// =======================
/// DETAIL SHEET (POPUP BAGUS)
/// =======================
class _BiotaDetailSheet extends StatefulWidget {
  final int biotaId;
  const _BiotaDetailSheet({required this.biotaId});

  @override
  State<_BiotaDetailSheet> createState() => _BiotaDetailSheetState();
}

class _BiotaDetailSheetState extends State<_BiotaDetailSheet> {
  static const String _bucket = 'aquaverse';
  static const String _realFolder = 'biota_real';
  static const String _spriteFolder = 'biota';

  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadDetail();
  }

  Future<Map<String, dynamic>> _loadDetail() async {
    final res = await supabase
        .from('biota')
        .select('''
          id,
          nama,
          nama_latin,
          deskripsi,
          habitat,
          status_konservasi,
          fakta_unik,
          depth_meters,
          image_path,
          kategori(nama)
        ''')
        .eq('id', widget.biotaId)
        .single();

    return Map<String, dynamic>.from(res);
  }

  String _fileName(dynamic imagePath) {
    final raw = (imagePath ?? '').toString().trim();
    if (raw.isEmpty) return '';
    return raw.split('/').last;
  }

  String? _realUrl(Map<String, dynamic> b) {
    final fn = _fileName(b['image_path']);
    if (fn.isEmpty) return null;
    final path = '$_realFolder/$fn';
    return ImageUrlCache.publicUrl(bucket: _bucket, path: path);
  }

  String? _spriteUrl(Map<String, dynamic> b) {
    final fn = _fileName(b['image_path']);
    if (fn.isEmpty) return null;
    final path = '$_spriteFolder/$fn';
    return ImageUrlCache.publicUrl(bucket: _bucket, path: path);
  }

  String _meters(dynamic v) {
    final d = double.tryParse(v.toString());
    if (d == null) return '${v}m';
    if (d % 1 == 0) return '${d.toInt()}m';
    return '${d.toStringAsFixed(1)}m';
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(22),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Gagal memuat detail',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(snap.error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Tutup'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              setState(() => _future = _loadDetail()),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba lagi'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          final b = snap.data!;

          final nama = (b['nama'] ?? '-').toString();
          final latin = (b['nama_latin'] ?? '').toString();
          final deskripsi = (b['deskripsi'] ?? '').toString();
          final habitat = (b['habitat'] ?? '').toString();
          final status = (b['status_konservasi'] ?? '').toString();
          final fakta = (b['fakta_unik'] ?? '').toString();
          final kategoriNama = (b['kategori']?['nama'] ?? '').toString();
          final depth = b['depth_meters'];
          final depthText = depth == null ? '-' : _meters(depth);

          final realUrl = _realUrl(b);
          final spriteUrl = _spriteUrl(b);

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            minChildSize: 0.45,
            maxChildSize: 0.95,
            builder: (context, scrollCtrl) {
              return SingleChildScrollView(
                controller: scrollCtrl,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),

                      // FOTO REAL (fallback ke sprite)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: _SmartImage(
                            primaryUrl: realUrl,
                            fallbackUrl: spriteUrl,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nama,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (latin.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    latin,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            tooltip: 'Tutup',
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ChipPill(icon: Icons.waves, label: depthText),
                          if (kategoriNama.isNotEmpty)
                            _ChipPill(
                              icon: Icons.category_rounded,
                              label: kategoriNama,
                            ),
                          if (status.isNotEmpty)
                            _ChipPill(
                              icon: Icons.shield_rounded,
                              label: status,
                            ),
                          if (habitat.isNotEmpty)
                            _ChipPill(
                              icon: Icons.place_rounded,
                              label: habitat,
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      _SectionCard(
                        title: 'Deskripsi',
                        icon: Icons.menu_book_rounded,
                        child: Text(
                          deskripsi.isEmpty
                              ? 'Belum ada deskripsi.'
                              : deskripsi,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ),

                      if (fakta.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _SectionCard(
                          title: 'Fakta unik',
                          icon: Icons.auto_awesome_rounded,
                          child: Text(
                            fakta,
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
                              label: const Text('Tutup'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Image yang coba primary dulu (real), kalau error -> fallback (sprite)
class _SmartImage extends StatefulWidget {
  final String? primaryUrl;
  final String? fallbackUrl;

  const _SmartImage({required this.primaryUrl, required this.fallbackUrl});

  @override
  State<_SmartImage> createState() => _SmartImageState();
}

class _SmartImageState extends State<_SmartImage> {
  bool _useFallback = false;

  @override
  void didUpdateWidget(covariant _SmartImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryUrl != widget.primaryUrl ||
        oldWidget.fallbackUrl != widget.fallbackUrl) {
      _useFallback = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _useFallback ? widget.fallbackUrl : widget.primaryUrl;

    if (url == null) {
      return Container(
        color: Colors.black.withOpacity(0.06),
        child: const Center(child: Icon(Icons.image, size: 30)),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,

      // ✅ decode sesuai ukuran area sheet (biar ga berat)
      cacheWidth: 720,

      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.black.withOpacity(0.06),
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) {
        if (!_useFallback && widget.fallbackUrl != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _useFallback = true);
          });
          return Container(
            color: Colors.black.withOpacity(0.06),
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return Container(
          color: Colors.black.withOpacity(0.06),
          child: const Center(child: Icon(Icons.broken_image)),
        );
      },
    );
  }
}

class _SheetShell extends StatelessWidget {
  final Widget child;
  const _SheetShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ChipPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// GLOBAL URL CACHE (string URL saja)
/// =======================
class ImageUrlCache {
  ImageUrlCache._();

  static final Map<String, String> _cache = {};

  static String publicUrl({required String bucket, required String path}) {
    final key = '$bucket|$path';
    return _cache.putIfAbsent(
      key,
      () => Supabase.instance.client.storage.from(bucket).getPublicUrl(path),
    );
  }

  static void clear() => _cache.clear();
}
