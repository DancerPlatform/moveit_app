import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/services/supabase_service.dart';
import '../signup_data.dart';

class SignupStep2Profile extends StatefulWidget {
  final SignupData signupData;
  final bool isLoading;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const SignupStep2Profile({
    super.key,
    required this.signupData,
    required this.isLoading,
    required this.onNext,
    required this.onSkip,
  });

  @override
  State<SignupStep2Profile> createState() => _SignupStep2ProfileState();
}

class _SignupStep2ProfileState extends State<SignupStep2Profile> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isCheckingNickname = false;
  bool? _isNicknameAvailable;
  String? _checkedNickname;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.signupData.name;
    _nicknameController.text = widget.signupData.nickname;
    _phoneController.text = widget.signupData.phone;

    _nicknameController.addListener(_onNicknameChanged);
  }

  @override
  void dispose() {
    _nicknameController.removeListener(_onNicknameChanged);
    _nameController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onNicknameChanged() {
    // Reset availability status when nickname changes
    if (_checkedNickname != _nicknameController.text.trim()) {
      setState(() {
        _isNicknameAvailable = null;
        _checkedNickname = null;
      });
    }
  }

  Future<void> _checkNicknameDuplicate() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) return;

    setState(() => _isCheckingNickname = true);

    try {
      final response = await SupabaseService.client
          .from('users')
          .select('id')
          .eq('nickname', nickname)
          .maybeSingle();

      setState(() {
        _isNicknameAvailable = response == null;
        _checkedNickname = nickname;
      });
    } catch (e) {
      setState(() {
        _isNicknameAvailable = null;
        _checkedNickname = null;
      });
    } finally {
      setState(() => _isCheckingNickname = false);
    }
  }

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      // Check if nickname was verified
      final nickname = _nicknameController.text.trim();
      if (nickname.isNotEmpty && _checkedNickname != nickname) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.nicknameCheckRequired),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (_isNicknameAvailable == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.nicknameTaken),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      widget.signupData.name = _nameController.text.trim();
      widget.signupData.nickname = nickname;
      widget.signupData.phone = _phoneController.text.trim();
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              AppStrings.signupStep2Title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.signupStep2Subtitle,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 40),
            _buildNameField(),
            const SizedBox(height: 20),
            _buildNicknameField(),
            const SizedBox(height: 20),
            _buildPhoneField(),
            const SizedBox(height: 40),
            _buildNextButton(),
            const SizedBox(height: 12),
            _buildSkipButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          keyboardType: TextInputType.name,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: AppStrings.nameHint,
            hintStyle: const TextStyle(color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppStrings.nameRequired;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNicknameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.nickname,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _nicknameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: AppStrings.nicknameHint,
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  suffixIcon: _isNicknameAvailable != null
                      ? Icon(
                          _isNicknameAvailable!
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: _isNicknameAvailable!
                              ? AppColors.success
                              : AppColors.error,
                        )
                      : null,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.nicknameRequired;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isCheckingNickname ||
                        _nicknameController.text.trim().isEmpty
                    ? null
                    : _checkNicknameDuplicate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(
                    color: AppColors.border,
                    width: 1,
                  ),
                  disabledBackgroundColor: AppColors.surface,
                  disabledForegroundColor: AppColors.textHint,
                ),
                child: _isCheckingNickname
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textSecondary),
                        ),
                      )
                    : Text(
                        AppStrings.checkDuplicate,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ],
        ),
        if (_isNicknameAvailable != null) ...[
          const SizedBox(height: 8),
          Text(
            _isNicknameAvailable!
                ? AppStrings.nicknameAvailable
                : AppStrings.nicknameTaken,
            style: TextStyle(
              fontSize: 13,
              color:
                  _isNicknameAvailable! ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.phone,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: AppStrings.phoneHint,
            hintStyle: const TextStyle(color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: widget.isLoading ? null : _handleNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
        ),
        child: widget.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                ),
              )
            : Text(
                AppStrings.next,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TextButton(
        onPressed: widget.onSkip,
        child: Text(
          AppStrings.skip,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
