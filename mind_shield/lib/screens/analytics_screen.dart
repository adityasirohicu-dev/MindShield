import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/design_tokens.dart';
import '../theme/typography.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_chip.dart';
import '../widgets/ai_attribution_driver.dart';
import '../widgets/trend_chart.dart';
import '../services/mind_shield_api.dart';

class AnalyticsScreen extends StatefulWidget {
  final MindShieldApi api;
  const AnalyticsScreen({super.key, required this.api});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedRange = '7 DAYS';
  final List<String> _ranges = ['7 DAYS', '14 DAYS', '30 DAYS', 'DUTY CYCLE'];
  List<Map<String, dynamic>> _checkins = [];
  Map<String, dynamic>? _risk;
  String? _loadError;
  bool _loading = true;
  final Map<String, bool> _consents = {};

  @override
  void initState() { super.initState(); _load(); }

  String get _rangeDays => switch (_selectedRange) { '14 DAYS' => '14d', '30 DAYS' => '30d', 'DUTY CYCLE' => '90d', _ => '7d' };

  Future<void> _load() async {
    setState(() { _loading = true; _loadError = null; });
    try {
      final results = await Future.wait([widget.api.getMyCheckIns(_rangeDays), widget.api.getMyRisk(), widget.api.getConsentSources()]);
      if (mounted) setState(() {
        _checkins = results[0] as List<Map<String, dynamic>>;
        _risk = results[1] as Map<String, dynamic>;
        for (final row in results[2] as List<Map<String, dynamic>>) {
          _consents[row['data_type'].toString()] = row['status'] == 'granted';
        }
        _loading = false;
      });
    } on ApiException catch (e) { if (mounted) setState(() { _loadError = e.message; _loading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_loadError!), const SizedBox(height: 12), FilledButton(onPressed: _load, child: const Text('Retry'))])));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildZeroSupervisoryStrip(),
          const SizedBox(height: 16),
          _buildTimeRangeSelector(),
          const SizedBox(height: 16),
          _buildPredictiveStrainForecast(),
          const SizedBox(height: 16),
          _buildAiDrivers(),
          const SizedBox(height: 16),
          _buildTrendChart(),
          const SizedBox(height: 16),
          _buildAiSuggestionPanel(),
          const SizedBox(height: 16),
          _buildConsentControls(),
        ],
      ),
    );
  }

  Widget _buildZeroSupervisoryStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.surfaceContainerHigh,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.visibility_off,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            'RAW NOTES AND SENSOR STREAMS ARE NOT SHARED',
            style: AppTypography.labelSm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _ranges.map((range) {
        final isSelected = range == _selectedRange;
        return GestureDetector(
          onTap: () { setState(() => _selectedRange = range); _load(); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.borderDefault,
              ),
            ),
            child: Text(
              range,
              style: AppTypography.labelSm.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPredictiveStrainForecast() {
    return GlassCard(
      title: 'Predictive Strain Forecast',
      statusVariant: StatusChipVariant.alert,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusChip(
            label: (_risk?['status_chip']?.toString() ?? 'CHECK IN TO BUILD YOUR TREND').toUpperCase(),
            variant: _risk?['risk_level'] == 'high' ? StatusChipVariant.alert : StatusChipVariant.advisory,
          ),
          const SizedBox(height: 12),
          Text(
            _risk?['forecast_text']?.toString() ?? 'Your check-in history will shape a personal readiness forecast.',
            style: AppTypography.bodyMd,
          ),
        ],
      ),
    );
  }

  Widget _buildAiDrivers() {
    return GlassCard(
      title: 'AI Attribution Drivers',
      child: Column(
        children: [
          for (final factor in ((_risk?['contributing_factors'] as List<dynamic>?) ?? const []))
            AiAttributionDriver(
              factorName: (factor as Map<String, dynamic>)['factor'].toString(),
              impactPercentage: (((factor['weight'] as num?) ?? 0) * 100).round(),
              explanation: factor['explanation']?.toString() ?? 'Contributes to the current readiness estimate.',
              isPositiveImpact: factor['trend'] == 'improving',
            ),
          if (((_risk?['contributing_factors'] as List<dynamic>?) ?? const []).isEmpty)
            const Text('Complete check-ins to see the factors that shape your personal trend.'),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    return GlassCard(
      title: 'Stress Load vs. Recovery Trend',
      child: _checkins.isEmpty ? const Padding(padding: EdgeInsets.all(20), child: Text('No check-ins in this time range yet.')) : TrendChart(
        stressData: _checkins.map((e) => (e['stress_score'] as num).toDouble()).toList(),
        recoveryData: _checkins.map((e) => (e['recovery_score'] as num).toDouble()).toList(),
        labels: _checkins.map((e) => DateTime.tryParse(e['submitted_at'].toString())?.day.toString() ?? '').toList(),
        spikeLabel: 'STRESS LOAD — ${_selectedRange.toLowerCase()}',
        spikeIndex: null,
      ),
    );
  }

  Widget _buildAiSuggestionPanel() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderDefault),
              ),
            ),
            child: Row(
              children: [
                Text('AI EARLY SUGGESTION', style: AppTypography.labelMd),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  color: AppColors.surfaceContainerHigh,
                  child: Text(
                    'ADVISORY ONLY',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your indicators suggest pre-fatigue strain accumulating. Consider the following before your next cycle:',
                  style: AppTypography.bodyMd,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSuggestionButton(
                        'REST PROTOCOL',
                        Icons.bedtime_outlined,
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSuggestionButton(
                        'LOG OFF-DUTY',
                        Icons.logout,
                        AppColors.advisory,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionButton(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(border: Border.all(color: color)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: AppTypography.labelSm.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildConsentControls() {
    return GlassCard(
      title: 'Data Sources & Consent Controls',
      child: Column(
        children: [
          _buildConsentRow('Risk scoring from check-ins', 'risk_scoring'),
          const Divider(height: 24, color: AppColors.borderDefault),
          _buildConsentRow('Activity sensing', 'accelerometer'),
          const Divider(height: 24, color: AppColors.borderDefault),
          _buildConsentRow('Wearable features', 'wearable'),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
                title: const Text('Purge optional sensor data?'),
                content: const Text('Derived sensor features will be deleted and excluded from future scoring. Your check-in history remains available.'),
                actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Purge data'))],
              ));
              if (confirmed == true) {
                try { await widget.api.purgeSensorData(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Optional sensor data purged.'))); }
                on ApiException catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))); }
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.alert,
              side: const BorderSide(color: AppColors.alert),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadii.control,
              ),
            ),
            child: const Text('INSTANT LOCAL PURGE'),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentRow(String title, String dataType) {
    final isEnabled = _consents[dataType] ?? false;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              color: isEnabled ? AppColors.nominal : AppColors.borderEmphasis,
            ),
            const SizedBox(width: 10),
            Text(title, style: AppTypography.bodyMd),
          ],
        ),
        Switch(
          value: isEnabled,
          onChanged: (val) async {
            setState(() => _consents[dataType] = val);
            try { await widget.api.updateConsent(dataType, val); }
            on ApiException catch (e) { if (mounted) { setState(() => _consents[dataType] = !val); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))); } }
          },
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }
}
