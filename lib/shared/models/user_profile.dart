class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String role; // 'admin' or 'vip'
  final String? businessName;
  final String? gstNumber;
  
  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.role = 'vip',
    this.businessName,
    this.gstNumber,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'vip',
      businessName: json['business_name'],
      gstNumber: json['gst_number'],
    );
  }
}
