class UserAddress {
  final String id;
  final String userId;
  final String label;
  final String addressLine;
  final String city;
  final String state;
  final String? zipCode;
  final bool isDefault;

  UserAddress({
    required this.id,
    required this.userId,
    required this.label,
    required this.addressLine,
    required this.city,
    required this.state,
    this.zipCode,
    this.isDefault = false,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id'],
      userId: json['user_id'],
      label: json['label'],
      addressLine: json['address_line'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zip_code'],
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'label': label,
      'address_line': addressLine,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'is_default': isDefault,
    };
  }

  @override
  String toString() {
    return '$addressLine, $city, $state${zipCode != null ? ' - $zipCode' : ''}';
  }
}
