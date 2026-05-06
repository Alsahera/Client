// ─── Model: Kos ──────────────────────────────────────────────────────────────
class Kos {
  final int id;
  final String namaKos;
  final double harga;
  final String lokasi;
  final String? deskripsi;
  final int? galeriCount;
  final int? bookingCount;

  Kos({
    required this.id,
    required this.namaKos,
    required this.harga,
    required this.lokasi,
    this.deskripsi,
    this.galeriCount,
    this.bookingCount,
  });

  factory Kos.fromJson(Map<String, dynamic> json) => Kos(
        // Perbaikan: Pakai int.tryParse karena Oracle sering kirim String
        id: int.tryParse(json['id'].toString()) ?? 0,
        namaKos: json['nama_kos'] ?? '',
        harga: double.tryParse(json['harga'].toString()) ?? 0,
        lokasi: json['lokasi'] ?? '',
        deskripsi: json['deskripsi'],
        galeriCount: int.tryParse(json['galeri_count'].toString()),
        bookingCount: int.tryParse(json['booking_count'].toString()),
      );

  Map<String, dynamic> toJson() => {
        'nama_kos': namaKos,
        'harga': harga,
        'lokasi': lokasi,
        'deskripsi': deskripsi,
      };
}

// ─── Model: User ─────────────────────────────────────────────────────────────
class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: int.tryParse(json['id'].toString()) ?? 0, // Perbaikan
        name: json['name'] ?? '',
        email: json['email'] ?? '',
      );
}

// ─── Model: Booking ──────────────────────────────────────────────────────────
class Booking {
  final int id;
  final int userId;
  final int kosId;
  final String tanggalMasuk;
  final int durasiSewa;
  final User? user;
  final Kos? kos;
  final Pembayaran? pembayaran;

  Booking({
    required this.id,
    required this.userId,
    required this.kosId,
    required this.tanggalMasuk,
    required this.durasiSewa,
    this.user,
    this.kos,
    this.pembayaran,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: int.tryParse(json['id'].toString()) ?? 0, // Perbaikan
        userId: int.tryParse(json['user_id'].toString()) ?? 0, // Perbaikan
        kosId: int.tryParse(json['kos_id'].toString()) ?? 0, // Perbaikan
        tanggalMasuk: json['tanggal_masuk'] ?? '',
        durasiSewa: int.tryParse(json['durasi_sewa'].toString()) ?? 1, // Perbaikan
        user: json['user'] != null ? User.fromJson(json['user']) : null,
        kos: json['kos'] != null ? Kos.fromJson(json['kos']) : null,
        pembayaran: json['pembayaran'] != null
            ? Pembayaran.fromJson(json['pembayaran'])
            : null,
      );
}

// ─── Model: Pembayaran ────────────────────────────────────────────────────────
class Pembayaran {
  final int id;
  final int bookingId;
  final double totalTagihan;
  final String statusBayar;
  final String metodeBayar;
  final Booking? booking;

  Pembayaran({
    required this.id,
    required this.bookingId,
    required this.totalTagihan,
    required this.statusBayar,
    required this.metodeBayar,
    this.booking,
  });

  factory Pembayaran.fromJson(Map<String, dynamic> json) => Pembayaran(
        id: int.tryParse(json['id'].toString()) ?? 0, // Perbaikan
        bookingId: int.tryParse(json['booking_id'].toString()) ?? 0, // Perbaikan
        totalTagihan:
            double.tryParse(json['total_tagihan'].toString()) ?? 0,
        statusBayar: json['status_bayar'] ?? 'pending',
        metodeBayar: json['metode_bayar'] ?? '',
        booking: json['booking'] != null
            ? Booking.fromJson(json['booking'])
            : null,
      );
}