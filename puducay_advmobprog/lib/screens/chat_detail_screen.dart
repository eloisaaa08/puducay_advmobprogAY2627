import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

final ChatService chatService = ChatService();

class ChatDetailsScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailsScreen({
    Key? key,
    required this.currentUserEmail,
    required this.tappedUser,
  }) : super(key: key);

  @override
  State<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  // Message IDs already on screen so only newly arrived messages animate in.
  final Set<String> _shownIds = {};
  bool _firstLoad = true;
  bool _markingSeen = false;
  bool _hasText = false;

  // The Firebase UID of the signed-in user.
  String get _currentUserId => userService.value.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(() {
      final hasText = _msgCtrl.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // Clears the box right away while Firestore shows the message as "sending…".
  Future<void> _send(String receiverId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    _msgCtrl.clear();
    _msgFocus.requestFocus();

    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    try {
      await chatService.sendMessage(receiverId, text);
    } catch (e) {
      if (!mounted) return;
      _msgCtrl.text = text;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    }
  }

  // Enhancement 3: marks incoming messages as seen while this chat is open.
  void _markSeen(List<QueryDocumentSnapshot> docs, String otherUserId) {
    final hasUnseen = docs.any((d) {
      final data = d.data() as Map<String, dynamic>;
      return data['receiverId'] == _currentUserId && data['seen'] == false;
    });
    if (!hasUnseen || _markingSeen) return;

    _markingSeen = true;
    chatService
        .markMessagesAsSeen(_currentUserId, otherUserId)
        .whenComplete(() => _markingSeen = false);
  }

  // Formats a timestamp as a 12-hour time like 3:05 PM.
  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final date = ts.toDate();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tappedUserId = (widget.tappedUser['uid'] ?? '').toString();
    final tappedUserName =
        '${widget.tappedUser['firstName'] ?? ''} ${widget.tappedUser['lastName'] ?? ''}'
            .trim();
    final title = tappedUserName.isNotEmpty
        ? tappedUserName
        : (widget.tappedUser['email'] ?? 'Chat').toString();

    if (_currentUserId.isEmpty || tappedUserId.isEmpty) {
      return Scaffold(
        body: Center(
          child: CustomText(text: 'Error loading user data', fontSize: 14.sp),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        titleSpacing: 0,
        title: Row(
          children: [
            Hero(
              tag: 'avatar_$tappedUserId',
              child: CircleAvatar(
                radius: 18.r,
                backgroundColor: colors.primary.withValues(alpha: 0.12),
                child: CustomText(
                  text: title.isNotEmpty ? title[0].toUpperCase() : '?',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: title,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  CustomText(
                    text: (widget.tappedUser['email'] ?? '').toString(),
                    fontSize: 12.sp,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chatService.getMessages(_currentUserId, tappedUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.r),
                      child: CustomText(
                        text: 'Error: ${snapshot.error}',
                        fontSize: 14.sp,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                _markSeen(docs, tappedUserId);

                // History loaded on open is shown without animation.
                if (_firstLoad) {
                  _shownIds.addAll(docs.map((d) => d.id));
                  _firstLoad = false;
                }

                if (docs.isEmpty) {
                  return _EmptyChat(name: title);
                }

                // The newest message I sent is the one that shows its status label.
                final latestMineId = docs
                    .where(
                      (d) => (d.data() as Map)['senderId'] == _currentUserId,
                    )
                    .map((d) => d.id)
                    .firstOrNull;

                return ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == _currentUserId;
                    final animate = !_shownIds.contains(doc.id);
                    _shownIds.add(doc.id);

                    // Consecutive messages from the same sender are grouped closer together.
                    final olderDoc = index + 1 < docs.length
                        ? docs[index + 1].data() as Map<String, dynamic>
                        : null;
                    final isGrouped = olderDoc?['senderId'] == data['senderId'];

                    return _AnimatedMessage(
                      key: ValueKey(doc.id),
                      animate: animate,
                      fromRight: isMe,
                      child: _MessageBubble(
                        text: (data['message'] ?? '').toString(),
                        time: _formatTime(data['timestamp'] as Timestamp?),
                        isMe: isMe,
                        isGrouped: isGrouped,
                        status: !isMe
                            ? null
                            : doc.metadata.hasPendingWrites
                            ? _SendStatus.sending
                            : data['seen'] == true
                            ? _SendStatus.seen
                            : _SendStatus.delivered,
                        showStatusLabel: doc.id == latestMineId,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Composer bar styled like the cart's checkout bar.
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 8.w, 10.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgCtrl,
                        focusNode: _msgFocus,
                        textInputAction: TextInputAction.send,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 4,
                        onSubmitted: (_) => _send(tappedUserId),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14.sp,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14.sp,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: colors.primary,
                              width: 2,
                            ),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),

                    // The send button grows in once there is text to send.
                    AnimatedScale(
                      scale: _hasText ? 1 : 0.85,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: AnimatedOpacity(
                        opacity: _hasText ? 1 : 0.5,
                        duration: const Duration(milliseconds: 200),
                        child: IconButton(
                          icon: Icon(Icons.send_rounded, size: 26.sp),
                          color: colors.primary,
                          onPressed: _hasText
                              ? () => _send(tappedUserId)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Enhancement 3: the three states a sent message can be in.
enum _SendStatus { sending, delivered, seen }

// Enhancement 3: fades and slides a new message in from the sender's side.
class _AnimatedMessage extends StatefulWidget {
  final bool animate;
  final bool fromRight;
  final Widget child;

  const _AnimatedMessage({
    super.key,
    required this.animate,
    required this.fromRight,
    required this.child,
  });

  @override
  State<_AnimatedMessage> createState() => _AnimatedMessageState();
}

class _AnimatedMessageState extends State<_AnimatedMessage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
    value: widget.animate ? 0 : 1,
  );

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(widget.fromRight ? 0.25 : -0.25, 0.15),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

// Enhancement 3: chat bubble with different colors, corners, and alignment per side.
class _MessageBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isMe;
  final bool isGrouped;
  final _SendStatus? status;
  final bool showStatusLabel;

  const _MessageBubble({
    required this.text,
    required this.time,
    required this.isMe,
    required this.isGrouped,
    required this.status,
    required this.showStatusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // My bubbles use the same primary tint as the profile avatar while the other user's bubbles match the app's cards.
    final bubbleColor = isMe
        ? colorScheme.primary.withValues(alpha: 0.12)
        : theme.cardColor;
    final textColor = colorScheme.onSurface;
    final radius = Radius.circular(16.r);
    final tail = Radius.circular(4.r);

    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 60.w : 16.w,
        right: isMe ? 16.w : 60.w,
        top: isGrouped ? 3.h : 10.h,
      ),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 8.h),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: radius,
                topRight: radius,
                bottomLeft: isMe ? radius : tail,
                bottomRight: isMe ? tail : radius,
              ),
              // Only the other user's card-colored bubble gets a card shadow since my bubble is see-through.
              boxShadow: isMe
                  ? null
                  : [
                      BoxShadow(
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    ],
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: textColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    text: text.isNotEmpty ? text : '[empty]',
                    fontSize: 14.sp,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: 0.75,
                        child: CustomText(text: time, fontSize: 10.sp),
                      ),
                      if (status != null) ...[
                        SizedBox(width: 4.w),
                        _StatusIcon(status: status!, color: textColor),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // The status label under my latest message switches with a fade.
          if (showStatusLabel && status != null)
            Padding(
              padding: EdgeInsets.only(top: 4.h, right: 4.w),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: CustomText(
                  key: ValueKey(status),
                  text: switch (status!) {
                    _SendStatus.sending => 'Sending…',
                    _SendStatus.delivered => 'Delivered',
                    _SendStatus.seen => 'Seen',
                  },
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  fontStyle: status == _SendStatus.sending
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Enhancement 3: clock while sending, one check when delivered, and amber double check when seen.
class _StatusIcon extends StatelessWidget {
  final _SendStatus status;
  final Color color;

  const _StatusIcon({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color iconColor) = switch (status) {
      _SendStatus.sending => (Icons.schedule, color.withValues(alpha: 0.7)),
      _SendStatus.delivered => (Icons.done, color.withValues(alpha: 0.85)),
      _SendStatus.seen => (Icons.done_all, Colors.amber),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: Icon(icon, key: ValueKey(status), size: 14.sp, color: iconColor),
    );
  }
}

// Empty state laid out like the "Your cart is empty" screen.
class _EmptyChat extends StatelessWidget {
  final String name;

  const _EmptyChat({required this.name});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: ListView(
        padding: EdgeInsets.all(24.r),
        children: [
          SizedBox(height: 80.h),
          Icon(Icons.chat_bubble_outline, size: 72.sp),
          SizedBox(height: 16.h),
          CustomText(
            text: 'No messages yet',
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          CustomText(
            text: 'Send a message to start chatting with $name.',
            fontSize: 14.sp,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
