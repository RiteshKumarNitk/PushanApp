import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class AddressBookPage extends StatelessWidget {
  const AddressBookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Address Book")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAddressCard(
            label: "Main Office",
            address: "123, Tea Garden Road, Siliguri, West Bengal - 734001",
            isDefault: true,
          ),
          const SizedBox(height: 16),
          _buildAddressCard(
            label: "Warehouse 2",
            address: "Plot 45, Industrial Area, Noida, UP - 201301",
            isDefault: false,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text("Add New Address"),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard({required String label, required String address, required bool isDefault}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: isDefault ? AppTheme.primaryGreen : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: isDefault ? AppTheme.primaryGreen.withOpacity(0.05) : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(4)),
                  child: const Text("DEFAULT", style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(address, style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(onPressed: () {}, child: const Text("Edit")),
              TextButton(onPressed: () {}, child: const Text("Delete", style: TextStyle(color: Colors.red))),
            ],
          )
        ],
      ),
    );
  }
}
