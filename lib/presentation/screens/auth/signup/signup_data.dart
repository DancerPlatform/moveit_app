/// Data model to hold signup information across multiple steps
class SignupData {
  // Step 1: Account
  String email = '';
  String password = '';

  // Step 2: Profile
  String name = '';
  String nickname = '';
  String phone = '';

  // Step 3: Personal
  String? gender;
  DateTime? birthdate;
  String nationality = '한국';

  // Step 4: Profile Image
  String? profileImagePath;

  SignupData();

  Map<String, dynamic> toProfileJson() {
    return {
      'name': name.isNotEmpty ? name : null,
      'nickname': nickname.isNotEmpty ? nickname : null,
      'phone': phone.isNotEmpty ? phone : null,
      'gender': gender,
      'birth_date': birthdate?.toIso8601String().split('T').first,
      'nationality': nationality,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}