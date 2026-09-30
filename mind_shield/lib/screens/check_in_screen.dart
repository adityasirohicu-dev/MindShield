import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/design_tokens.dart';
import '../theme/typography.dart';
import '../widgets/primary_button.dart';
import '../widgets/glass_card.dart';
import '../services/mind_shield_api.dart';

class CheckInScreen extends StatefulWidget {
  final MindShieldApi api;
  final VoidCallback onComplete;

  const CheckInScreen({super.key, required this.api, required this.onComplete});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Form State
  String? _selectedMentalState;
  double _stressLevel = 5;
  int _sleepHours = 6;
  String? _restQuality;
  final List<String> _selectedFrictions = [];
  bool _consentGiven = false;
  bool _isSubmitting = false;
  String? _submitError;

  final List<String> _mentalStates = [
    'Energetic & Alert',
    'Steady-Focused',
    'Fatigued-Strained',
    'Anxious-Overwhelmed',
    'Exhausted',
  ];

  final List<String> _frictionFactors = [
    'Extended duty hours',
    'Traumatic incident exposure',
    'Family separation',
    'Administrative load',
    'None today',
  ];

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });
    try {
      await widget.api.submitCheckIn(
        readinessState: switch (_selectedMentalState) {
          'Energetic & Alert' => 'energetic_alert',
          'Steady-Focused' => 'steady_focused',
          'Fatigued-Strained' => 'fatigued_strained',
          'Anxious-Overwhelmed' => 'anxious_overwhelmed',
          _ => 'exhausted',
        },
        stressLevel: _stressLevel.toInt(),
        sleepHours: _sleepHours,
        restQuality: switch (_restQuality) {
          'Restful' => 'restful',
          'Interrupted' => 'interrupted',
          _ => 'poor',
        },
        frictionFactors: _selectedFrictions,
      );
      if (mounted) widget.onComplete();
    } on ApiException catch (error) {
      if (mounted) setState(() => _submitError = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_submitError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              _submitError!,
              style: const TextStyle(color: AppColors.alert),
            ),
          ),
        // Progress Bar
        _buildProgressBar(),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildCurrentStep(),
          ),
        ),

        // Bottom Actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.borderDefault)),
          ),
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: PrimaryButton(
                    label: 'Back',
                    variant: PrimaryButtonVariant.secondary,
                    onPressed: _prevStep,
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: _isSubmitting
                      ? 'SUBMITTING...'
                      : (_currentStep == _totalSteps - 1
                            ? 'Submit Check-In'
                            : 'Continue'),
                  variant: PrimaryButtonVariant.primary,
                  onPressed: _canProceed() && !_isSubmitting ? _nextStep : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _canProceed() {
    if (_currentStep == 0) return _selectedMentalState != null;
    if (_currentStep == 1) return _restQuality != null;
    if (_currentStep == 2) return _consentGiven;
    return true;
  }

  Widget _buildProgressBar() {
    return Container(
      height: 4,
      width: double.infinity,
      color: AppColors.surfaceContainerHigh,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: (_currentStep + 1) / _totalSteps,
        child: Container(color: AppColors.primary),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP 1/3',
          style: AppTypography.labelMd.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Text('MENTAL READINESS STATE', style: AppTypography.headlineSm),
        const SizedBox(height: 24),
        ..._mentalStates.map((state) {
          final isSelected = _selectedMentalState == state;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => setState(() => _selectedMentalState = state),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryPressed.withValues(alpha: 0.1)
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
                    ),
                    const SizedBox(width: 12),
                    Text(
                      state,
                      style: AppTypography.bodyLg.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP 2/3',
          style: AppTypography.labelMd.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Text('DUTY STRESS & SLEEP', style: AppTypography.headlineSm),
        const SizedBox(height: 24),

        GlassCard(
          title: 'Duty Stress & Tension',
          child: Column(
            children: [
              Text(
                'Current Level: ${_stressLevel.toInt()}',
                style: AppTypography.labelLg,
              ),
              Slider(
                value: _stressLevel,
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _stressLevel = val),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('CALM', style: AppTypography.labelSm),
                  Text('CRITICAL', style: AppTypography.labelSm),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        GlassCard(
          title: 'Biological Rest',
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sleep Hours', style: AppTypography.bodyMd),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () => setState(
                          () => _sleepHours = (_sleepHours > 0)
                              ? _sleepHours - 1
                              : 0,
                        ),
                      ),
                      Text('$_sleepHours h', style: AppTypography.labelLg),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => setState(() => _sleepHours++),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(color: AppColors.borderDefault),
              Text('Rest Quality', style: AppTypography.bodyMd),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['Restful', 'Interrupted', 'Poor'].map((quality) {
                  final isSelected = _restQuality == quality;
                  return ChoiceChip(
                    label: Text(quality),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _restQuality = quality),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.control,
                    ),
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        GlassCard(
          title: 'Operational Friction Factors',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _frictionFactors.map((factor) {
              final isSelected = _selectedFrictions.contains(factor);
              return FilterChip(
                label: Text(factor, style: const TextStyle(fontSize: 12)),
                selected: isSelected,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.control,
                ),
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      if (factor == 'None today') {
                        _selectedFrictions.clear();
                      } else {
                        _selectedFrictions.remove('None today');
                      }
                      _selectedFrictions.add(factor);
                    } else {
                      _selectedFrictions.remove(factor);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP 3/3',
          style: AppTypography.labelMd.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Text('REVIEW & CONSENT', style: AppTypography.headlineSm),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            border: Border.all(color: AppColors.borderEmphasis),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _consentGiven,
                activeColor: AppColors.primary,
                onChanged: (val) =>
                    setState(() => _consentGiven = val ?? false),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Automated Early-Warning Consent',
                      style: AppTypography.labelMd,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'I consent to my check-in data being used by the Mind Shield AI to calculate my risk trend. I understand this is for early-warning support routing and not for command surveillance. I can revoke this at any time.',
                      style: AppTypography.bodySm,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
