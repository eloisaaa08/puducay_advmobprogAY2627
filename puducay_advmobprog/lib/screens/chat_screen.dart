import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchChatController = TextEditingController();
  final ChatService _chatService = ChatService();
  String? _currentUserEmail;
  String _searchText = '';

  // The Firebase UID of the signed-in user, which is empty for a DummyJSON session.
  String get _currentUserId => userService.value.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
  }

  Future<void> _loadCurrentUserEmail() async {
    final userData = await userService.value.getUserData();
    if (!mounted) return;
    setState(() {
      _currentUserEmail = userData['email'];
    });
  }

  @override
  void dispose() {
    _searchChatController.dispose();
    super.dispose();
  }

  // Joins the first and last name, falling back to the username or email.
  String _displayName(Map<String, dynamic> user) {
    final fullName = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
        .trim();
    if (fullName.isNotEmpty) return fullName;
    final username = (user['username'] ?? '').toString();
    if (username.isNotEmpty) return username;
    return (user['email'] ?? 'Unknown').toString();
  }

  // Enhancement 1: removes the signed-in user from the list by UID or email.
  bool _isCurrentUser(Map<String, dynamic> user) {
    final uid = (user['uid'] ?? '').toString();
    final email = (user['email'] ?? '').toString();
    return (uid.isNotEmpty && uid == _currentUserId) ||
        (email.isNotEmpty && email == _currentUserEmail);
  }

  // Enhancement 2: keeps users whose name, username, or email contains the search text.
  bool _matchesSearch(Map<String, dynamic> user) {
    if (_searchText.isEmpty) return true;
    final haystack = [
      _displayName(user),
      user['username'] ?? '',
      user['email'] ?? '',
    ].join(' ').toLowerCase();
    return haystack.contains(_searchText);
  }

  // Shows a centered message in the same style as the product list.
  Widget _message(String text) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: CustomText(
          text: text,
          fontSize: 14.sp,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        title: CustomText(
          text: 'Chats',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhancement 2: search bar that filters the list as the user types.
            TextField(
              controller: _searchChatController,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() => _searchText = value.trim().toLowerCase());
              },
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchChatController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchChatController.clear();
                            _searchText = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Enhancement 1: lists every registered user from Firestore.
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getUsersStream(),
              builder: (context, snapshot) {
                if (_currentUserId.isEmpty) {
                  return _message('Sign in with a Firebase account to chat.');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.r),
                      child: const CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _message('Error: ${snapshot.error}');
                }

                final users = (snapshot.data ?? [])
                    .where((user) => !_isCurrentUser(user))
                    .toList();

                if (users.isEmpty) {
                  return _message('No users found.');
                }

                final results = users.where(_matchesSearch).toList();

                if (results.isEmpty) {
                  return _message('No users match "$_searchText".');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final user = results[index];
                    final name = _displayName(user);

                    return Card(
                      elevation: 1.5,
                      clipBehavior: Clip.antiAlias,
                      margin: EdgeInsets.only(bottom: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 4.h,
                        ),
                        onTap: () {
                          if (_currentUserEmail == null) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailsScreen(
                                currentUserEmail: _currentUserEmail!,
                                tappedUser: user,
                              ),
                            ),
                          );
                        },

                        // The avatar flies into the chat header through a Hero animation.
                        leading: Hero(
                          tag: 'avatar_${user['uid']}',
                          child: CircleAvatar(
                            radius: 22.r,
                            backgroundColor: colorScheme.primary.withValues(
                              alpha: 0.12,
                            ),
                            child: CustomText(
                              text: name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : '?',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: CustomText(
                          text: name,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: CustomText(
                          text: (user['email'] ?? 'No email').toString(),
                          fontSize: 12.sp,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Icon(Icons.chevron_right, size: 22.sp),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
