import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'ออกจากระบบ',
      icon: const Icon(Icons.logout),
      onPressed: () => FirebaseAuth.instance.signOut(),
    );
  }
}
