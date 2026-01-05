import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_service.dart';
import '../core/app_theme.dart';

// Assuming you have a layout wrapper or will create one. 
// For now, let's just make the page clean and assume it will be used inside a navigation rail/drawer.
// But the user asked for a "Side Menu" structure. 
// Since navigation architecture changes are big, I will first Fix this page's UI 
// and suggest the Side Menu structure in the next step.

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final _authService = AuthService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _authService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- Refined Dialog Logic ---
  final _formKey = GlobalKey<FormState>();
  // Controllers...
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(); 
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLineController = TextEditingController(); 
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  String? _selectedRole;

  void _showUserDialog({Map<String, dynamic>? user}) {
    final isEdit = user != null;

    if (isEdit) {
      _emailController.text = user['email'] ?? '';
      _nameController.text = user['full_name'] ?? '';
      _phoneController.text = user['phone'] ?? '';
      _selectedRole = user['role'] ?? 'customer';
    } else {
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _phoneController.clear();
      const String empty = ''; // Avoid repetition
      _addressLineController.text = empty;
      _cityController.text = empty;
      _stateController.text = empty;
      _zipCodeController.text = empty;
      _selectedRole = 'vip';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? "Edit User Details" : "Create New User", style: TextStyle(color: AppTheme.primaryGreen)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: SizedBox(
          width: 400, // Limit width for better look
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSectionTitle("Basic Info"),
                  if (!isEdit) ...[
                     TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email)),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "Password", prefixIcon: Icon(Icons.lock)),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ] else 
                     TextFormField(
                      initialValue: user['email'],
                      decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email), filled: true),
                      readOnly: true,
                    ),
                  
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: "Phone", prefixIcon: Icon(Icons.phone)),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(labelText: "System Role", prefixIcon: Icon(Icons.admin_panel_settings)),
                    items: const [
                       DropdownMenuItem(value: 'customer', child: Text("Customer")),
                       DropdownMenuItem(value: 'vip', child: Text("VIP Member")),
                       DropdownMenuItem(value: 'admin', child: Text("Administrator")),
                    ],
                    onChanged: (val) => setState(() => _selectedRole = val),
                  ),
                  
                  if (!isEdit) ...[
                    const SizedBox(height: 20),
                     _buildSectionTitle("Address (Optional)"),
                    TextFormField(controller: _addressLineController, decoration: const InputDecoration(labelText: "Address Line")),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: TextFormField(controller: _cityController, decoration: const InputDecoration(labelText: "City"))),
                      const SizedBox(width: 10),
                      Expanded(child: TextFormField(controller: _stateController, decoration: const InputDecoration(labelText: "State"))),
                    ]),
                    const SizedBox(height: 10),
                    TextFormField(controller: _zipCodeController, decoration: const InputDecoration(labelText: "Zip Code")),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
            onPressed: () async {
               if (_formKey.currentState!.validate()) {
                 Navigator.pop(context); // Close immediately
                 
                 // Show loading indicator
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Processing...')));

                 try {
                   if (isEdit) {
                     await _authService.updateUser(
                       user['id'],
                       fullName: _nameController.text.trim(),
                       phone: _phoneController.text.trim(),
                       role: _selectedRole,
                     );
                   } else {
                      await ref.read(authControllerProvider.notifier).createVipUser(
                        email: _emailController.text.trim(),
                        password: _passwordController.text.trim(),
                        fullName: _nameController.text.trim(),
                        phone: _phoneController.text.trim(),
                        addressLine: _addressLineController.text.trim(),
                        city: _cityController.text.trim(),
                        addressState: _stateController.text.trim(),
                        zipCode: _zipCodeController.text.trim(),
                      );
                   }
                   _loadUsers(); // Refresh
                 } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                 }
               }
            },
            child: Text(isEdit ? "Update User" : "Create User"),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          // Standard Custom Header
          Container(
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("System", style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    const SizedBox(height: 4),
                    const Text("User Management", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                GestureDetector(
                  onTap: () => _showUserDialog(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                         BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.person_add, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text("Add User", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text("No users found", style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final role = (user['role'] ?? 'customer').toString().toUpperCase();
                      final isVip = role == 'VIP';
                      final isAdmin = role == 'ADMIN';
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          borderRadius: BorderRadius.circular(16), 
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4))]
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: isAdmin ? Colors.red[50] : (isVip ? Colors.amber[50] : Colors.blueGrey[50]),
                            child: Icon(
                              isAdmin ? Icons.security : (isVip ? Icons.star : Icons.person),
                              color: isAdmin ? Colors.red : (isVip ? Colors.amber[800] : Colors.blueGrey),
                              size: 24,
                            ),
                          ),
                          title: Text(user['full_name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${user['email']}", style: TextStyle(color: Colors.grey[600], height: 1.4)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                       width: 8, height: 8,
                                       decoration: BoxDecoration(
                                         color: (user['is_active'] ?? true) ? Colors.green : Colors.red,
                                         shape: BoxShape.circle,
                                       ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (user['is_active'] ?? true) ? "Active" : "Inactive",
                                      style: TextStyle(
                                        fontSize: 12, 
                                        color: (user['is_active'] ?? true) ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.w600
                                      )
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (isAdmin ? Colors.red : (isVip ? Colors.amber : Colors.blueGrey)).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12)
                                    ),
                                    child: Text(
                                      role, 
                                      style: TextStyle(
                                        fontSize: 10, 
                                        fontWeight: FontWeight.bold, 
                                        color: isAdmin ? Colors.red : (isVip ? Colors.amber[900] : Colors.blueGrey)
                                      )
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => _showUserDialog(user: user),
                                    child: Text("Edit", style: TextStyle(color: Colors.grey[500], decoration: TextDecoration.underline, fontSize: 12)),
                                  )
                                ],
                              ),
                              const SizedBox(width: 16),
                              Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: user['is_active'] ?? true, 
                                  activeColor: AppTheme.primaryGreen,
                                  onChanged: (val) async {
                                    await _authService.updateUser(user['id'], isActive: val);
                                    _loadUsers();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
  }
}
