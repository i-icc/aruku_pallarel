import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../widgets/app_background.dart';

@RoutePage()
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: const AppBackground(
        safeAreaTop: false,
        child: Center(
          child: Text('Chat is coming soon.'),
        ),
      ),
    );
  }
}
