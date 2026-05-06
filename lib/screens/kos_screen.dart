import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/empty_widget.dart';
import '../widgets/error_widget.dart';

class KosScreen extends StatefulWidget {
  const KosScreen({super.key});

  @override
  State<KosScreen> createState() => _KosScreenState();
}

class _KosScreenState extends State<KosScreen> {
  List<Kos> _kosList = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('kos');
      if (res['success'] == true) {
        setState(() {
          _kosList = (res['data'] as List).map((e) => Kos.fromJson(e)).toList();
        });
      } else {
        setState(() => _error = 'Gagal memuat data.');
      }
    } catch (e) {
      setState(() => _error = 'Koneksi gagal: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showForm({Kos? kos}) async {
    final namaCtrl = TextEditingController(text: kos?.namaKos ?? '');
    final hargaCtrl = TextEditingController(
        text: kos != null ? kos.harga.toStringAsFixed(0) : '');
    final lokasiCtrl = TextEditingController(text: kos?.lokasi ?? '');
    final deskCtrl  = TextEditingController(text: kos?.deskripsi ?? '');
    final formKey   = GlobalKey<FormState>();
    bool saving     = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(kos == null ? 'Tambah Kos' : 'Edit Kos',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 12),
                _field('Nama Kos', namaCtrl,
                    hint: 'Kos Putri Melati', required: true),
                const SizedBox(height: 10),
                _field('Harga / Bulan (Rp)', hargaCtrl,
                    hint: '750000',
                    keyboardType: TextInputType.number,
                    required: true),
                const SizedBox(height: 10),
                _field('Lokasi', lokasiCtrl,
                    hint: 'Jl. Sudirman No. 10', required: true),
                const SizedBox(height: 10),
                _field('Deskripsi', deskCtrl,
                    hint: 'Fasilitas dan info kos...', maxLines: 3),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModal(() => saving = true);
                            try {
                              final body = {
                                'nama_kos':  namaCtrl.text,
                                'harga':     double.tryParse(hargaCtrl.text) ?? 0,
                                'lokasi':    lokasiCtrl.text,
                                'deskripsi': deskCtrl.text.isEmpty
                                    ? null
                                    : deskCtrl.text,
                              };
                              Map<String, dynamic> res;
                              if (kos == null) {
                                res = await ApiService.post('kos', body);
                              } else {
                                res = await ApiService.put('kos/${kos.id}', body);
                              }
                              if (res['success'] == true) {
                                if (ctx.mounted) Navigator.pop(ctx);
                                _loadData();
                                _showSnack(kos == null
                                    ? 'Kos berhasil ditambahkan!'
                                    : 'Kos berhasil diperbarui!');
                              } else {
                                _showSnack('Gagal menyimpan.', isError: true);
                              }
                            } catch (e) {
                              _showSnack('Error: $e', isError: true);
                            } finally {
                              setModal(() => saving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A56DB),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(kos == null ? 'Simpan Kos' : 'Update Kos',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(Kos kos) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Hapus Kos?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('Yakin hapus "${kos.namaKos}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.delete('kos/${kos.id}');
        _loadData();
        _showSnack('Kos berhasil dihapus!');
      } catch (e) {
        _showSnack('Gagal menghapus.', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: const Color(0xFF1A56DB),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Kos',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF1A56DB),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1A56DB)))
            : _error != null
                ? AppErrorWidget(message: _error!, onRetry: _loadData)
                : _kosList.isEmpty
                    ? const EmptyWidget(
                        icon: Icons.house_outlined,
                        message: 'Belum ada data kos',
                        sub: 'Tap + untuk menambah kos baru')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                        itemCount: _kosList.length,
                        itemBuilder: (_, i) => _KosCard(
                          kos: _kosList[i],
                          onEdit: () => _showForm(kos: _kosList[i]),
                          onDelete: () => _delete(_kosList[i]),
                        ),
                      ),
      ),
    );
  }
}

class _KosCard extends StatelessWidget {
  final Kos kos;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _KosCard(
      {required this.kos, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.house_rounded,
                      color: Color(0xFF1A56DB), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kos.namaKos,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(kos.lokasi,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B))),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit_outlined,
                              size: 16, color: Color(0xFF1A56DB)),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ])),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline,
                              size: 16, color: Color(0xFFEF4444)),
                          SizedBox(width: 8),
                          Text('Hapus',
                              style: TextStyle(color: Color(0xFFEF4444))),
                        ])),
                  ],
                ),
              ],
            ),
            const Divider(height: 20, color: Color(0xFFF1F5F9)),
            Row(
              children: [
                _Chip(
                  icon: Icons.payments_outlined,
                  label:
                      'Rp ${_fmt(kos.harga)}/bln',
                  color: const Color(0xFF1A56DB),
                  bg: const Color(0xFFEFF6FF),
                ),
                const SizedBox(width: 8),
                _Chip(
                  icon: Icons.image_outlined,
                  label: '${kos.galeriCount ?? 0} foto',
                  color: const Color(0xFF8B5CF6),
                  bg: const Color(0xFFF5F3FF),
                ),
                const SizedBox(width: 8),
                _Chip(
                  icon: Icons.calendar_today_outlined,
                  label: '${kos.bookingCount ?? 0} booking',
                  color: const Color(0xFF06B6D4),
                  bg: const Color(0xFFECFEFF),
                ),
              ],
            ),
            if (kos.deskripsi != null && kos.deskripsi!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(kos.deskripsi!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF64748B))),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(double n) {
    final s = n.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  const _Chip(
      {required this.icon,
      required this.label,
      required this.color,
      required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Helper field ─────────────────────────────────────────────────────────────
Widget _field(String label, TextEditingController ctrl,
    {String hint = '',
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text}) {
  return TextFormField(
    controller: ctrl,
    maxLines: maxLines,
    keyboardType: keyboardType,
    validator: required
        ? (v) => (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null
        : null,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1A56DB), width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      isDense: true,
    ),
  );
}