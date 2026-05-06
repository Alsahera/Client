import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/empty_widget.dart';
import '../widgets/error_widget.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  List<Booking> _list = [];
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
      final res = await ApiService.get('booking');
      if (res['success'] == true) {
        setState(() {
          _list = (res['data'] as List)
              .map((e) => Booking.fromJson(e))
              .toList();
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

  // Ambil daftar kos & user untuk dropdown
  Future<List<Kos>> _fetchKos() async {
    final res = await ApiService.get('kos');
    if (res['success'] == true) {
      return (res['data'] as List).map((e) => Kos.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> _showForm({Booking? booking}) async {
    List<Kos> kosList = [];
    bool fetchingKos = true;

    // userId dan kosId default
    int? selectedUserId  = booking?.userId;
    int? selectedKosId   = booking?.kosId;
    final tglCtrl    = TextEditingController(text: booking?.tanggalMasuk ?? '');
    final durasiCtrl = TextEditingController(
        text: booking != null ? booking.durasiSewa.toString() : '1');
    final formKey    = GlobalKey<FormState>();
    bool saving      = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          // Load kos sekali
          if (fetchingKos) {
            _fetchKos().then((list) {
              setModal(() {
                kosList = list;
                fetchingKos = false;
                if (selectedKosId == null && list.isNotEmpty) {
                  selectedKosId = list.first.id;
                }
              });
            });
          }

          return Padding(
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
                      Text(booking == null ? 'Tambah Booking' : 'Edit Booking',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // User ID manual (karena list user butuh endpoint terpisah)
                  TextFormField(
                    initialValue: selectedUserId?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    onChanged: (v) => selectedUserId = int.tryParse(v),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'User ID wajib diisi'
                        : null,
                    decoration: _deco('User ID', 'Masukkan ID user (misal: 1)'),
                  ),
                  const SizedBox(height: 10),

                  // Pilih Kos dropdown
                  fetchingKos
                      ? const LinearProgressIndicator()
                      : DropdownButtonFormField<int>(
                          initialValue: selectedKosId,
                          decoration: _deco('Pilih Kos', ''),
                          items: kosList
                              .map((k) => DropdownMenuItem(
                                    value: k.id,
                                    child: Text(
                                        '${k.namaKos} – Rp ${_fmt(k.harga)}/bln',
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setModal(() => selectedKosId = v),
                          validator: (v) =>
                              v == null ? 'Pilih kos' : null,
                        ),
                  const SizedBox(height: 10),

                  // Tanggal Masuk
                  TextFormField(
                    controller: tglCtrl,
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        tglCtrl.text =
                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      }
                    },
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Tanggal masuk wajib diisi'
                        : null,
                    decoration: _deco('Tanggal Masuk', 'YYYY-MM-DD')
                        .copyWith(
                            suffixIcon: const Icon(Icons.calendar_today,
                                size: 18)),
                  ),
                  const SizedBox(height: 10),

                  // Durasi
                  TextFormField(
                    controller: durasiCtrl,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 1 || n > 24) {
                        return 'Durasi 1–24 bulan';
                      }
                      return null;
                    },
                    decoration:
                        _deco('Durasi Sewa (bulan)', '1 – 24'),
                  ),
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
                                  'user_id':       selectedUserId,
                                  'kos_id':        selectedKosId,
                                  'tanggal_masuk': tglCtrl.text,
                                  'durasi_sewa':
                                      int.tryParse(durasiCtrl.text) ?? 1,
                                };
                                Map<String, dynamic> res;
                                if (booking == null) {
                                  res = await ApiService.post('booking', body);
                                } else {
                                  res = await ApiService.put(
                                      'booking/${booking.id}', body);
                                }
                                if (res['success'] == true) {
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  _loadData();
                                  _snack(booking == null
                                      ? 'Booking ditambahkan!'
                                      : 'Booking diperbarui!');
                                } else {
                                  _snack('Gagal menyimpan.', err: true);
                                }
                              } catch (e) {
                                _snack('Error: $e', err: true);
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
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(
                              booking == null
                                  ? 'Simpan Booking'
                                  : 'Update Booking',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _delete(Booking b) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Hapus Booking?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
            'Hapus booking #${b.id} milik ${b.user?.name ?? ''}?'),
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
            child:
                const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.delete('booking/${b.id}');
        _loadData();
        _snack('Booking berhasil dihapus!');
      } catch (_) {
        _snack('Gagal menghapus.', err: true);
      }
    }
  }

  void _snack(String msg, {bool err = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          err ? const Color(0xFFEF4444) : const Color(0xFF10B981),
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
        backgroundColor: const Color(0xFF06B6D4),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Booking',
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
                : _list.isEmpty
                    ? const EmptyWidget(
                        icon: Icons.calendar_today_outlined,
                        message: 'Belum ada booking',
                        sub: 'Tap + untuk membuat booking baru')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                        itemCount: _list.length,
                        itemBuilder: (_, i) => _BookingCard(
                          booking: _list[i],
                          onEdit: () => _showForm(booking: _list[i]),
                          onDelete: () => _delete(_list[i]),
                        ),
                      ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _BookingCard(
      {required this.booking,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final statusColor = booking.pembayaran?.statusBayar == 'lunas'
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);
    final statusBg = booking.pembayaran?.statusBayar == 'lunas'
        ? const Color(0xFFECFDF5)
        : const Color(0xFFFFFBEB);

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
                    color: const Color(0xFFECFEFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.calendar_month,
                      color: Color(0xFF06B6D4), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.user?.name ?? 'User #${booking.userId}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A))),
                      Text(booking.user?.email ?? '',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF94A3B8))),
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _Row(Icons.house_rounded,
                      booking.kos?.namaKos ?? 'Kos #${booking.kosId}',
                      const Color(0xFF1A56DB)),
                  const SizedBox(height: 6),
                  _Row(Icons.calendar_today_outlined,
                      booking.tanggalMasuk, const Color(0xFF64748B)),
                  const SizedBox(height: 6),
                  _Row(Icons.timelapse,
                      '${booking.durasiSewa} bulan', const Color(0xFF64748B)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                booking.pembayaran != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          booking.pembayaran!.statusBayar == 'lunas'
                              ? '✅ Lunas'
                              : '⏳ Pending',
                          style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w600),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Belum Bayar',
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFF59E0B),
                                fontWeight: FontWeight.w600)),
                      ),
                Text('#${booking.id}',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Row(this.icon, this.text, this.color);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 12, color: color))),
        ],
      );
}

InputDecoration _deco(String label, String hint) => InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle:
          const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: Color(0xFF1A56DB), width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      isDense: true,
    );

String _fmt(double n) {
  final s = n.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}