import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../api/api_service.dart';
import '../../core/app_export.dart';
import '../../models/friend_model.dart';
import '../../widgets/app_bar/appbar_subtitle.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import 'bloc/friend_bloc.dart';

class FriendScreen extends StatefulWidget {
  final int userId;

  const FriendScreen({super.key, required this.userId});

  static Widget builder(BuildContext context, int userId) {
    return BlocProvider(
      create: (context) =>
          FriendBloc(apiService: ApiService())..add(FriendInitialEvent(userId)),
      child: FriendScreen(userId: userId),
    );
  }

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray50,
        appBar: _buildAppBar(context),
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFriendsList(),
                  _buildPendingRequests(),
                  _buildSearchTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      height: 56.h,
      title: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: appTheme.gray900),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.only(right: 8.h),
          ),
          Expanded(
            child: Center(
              child: Text(
                "Teman",
                style: TextStyle(
                  fontSize: 18.fSize,
                  fontWeight: FontWeight.w600,
                  color: appTheme.gray900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.h),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(10.h),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: appTheme.gray600,
        labelStyle: TextStyle(
          fontSize: 13.fSize,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 13.fSize,
          fontWeight: FontWeight.w500,
        ),
        padding: EdgeInsets.all(4.h),
        tabs: const [
          Tab(text: 'Teman'),
          Tab(text: 'Permintaan'),
          Tab(text: 'Cari'),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    return BlocBuilder<FriendBloc, FriendState>(
      builder: (context, state) {
        if (state.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
          );
        }

        if (state.friends.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_outline_rounded,
            title: 'Belum Ada Teman',
            subtitle:
                'Mulai cari dan tambahkan teman\nuntuk memulai perjalanan bersama!',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.h),
          itemCount: state.friends.length,
          itemBuilder: (context, index) {
            final friend = state.friends[index];
            return _buildFriendCard(friend, context);
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64.h,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 18.fSize,
              fontWeight: FontWeight.w600,
              color: appTheme.gray900,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.fSize,
              color: appTheme.gray600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(FriendModel friend, BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.h),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.h),
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.all(16.h),
            child: Row(
              children: [
                _buildAvatar(friend.name, friend.profilePicture),
                SizedBox(width: 14.h),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.name,
                        style: TextStyle(
                          fontSize: 16.fSize,
                          fontWeight: FontWeight.w600,
                          color: appTheme.gray900,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 14.h,
                            color: appTheme.gray500,
                          ),
                          SizedBox(width: 4.h),
                          Text(
                            'ID: ${friend.id}',
                            style: TextStyle(
                              fontSize: 12.fSize,
                              color: appTheme.gray600,
                            ),
                          ),
                        ],
                      ),
                      if (friend.phone != null) ...[
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 14.h,
                              color: appTheme.gray500,
                            ),
                            SizedBox(width: 4.h),
                            Text(
                              friend.phone!,
                              style: TextStyle(
                                fontSize: 12.fSize,
                                color: appTheme.gray600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: appTheme.red600.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.h),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.person_remove_outlined,
                      color: appTheme.red600,
                      size: 22.h,
                    ),
                    onPressed: () => _showRemoveFriendDialog(friend, context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, String? profilePicture) {
    return Container(
      width: 56.h,
      height: 56.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.h),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.fSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildPendingRequests() {
    return BlocBuilder<FriendBloc, FriendState>(
      builder: (context, state) {
        if (state.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
          );
        }

        if (state.pendingRequests.isEmpty) {
          return _buildEmptyState(
            icon: Icons.mark_email_unread_outlined,
            title: 'Tidak Ada Permintaan',
            subtitle: 'Belum ada permintaan pertemanan\nyang masuk saat ini.',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.h),
          itemCount: state.pendingRequests.length,
          itemBuilder: (context, index) {
            final request = state.pendingRequests[index];
            return _buildPendingRequestCard(request, context);
          },
        );
      },
    );
  }

  Widget _buildPendingRequestCard(
      PendingRequestModel request, BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.h),
        child: Column(
          children: [
            Row(
              children: [
                _buildAvatar(request.user.name, request.user.profilePicture),
                SizedBox(width: 14.h),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.user.name,
                        style: TextStyle(
                          fontSize: 16.fSize,
                          fontWeight: FontWeight.w600,
                          color: appTheme.gray900,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 14.h,
                            color: appTheme.gray500,
                          ),
                          SizedBox(width: 4.h),
                          Text(
                            'ID: ${request.user.id}',
                            style: TextStyle(
                              fontSize: 12.fSize,
                              color: appTheme.gray600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<FriendBloc>().add(
                            RejectFriendEvent(
                                request.friendshipId, widget.userId),
                          );
                    },
                    icon: Icon(Icons.close, size: 18.h),
                    label: const Text('Tolak'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: appTheme.red600,
                      side: BorderSide(color: appTheme.red600),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.h),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.h),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<FriendBloc>().add(
                            AcceptFriendEvent(
                                request.friendshipId, widget.userId),
                          );
                    },
                    icon: Icon(Icons.check, size: 18.h),
                    label: const Text('Terima'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.h),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTab() {
    return BlocConsumer<FriendBloc, FriendState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: theme.colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: appTheme.red600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.h, 8.h, 16.h, 16.h),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.h),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    fontSize: 15.fSize,
                    color: appTheme.gray900,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari berdasarkan ID, Nama, atau Email...',
                    hintStyle: TextStyle(
                      fontSize: 14.fSize,
                      color: appTheme.gray500,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: theme.colorScheme.primary,
                      size: 24.h,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: appTheme.gray500,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              context
                                  .read<FriendBloc>()
                                  .add(ClearSearchEvent());
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.h),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.h,
                      vertical: 16.h,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    context.read<FriendBloc>().add(
                          SearchUsersEvent(value, widget.userId),
                        );
                  },
                ),
              ),
            ),
            if (state.isSearching)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                ),
              )
            else if (state.searchResults.isEmpty &&
                _searchController.text.isNotEmpty)
              Expanded(
                child: _buildEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Tidak Ditemukan',
                  subtitle:
                      'Pengguna dengan kata kunci\n"${_searchController.text}" tidak ditemukan.',
                ),
              )
            else if (state.searchResults.isEmpty)
              Expanded(
                child: _buildEmptyState(
                  icon: Icons.person_search_rounded,
                  title: 'Cari Teman Baru',
                  subtitle:
                      'Masukkan ID, Nama, atau Email\nuntuk mencari pengguna.',
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.h),
                  itemCount: state.searchResults.length,
                  itemBuilder: (context, index) {
                    final user = state.searchResults[index];
                    return _buildSearchResultCard(user, context);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSearchResultCard(FriendModel user, BuildContext context) {
    String buttonText = 'Tambah';
    bool isDisabled = false;
    Color buttonColor = theme.colorScheme.primary;
    IconData buttonIcon = Icons.person_add_outlined;

    if (user.friendshipStatus == 'accepted') {
      buttonText = 'Teman';
      isDisabled = true;
      buttonColor = appTheme.gray400;
      buttonIcon = Icons.check_circle_outline;
    } else if (user.friendshipStatus == 'pending') {
      buttonText = 'Menunggu';
      isDisabled = true;
      buttonColor = appTheme.orange;
      buttonIcon = Icons.schedule;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.h),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.h),
        child: Row(
          children: [
            _buildAvatar(user.name, user.profilePicture),
            SizedBox(width: 14.h),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 16.fSize,
                      fontWeight: FontWeight.w600,
                      color: appTheme.gray900,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        size: 14.h,
                        color: appTheme.gray500,
                      ),
                      SizedBox(width: 4.h),
                      Flexible(
                        child: Text(
                          'ID: ${user.id}',
                          style: TextStyle(
                            fontSize: 12.fSize,
                            color: appTheme.gray600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (user.email.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 14.h,
                          color: appTheme.gray500,
                        ),
                        SizedBox(width: 4.h),
                        Flexible(
                          child: Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 12.fSize,
                              color: appTheme.gray600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.h),
            ElevatedButton.icon(
              onPressed: isDisabled
                  ? null
                  : () {
                      context.read<FriendBloc>().add(
                            AddFriendEvent(widget.userId, user.id),
                          );
                    },
              icon: Icon(buttonIcon, size: 18.h),
              label: Text(
                buttonText,
                style: TextStyle(fontSize: 12.fSize),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: buttonColor.withOpacity(0.6),
                disabledForegroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.h),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveFriendDialog(FriendModel friend, BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: appTheme.red600.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_remove_outlined,
                color: appTheme.red600,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Hapus Teman',
              style: TextStyle(
                fontSize: 18.fSize,
                fontWeight: FontWeight.w600,
                color: appTheme.gray900,
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${friend.name} dari daftar teman?',
          style: TextStyle(
            fontSize: 14.fSize,
            color: appTheme.gray600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Batal',
              style: TextStyle(
                color: appTheme.gray600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<FriendBloc>().add(
                    RemoveFriendEvent(friend.friendshipId!, widget.userId),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: appTheme.red600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
