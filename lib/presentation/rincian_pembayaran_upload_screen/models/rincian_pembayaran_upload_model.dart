class RincianPembayaranUploadModel {
  final int id;
  final int idPesanan;
  final double totalBayar;
  final String statusPesanan;
  final String? waktuPembayaran;
  final String? bukti;
  final Payment payment;

  RincianPembayaranUploadModel({
    required this.id,
    required this.idPesanan,
    required this.totalBayar,
    required this.statusPesanan,
    this.waktuPembayaran,
    this.bukti,
    required this.payment,
  });

  factory RincianPembayaranUploadModel.fromJson(Map<String, dynamic> json) {
    return RincianPembayaranUploadModel(
      id: json['id'],
      idPesanan: json['id_pesanan'],
      totalBayar: json['total_bayar'].toDouble(),
      statusPesanan: json['status_pesanan'],
      waktuPembayaran: json['waktu_pembayaran'],
      bukti: json['bukti'],
      payment: Payment.fromJson(json['payment']),
    );
  }
}

class Payment {
  final int id;
  final String namaPembayaran;
  final String gambarPembayaran;
  final String nomorPembayaran;

  Payment({
    required this.id,
    required this.namaPembayaran,
    required this.gambarPembayaran,
    required this.nomorPembayaran,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      namaPembayaran: json['nama_pembayaran'],
      gambarPembayaran: json['gambar_pembayaran'],
      nomorPembayaran: json['nomor_pembayaran'],
    );
  }
  String get imagePath {
    const baseUrl = 'http://myhiking.my.id/storage';
    return (gambarPembayaran != null && gambarPembayaran.isNotEmpty)
        ? '$baseUrl/$gambarPembayaran'
        : '';
  }
}
