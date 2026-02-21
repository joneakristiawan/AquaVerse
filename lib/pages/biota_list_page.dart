import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../image/image_url_cache.dart';

class BiotaListPage extends StatefulWidget {
  const BiotaListPage({super.key});

  @override
  State<BiotaListPage> createState() => _BiotaListPageState();
}

class _BiotaListPageState extends State<BiotaListPage> {
  final supabase = Supabase.instance.client;

  // ==== CONFIG & STYLE ====
  static const String _bucket = 'aquaverse';
  static const String _realFolder = 'biota_real';
  static const Color _headerBlue = Color.fromRGBO(148, 214, 245, 1);
  static const Color _titleNavy = Color.fromRGBO(63, 68, 102, 1);
  static const Color _pillBlue = Color.fromRGBO(217, 246, 252, 1);

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _kategori = [];

  bool _isFirstLoading = true;
  bool _isFiltering = false;

  String _searchQuery = '';
  Timer? _debounce;
  int? _selectedKategoriId;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // --- LOGIC: Popup Detail ---
  void _showBiotaDetail(BuildContext ctx, Map<String, dynamic> item) {
    if (!mounted) return;

    final String? imageUrl = _getThumbUrl(item);
    final String nama = (item['nama'] ?? '-').toString();
    final String latin = (item['nama_latin'] ?? '').toString();
    final String deskripsi = (item['deskripsi'] ?? 'Tidak ada deskripsi.')
        .toString();
    final String habitat = (item['habitat'] ?? '').toString();
    final String fakta = (item['fakta_unik'] ?? '').toString();
    final String status = (item['status_konservasi'] ?? '').toString();

    String kategori = 'UMUM';
    final kat = item['kategori'];
    if (kat is Map) {
      kategori = (kat['nama'] ?? 'UMUM').toString().toUpperCase();
    }

    final String depth = "${item['depth_meters'] ?? 0}m";

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (bottomSheetContext) {
        return Container(
          height: MediaQuery.of(bottomSheetContext).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: imageUrl != null
                            ? Image.network(
                                imageUrl,
                                width: double.infinity,
                                height: 250,
                                fit: BoxFit.cover,
                                cacheWidth: 600,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 250,
                                  color: Colors.grey[100],
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 50,
                                  ),
                                ),
                              )
                            : Container(
                                height: 250,
                                color: Colors.grey[100],
                                child: const Icon(Icons.image),
                              ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StatPill(
                            label: kategori,
                            color: _pillBlue,
                            textColor: _titleNavy,
                          ),
                          _StatPill(
                            label: "Kedalaman: $depth",
                            icon: Icons.water,
                            color: Colors.blue[50]!,
                            textColor: Colors.blue[800]!,
                          ),
                          if (status.isNotEmpty)
                            _StatPill(
                              label: status,
                              icon: Icons.verified,
                              color: Colors.green[50]!,
                              textColor: Colors.green[800]!,
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        nama,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _titleNavy,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      if (latin.isNotEmpty)
                        Text(
                          latin,
                          style: TextStyle(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      const Divider(height: 40, thickness: 1),
                      _DetailSection(
                        title: "Deskripsi",
                        content: deskripsi,
                        icon: Icons.subject,
                      ),
                      if (habitat.isNotEmpty)
                        _DetailSection(
                          title: "Habitat",
                          content: habitat,
                          icon: Icons.place,
                        ),
                      if (fakta.isNotEmpty)
                        _DetailSection(
                          title: "Fakta Unik",
                          content: fakta,
                          icon: Icons.auto_awesome,
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- DATABASE LOGIC ---
  Future<void> _initData() async {
    if (!mounted) return;
    try {
      setState(() => _isFirstLoading = true);
      await Future.wait([
        _loadKategori(),
        _loadBiota(query: _searchQuery, showSpinner: false),
      ]);
    } catch (e) {
      debugPrint("Init Error: $e");
    } finally {
      if (mounted) setState(() => _isFirstLoading = false);
    }
  }

  Future<void> _loadKategori() async {
    final res = await supabase
        .from('kategori')
        .select('id, nama')
        .order('nama', ascending: true);
    if (!mounted) return;
    setState(() => _kategori = List<Map<String, dynamic>>.from(res));
  }

  Future<void> _loadBiota({String query = '', bool showSpinner = true}) async {
    if (!mounted) return;
    if (showSpinner) setState(() => _isFiltering = true);
    try {
      dynamic request = supabase
          .from('biota')
          .select(
            'id, nama, nama_latin, image_path, depth_meters, kategori_id, deskripsi, habitat, fakta_unik, status_konservasi, kategori(nama)',
          );
      if (_selectedKategoriId != null) {
        request = request.eq('kategori_id', _selectedKategoriId!);
      }
      final trimmed = query.trim();
      if (trimmed.isNotEmpty) {
        request = request.or(
          'nama.ilike.%$trimmed%,nama_latin.ilike.%$trimmed%',
        );
      }
      final res = await request.order('depth_meters', ascending: true);
      if (!mounted) return;
      setState(() {
        _items = List<Map<String, dynamic>>.from(res);
      });
    } catch (e) {
      debugPrint("Load biota error: $e");
    } finally {
      if (mounted && showSpinner) setState(() => _isFiltering = false);
    }
  }

  String? _getThumbUrl(Map<String, dynamic> row) {
    final rawPath = (row['image_path'] ?? '').toString().trim();
    if (rawPath.isEmpty) return null;
    return ImageUrlCache.publicUrl(
      bucket: _bucket,
      path: '$_realFolder/${rawPath.split('/').last}',
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() => _searchQuery = value);
      _loadBiota(query: value, showSpinner: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final aquaVerseLogoUrl = supabase.storage
        .from('aquaverse')
        .getPublicUrl('assets/images/logo/Logo-AquaVerse.png');
    final logbookTextLogoUrl = supabase.storage
        .from('aquaverse')
        .getPublicUrl('assets/images/log/Text-AquaVerseLogbook.png');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 190,
            child: Container(
              padding: const EdgeInsets.only(top: 40),
              decoration: BoxDecoration(
                color: _headerBlue,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Image.network(aquaVerseLogoUrl, height: 55),
                        const SizedBox(width: 10),
                        Image.network(
                          logbookTextLogoUrl,
                          height: 40,
                          width: 250,
                          fit: BoxFit.cover,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 15,
                      left: 15,
                      right: 15,
                    ),
                    child: TextField(
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: "Cari biota (nama / latin)...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const _FrostedEffect(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 160),
              child: _isFirstLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          if (_searchQuery.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                "Hasil Pencarian",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  color: _titleNavy,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Text(
                                'Untuk: $_searchQuery',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                          ],
                          SizedBox(
                            height: 45,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              children: [
                                _buildCategoryChip('SEMUA', null),
                                ..._kategori.map(
                                  (k) => _buildCategoryChip(
                                    (k['nama'] as String).toUpperCase(),
                                    k['id'] as int,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          _items.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(40),
                                    child: Text("Biota tidak ditemukan."),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.only(bottom: 100),
                                  itemCount: _items.length,
                                  itemBuilder: (context, index) {
                                    return _BiotaTile(
                                      item: _items[index],
                                      imageUrl: _getThumbUrl(_items[index]),
                                      onTap: () => _showBiotaDetail(
                                        context,
                                        _items[index],
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Kembali'),
        backgroundColor: const Color.fromRGBO(30, 134, 185, 1),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildCategoryChip(String label, int? id) {
    final bool isSel = _selectedKategoriId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.black,
            fontWeight: isSel ? FontWeight.bold : FontWeight.w400,
          ),
        ),
        selected: isSel,
        onSelected: (_) {
          setState(() => _selectedKategoriId = id);
          _loadBiota(query: _searchQuery, showSpinner: true);
        },
        backgroundColor: Colors.grey[200],
        selectedColor: _pillBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: isSel ? _pillBlue : Colors.transparent),
        ),
      ),
    );
  }
}

class _BiotaTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final String? imageUrl;
  final VoidCallback onTap;
  const _BiotaTile({required this.item, this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String kat = (item['kategori'] != null ? item['kategori']['nama'] : 'UMUM')
        .toString()
        .toUpperCase();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      // ✅ KUNCI AGAR LIST TIDAK UNGU (MENGHILANGKAN SURFACE TINT MATERIAL 3)
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.blue.withValues(alpha: 0.1),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        cacheWidth: 220,
                        errorBuilder: (_, __, ___) => Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image),
                        ),
                      )
                    : Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kat,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      item['nama'] ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Color.fromRGBO(63, 68, 102, 1),
                      ),
                    ),
                    if (item['nama_latin'] != null)
                      Text(
                        item['nama_latin'],
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(217, 246, 252, 1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Kedalaman: ${item['depth_meters'] ?? 0}m",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(63, 68, 102, 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Color textColor;
  const _StatPill({
    required this.label,
    this.icon,
    required this.color,
    required this.textColor,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  const _DetailSection({
    required this.title,
    required this.content,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color.fromRGBO(63, 68, 102, 1)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(63, 68, 102, 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.7,
              color: Colors.black87,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}

class _FrostedEffect extends StatelessWidget {
  const _FrostedEffect();
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.75),
              Colors.white.withOpacity(0.0),
            ],
          ),
        ),
      ),
    );
  }
}
