import 'package:flutter/material.dart';

class InboxBox extends StatefulWidget {
  const InboxBox({super.key});

  @override
  State<InboxBox> createState() => _InboxBoxState();
}

class _InboxBoxState extends State<InboxBox> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Inbox Box'),
      ),
    );
  }
}
