import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myhiking/api/api_service.dart';
import 'package:myhiking/models/trail_model.dart';
import 'package:myhiking/presentation/payment_method_screen/payment_method_screen.dart';
import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_outlined_button.dart';
import 'bloc/booking_bloc.dart';
import 'models/booking_model.dart';

class BookingScreen extends StatefulWidget {
  final int? jalurId;
  final int? idGunung;
  const BookingScreen(
      {super.key, required this.jalurId, required this.idGunung});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late String imageUrl; // Deklarasi imageUrl
  late final BookingBloc _bookingBloc;
  String userName = '';
  String userId = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserProfile();

    _bookingBloc = BookingBloc(apiService: ApiService());
    if (widget.idGunung != null && widget.jalurId != null) {
      _bookingBloc.add(BookingInitialEvent(
        idGunung: widget.idGunung!,
        jalurId: widget.jalurId!,
      ));
      print(
          "Navigating with idGunung: ${widget.idGunung} and jalurId: ${widget.jalurId},");
    }
  }

  @override
  void dispose() {
    _bookingBloc.close();
    super.dispose();
  }

  Future<void> _getUserProfile() async {
    final token = await ApiService().getToken();
    if (token != null) {
      final response = await ApiService().getUserProfile(token);
      if (response['success']) {
        setState(() {
          userId = response['data']['id'].toString();
        });
      }
    }
    print("Navigating with $userId");
  }

  Future<int?> _resolveCurrentUserId(BuildContext context) async {
    if (userId.isNotEmpty) {
      final parsed = int.tryParse(userId);
      if (parsed != null) {
        return parsed;
      }
    }

    final token = await ApiService().getToken();
    if (token == null) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi login tidak ditemukan. Silakan login ulang.'),
        ),
      );
      return null;
    }

    final response = await ApiService().getUserProfile(token);
    if (response['success'] == true) {
      final fetchedUserId = response['data']?['id']?.toString();
      final parsed = int.tryParse(fetchedUserId ?? '');
      if (parsed != null) {
        if (mounted) {
          setState(() {
            userId = parsed.toString();
          });
        }
        return parsed;
      }
    }

    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data pengguna belum tersedia. Coba lagi sebentar.'),
      ),
    );
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
        value: _bookingBloc,
        child: Scaffold(
          backgroundColor: const Color(0xFFF2F5F4),
          appBar: _buildAppbar(context),
          body: BlocBuilder<BookingBloc, BookingState>(
            builder: (context, state) {
              if (state.isLoading) {
                return Center(child: CircularProgressIndicator());
              }
              if (state.trail == null || state.mountain == null) {
                return Center(
                    child: Text('Data jalur atau gunung tidak tersedia.'));
              }

              final resDetailRouteCentres = ResTrailModel(
                status: true,
                message: "Success",
                trail: state.trail!,
              );

              final trailModel =
                  BookingModel.resTrailModelFromJson(resDetailRouteCentres);

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.only(
                          left: 16.h, right: 16.h, top: 0, bottom: 2.h),
                      children: [
                        _buildProgressSection(context),
                        SizedBox(height: 20.h),
                        _buildHotelCard(context, trailModel),
                        SizedBox(height: 20.h),
                        _buildFormContainer(context),
                      ],
                    ),
                  ),
                  _buildBottomBar(context, trailModel, state),
                ],
              );
            },
          ),
        ));
  }

  Widget _buildFormContainer(BuildContext context) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        return Container(
          width: double.maxFinite,
          padding: EdgeInsets.all(16.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.h),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                spreadRadius: 2.h,
                blurRadius: 4.h,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Lengkapi Detail Pesanan",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                "Tanggal Naik",
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              SizedBox(height: 8.h),
              _buildBookingDateField(context),
              SizedBox(height: 16.h),
              Text(
                "Tanggal Turun",
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              SizedBox(height: 8.h),
              _buildReturnDateField(context),
              SizedBox(height: 4.h),
              Text(
                "Tektok: tanggal naik = tanggal turun. Camping: tanggal turun setelah tanggal naik.",
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              SizedBox(height: 14.h),
              _buildQuotaInfoSection(context, state),
              SizedBox(height: 16.h),
              Text(
                "Tambah Anggota",
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              SizedBox(height: 8.h),
              _buildMemberIdField(context),
              SizedBox(height: 8.h),
              Text(
                "Max 10 Orang per Booking.",
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuotaInfoSection(BuildContext context, BookingState state) {
    final quota = state.bookingQuotaAvailability;
    final startDay = quota?.startDay;
    final hasDate =
        (state.bookingDateFieldController?.text.isNotEmpty ?? false);
    final isMultiDay = quota != null && quota.tanggalNaik != quota.tanggalTurun;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Info Kuota Pendaki",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 10.h),
          if (state.isQuotaLoading)
            Row(
              children: [
                SizedBox(
                  width: 14.h,
                  height: 14.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: const Color(0xFF1B8A5F),
                  ),
                ),
                SizedBox(width: 8.h),
                Text(
                  'Memuat info kuota...',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            )
          else if (!hasDate)
            Text(
              'Pilih tanggal naik untuk melihat kuota pendaki.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _buildQuotaSummaryItem(
                    label: 'Limit Pendaki Harian',
                    value: quota?.dailyHikerLimit?.toString() ?? '-',
                  ),
                ),
                SizedBox(width: 10.h),
                Expanded(
                  child: _buildQuotaSummaryItem(
                    label: 'Sisa Slot Tanggal Naik',
                    value: startDay?.remainingSlots?.toString() ?? '-',
                  ),
                ),
              ],
            ),
            if (quota != null && isMultiDay && quota.days.isNotEmpty) ...[
              SizedBox(height: 10.h),
              ...quota.days.map((day) => Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatQuotaDate(day.date),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${day.remainingSlots ?? '-'} slot',
                          style: TextStyle(
                            fontSize: 11,
                            color: day.isFull
                                ? Colors.red.shade700
                                : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            if (quota?.hasFullDay == true) ...[
              SizedBox(height: 6.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(8.h),
                ),
                child: Text(
                  'Ada tanggal yang sudah penuh. Silakan pilih tanggal lain.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (state.quotaError.isNotEmpty && quota == null) ...[
              SizedBox(height: 8.h),
              Text(
                'Info kuota belum tersedia.',
                style: TextStyle(fontSize: 11, color: Colors.red.shade700),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildQuotaSummaryItem({
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.h),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B8A5F),
            ),
          ),
        ],
      ),
    );
  }

  String _formatQuotaDate(String rawDate) {
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) {
      return rawDate;
    }

    return DateFormat('dd MMM yyyy', 'id_ID').format(parsed);
  }

  Widget _buildBottomBar(
      BuildContext context, BookingModel trailModel, BookingState state) {
    int totalMembers =
        (state.selectedMembers?.length ?? 0) + 1; // 1 represents the main user
    int totalCost = (trailModel.biaya ?? 0).toInt() * totalMembers;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ringkasan Harga",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Text(
                "Total ($totalMembers Orang): ",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Expanded(
                child: Text(
                  NumberFormat.currency(
                          locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                      .format(totalCost),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed: () => _submitBooking(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B8A5F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.h),
                ),
                elevation: 0,
              ),
              child: Text(
                "LANJUT",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppbar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF2F5F4),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: Text(
        "BOOKING",
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w900,
          fontSize: 18,
          letterSpacing: 1.2,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () {
          Navigator.of(context).pop(); // Navigate back
        },
      ),
    );
  }

  /// Section Widget
  Widget _buildProgressSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 4.h, bottom: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildProgressCircle('1', isActive: true),
          _buildProgressLine(),
          _buildProgressCircle('', isActive: false),
          _buildProgressLine(),
          _buildProgressCircle('', isActive: false),
        ],
      ),
    );
  }

  Widget _buildProgressCircle(String text, {required bool isActive}) {
    return Container(
      width: 24.h,
      height: 24.h,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1B8A5F) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF1B8A5F),
          width: 2.h,
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.transparent,
            fontWeight: FontWeight.bold,
            fontSize: 12.h,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressLine() {
    return Container(
      width: 60.h,
      height: 2.h,
      color: const Color(0xFF1B8A5F),
    );
  }

  /// Section Widget
  Widget _buildHotelCard(BuildContext context, BookingModel jalur) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.h),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            spreadRadius: 2.h,
            blurRadius: 4.h,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.h)),
            child: Image.network(
              jalur.gambar,
              height: 150.h,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 150.h,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    jalur.name ?? 'Nama Jalur',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.h),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Mulai Dari",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Rp ${NumberFormat('#,##0', 'id_ID').format(jalur.biaya)}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          " / org",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildBookingDateField(BuildContext context) {
    return BlocSelector<BookingBloc, BookingState, TextEditingController?>(
      selector: (state) => state.bookingDateFieldController,
      builder: (context, bookingDateFieldController) {
        return GestureDetector(
          onTap: () => onTapBookingDateInput(context),
          child: Container(
            width: double.maxFinite,
            padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F4),
              borderRadius: BorderRadius.circular(10.h),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 20.h, color: Colors.grey.shade700),
                SizedBox(width: 12.h),
                Expanded(
                  child: Text(
                    (bookingDateFieldController?.text.isEmpty ?? true)
                        ? "Pilih Tanggal Naik"
                        : bookingDateFieldController!.text,
                    style: TextStyle(
                      color: (bookingDateFieldController?.text.isEmpty ?? true)
                          ? Colors.grey.shade700
                          : Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Section Widget - Tanggal Turun
  Widget _buildReturnDateField(BuildContext context) {
    return BlocSelector<BookingBloc, BookingState, TextEditingController?>(
      selector: (state) => state.returnDateFieldController,
      builder: (context, returnDateFieldController) {
        return GestureDetector(
          onTap: () => onTapReturnDateInput(context),
          child: Container(
            width: double.maxFinite,
            padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F4),
              borderRadius: BorderRadius.circular(10.h),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 20.h, color: Colors.grey.shade700),
                SizedBox(width: 12.h),
                Expanded(
                  child: Text(
                    (returnDateFieldController?.text.isEmpty ?? true)
                        ? "Pilih Tanggal Turun"
                        : returnDateFieldController!.text,
                    style: TextStyle(
                      color: (returnDateFieldController?.text.isEmpty ?? true)
                          ? Colors.grey.shade700
                          : Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Section Widget
  Widget _buildMemberIdField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected members display
        BlocSelector<BookingBloc, BookingState, List<SelectedMember>>(
          selector: (state) => state.selectedMembers ?? [],
          builder: (context, selectedMembers) {
            if (selectedMembers.isEmpty) {
              return SizedBox.shrink();
            }
            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              child: Wrap(
                spacing: 8.h,
                runSpacing: 8.h,
                children: selectedMembers.map((member) {
                  return Chip(
                    label: Text(member.name),
                    deleteIcon: Icon(Icons.close, size: 16.h),
                    onDeleted: () {
                      context.read<BookingBloc>().add(
                            RemoveSelectedMember(member.id),
                          );
                    },
                  );
                }).toList(),
              ),
            );
          },
        ),
        // Buttons row
        Row(
          children: [
            // Select from friends button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showFriendSelectionDialog(context),
                icon: Icon(Icons.person_add_alt_1,
                    size: 18.h, color: Colors.white),
                label: Text(
                  'Pilih dari Teman',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B8A5F),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.h),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            SizedBox(width: 8.h),
            // Manual ID input button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showManualIdDialog(context),
                icon: Icon(Icons.edit_outlined,
                    size: 18.h, color: Colors.black87),
                label: Text(
                  'Input ID Manual',
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  side: BorderSide(color: Colors.grey.shade400, width: 1.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.h),
                  ),
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        BlocSelector<BookingBloc, BookingState, List<SelectedMember>>(
          selector: (state) => state.selectedMembers ?? const [],
          builder: (context, selectedMembers) {
            final hasSelected = selectedMembers.isNotEmpty;
            return Text(
              hasSelected
                  ? '${selectedMembers.length} anggota sudah ditambahkan.'
                  : 'Belum ada anggota ditambahkan.',
              style: TextStyle(
                fontSize: 12,
                color: hasSelected
                    ? const Color(0xFF1B8A5F)
                    : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
      ],
    );
  }

  void _showFriendSelectionDialog(BuildContext context) async {
    final userIdInt = await _resolveCurrentUserId(context);
    if (userIdInt == null) return;

    // Fetch friends
    final response = await ApiService().getFriends(userIdInt);

    if (response['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat daftar teman')),
      );
      return;
    }

    final rawFriends = response['data'];
    final friends = <SelectedMember>[];

    if (rawFriends is List) {
      for (final item in rawFriends) {
        if (item is! Map) continue;
        final friendMap = Map<String, dynamic>.from(item);
        final friendId = int.tryParse(friendMap['id']?.toString() ?? '');
        if (friendId == null) continue;

        final friendName = (friendMap['name'] ?? '').toString().trim();
        friends.add(
          SelectedMember(
            id: friendId,
            name: friendName.isEmpty ? 'User $friendId' : friendName,
          ),
        );
      }
    }

    if (friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Anda belum memiliki teman. Tambahkan teman terlebih dahulu!')),
      );
      return;
    }

    final currentSelected = List<SelectedMember>.from(
        context.read<BookingBloc>().state.selectedMembers ?? []);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Pilih Teman'),
              content: SizedBox(
                width: double.maxFinite,
                height: 300.h,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    final isSelected =
                        currentSelected.any((m) => m.id == friend.id);

                    return CheckboxListTile(
                      title: Text(friend.name),
                      subtitle: Text('ID: ${friend.id}'),
                      value: isSelected,
                      onChanged: (value) {
                        setDialogState(() {
                          if (value == true) {
                            if (!currentSelected
                                .any((m) => m.id == friend.id)) {
                              currentSelected.add(friend);
                            }
                          } else {
                            currentSelected
                                .removeWhere((m) => m.id == friend.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black54,
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B8A5F),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // Update bloc with selected members
                    _bookingBloc.add(
                      UpdateSelectedMembers(List.from(currentSelected)),
                    );
                    Navigator.pop(dialogContext);
                  },
                  child: Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showManualIdDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Masukkan ID Anggota'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Contoh: 123456789',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black54,
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B8A5F),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final idText = controller.text.trim();
                if (idText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ID tidak boleh kosong')),
                  );
                  return;
                }

                final id = int.tryParse(idText);
                if (id == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ID harus berupa angka')),
                  );
                  return;
                }

                final currentUserId = await _resolveCurrentUserId(context);
                if (currentUserId == null) return;

                if (id == currentUserId) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Tidak bisa menambahkan ID milik Anda sendiri.'),
                    ),
                  );
                  return;
                }

                // Verify user exists by searching
                final response =
                    await ApiService().searchUsers(idText, currentUserId);

                Map<String, dynamic>? userData;
                if (response['success'] == true && response['data'] is List) {
                  final users = (response['data'] as List)
                      .whereType<Map>()
                      .map((e) => Map<String, dynamic>.from(e))
                      .toList();

                  for (final user in users) {
                    final userIdFromApi =
                        int.tryParse(user['id']?.toString() ?? '');
                    if (userIdFromApi == id) {
                      userData = user;
                      break;
                    }
                  }
                }

                // Fallback: exact lookup by ID when search endpoint does not return exact numeric match.
                if (userData == null) {
                  final lookup = await ApiService().getUserById(id);
                  if (lookup['success'] == true && lookup['data'] is Map) {
                    userData = Map<String, dynamic>.from(lookup['data']);
                  }
                }

                if (userData == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Pengguna dengan ID tersebut tidak ditemukan')),
                  );
                  return;
                }

                final memberName = (userData['name'] ?? '').toString().trim();
                final member = SelectedMember(
                  id: id,
                  name: memberName.isEmpty ? 'User $id' : memberName,
                );

                _bookingBloc.add(
                  AddSelectedMember(member),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Anggota ${member.name} berhasil ditambahkan.'),
                    ),
                  );
                }
                Navigator.pop(dialogContext);
              },
              child: Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return CustomOutlinedButton(
      height: 42.h,
      text: "lbl_lanjut2".tr,
      margin: EdgeInsets.only(
        left: 4.h,
        right: 4.h,
      ),
      buttonStyle: CustomButtonStyles.fillPrimary,
      buttonTextStyle: CustomTextStyles.labelLarge13,
      onPressed: () async {
        await _submitBooking(context);
      },
    );
  }

  Future<void> _submitBooking(BuildContext context,
      {bool forceContinue = false}) async {
    try {
      final bookingBloc = BlocProvider.of<BookingBloc>(context);
      final state = bookingBloc.state;

      final selectedMembers = state.selectedMembers ?? [];
      final bookingDate = state.bookingDateFieldController?.text;
      final returnDate = state.returnDateFieldController?.text;
      final idGunung = state.mountain?.id;
      final jalurId = state.trail?.id;
      final biaya = state.trail?.biaya;
      final userIdInt = await _resolveCurrentUserId(context);

      String formatTanggal(String rawDate) {
        final DateTime dateTime = DateTime.parse(rawDate);
        final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
        return dateFormat.format(dateTime);
      }

      final formattedDate = bookingDate != null && bookingDate.isNotEmpty
          ? formatTanggal(bookingDate)
          : null;
      final formattedReturnDate = returnDate != null && returnDate.isNotEmpty
          ? formatTanggal(returnDate)
          : null;

      List<int>? anggotaIds = selectedMembers.isNotEmpty
          ? selectedMembers.map((m) => m.id).toList()
          : null;

      if (formattedDate == null ||
          formattedReturnDate == null ||
          idGunung == null ||
          jalurId == null ||
          userIdInt == null ||
          biaya == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Harap lengkapi data pemesanan, termasuk tanggal naik dan tanggal turun.')),
        );
        return;
      }

      // Validasi: tanggal turun tidak boleh sebelum tanggal naik
      final dtNaik = DateTime.parse(formattedDate);
      final dtTurun = DateTime.parse(formattedReturnDate);
      if (dtTurun.isBefore(dtNaik)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tanggal turun tidak boleh sebelum tanggal naik.')),
        );
        return;
      }

      final decisionResult = await ApiService().createBookingWithDecision(
        idGunung,
        jalurId,
        userIdInt,
        formattedDate,
        formattedReturnDate,
        biaya.toInt(),
        anggotaIds: anggotaIds?.isNotEmpty == true ? anggotaIds : null,
        forceContinue: forceContinue,
      );

      final booking = decisionResult.booking;

      if (!context.mounted) return;

      final warning = decisionResult.warning;
      if (warning != null && warning['message'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(warning['message'].toString()),
            backgroundColor: warning['type'] == 'high_risk'
                ? Colors.red.shade700
                : Colors.amber.shade700,
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking berhasil dibuat!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentMethodScreen(orderId: booking.id),
        ),
      );
    } on ApiActionException catch (apiError) {
      if (apiError.code == 'HIGH_RISK_CONFIRMATION_REQUIRED') {
        final continueBooking = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Peringatan Risiko Tinggi'),
            content: Text(
              apiError.message.isNotEmpty
                  ? apiError.message
                  : 'Jalur ini memiliki risiko tinggi untuk tingkat pengalaman Anda. Apakah tetap lanjut?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Lanjutkan'),
              ),
            ],
          ),
        );

        if (continueBooking == true) {
          await _submitBooking(context, forceContinue: true);
        }
        return;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiError.message)),
        );
      }
    } catch (e) {
      String errorMessage;
      if (e is FormatException) {
        errorMessage = 'Format tanggal tidak valid.';
      } else if (e is SocketException) {
        errorMessage = 'Terjadi masalah dengan koneksi internet.';
      } else if (e is HttpException) {
        errorMessage = 'Terjadi kesalahan saat menghubungi server.';
      } else {
        errorMessage = 'Terjadi kesalahan yang tidak terduga.';
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  void onTapBookingDateInput(BuildContext context) async {
    DateTime currentDate = DateTime.now();

    DateTime? pickedDate = await showDatePicker(
      context: context,
      useRootNavigator: false,
      initialDate: currentDate,
      firstDate: currentDate,
      lastDate: DateTime(
        currentDate.year + 2,
        currentDate.month,
        currentDate.day,
      ),
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      BlocProvider.of<BookingBloc>(context)
          .add(UpdateBookingDateEvent(formattedDate));
    }
  }

  void onTapReturnDateInput(BuildContext context) async {
    final state = BlocProvider.of<BookingBloc>(context).state;
    final bookingDateText = state.bookingDateFieldController?.text;

    // Tanggal naik harus dipilih dahulu
    DateTime firstDate;
    DateTime initialDate;
    if (bookingDateText != null && bookingDateText.isNotEmpty) {
      firstDate = DateTime.parse(bookingDateText);
      initialDate = firstDate;
    } else {
      firstDate = DateTime.now();
      initialDate = firstDate;
    }

    DateTime? pickedDate = await showDatePicker(
      context: context,
      useRootNavigator: false,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(
        firstDate.year + 2,
        firstDate.month,
        firstDate.day,
      ),
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      BlocProvider.of<BookingBloc>(context)
          .add(UpdateReturnDateEvent(formattedDate));
    }
  }
}
