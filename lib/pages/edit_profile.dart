// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final supabase = Supabase.instance.client;

  static const baseColor = Color.fromRGBO(30, 134, 185, 1);

  // Banner sama kayak HomePage / Profile
  static const _homeBannerUrl =
      "https://ccuigpzseuhwietjcyyi.supabase.co/storage/v1/object/public/aquaverse/assets/images/home/Banner-no-logo.jpg";

  final _formKey = GlobalKey<FormState>();

  final _usernameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController(); // cuma UI, gak dipakai update

  bool _loading = true;
  bool _saving = false;
  String? _error;

  // buat header
  String _rankName = 'DIVER';
  String _badgeUrl = '';
  String _usernameHeader = '...';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) {
        throw Exception('User belum login');
      }

      final res = await supabase
          .from('profiles')
          .select('''
            username,
            name,
            email,
            user_rank (
              points,
              ranks (
                id,
                name,
                image_url
              )
            )
          ''')
          .eq('id', uid)
          .single();

      final username = (res['username'] ?? '').toString();
      final name = (res['name'] ?? '').toString();
      final email = (res['email'] ?? '').toString();

      _usernameCtrl.text = username;
      _nameCtrl.text = name;
      _emailCtrl.text = email;

      final userRank = res['user_rank'] as Map<String, dynamic>?;
      final rankData = userRank?['ranks'] as Map<String, dynamic>?;
      _rankName = (rankData?['name'] ?? 'DIVER').toString();

      final imageFile = (rankData?['image_url'] ?? '').toString();
      _badgeUrl = imageFile.isEmpty
          ? ''
          : supabase.storage
                .from('aquaverse')
                .getPublicUrl('assets/images/ranks/$imageFile');

      _usernameHeader = username.isEmpty ? 'Diver' : username;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    final username = _usernameCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      // Update cuma ke profiles (sesuai permintaan)
      await supabase
          .from('profiles')
          .update({'username': username, 'name': name, 'email': email})
          .eq('id', uid);

      if (!mounted) return;

      setState(() {
        _usernameHeader = username;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );
    } on PostgrestException catch (e) {
      // handle username unique constraint
      final msg = e.message.toLowerCase();
      if (msg.contains('duplicate') || msg.contains('unique')) {
        setState(() => _error = 'Username sudah dipakai user lain.');
      } else {
        setState(() => _error = e.message);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _load)
          : Stack(
              children: [
                Positioned.fill(child: Container(color: Colors.white)),

                // HEADER
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _HeaderOceanEdit(
                    title: 'Edit Profile & Account',
                    username: _usernameHeader,
                    badgeUrl: _badgeUrl,
                    rankName: _rankName,
                    onBack: () => Navigator.pop(context),
                  ),
                ),

                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 240),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Identify Information',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color.fromRGBO(63, 68, 102, 1),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(height: 1, color: Colors.black12),
                            const SizedBox(height: 14),

                            _Label('Username (Nickname)'),
                            _InputBox(
                              controller: _usernameCtrl,
                              hintText: 'Username',
                              prefixIcon: Icons.person_outline,
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) {
                                  return 'Username tidak boleh kosong';
                                }
                                if (s.length < 3) return 'Minimal 3 karakter';
                                return null;
                              },
                            ),

                            const SizedBox(height: 12),

                            _Label('Full Name'),
                            _InputBox(
                              controller: _nameCtrl,
                              hintText: 'Nama lengkap',
                              prefixIcon: Icons.badge_outlined,
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) return 'Nama tidak boleh kosong';
                                return null;
                              },
                            ),

                            const SizedBox(height: 12),

                            _Label('Email'),
                            _InputBox(
                              controller: _emailCtrl,
                              hintText: 'Email',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              textAlign: TextAlign.start,
                              enabled: false,
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) {
                                  return 'Email tidak boleh kosong';
                                }
                                if (!s.contains('@')) {
                                  return 'Format email tidak valid';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 12),

                            _Label('Password'),
                            _InputBox(
                              controller: _passwordCtrl,
                              hintText: '************',
                              prefixIcon: Icons.lock_outline,
                              obscureText: true,
                              enabled: false, // prototype doang
                            ),

                            const SizedBox(height: 18),

                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 56,
                                    child: ElevatedButton.icon(
                                      onPressed: _saving ? null : _save,
                                      icon: _saving
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.black54,
                                              ),
                                            )
                                          : const Icon(Icons.save_outlined),
                                      label: const Text(
                                        'Apply Changes',
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(
                                          255,
                                          221,
                                          244,
                                          255,
                                        ),
                                        foregroundColor: const Color.fromRGBO(
                                          63,
                                          68,
                                          102,
                                          1,
                                        ),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _HeaderOceanEdit extends StatelessWidget {
  final String title;
  final String username;
  final String badgeUrl;
  final String rankName;
  final VoidCallback onBack;

  static const _homeBannerUrl =
      "https://ccuigpzseuhwietjcyyi.supabase.co/storage/v1/object/public/aquaverse/assets/images/home/Banner-no-logo.jpg";

  const _HeaderOceanEdit({
    required this.title,
    required this.username,
    required this.badgeUrl,
    required this.rankName,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
      child: SizedBox(
        height: 240,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                _homeBannerUrl,
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(0.9),
              ),
            ),
            Positioned.fill(
              child: Container(
                color: const Color.fromARGB(
                  255,
                  75,
                  172,
                  251,
                ).withOpacity(0.35),
              ),
            ),

            // back button (kiri atas)
            Positioned(top: 46, left: 16, child: _BackPill(onTap: onBack)),

            // title (tengah)
            Positioned(
              top: 56,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // badge + username + rank
            Positioned(
              top: 92,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                          color: Colors.black.withOpacity(0.18),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: badgeUrl.isEmpty
                          ? const Center(child: Icon(Icons.emoji_events))
                          : Image.network(
                              badgeUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Center(child: Icon(Icons.emoji_events)),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9D9FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.scuba_diving, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              rankName.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackPill extends StatelessWidget {
  final VoidCallback onTap;
  const _BackPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.black54,
        ),
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final TextAlign textAlign;
  final String? Function(String?)? validator;

  const _InputBox({
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.textAlign = TextAlign.start,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textAlign: textAlign,
      validator: validator,
      style: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 191, 232, 247),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 120, 200, 235),
            width: 1.6,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 220, 220, 220),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
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
