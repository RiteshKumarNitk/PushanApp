import 'package:flutter/material.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Security")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            title: Text("Change Password"),
            trailing: Icon(Icons.chevron_right),
          ),
          const Divider(),
          SwitchListTile(
            value: true,
            onChanged: (val) {},
            title: const Text("Biometric Login"),
            subtitle: const Text("Use Fingerprint or FaceID"),
          ),
          const Divider(),
          SwitchListTile(
            value: false,
            onChanged: (val) {},
            title: const Text("Two-Factor Authentication"),
            subtitle: const Text("Sent OTP to registered mobile"),
          ),
        ],
      ),
    );
  }
}
