import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/empty_widget.dart';
import '../widgets/error_widget.dart';

class PembayaranScreen extends StatefulWidget {
  const PembayaranScreen({super.key});

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  List<Pembayaran> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.get('pembayaran');
      if (res['success'] == true) {
        setState(() {
          _list = (res['data'] as List)
              .map((e) => Pembayaran.fromJson(e))
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

  // Ambil booking yang belum punya pembayaran (untuk form tambah)
  Future<List<Booking>> _fetchBookingList() async {
    final res = await ApiService.get('booking');
    if (res['success'] == true) {
      return (res['data'] as List)
          .map((e) => Booking.fromJson(e))
          .where((b) => b.pembayaran == null)
          .toList();
    }
    return [];
  }

  Future<void> _showForm({Pembayaran? p}) async {
    // Untuk edit, kita tidak perlu pilih booking
    int? selectedBookingId = p?.bookingId;
    String selectedStatus  = p?.statusBayar ?? 'pending';
    String selectedMetode  = p?.metodeBayar ?? 'Mandiri';
    final tagihanCtrl = TextEditingController(
        text: p != null ? p.totalTagihan.toStringAsFixed(0) : '');
    final formKey = GlobalKey<FormState>();
    bool saving   = false;

    // Hanya fetch booking list saat tambah baru
    List<Booking> bookingList = [];
    bool fetchingBooking = p == null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          if (fetchingBooking) {
            _fetchBookingList().then((list) {
              setModal(() {
                bookingList     = list;
                fetchingBooking = false;
                if (selectedBookingId == null && list.isNotEmpty) {
                  selectedBookingId = list.first.id;
                  // Auto-fill total tagihan dari harga × durasi
                  final b = list.first;
                  if (b.kos != null) {
                    tagihanCtrl.text =
                        (b.kos!.harga * b.durasiSewa).toStringAsFixed(0);
                  }
                }
              });
            });
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            p == null
                                ? 'Tambah Pembayaran'
                                : 'Edit Pembayaran #${p.id}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Pilih Booking (hanya saat tambah) ──
                    if (p == null) ...[
                      fetchingBooking
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: LinearProgressIndicator(),
                            )
                          : bookingList.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF7ED),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: const Color(0xFFFED7AA)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded,
                                          color: Color(0xFFF59E0B), size: 18),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Semua booking sudah memiliki pembayaran.',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFFB45309)),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : DropdownButtonFormField<int>(
                                  initialValue: selectedBookingId,
                                  decoration:
                                      _inputDeco('Pilih Booking', ''),
                                  isExpanded: true,
                                  items: bookingList
                                      .map((b) => DropdownMenuItem(
                                            value: b.id,
                                            child: Text(
                                              '#${b.id} – ${b.user?.name ?? 'User'} → ${b.kos?.namaKos ?? 'Kos'} (${b.durasiSewa} bln)',
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 13),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    setModal(() {
                                      selectedBookingId = v;
                                      // Auto-fill tagihan
                                      final b = bookingList
                                          .firstWhere((x) => x.id == v);
                                      if (b.kos != null) {
                                        tagihanCtrl.text = (b.kos!.harga *
                                                b.durasiSewa)
                                            .toStringAsFixed(0);
                                      }
                                    });
                                  },
                                  validator: (v) =>
                                      v == null ? 'Pilih booking' : null,
                                ),
                      const SizedBox(height: 10),
                    ] else ...[
                      // Info booking saat edit
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Color(0xFF16A34A), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Booking #${p.bookingId} – ${p.booking?.kos?.namaKos ?? ''}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF166534)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // ── Total Tagihan ──
                    TextFormField(
                      controller: tagihanCtrl,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n < 0) {
                          return 'Masukkan nominal yang valid';
                        }
                        return null;
                      },
                      decoration:
                          _inputDeco('Total Tagihan (Rp)', '750000'),
                    ),
                    const SizedBox(height: 10),

                    // ── Metode Bayar ──
                    DropdownButtonFormField<String>(
                      initialValue: selectedMetode,
                      decoration:
                          _inputDeco('Metode Pembayaran', ''),
                      items: ['Mandiri', 'BCA', 'Dana']
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: m == 'Dana'
                                            ? const Color(0xFF0082C8)
                                            : m == 'BCA'
                                                ? const Color(0xFF003D87)
                                                : const Color(0xFF005FCC),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Center(
                                        child: Text(
                                          m[0],
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight:
                                                  FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(m),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setModal(() => selectedMetode = v!),
                    ),
                    const SizedBox(height: 10),

                    // ── Status Bayar ──
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration:
                          _inputDeco('Status Pembayaran', ''),
                      items: [
                        DropdownMenuItem(
                          value: 'pending',
                          child: Row(children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('⏳ Pending'),
                          ]),
                        ),
                        DropdownMenuItem(
                          value: 'lunas',
                          child: Row(children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('✅ Lunas'),
                          ]),
                        ),
                      ],
                      onChanged: (v) =>
                          setModal(() => selectedStatus = v!),
                    ),
                    const SizedBox(height: 20),

