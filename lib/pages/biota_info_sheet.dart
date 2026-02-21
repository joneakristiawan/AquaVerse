import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../image/image_url_cache.dart';

final supabase = Supabase.instance.client;

String _withVersion(String url, DateTime? updatedAt) {
  final v = updatedAt?.millisecondsSinceEpoch;
  if (v == null) return url;
  final join = url.contains('?') ? '&' : '?';
  return '$url${join}v=$v';
}

class BiotaInfoSheet {
  static Future<void> show(BuildContext context, {required int biotaId}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'biota-info',
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => _BiotaInfoDialog(biotaId: biotaId),
      transitionBuilder: (_, anim, __, child) {
        final t = Curves.easeOutCubic.transform(anim.value);
        return Transform.scale(
          scale: 0.98 + 0.02 * t,
          child: Opacity(opacity: t, child: child),
        );
      },
    );
  }
}

class _BiotaInfoDialog extends StatefulWidget {
  final int biotaId;
  const _BiotaInfoDialog({required this.biotaId});

  @override
  State<_BiotaInfoDialog> createState() => _BiotaInfoDialogState();
}

class _BiotaInfoDialogState extends State<_BiotaInfoDialog> {
  static const String bucketName = 'aquaverse';

  bool _loading = true;
  bool _isFavorited = false; // Status favorit
  String? _error;
  Map<String, dynamic>? _row;

  @override
  void initState() {
    super.initState();
    _fetch();
    _checkFavoriteStatus();
  }

  // Cek apakah biota ini ada di daftar favorit user
  Future<void> _checkFavoriteStatus() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final res = await supabase
          .from('favorit')
          .select()
          .eq('user_id', user.id)
          .eq('biota_id', widget.biotaId)
          .maybeSingle();

