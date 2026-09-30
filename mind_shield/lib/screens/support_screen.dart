import 'package:flutter/material.dart';

import 'dart:math' as math;

import '../theme/colors.dart';
import '../theme/design_tokens.dart';
import '../theme/typography.dart';
import '../widgets/primary_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_chip.dart';
import '../services/mind_shield_api.dart';

class SupportScreen extends StatefulWidget {
  final MindShieldApi api;
  const SupportScreen({super.key, required this.api});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedChannel;
  String? _selectedWindow;
  String? _selectedUrgency;
  bool _requestSubmitted = false;

  // Breathing pacer animation
  late final AnimationController _breathController;
  late final Animation<double> _breathAnim;
  bool _breathingActive = false;
  int _breathPhase = 0; // 0=inhale, 1=hold, 2=exhale
  final List<String> _phaseLabels = ['INHALE', 'HOLD', 'EXHALE'];
  final List<int> _phaseDurations = [4, 4, 6]; // seconds

  // Mock requests
  List<Map<String, String>> _requests = [];
  String? _requestError;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _breathAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final rows = await widget.api.getMyCounsellingRequests();
      if (mounted) setState(() => _requests = rows.map((r) => {
        'id': r['request_id'].toString(), 'channel': r['source'].toString(),
        'urgency': r['urgency']?.toString() ?? 'routine_48h',
        'status': r['status'].toString().toUpperCase(),
      }).toList());
      if (mounted) setState(() => _requestError = null);
    } on ApiException catch (e) {
      if (mounted) setState(() => _requestError = e.message);
    }
  }

  void _startBreathing() {
    setState(() => _breathingActive = true);
    _runBreathCycle();
  }

  void _stopBreathing() {
    setState(() {
      _breathingActive = false;
      _breathPhase = 0;
    });
    _breathController.stop();
    _breathController.reset();
  }

  void _runBreathCycle() async {
    while (_breathingActive && mounted) {
      for (int p = 0; p < 3; p++) {
        if (!_breathingActive || !mounted) break;
        setState(() => _breathPhase = p);
        final dur = Duration(seconds: _phaseDurations[p]);
        if (p == 0) {
          _breathController.duration = dur;
          await _breathController.forward(from: 0.0);
        } else if (p == 1) {
          await Future.delayed(dur);
        } else {
          _breathController.duration = Duration(seconds: _phaseDurations[p]);
          await _breathController.reverse(from: 1.0);
        }
      }
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSanctuaryBanner(),
          const SizedBox(height: 16),
          _buildCrisisLifeline(),
          const SizedBox(height: 16),
          _buildRequestSessionForm(),
          const SizedBox(height: 16),
          _buildWelfareContact(context),
          const SizedBox(height: 16),
          _buildBreathingPacer(),
          const SizedBox(height: 16),
          _buildMyRequests(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSanctuaryBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.surfaceContainerHigh,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock_outline,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            'CONFIDENTIAL SUPPORT ROUTING — SHARED WITH AUTHORIZED STAFF',
            style: AppTypography.labelSm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrisisLifeline() {
    return GestureDetector(
      onTap: () => showDialog<void>(context: context, builder: (context) => AlertDialog(
        title: const Text('Urgent support'),
        content: const Text('If you or someone else is in immediate danger, contact your local emergency services or go to the nearest emergency department. Ask a trusted person to stay with you. This demo has no crisis phone number configured.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      )),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.alert,
          border: Border.all(color: AppColors.alert),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'URGENT SUPPORT',
                    style: AppTypography.labelLg.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap for immediate safety guidance.',
                    style: AppTypography.bodySm.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.phone_in_talk, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestSessionForm() {
    return GlassCard(
      title: 'Request 1-on-1 Session',
      child: _requestSubmitted
          ? _buildRequestConfirmation()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('TRANSMISSION CHANNEL', style: AppTypography.labelSm),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedChannel,
                  decoration: const InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(borderRadius: AppRadii.control),
                  ),
                  items: ['Anonymous Voice', 'Secure Chat', 'Base Clinic']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedChannel = val),
                  hint: const Text('Select Channel'),
                ),
                const SizedBox(height: 16),
                Text('PREFERRED TIME WINDOW', style: AppTypography.labelSm),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedWindow,
                  decoration: const InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(borderRadius: AppRadii.control),
                  ),
                  items:
                      [
                            'Morning (06:00–12:00)',
                            'Evening (18:00–22:00)',
                            'Off-Duty',
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => _selectedWindow = val),
                  hint: const Text('Select Window'),
                ),
                const SizedBox(height: 16),
                Text('URGENCY TRIAGE', style: AppTypography.labelSm),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedUrgency,
                  decoration: const InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(borderRadius: AppRadii.control),
                  ),
                  items: ['Routine (48h)', 'Priority (4h)']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedUrgency = val),
                  hint: const Text('Select Urgency'),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Confirm Encrypted Appointment',
                  variant: PrimaryButtonVariant.command,
                  fullWidth: true,
                  onPressed:
                      (_selectedChannel != null && _selectedUrgency != null)
                      ? () async {
                          try {
                            await widget.api.createCounsellingRequest(
                              channel: switch (_selectedChannel) {
                                'Anonymous Voice' => 'anonymous_voice',
                                'Secure Chat' => 'secure_chat',
                                _ => 'base_clinic',
                              },
                              timeWindow: _selectedWindow ?? 'Off-Duty',
                              urgency: _selectedUrgency == 'Priority (4h)' ? 'priority_4h' : 'routine_48h',
                            );
                            await _loadRequests();
                          setState(() {
                            _requestSubmitted = true;
                          });
                          } on ApiException catch (e) {
                            setState(() => _requestError = e.message);
                          }
                        }
                      : null,
                ),
              ],
            ),
    );
  }

  Widget _buildRequestConfirmation() {
    return Column(
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: AppColors.nominal,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          'REQUEST SUBMITTED',
          style: AppTypography.labelLg.copyWith(color: AppColors.nominal),
        ),
        const SizedBox(height: 8),
        Text(
          'Your request is confidential. An authorized counsellor will reach out within your selected time window.',
          style: AppTypography.bodyMd,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Submit Another',
          variant: PrimaryButtonVariant.secondary,
          fullWidth: true,
          onPressed: () => setState(() {
            _requestSubmitted = false;
            _selectedChannel = null;
            _selectedWindow = null;
            _selectedUrgency = null;
          }),
        ),
      ],
    );
  }

  Widget _buildWelfareContact(BuildContext context) {
    return GlassCard(
      title: 'Unit Welfare Coordinator',
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            color: AppColors.surfaceContainerHigh,
            child: const Icon(Icons.person, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Unit welfare coordinator', style: AppTypography.labelMd),
                Text('Contact details are not configured in this demo.', style: AppTypography.bodySm),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.mail_outline, color: AppColors.primary),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No email contact is configured for this demo.'))),
          ),
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: AppColors.primary),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No phone contact is configured for this demo.'))),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingPacer() {
    return GlassCard(
      title: 'Tactical Regulation — Breathing Exercise',
      child: Column(
        children: [
          if (!_breathingActive) ...[
            Text(
              'Follow a short paced breathing cycle to steady your breathing.',
              style: AppTypography.bodyMd,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Start Breathing Exercise',
              variant: PrimaryButtonVariant.primary,
              fullWidth: true,
              onPressed: _startBreathing,
            ),
          ] else ...[
            AnimatedBuilder(
              animation: _breathAnim,
              builder: (context, _) {
                return Column(
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CustomPaint(
                        painter: _BreathPainter(scale: _breathAnim.value),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _phaseLabels[_breathPhase],
                                style: AppTypography.labelLg.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                '${_phaseDurations[_breathPhase]}s',
                                style: AppTypography.headlineSm.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '4s Inhale · 4s Hold · 6s Exhale',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Stop',
                      variant: PrimaryButtonVariant.secondary,
                      onPressed: _stopBreathing,
                    ),
                  ],
                );
              },
            ),
          ],
          const Divider(height: 32, color: AppColors.borderDefault),
          _buildResourceLink(
            'Post-Traumatic Incident Protocol',
            Icons.article_outlined,
          ),
          const SizedBox(height: 12),
          _buildResourceLink(
            'Family Distance Coping Playbook',
            Icons.family_restroom,
          ),
        ],
      ),
    );
  }

  Widget _buildResourceLink(String title, IconData icon) {
    return GestureDetector(
      onTap: () {},
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildMyRequests() {
    return GlassCard(
      title: 'My Requests',
      child: Column(
        children: _requestError != null
            ? [Text(_requestError!, style: const TextStyle(color: AppColors.alert))]
            : _requests.isEmpty
            ? [
                Text(
                  'No requests yet.',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ]
            : _requests.map((r) {
                StatusChipVariant chipVariant;
                switch (r['status']) {
                  case 'ASSIGNED':
                    chipVariant = StatusChipVariant.operational;
                    break;
                  case 'IN PROGRESS':
                    chipVariant = StatusChipVariant.nominal;
                    break;
                  case 'CLOSED':
                    chipVariant = StatusChipVariant.neutral;
                    break;
                  default:
                    chipVariant = StatusChipVariant.neutral;
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r['id']!, style: AppTypography.labelMd),
                              const SizedBox(height: 2),
                              Text(
                                '${r['channel']} · ${r['urgency']}',
                                style: AppTypography.bodySm,
                              ),
                            ],
                          ),
                        ),
                        StatusChip(label: r['status']!, variant: chipVariant),
                      ],
                    ),
                    if (r != _requests.last)
                      const Divider(height: 20, color: AppColors.borderDefault),
                  ],
                );
              }).toList(),
      ),
    );
  }
}

class _BreathPainter extends CustomPainter {
  final double scale;

  _BreathPainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * scale;
    final outerPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final ringPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, outerPaint);
    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(
      center,
      size.width / 2,
      ringPaint..color = AppColors.borderDefault,
    );
  }

  @override
  bool shouldRepaint(covariant _BreathPainter old) => old.scale != scale;
}