                    // ── Submit ──
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: (saving ||
                                (p == null &&
                                    bookingList.isEmpty &&
                                    !fetchingBooking))
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }
                                setModal(() => saving = true);
                                try {
                                  Map<String, dynamic> body;
                                  Map<String, dynamic> res;

                                  if (p == null) {
                                    body = {
                                      'booking_id':
                                          selectedBookingId,
                                      'total_tagihan': double.tryParse(
                                              tagihanCtrl.text) ??
                                          0,
                                      'status_bayar': selectedStatus,
                                      'metode_bayar': selectedMetode,
                                    };
                                    res = await ApiService.post(
                                        'pembayaran', body);
                                  } else {
                                    body = {
                                      'total_tagihan': double.tryParse(
                                              tagihanCtrl.text) ??
                                          0,
                                      'status_bayar': selectedStatus,
                                      'metode_bayar': selectedMetode,
                                    };
                                    res = await ApiService.put(
                                        'pembayaran/${p.id}', body);
                                  }

                                  if (res['success'] == true) {
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    _loadData();
                                    _snack(p == null
                                        ? 'Pembayaran berhasil disimpan!'
                                        : 'Pembayaran berhasil diperbarui!');
                                  } else {
                                    _snack('Gagal menyimpan.',
                                        err: true);
                                  }
                                } catch (e) {
                                  _snack('Error: $e', err: true);
                                } finally {
                                  setModal(() => saving = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
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
                                p == null
                                    ? 'Simpan Pembayaran'
                                    : 'Update Pembayaran',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _delete(Pembayaran p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Hapus Pembayaran?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content:
            Text('Hapus pembayaran #${p.id} – Rp ${_fmt(p.totalTagihan)}?'),
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
            child: const Text('Hapus',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.delete('pembayaran/${p.id}');
        _loadData();
        _snack('Pembayaran berhasil dihapus!');
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
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Hitung total lunas & pending untuk summary bar
    final totalLunas = _list
        .where((p) => p.statusBayar == 'lunas')
        .fold<double>(0, (sum, p) => sum + p.totalTagihan);
    final totalPending = _list
        .where((p) => p.statusBayar == 'pending')
        .fold<double>(0, (sum, p) => sum + p.totalTagihan);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: const Color(0xFF10B981),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Pembayaran',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF1A56DB),
        child: _loading
            ? const Center(
                child:
                    CircularProgressIndicator(color: Color(0xFF1A56DB)))
            : _error != null
                ? AppErrorWidget(message: _error!, onRetry: _loadData)
                : _list.isEmpty
                    ? const EmptyWidget(
                        icon: Icons.credit_card_outlined,
                        message: 'Belum ada data pembayaran',
                        sub: 'Tap + untuk menambah pembayaran')
                    : CustomScrollView(
                        slivers: [
                          // ── Summary Cards ──
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 16, 16, 0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _SummaryCard(
                                      label: 'Total Lunas',
                                      amount: totalLunas,
                                      count: _list
                                          .where((p) =>
                                              p.statusBayar == 'lunas')
                                          .length,
                                      color: const Color(0xFF10B981),
                                      bg: const Color(0xFFECFDF5),
                                      icon: Icons.check_circle_outline,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _SummaryCard(
                                      label: 'Pending',
                                      amount: totalPending,
                                      count: _list
                                          .where((p) =>
                                              p.statusBayar == 'pending')
                                          .length,
                                      color: const Color(0xFFF59E0B),
                                      bg: const Color(0xFFFFFBEB),
                                      icon: Icons.hourglass_bottom_outlined,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── List ──
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                                16, 12, 16, 88),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => _PembayaranCard(
                                  pembayaran: _list[i],
                                  onEdit: () =>
                                      _showForm(p: _list[i]),
                                  onDelete: () => _delete(_list[i]),
                                ),
                                childCount: _list.length,
                              ),
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }
}

// ── Summary card ─────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final int count;
  final Color color;
  final Color bg;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.count,
    required this.color,
    required this.bg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            Text('Rp ${_fmt(amount)}',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text('$count transaksi',
                style: TextStyle(
                    fontSize: 11,
                    color: color.withOpacity(0.7))),
          ],
        ),
      );
}

// ── Card item ─────────────────────────────────────────────────────────────────
class _PembayaranCard extends StatelessWidget {
  final Pembayaran pembayaran;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PembayaranCard({
    required this.pembayaran,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isLunas = pembayaran.statusBayar == 'lunas';
    final statusColor =
        isLunas ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final statusBg =
        isLunas ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB);

    final metodeColor = pembayaran.metodeBayar == 'Dana'
        ? const Color(0xFF0082C8)
        : pembayaran.metodeBayar == 'BCA'
            ? const Color(0xFF003D87)
            : const Color(0xFF005FCC);

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
            // ── Header ──
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.credit_card_rounded,
                      color: Color(0xFF10B981), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pembayaran.booking?.user?.name ??
                            'Booking #${pembayaran.bookingId}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A)),
                      ),
                      Text(
                        pembayaran.booking?.kos?.namaKos ?? '',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8)),
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
                              style: TextStyle(
                                  color: Color(0xFFEF4444))),
                        ])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Amount ──
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Tagihan',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B))),
                      Text(
                        'Rp ${_fmt(pembayaran.totalTagihan)}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A56DB)),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isLunas ? '✅ Lunas' : '⏳ Pending',
                          style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Metode badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: metodeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          pembayaran.metodeBayar,
                          style: TextStyle(
                              fontSize: 11,
                              color: metodeColor,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Footer info ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking #${pembayaran.bookingId}',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                Text(
                  '#${pembayaran.id}',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _inputDeco(String label, String hint) => InputDecoration(
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