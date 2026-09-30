import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/design_tokens.dart';
import '../theme/typography.dart';
import '../widgets/primary_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_chip.dart';
import '../widgets/radial_gauge.dart';
import 'check_in_screen.dart';
import '../services/mind_shield_api.dart';

class HomeScreen extends StatefulWidget {
  final MindShieldApi api;

  const HomeScreen({super.key, required this.api});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _profile;
  late Future<List<Map<String, dynamic>>> _checkins;
  late Future<Map<String, dynamic>> _risk;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _profile = widget.api.getMyProfile();
    _checkins = widget.api.getMyCheckIns('7d');
    _risk = widget.api.getMyRisk();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: _profile,
            builder: (context, snapshot) => _buildIdentityRibbon(snapshot.data),
          ),
          const SizedBox(height: 16),
          _buildTrustBanner(),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>>(
            future: _risk,
            builder: (context, snapshot) => _buildReadinessCard(context, snapshot.data),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _checkins,
            builder: (context, snapshot) {
              final today = DateTime.now();
              final queued = widget.api.pendingCheckinsCount > 0;
              final completed = (snapshot.data ?? const []).any((entry) {
                final submitted = DateTime.tryParse(entry['submitted_at']?.toString() ?? '');
                return submitted != null && submitted.year == today.year && submitted.month == today.month && submitted.day == today.day;
              });
              return queued || completed
                  ? _buildCheckInComplete(pending: queued)
                  : _buildCheckInCTA(context);
            },
          ),
          const SizedBox(height: 16),
          _buildTacticalInterventions(context),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _checkins,
            builder: (context, snapshot) => _buildSleepSummaryCard(snapshot.data ?? const []),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _checkins,
            builder: (context, snapshot) => _buildOperationalTempoCard(snapshot.data ?? const []),
          ),
          const SizedBox(height: 16),
          _buildDailyAnchor(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildIdentityRibbon([Map<String, dynamic>? profile]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(profile?['display_name']?.toString() ?? 'MIND SHIELD MEMBER', style: AppTypography.headlineSm),
            Text(
              'RANK: ${profile?['rank_label'] ?? 'Operator'}  •  UNIT: ${profile?['unit_name'] ?? 'Unit'}',
              style: AppTypography.labelMd.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const StatusChip(
          label: 'SHIFT: 14:00–22:00',
          variant: StatusChipVariant.operational,
        ),
      ],
    );
  }

  Widget _buildTrustBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderDefault),
        borderRadius: AppRadii.card,
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PRIVATE CHECK-INS · HUMAN REVIEW', style: AppTypography.labelMd),
                const SizedBox(height: 4),
                Text(
                  'Check-ins inform a readiness estimate. Authorized welfare staff review privacy-preserving summaries; no automated punitive action is taken.',
                  style: AppTypography.bodySm,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: AppColors.nominalTint,
            child: Text(
              'DPDP',
              style: AppTypography.labelSm.copyWith(color: AppColors.nominal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadinessCard(BuildContext context, [Map<String, dynamic>? risk]) {
    final score = (risk?['wellness_index'] as num?)?.round() ?? 0;
    final level = risk?['risk_level']?.toString() ?? 'unknown';
    final variant = level == 'high' ? StatusChipVariant.alert : level == 'elevated' ? StatusChipVariant.advisory : StatusChipVariant.nominal;
    return GlassCard(
      title: 'Operational Readiness',
      statusVariant: variant,
      child: Column(
        children: [
          RadialGauge(
            score: score.toDouble(),
            title: risk?['status_chip']?.toString() ?? 'Awaiting check-in',
            statusVariant: variant,
          ),
          const SizedBox(height: 16),
          Text(
            risk?['forecast_text']?.toString() ?? 'Submit a check-in to build your personal readiness trend.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Updated just now',
            style: AppTypography.labelSm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInComplete({bool pending = false}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: const BoxDecoration(color: AppColors.nominalTint),
    child: Row(children: [Icon(pending ? Icons.cloud_upload_outlined : Icons.check_circle, color: AppColors.nominal), const SizedBox(width: 12), Expanded(child: Text(pending ? 'Check-in queued in this session. Reconnect before closing the app to sync it.' : 'Daily check-in complete. Thanks for checking in.'))]),
  );

  Widget _buildCheckInCTA(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.22)),
        borderRadius: AppRadii.panel,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DAILY CHECK-IN', style: AppTypography.labelMd),
                const SizedBox(height: 4),
                Text(
                  'Takes 60 seconds. Your data stays private.',
                  style: AppTypography.bodySm,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          PrimaryButton(
            label: 'Start',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('DAILY CHECK-IN')),
                    body: CheckInScreen(
                      api: widget.api,
                      onComplete: () {
                        Navigator.of(context).pop();
                        setState(_load);
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalInterventions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TACTICAL INTERVENTIONS', style: AppTypography.labelMd),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInterventionCard(
                context,
                'Breathing',
                '2 Min Regulate',
                Icons.air,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInterventionCard(
                context,
                'Grounding',
                '5-4-3-2-1 Reset',
                Icons.spa_outlined,
                AppColors.advisory,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInterventionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RegulationExerciseScreen(grounding: title == 'Grounding'),
      )),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderDefault),
        borderRadius: AppRadii.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title.toUpperCase(), style: AppTypography.labelMd),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTypography.bodySm),
        ],
      ),
      ),
    );
  }

  Widget _buildSleepSummaryCard(List<Map<String, dynamic>> entries) {
    final sleeps = entries.map((row) => (row['sleep_hours'] as num?)?.toDouble()).whereType<double>().toList();
    final average = sleeps.isEmpty ? null : sleeps.reduce((a, b) => a + b) / sleeps.length;
    final lastQuality = entries.isEmpty ? null : entries.last['rest_quality']?.toString();
    final qualityLabel = lastQuality?.replaceAll('_', ' ').toUpperCase() ?? 'NO DATA';
    return GlassCard(
      title: 'Sleep Summary',
      statusVariant: average != null && average < 6 ? StatusChipVariant.alert : StatusChipVariant.nominal,
      child: Row(
        children: [
          Expanded(child: _buildSleepStat(average == null ? '—' : '${average.toStringAsFixed(1)}h', 'AVG SLEEP', average != null && average < 6 ? AppColors.advisory : AppColors.nominal)),
          Container(width: 1, height: 48, color: AppColors.borderDefault),
          Expanded(
            child: _buildSleepStat(qualityLabel, 'LAST REPORTED', lastQuality == 'poor' ? AppColors.alert : AppColors.textSecondary),
          ),
          Container(width: 1, height: 48, color: AppColors.borderDefault),
          Expanded(
            child: _buildSleepStat(
              '${sleeps.length}',
              'CHECK-INS',
              AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepStat(String value, String label, Color valueColor) {
    return Column(
      children: [
        FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: AppTypography.headlineSm.copyWith(color: valueColor))),
        const SizedBox(height: 4),
        FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: AppTypography.labelSm.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center)),
      ],
    );
  }

  Widget _buildOperationalTempoCard(List<Map<String, dynamic>> entries) {
    final recent = entries.length > 7 ? entries.sublist(entries.length - 7) : entries;
    if (recent.isEmpty) return const GlassCard(title: 'Duty Stress — Recent Check-ins', child: Text('Submit a check-in to see your recent duty-stress trend.'));
    return GlassCard(
      title: 'Duty Stress — Recent Check-ins',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(recent.length, (i) {
          final stress = ((recent[i]['stress_score'] as num?) ?? 0).toDouble();
          final level = (stress / 5).clamp(0.05, 1.0).toDouble();
          Color barColor;
          if (stress >= 4) {
            barColor = AppColors.alert;
          } else if (stress >= 3) {
            barColor = AppColors.advisory;
          } else {
            barColor = AppColors.nominal;
          }

          return Column(
            children: [
              Container(
                width: 28,
                height: 56,
                alignment: Alignment.bottomCenter,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  border: i == recent.length - 1
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: FractionallySizedBox(
                heightFactor: level,
                  child: Container(color: barColor),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                DateTime.tryParse(recent[i]['submitted_at'].toString())?.day.toString() ?? '—',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildDailyAnchor() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: AppRadii.panel,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.format_quote,
                color: AppColors.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'DAILY ANCHOR',
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Resilience is not built in comfort. Every check-in is a commitment to your own readiness.',
            style: AppTypography.bodyLg.copyWith(
              color: AppColors.command,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '— SYNAPTIQ WELLNESS PROTOCOL',
            style: AppTypography.labelSm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class RegulationExerciseScreen extends StatefulWidget {
  final bool grounding;
  const RegulationExerciseScreen({super.key, required this.grounding});

  @override
  State<RegulationExerciseScreen> createState() => _RegulationExerciseScreenState();
}

class _RegulationExerciseScreenState extends State<RegulationExerciseScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Set<int> _completed = {};
  static const _prompts = ['Name 5 things you can see', 'Notice 4 things you can feel', 'Identify 3 things you can hear', 'Notice 2 things you can smell', 'Name 1 thing you can taste'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8), lowerBound: .55, upperBound: 1)..repeat(reverse: true);
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.grounding ? 'GROUNDING RESET' : 'BREATHING RESET')),
    body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: widget.grounding
      ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('Bring your attention back to the present, one sense at a time.', style: AppTypography.bodyLg), const SizedBox(height: 24), ...List.generate(_prompts.length, (i) => CheckboxListTile(value: _completed.contains(i), title: Text(_prompts[i]), onChanged: (_) { HapticFeedback.selectionClick(); setState(() => _completed.contains(i) ? _completed.remove(i) : _completed.add(i)); }))])
      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [ScaleTransition(scale: _controller, child: Container(width: 220, height: 220, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary), child: const Center(child: Text('Breathe\nslowly', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 24))))), const SizedBox(height: 24), Text('Inhale as the circle expands. Exhale as it contracts.', textAlign: TextAlign.center, style: AppTypography.bodyLg)]))),
  );
}
