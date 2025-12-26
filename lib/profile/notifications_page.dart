import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        separatorBuilder: (c, i) => const Divider(),
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade50,
              child: Icon(Icons.notifications, color: Colors.orange),
            ),
            title: Text(index == 0 ? "Order Shipped!" : "New Offer Alert"),
            subtitle: Text(index == 0 
              ? "Your order #ORD-001 has been shipped via Fedex."
              : "Get 10% off on your next Darjeeling Tea bulk order. Valid till Sunday."
            ),
            trailing: Text(index == 0 ? "2m ago" : "1d ago", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          );
        },
      ),
    );
  }
}
