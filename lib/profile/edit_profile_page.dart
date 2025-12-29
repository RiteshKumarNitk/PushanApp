import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_config.dart';
import '../../core/app_theme.dart';
import '../../auth/auth_controller.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _businessCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _gstCtrl;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProfileProvider).value;
    _nameCtrl = TextEditingController(text: user?['full_name'] ?? '');
    _businessCtrl = TextEditingController(text: user?['business_name'] ?? '');
    _phoneCtrl = TextEditingController(text: user?['phone_number'] ?? '');
    _addressCtrl = TextEditingController(text: user?['address'] ?? '');
    _gstCtrl = TextEditingController(text: user?['gst_number'] ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _businessCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _gstCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = ref.read(userProfileProvider).value;
      if (user == null) return;

      final updates = {
        'full_name': _nameCtrl.text,
        'business_name': _businessCtrl.text,
        'phone_number': _phoneCtrl.text,
        'address': _addressCtrl.text,
        'gst_number': _gstCtrl.text,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await SupabaseConfig.client
          .from('users')
          .update(updates)
          .eq('id', user['id']);

      // Refresh local state
      ref.refresh(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated Successfully")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField("Full Name", _nameCtrl, Icons.person),
              const SizedBox(height: 16),
              _buildTextField("Business Name", _businessCtrl, Icons.store),
              const SizedBox(height: 16),
              _buildTextField("Phone Number", _phoneCtrl, Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField("Shipping Address", _addressCtrl, Icons.local_shipping, maxLines: 3),
              const SizedBox(height: 16),
              _buildTextField("GST Number (Optional)", _gstCtrl, Icons.receipt_long),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.royalMaroon,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Text("SAVE CHANGES"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.royalMaroon, width: 2),
        ),
      ),
      validator: (v) {
        if (label != 'GST Number (Optional)' && (v == null || v.isEmpty)) {
          return "$label is required";
        }
        return null;
      },
    );
  }
}
