import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/walk_chat_message.dart';

part 'walk_chat_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<List<WalkChatMessage>> walkChatMessages(
  Ref ref,
  String walkId,
) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || walkId.isEmpty) {
    return Stream.value(const <WalkChatMessage>[]);
  }

  final query = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('walks')
      .doc(walkId)
      .collection('chat')
      .orderBy('createdAt');

  return query.snapshots().map((snapshot) {
    final result = <WalkChatMessage>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final message = data['message'] as String?;
      if (message == null || message.isEmpty) {
        continue;
      }
      final chatId = data['chatId'] as String? ?? doc.id;
      final senderType = data['senderType'] as String? ?? 'system';
      result.add(
        WalkChatMessage(
          chatId: chatId,
          senderType: senderType,
          message: message,
          url: data['url'] as String?,
          suggestId: data['suggestId'] as String?,
          createdAt: _toDateTime(data['createdAt']),
        ),
      );
    }
    return result;
  });
}

DateTime? _toDateTime(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}
