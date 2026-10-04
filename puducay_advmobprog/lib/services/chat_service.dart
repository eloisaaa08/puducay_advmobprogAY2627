import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Enhancement 1: streams every registered user saved in the Users collection.
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        user['uid'] ??= doc.id;
        return user;
      }).toList();
    });
  }

  // Builds the same chat room ID for any two users by sorting their UIDs.
  String getChatRoomId(String userID, String otherUserID) {
    List<String> ids = [userID, otherUserID];
    ids.sort();
    return ids.join("_");
  }

  // Saves a new message and updates the chat room's participants and last message.
  Future<void> sendMessage(String receiverId, String message) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String? currentUserEmail = _firebaseAuth.currentUser!.email;
    final Timestamp timestamp = Timestamp.now();
    MessageModel newMessage = MessageModel(
      senderId: currentUserId,
      senderEmail: currentUserEmail ?? "",
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
    );

    final String chatRoomID = getChatRoomId(currentUserId, receiverId);
    final chatRoom = _firestore.collection("chat_rooms").doc(chatRoomID);

    // A batch writes both documents together so the message shows up locally right away.
    final batch = _firestore.batch();
    batch.set(chatRoom, {
      'participants': [currentUserId, receiverId],
      'lastMessage': message,
      'lastTimestamp': timestamp,
    }, SetOptions(merge: true));
    batch.set(chatRoom.collection("messages").doc(), newMessage.toMap());
    await batch.commit();
  }

  // Enhancement 3: streams the messages including local pending writes for the "sending…" state.
  Stream<QuerySnapshot> getMessages(String userID, String otherUserID) {
    final String chatRoomID = getChatRoomId(userID, otherUserID);

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy('timestamp', descending: true)
        .snapshots(includeMetadataChanges: true);
  }

  // Enhancement 3: marks every unseen message sent to the current user as seen.
  Future<void> markMessagesAsSeen(
    String currentUserId,
    String otherUserID,
  ) async {
    final String chatRoomID = getChatRoomId(currentUserId, otherUserID);

    final unseen = await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .where('receiverId', isEqualTo: currentUserId)
        .where('seen', isEqualTo: false)
        .get();

    if (unseen.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unseen.docs) {
      batch.update(doc.reference, {'seen': true});
    }
    await batch.commit();
  }

  // Finds a user's UID from the email saved in their Users document.
  Future<String?> getUidByEmail(String email) async {
    final q = await _firestore
        .collection('Users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (q.docs.isEmpty) return null;
    return (q.docs.first.data()['uid'] ?? q.docs.first.id).toString();
  }
}
