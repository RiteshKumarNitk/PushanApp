import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Help & Support")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.support_agent, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "How can we help you?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Our team at Pushan Tea is dedicated to providing you the best service.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _buildSupportOption(Icons.phone, "Call Us", "+91 9876543210"),
            const SizedBox(height: 16),
            _buildSupportOption(Icons.email, "Email Us", "support@pushantea.com"),
            const SizedBox(height: 16),
            _buildSupportOption(Icons.chat, "Chat with Admin", "Available 9 AM - 9 PM"),
            
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade50,
              child: const Text(
                "Pushan Tea Pvt Ltd\n123, Green Valley, Assam, India",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportOption(IconData icon, String title, String subtitle) {
    return Card(
      elevation: 0,
       shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.royalMaroon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