      if (mounted) {
        setState(() => _isFavorited = res != null);
      }
    } catch (e) {
      debugPrint("Error check favorite: $e");
    }
  }

  // Toggle Favorit (Tambah/Hapus)
  Future<void> _toggleFavorite() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final wasFavorited = _isFavorited;
    setState(() => _isFavorited = !wasFavorited); // Optimistic update

    try {
      if (wasFavorited) {
        await supabase.from('favorit').delete().match({
          'user_id': user.id,
          'biota_id': widget.biotaId,
        });
      } else {
        await supabase.from('favorit').insert({
          'user_id': user.id,
          'biota_id': widget.biotaId,
        });
      }
    } catch (e) {
      debugPrint("Error toggle favorite: $e");
      if (mounted) {
        setState(() => _isFavorited = wasFavorited); // Revert jika gagal
      }
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
      _row = null;
    });

    try {
      final res = await supabase
          .from('biota')
          .select(
            'id,nama,nama_latin,deskripsi,habitat,status_konservasi,fakta_unik,depth_meters,image_path,updated_at',
          )
          .eq('id', widget.biotaId)
          .maybeSingle();

      if (res == null) {
        throw 'Data biota tidak ditemukan.';
      }
      _row = Map<String, dynamic>.from(res);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  DateTime? _parseUpdatedAt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  String? _realImageUrl(Map<String, dynamic> row) {
    final filename = (row['image_path'] ?? '')
        .toString()
        .trim()
        .split('/')
        .last;
    if (filename.isEmpty) return null;

    final updatedAt = _parseUpdatedAt(row['updated_at']);
    final base = ImageUrlCache.publicUrl(
      bucket: bucketName,
      path: 'biota_real/$filename',
    );
    return _withVersion(base, updatedAt);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final cardW = w.clamp(0.0, 460.0);

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
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(22),
                          child: _LoadingView(),
                        )
                      : (_error != null)
                      ? Padding(
                          padding: const EdgeInsets.all(18),
                          child: _ErrorBox(
                            error: _error!,
                            onClose: () => Navigator.pop(context),
                          ),
                        )
                      : _Content(
                          row: _row!,
                          imageUrl: _realImageUrl(_row!),
                          isFavorited: _isFavorited,
                          onFavoriteToggle: _toggleFavorite,
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

class _Content extends StatelessWidget {
  final Map<String, dynamic> row;
  final String? imageUrl;
  final bool isFavorited;
  final VoidCallback onFavoriteToggle;

  const _Content({
    required this.row,
    required this.imageUrl,
    required this.isFavorited,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final name = (row['nama'] ?? 'Unknown').toString();
    final latin = (row['nama_latin'] ?? '').toString().trim();
    final habitat = (row['habitat'] ?? '').toString().trim();
    final desc = (row['deskripsi'] ?? '').toString().trim();
    final fakta = (row['fakta_unik'] ?? '').toString().trim();
    final status = (row['status_konservasi'] ?? '').toString().trim();
    final depth = (row['depth_meters'] as num?)?.toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.blueAccent,
                        decorationThickness: 1,
                        fontFamily: 'Montserrat'
                      ),
                    ),
                    if (latin.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        latin,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.80),
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                          decoration: TextDecoration.none,
                          fontFamily: 'Montserrat'
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Tombol Favorit (Love)
              IconButton(
                onPressed: onFavoriteToggle,
                icon: Icon(
                  isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: isFavorited ? Colors.redAccent : Colors.white,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                color: Colors.white,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Image
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  cacheWidth: 1400,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.white.withOpacity(0.08),
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image, color: Colors.white),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Chips
          if (depth != null || status.isNotEmpty) ...[
            SizedBox(
              height: 34,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    if (depth != null)
                      _StatPill(
                        icon: Icons.water,
                        label: 'Depth',
                        value: '${depth.toStringAsFixed(0)} m',
                      ),
                    if (depth != null && status.isNotEmpty)
                      const SizedBox(width: 8),
                    if (status.isNotEmpty)
                      _StatPill(
                        icon: Icons.verified,
                        label: 'Status',
                        value: status,
                      ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Sections
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  if (habitat.isNotEmpty)
                    _Section(
                      icon: Icons.place,
                      title: 'Habitat',
                      body: habitat,
                    ),
                  if (desc.isNotEmpty)
                    _Section(
                      icon: Icons.subject,
                      title: 'Deskripsi',
                      body: desc,
                    ),
                  if (fakta.isNotEmpty)
                    _Section(
                      icon: Icons.auto_awesome,
                      title: 'Fakta unik',
                      body: fakta,
                    ),
                  if (habitat.isEmpty && desc.isEmpty && fakta.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Belum ada informasi tambahan untuk biota ini.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.80),
                          decoration: TextDecoration.none, 
                          fontFamily: 'Montserrat'
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.white.withOpacity(0.18),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withOpacity(0.22)),
                ),
              ),
              child: const Text(
                'Tutup',
                style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Montserrat'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sub-widgets tetap sama (_Section, _StatPill, _LoadingView, _ErrorBox)
class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Section({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.blueAccent,
                    decorationThickness: 2,
                    fontFamily: 'Montserrat'
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.86),
                    decoration: TextDecoration.none,
                    height: 1.35,
                    fontSize: 12.5, 
                    fontFamily: 'Afacad'
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

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withOpacity(0.9)),
          const SizedBox(width: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label  ',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Afacad'
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.85)),
        ),
        const SizedBox(height: 12),
        Text(
          'Memuat informasi...',
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 14,
            decoration: TextDecoration.none,
            fontFamily: 'Montserrat'
          ),
        ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String error;
  final VoidCallback onClose;
  const _ErrorBox({required this.error, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 32),
        const SizedBox(height: 10),
        Text(
          error,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.90),
            decoration: TextDecoration.none,
            fontFamily: 'Montserrat'
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onClose,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.white.withOpacity(0.18),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.22)),
              ),
            ),
            child: const Text('Tutup', style: TextStyle(fontFamily: 'Montserrat'),),
          ),
        ),
      ],
    );
  }
}
