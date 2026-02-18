import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_config.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  User? get currentUser => _supabase.auth.currentUser;

  // Replaces public signUp with Admin-only creation
  Future<void> createVipUser({
    required String email,
    required String password,
    String? fullName,
    String? phone,
    String? addressLine,
    String? city,
    String? state,
    String? zipCode,
  }) async {
    final response = await _supabase.functions.invoke(
      'create_vip_user',
      body: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'phone': phone,
        'addressLine': addressLine,
        'city': city,
        'state': state,
        'zipCode': zipCode,
      },
    );

    if (response.status != 200) {
      throw Exception('Failed to create user: ${response.data}');
    }
  }

  Future<AuthResponse> signIn({
    required String email, 
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Fetch user profile to get Role
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .single();
    
    return response;
  }

  // Admin: Fetch all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final response = await _supabase
        .from('users')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Admin: Fetch ONLY VIP users (created by Admin)
  Future<List<Map<String, dynamic>>> getVipUsers() async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('role', 'vip') // STRICT FILTER
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Admin: Update User (Including Password if provided)
  Future<void> updateUser(String userId, {String? fullName, String? phone, String? role, bool? isActive, String? password}) async {
    // 1. Update Public Profile
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (role != null) updates['role'] = role;
    if (isActive != null) updates['is_active'] = isActive;

    if (updates.isNotEmpty) {
      await _supabase.from('users').update(updates).eq('id', userId);
    }

    // 2. Update Auth (Password) using Service Role
    if (password != null && password.isNotEmpty) {
       await SupabaseConfig.adminClient.auth.admin.updateUserById(
         userId,
         attributes: AdminUserAttributes(password: password),
       );
    }
  }
}
