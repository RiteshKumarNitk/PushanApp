import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_config.dart';
import '../../core/app_theme.dart';
import '../../auth/auth_controller.dart';
import '../../shared/models/user_address.dart';

final userAddressesProvider = StreamProvider<List<UserAddress>>((ref) {
  final user = ref.read(userProfileProvider).value;
  if (user == null) return const Stream.empty();

  return SupabaseConfig.client
      .from('user_addresses')
      .stream(primaryKey: ['id'])
      .eq('user_id', user['id'])
      .order('created_at', ascending: true)
      .map((data) => data.map((json) => UserAddress.fromJson(json)).toList());
});

class AddressBookPage extends ConsumerWidget {
  const AddressBookPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(userAddressesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Address Book")),
      body: addressesAsync.when(
        data: (addresses) {
          if (addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("No addresses found", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showAddAddressDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text("Add New Address"),
                  )
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...addresses.map((address) => _buildAddressCard(context, ref, address)),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _showAddAddressDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text("Add New Address"),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, WidgetRef ref, UserAddress address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: address.isDefault ? AppTheme.primaryGreen : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: address.isDefault ? AppTheme.primaryGreen.withOpacity(0.05) : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(address.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(4)),
                  child: const Text("DEFAULT", style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(address.toString(), style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!address.isDefault)
                TextButton(
                  onPressed: () => _setAsDefault(context, ref, address),
                  child: const Text("Set as Default"),
                ),
              TextButton(
                onPressed: () => _deleteAddress(context, address),
                child: const Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Future<void> _setAsDefault(BuildContext context, WidgetRef ref, UserAddress address) async {
    try {
      final user = ref.read(userProfileProvider).value;
      if (user == null) return;
      
      // Batch update: unset all, set one (Simplest approach)
      await SupabaseConfig.client.rpc('set_default_address', params: {
        'addr_id': address.id,
        'uid': user['id']
      }).catchError((_) async {
         // Fallback manual update if RPC missing
         await SupabaseConfig.client
            .from('user_addresses')
            .update({'is_default': false})
            .eq('user_id', user['id']);
         
         await SupabaseConfig.client
            .from('user_addresses')
            .update({'is_default': true})
            .eq('id', address.id);
      });

    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _deleteAddress(BuildContext context, UserAddress address) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Address?"),
        content: const Text("Are you sure you want to remove this address?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseConfig.client.from('user_addresses').delete().eq('id', address.id);
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _showAddAddressDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _AddAddressDialog(),
    );
  }
}

class _AddAddressDialog extends ConsumerStatefulWidget {
  const _AddAddressDialog();

  @override
  ConsumerState<_AddAddressDialog> createState() => _AddAddressDialogState();
}

class _AddAddressDialogState extends ConsumerState<_AddAddressDialog> {
  final _formKey = GlobalKey<FormState>();
  String _label = '';
  String _addressLine = '';
  String _city = '';
  String _state = '';
  String _zipCode = '';
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add New Address"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: "Label (e.g. Home)"),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onSaved: (v) => _label = v!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: "Address Line"),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onSaved: (v) => _addressLine = v!,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: "City"),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      onSaved: (v) => _city = v!,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: "State"),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      onSaved: (v) => _state = v!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: "Zip Code"),
                onSaved: (v) => _zipCode = v ?? '',
              ),
              const SizedBox(height: 12),
               CheckboxListTile(
                title: const Text("Set as Default"),
                value: _isDefault,
                onChanged: (val) => setState(() => _isDefault = val!),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        FilledButton(
          onPressed: _isLoading ? null : _saveAddress,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Save"),
        ),
      ],
    );
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final user = ref.read(userProfileProvider).value;
      if (user == null) return;

      if (_isDefault) {
         // Reset other defaults if this one is default
         await SupabaseConfig.client
            .from('user_addresses')
            .update({'is_default': false})
            .eq('user_id', user['id']);
      }

      await SupabaseConfig.client.from('user_addresses').insert({
        'user_id': user['id'],
        'label': _label,
        'address_line': _addressLine,
        'city': _city,
        'state': _state,
        'zip_code': _zipCode,
        'is_default': _isDefault,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
