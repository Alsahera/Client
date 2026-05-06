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
        id: json['id'],
        namaKos: json['nama_kos'] ?? '',
        harga: double.tryParse(json['harga'].toString()) ?? 0,
        lokasi: json['lokasi'] ?? '',
        deskripsi: json['deskripsi'],
        galeriCount: json['galeri_count'],
        bookingCount: json['booking_count'],
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
        id: json['id'],
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
        id: json['id'],
        userId: json['user_id'],
        kosId: json['kos_id'],
        tanggalMasuk: json['tanggal_masuk'] ?? '',
        durasiSewa: json['durasi_sewa'] ?? 1,
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
        id: json['id'],
        bookingId: json['booking_id'],
        totalTagihan:
            double.tryParse(json['total_tagihan'].toString()) ?? 0,
        statusBayar: json['status_bayar'] ?? 'pending',
        metodeBayar: json['metode_bayar'] ?? '',
        booking: json['booking'] != null
            ? Booking.fromJson(json['booking'])
            : null,
      );
}