import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/design_tokens.dart';
import '../theme/typography.dart';
import '../widgets/primary_button.dart';
import '../services/mind_shield_api.dart';

class SignUpScreen extends StatefulWidget {
  final MindShieldApi api;
  final void Function({String role}) onSignUpSuccess;
  final VoidCallback onSwitchToLogin;

  const SignUpScreen({
    super.key,
    required this.api,
    required this.onSignUpSuccess,
    required this.onSwitchToLogin,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _credController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  bool _sendingOtp = false;
  bool _demoOtp = false;
  int _resendCountdown = 0;
  String? _errorMsg;
  String _selectedRole = 'personnel';

  final List<Map<String, String>> _roles = [
    {'value': 'personnel', 'label': 'Member'},
    {'value': 'welfare_officer', 'label': 'Officer'},
    {'value': 'counsellor', 'label': 'Counsellor'},
    {'value': 'org_admin', 'label': 'Admin'},
  ];

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMsg = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _sendingOtp = true;
      _errorMsg = null;
    });

    try {
      final result = await widget.api.requestOtp(
        credential: _credController.text.trim(),
        email: email,
        purpose: 'register',
      );
      if (!mounted) return;
      setState(() { _sendingOtp = false; _otpSent = true; _demoOtp = result['delivery'] == 'demo'; _resendCountdown = 30; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['delivery'] == 'demo'
            ? 'Presentation code: 123456'
            : 'Verification code sent to $email'),
        duration: const Duration(seconds: 6),
      ));
      _startResendTimer();
    } on ApiException catch (error) {
      if (mounted) setState(() { _sendingOtp = false; _errorMsg = error.message; });
    }

    // Show success snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text('OTP sent to $email',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: AppColors.nominal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );

    // Start countdown timer
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCountdown--);
      return _resendCountdown > 0;
    });
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    if (_nameController.text.isEmpty ||
        _credController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _otpController.text.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMsg = 'Please fill in all fields';
      });
      return;
    }

    if (!_otpSent) {
      setState(() {
        _isLoading = false;
        _errorMsg = 'Please send and verify the OTP first';
      });
      return;
    }

    try {
      final role = await widget.api.register(
        credential: _credController.text.trim(),
        displayName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
        role: _selectedRole,
      );
      widget.onSignUpSuccess(role: role);
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMsg = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _credController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.page),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                _buildHeader(),
                const SizedBox(height: 48),
                _buildSignUpCard(),
                const SizedBox(height: 24),
                _buildSecurityNote(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.control,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x101B2A4A),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Image.asset('assets/mind_shield_logo.png'),
            ),
            const SizedBox(width: 12),
            Text(
              'MIND SHIELD',
              style: AppTypography.headlineLg.copyWith(
                color: AppColors.command,
                fontSize: 28,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 64),
          child: Text(
            'Personal Wellness & Health Analytics',
            style: AppTypography.labelSm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.nominalTint,
            borderRadius: AppRadii.pill,
            border: Border.all(
              color: AppColors.nominal.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, color: AppColors.nominal),
              const SizedBox(width: 8),
              Text(
                'Private & Secure',
                style: AppTypography.labelSm.copyWith(color: AppColors.nominal),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.panel,
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: const [
          BoxShadow(
            color: Color(0x121B2A4A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Create Account', style: AppTypography.headlineSm),
          const SizedBox(height: 4),
          Text(
            'Join Mind Shield to get started.',
            style: AppTypography.bodySm,
          ),
          const SizedBox(height: 24),

          // Role selector
          Text('Account Type', style: AppTypography.labelSm),
          const SizedBox(height: 8),
          Column(
            children: _roles.map((role) {
              final isSelected = _selectedRole == role['value'];
              return GestureDetector(
                onTap: () => setState(() => _selectedRole = role['value']!),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.surface,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.borderEmphasis,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textDisabled,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        role['label']!,
                        style: AppTypography.labelMd.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Display name field
          Text('Display Name', style: AppTypography.labelSm),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: AppTypography.bodyMd,
            decoration: const InputDecoration(
              hintText: 'Enter your name',
            ),
          ),
          const SizedBox(height: 16),

          // Credential field
          Text('Username', style: AppTypography.labelSm),
          const SizedBox(height: 8),
          TextField(
            controller: _credController,
            style: AppTypography.bodyMd,
            decoration: const InputDecoration(
              hintText: 'Choose a service ID',
            ),
          ),
          const SizedBox(height: 16),

          // Email field with Send OTP button
          Text('Email Address', style: AppTypography.labelSm),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTypography.bodyMd,
                  enabled: !_otpSent,
                  decoration: InputDecoration(
                    hintText: 'you@example.com',
                    suffixIcon: _otpSent
                        ? const Icon(Icons.check_circle,
                            color: AppColors.nominal, size: 20)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: Material(
                  color: _sendingOtp || (_otpSent && _resendCountdown > 0)
                      ? AppColors.borderEmphasis
                      : AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadii.control,
                  ),
                  child: InkWell(
                    borderRadius: AppRadii.control,
                    onTap: _sendingOtp || (_otpSent && _resendCountdown > 0)
                        ? null
                        : _sendOtp,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Center(
                        child: _sendingOtp
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _otpSent
                                    ? (_resendCountdown > 0
                                        ? 'Resend (${_resendCountdown}s)'
                                        : 'Resend')
                                    : 'Send OTP',
                                style: AppTypography.labelSm.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // OTP field (visually disabled until OTP is "sent")
          Text('Verification Code', style: AppTypography.labelSm),
          const SizedBox(height: 8),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            enabled: _otpSent,
            style: AppTypography.labelLg.copyWith(letterSpacing: 8),
            decoration: InputDecoration(
              hintText: _otpSent ? '• • • • • •' : 'Send OTP first',
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),

          if (_errorMsg != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: AppColors.alertTint,
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 16,
                    color: AppColors.alert,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMsg!,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.alert,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          if (_otpSent) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.nominalTint,
                borderRadius: AppRadii.control,
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: AppColors.nominal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _demoOtp
                          ? 'Presentation verification code: 123456'
                          : 'A 6-digit code has been sent to ${_emailController.text.trim()}',
                      style: AppTypography.labelSm
                          .copyWith(color: AppColors.nominal),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 16),
          PrimaryButton(
            label: _isLoading ? 'Creating Account...' : 'Create Account',
            variant: PrimaryButtonVariant.command,
            fullWidth: true,
            onPressed: (_isLoading || !_otpSent) ? null : _register,
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: widget.onSwitchToLogin,
              child: RichText(
                text: TextSpan(
                  text: 'Already have an account? ',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(
                      text: 'Sign In',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Column(
      children: [
        Text(
          'Share only what you choose. Support access is limited by account role and consent.',
          style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'SYNAPTIQ · SIH26186 · DPDP Compliant',
          style: AppTypography.labelSm.copyWith(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }
}
