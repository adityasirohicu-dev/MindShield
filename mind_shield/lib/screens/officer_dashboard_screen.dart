import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/design_tokens.dart';
import '../theme/typography.dart';
import '../widgets/primary_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_chip.dart';
import '../widgets/ai_attribution_driver.dart';
import '../services/mind_shield_api.dart';

// ─── Data models (mock) ────────────────────────────────────────────────
class _CaseItem {
  final String id;
  final String userRef;
  final String riskLevel;
  final String generatedAt;
  final String reviewStatus;
  final List<Map<String, dynamic>> factors;
  final List<String> recommendedActions;

  const _CaseItem({
    required this.id,
    required this.userRef,
    required this.riskLevel,
    required this.generatedAt,
    required this.reviewStatus,
    required this.factors,
    this.recommendedActions = const [],
  });
}

// ─── Officer Dashboard Root ─────────────────────────────────────────────
class OfficerDashboardScreen extends StatefulWidget {
  final MindShieldApi api;
  final VoidCallback onLogout;
  const OfficerDashboardScreen({super.key, required this.api, required this.onLogout});

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  int _selectedTab = 0;
  _CaseItem? _selectedCase;
  bool _loading = true;
  String? _loadError;
  Map<String, dynamic>? _trends;
  String _userRole = '';
  String _riskFilter = 'all';
  String _sortMode = 'risk';

  final List<_CaseItem> _queue = [
    _CaseItem(
      id: 'ASSESS-001',
      userRef: 'OPERATOR 117',
      riskLevel: 'high',
      generatedAt: '2h ago',
      reviewStatus: 'pending',
      factors: [
        {
          'factor': 'Extended Consecutive Duty',
          'weight': 0.42,
          'trend': 'worsening',
          'impact': 42,
          'isNegative': true,
          'explanation': '6 consecutive 12h shifts without rest.',
        },
        {
          'factor': 'Sleep Deficit',
          'weight': 0.31,
          'trend': 'worsening',
          'impact': 31,
          'isNegative': true,
          'explanation': 'Avg 4.1h sleep over 7 days.',
        },
        {
          'factor': 'High Friction Factors',
          'weight': 0.18,
          'trend': 'stable',
          'impact': 18,
          'isNegative': true,
          'explanation': 'Reported traumatic incident exposure × 2.',
        },
        {
          'factor': 'No Leave (14 days)',
          'weight': 0.09,
          'trend': 'worsening',
          'impact': 9,
          'isNegative': true,
          'explanation': 'No approved leave in current period.',
        },
      ],
    ),
    _CaseItem(
      id: 'ASSESS-002',
      userRef: 'OPERATOR 284',
      riskLevel: 'elevated',
      generatedAt: '5h ago',
      reviewStatus: 'pending',
      factors: [
        {
          'factor': 'Sleep Deficit',
          'weight': 0.35,
          'trend': 'worsening',
          'impact': 35,
          'isNegative': true,
          'explanation': 'Averaging 5.0h sleep over 14 days.',
        },
        {
          'factor': 'Missed Check-ins',
          'weight': 0.28,
          'trend': 'worsening',
          'impact': 28,
          'isNegative': true,
          'explanation': '4 of 7 daily check-ins skipped.',
        },
        {
          'factor': 'Recent Leave',
          'weight': 0.15,
          'trend': 'stable',
          'impact': 15,
          'isNegative': false,
          'explanation': '5 days leave taken 3 weeks ago.',
        },
      ],
    ),
    _CaseItem(
      id: 'ASSESS-003',
      userRef: 'OPERATOR 339',
      riskLevel: 'elevated',
      generatedAt: '1d ago',
      reviewStatus: 'reviewed',
      factors: [
        {
          'factor': 'Duty Stress Trend',
          'weight': 0.40,
          'trend': 'stable',
          'impact': 40,
          'isNegative': true,
          'explanation': 'Stress scores averaging 7.8/10 for 14 days.',
        },
        {
          'factor': 'Administrative Load',
          'weight': 0.22,
          'trend': 'stable',
          'impact': 22,
          'isNegative': true,
          'explanation': 'Reported administrative load 3× in check-ins.',
        },
      ],
    ),
    _CaseItem(
      id: 'ASSESS-004',
      userRef: 'OPERATOR 451',
      riskLevel: 'moderate',
      generatedAt: '2d ago',
      reviewStatus: 'actioned',
      factors: [
        {
          'factor': 'Sleep Interruptions',
          'weight': 0.30,
          'trend': 'improving',
          'impact': 30,
          'isNegative': true,
          'explanation': 'Reported interrupted sleep 5 of 7 nights.',
        },
      ],
    ),
  ];

  final List<Map<String, String>> _counsellingQueue = [
    {
      'id': 'REQ-001',
      'source': 'self_requested',
      'status': 'assigned',
      'created': '6h ago',
    },
    {
      'id': 'REQ-002',
      'source': 'risk_flagged',
      'status': 'requested',
      'created': '1d ago',
    },
    {
      'id': 'REQ-003',
      'source': 'self_requested',
      'status': 'in_progress',
      'created': '3d ago',
    },
  ];

  List<Map<String, String>> _auditLog = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard({String? levels}) async {
    try {
      final results = await Future.wait([
        widget.api.getRiskQueue(levels: levels ?? 'low,moderate,elevated,high', sort: _sortMode),
        widget.api.getCounsellingQueue(),
        widget.api.getOrgTrends(),
        widget.api.getMyProfile(),
      ]);
      if (!mounted) return;
      final profile = results[3] as Map<String, dynamic>;
      var auditRows = <Map<String, dynamic>>[];
      if (profile['role'] == 'org_admin') auditRows = await widget.api.getAuditLogs();
      if (!mounted) return;
      setState(() {
          _queue
          ..clear()
          ..addAll((results[0] as List<Map<String, dynamic>>).map((row) => _CaseItem(
            id: row['assessment_id'].toString(), userRef: row['user_ref'].toString(),
            riskLevel: row['risk_level'].toString(), generatedAt: row['generated_at'].toString(),
            reviewStatus: row['review_status'].toString(), factors: const [],
          )));
        _counsellingQueue
          ..clear()
          ..addAll((results[1] as List<Map<String, dynamic>>).map((row) => <String, String>{
            'id': row['request_id'].toString(),
            'source': row['source'].toString(),
            'status': row['status'].toString(),
            'created': row['created_at'].toString(),
          }));
        _trends = results[2] as Map<String, dynamic>;
        _userRole = profile['role']?.toString() ?? '';
        _auditLog = auditRows.map((row) => <String, String>{
          'actor': row['actor_id'].toString(),
          'action': row['action'].toString(),
          'target': row['target_user_id']?.toString() ?? '—',
          'time': row['timestamp'].toString(),
        }).toList();
        _loading = false;
        _loadError = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() { _loading = false; _loadError = e.message; });
    }
  }

  Future<void> _openCase(_CaseItem item) async {
    setState(() { _selectedCase = item; _loading = true; });
    try {
      final detail = await widget.api.getRiskDetail(item.id);
      final factors = (detail['contributing_factors'] as List<dynamic>? ?? const []).map((raw) {
        final factor = raw as Map<String, dynamic>;
        final weight = (factor['weight'] as num?) ?? 0;
        return <String, dynamic>{
          'factor': factor['factor'].toString(), 'weight': weight,
          'impact': (weight * 100).round(),
          'isNegative': factor['trend'] != 'improving',
          'explanation': factor['explanation']?.toString() ?? 'Contributing indicator',
        };
      }).toList();
      if (mounted) setState(() {
        _selectedCase = _CaseItem(id: item.id, userRef: item.userRef,
          riskLevel: detail['risk_level'].toString(), generatedAt: detail['generated_at'].toString(),
          reviewStatus: detail['review_status'].toString(), factors: factors,
          recommendedActions: (detail['recommended_actions'] as List<dynamic>? ?? const []).map((action) => action.toString()).toList());
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() { _selectedCase = null; _loading = false; _loadError = e.message; });
    }
  }

  Future<void> _changeCounsellingStatus(String requestId, String status) async {
    try {
      await widget.api.updateCounsellingRequest(requestId, status);
      await _loadDashboard();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedCase != null) {
      if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
      return _CaseDetailView(
        item: _selectedCase!,
        canReview: _userRole == 'welfare_officer',
        onBack: () => setState(() => _selectedCase = null),
        onReviewed: () {
          final reviewedCase = _selectedCase!;
          widget.api.reviewRisk(reviewedCase.id, action: 'support_contacted').then((_) {
            if (!mounted) return;
            setState(() {
          final idx = _queue.indexWhere((c) => c.id == reviewedCase.id);
          if (idx != -1) {
            _queue[idx] = _CaseItem(
              id: reviewedCase.id,
              userRef: reviewedCase.userRef,
              riskLevel: reviewedCase.riskLevel,
              generatedAt: reviewedCase.generatedAt,
              reviewStatus: 'actioned',
              factors: reviewedCase.factors,
              recommendedActions: reviewedCase.recommendedActions,
            );
          }
          _selectedCase = null;
            });
          }).catchError((Object _) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save the case review. Please retry.')));
          });
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.small,
              ),
              child: Image.asset('assets/mind_shield_logo.png'),
            ),
            const SizedBox(width: 10),
            const Text('Welfare Dashboard'),
          ],
        ),
        actions: [
          IconButton(onPressed: widget.onLogout, tooltip: 'Sign out', icon: const Icon(Icons.logout)),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECFF),
                borderRadius: AppRadii.pill,
              ),
              child: Center(
                child: Text(
                  'RBAC: WELFARE OFFICER',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: AppColors.surface,
            child: Row(
              children: [
                _buildTab('QUEUE', 0),
                _buildTab('COUNSELLING', 1),
                _buildTab('TRENDS', 2),
                _buildTab('AUDIT LOG', 3),
              ],
            ),
          ),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.borderDefault,
                width: isSelected ? 2 : 1,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.labelSm.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_loadError!), const SizedBox(height: 12), FilledButton(onPressed: _loadDashboard, child: const Text('Retry'))])));
    switch (_selectedTab) {
      case 0:
        return _buildPriorityQueue();
      case 1:
        return _buildCounsellingQueue();
      case 2:
        return _buildOrgTrends();
      case 3:
        return _buildAuditLog();
      default:
        return const SizedBox();
    }
  }

  Widget _buildPriorityQueue() {
    if (_queue.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.verified_user_outlined, size: 56, color: AppColors.nominal), const SizedBox(height: 16), Text(_riskFilter == 'all' ? 'No cases currently require follow-up.' : 'No ${_riskFilter.toUpperCase()} cases match this filter.'), const Text('You are up to date.')])));
    return Column(
      children: [
        // Summary strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.surfaceContainerHigh,
          child: Row(
            children: [
              _buildSummaryBadge('HIGH', '${_queue.where((c) => c.riskLevel == 'high').length}', AppColors.alert),
              const SizedBox(width: 12),
              _buildSummaryBadge('ELEVATED', '${_queue.where((c) => c.riskLevel == 'elevated').length}', AppColors.advisory),
              const SizedBox(width: 12),
              _buildSummaryBadge('MODERATE', '${_queue.where((c) => c.riskLevel == 'moderate').length}', AppColors.nominal),
              const Spacer(),
              PopupMenuButton<String>(
                tooltip: 'Sort cases',
                initialValue: _sortMode,
                onSelected: (value) { setState(() { _sortMode = value; _loading = true; }); _loadDashboard(); },
                itemBuilder: (_) => const [PopupMenuItem(value: 'risk', child: Text('Highest risk first')), PopupMenuItem(value: 'recency', child: Text('Most recent first'))],
                child: Row(children: [Text(_sortMode == 'risk' ? 'BY RISK' : 'BY DATE', style: AppTypography.labelSm.copyWith(color: AppColors.textSecondary)), const Icon(Icons.sort, size: 18)]),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(spacing: 8, children: [
            for (final filter in ['all', 'high', 'elevated', 'moderate'])
              FilterChip(label: Text(filter.toUpperCase()), selected: _riskFilter == filter, onSelected: (_) {
                setState(() { _riskFilter = filter; _loading = true; });
                _loadDashboard(levels: filter == 'all' ? 'low,moderate,elevated,high' : filter);
              }),
          ]),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _queue.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.borderDefault),
            itemBuilder: (context, i) {
              final item = _queue[i];
              return _buildQueueRow(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryBadge(String label, String count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 6),
        Text(
          '$count $label',
          style: AppTypography.labelSm.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildQueueRow(_CaseItem item) {
    Color riskColor;
    StatusChipVariant chipVariant;
    switch (item.riskLevel) {
      case 'high':
        riskColor = AppColors.alert;
        chipVariant = StatusChipVariant.alert;
        break;
      case 'elevated':
        riskColor = AppColors.advisory;
        chipVariant = StatusChipVariant.alert;
        break;
      default:
        riskColor = AppColors.nominal;
        chipVariant = StatusChipVariant.nominal;
    }

    return GestureDetector(
      onTap: () {
        if (item.reviewStatus == 'pending') {
          _openCase(item);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: item.riskLevel == 'high'
              ? AppColors.alertTint
              : AppColors.surface,
          border: item.riskLevel == 'high'
              ? const Border(left: BorderSide(color: AppColors.alert, width: 3))
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(item.userRef, style: AppTypography.labelMd),
                      const SizedBox(width: 8),
                      StatusChip(
                        label: item.riskLevel.toUpperCase(),
                        variant: chipVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${item.generatedAt}  ·  ',
                        style: AppTypography.bodySm,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        color: item.reviewStatus == 'pending'
                            ? AppColors.alertTint
                            : AppColors.nominalTint,
                        child: Text(
                          item.reviewStatus.toUpperCase(),
                          style: AppTypography.labelSm.copyWith(
                            color: item.reviewStatus == 'pending'
                                ? AppColors.alert
                                : AppColors.nominal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (item.reviewStatus == 'pending')
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounsellingQueue() {
    if (_counsellingQueue.isEmpty) return const Center(child: Text('No counselling requests are waiting.'));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _counsellingQueue.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final r = _counsellingQueue[i];
        StatusChipVariant chip;
        switch (r['status']) {
          case 'assigned':
            chip = StatusChipVariant.operational;
            break;
          case 'in_progress':
            chip = StatusChipVariant.nominal;
            break;
          default:
            chip = StatusChipVariant.neutral;
        }
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r['id']!, style: AppTypography.labelMd),
                    const SizedBox(height: 4),
                    Text(
                      '${r['source']!.replaceAll('_', ' ').toUpperCase()}  ·  ${r['created']!}',
                      style: AppTypography.bodySm,
                    ),
                  ],
                ),
              ),
              Row(mainAxisSize: MainAxisSize.min, children: [
                StatusChip(label: r['status']!.toUpperCase(), variant: chip),
                if (_userRole == 'counsellor' && r['status'] != 'closed') PopupMenuButton<String>(
                  tooltip: 'Update request',
                  onSelected: (status) => _changeCounsellingStatus(r['id']!, status),
                  itemBuilder: (_) => [
                    if (r['status'] == 'requested') const PopupMenuItem(value: 'assigned', child: Text('Assign to me')),
                    if (r['status'] == 'assigned') const PopupMenuItem(value: 'in_progress', child: Text('Start session')),
                    const PopupMenuItem(value: 'closed', child: Text('Close request')),
                  ],
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrgTrends() {
    final trend = _trends ?? const <String, dynamic>{};
    final buckets = (trend['buckets'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
    final counts = {for (final row in buckets) row['risk_level'].toString(): (row['count'] as num).toInt()};
    final unitStats = [{'unit': 'ORGANIZATION', 'low': counts['low'] ?? 0, 'moderate': counts['moderate'] ?? 0, 'elevated': counts['elevated'] ?? 0, 'high': counts['high'] ?? 0}];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.surfaceContainerHigh,
            child: Text(
              'ORG-LEVEL AGGREGATED — NO INDIVIDUAL IDENTIFICATION AT THIS LAYER',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            title: 'Risk Distribution by Unit (Anonymized)',
            child: Column(
              children: unitStats.map((s) {
                final total =
                    (s['low'] as int) +
                    (s['moderate'] as int) +
                    (s['elevated'] as int) +
                    (s['high'] as int);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s['unit'] as String, style: AppTypography.labelMd),
                        Text(
                          '$total PERSONNEL',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRect(
                      child: Row(
                        children: [
                          _buildBar(
                            (s['low'] as int) / total,
                            AppColors.nominal,
                          ),
                          _buildBar(
                            (s['moderate'] as int) / total,
                            AppColors.advisory,
                          ),
                          _buildBar(
                            (s['elevated'] as int) / total,
                            AppColors.alert.withValues(alpha: 0.6),
                          ),
                          _buildBar(
                            (s['high'] as int) / total,
                            AppColors.alert,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double fraction, Color color) {
    return Expanded(
      flex: (fraction * 100).round().clamp(0, 100),
      child: Container(height: 16, color: color),
    );
  }

  Widget _buildAuditLog() {
    if (_userRole != 'org_admin') return const Center(child: Text('Audit log access is limited to organization administrators.'));
    if (_auditLog.isEmpty) return const Center(child: Text('No audit events recorded yet.'));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _auditLog.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppColors.borderDefault),
      itemBuilder: (_, i) {
        final log = _auditLog[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                color: AppColors.surfaceContainerHigh,
                child: const Icon(
                  Icons.history,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log['actor']!, style: AppTypography.labelMd),
                    const SizedBox(height: 2),
                    Text(
                      '${log['action']!.replaceAll('_', ' ')} → ${log['target']!}',
                      style: AppTypography.bodyMd,
                    ),
                  ],
                ),
              ),
              Text(
                log['time']!,
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Case Detail View ───────────────────────────────────────────────────
class _CaseDetailView extends StatelessWidget {
  final _CaseItem item;
  final bool canReview;
  final VoidCallback onBack;
  final VoidCallback onReviewed;

  const _CaseDetailView({
    required this.item,
    required this.canReview,
    required this.onBack,
    required this.onReviewed,
  });

  Color _riskColor() {
    switch (item.riskLevel) {
      case 'high':
        return AppColors.alert;
      case 'elevated':
        return AppColors.advisory;
      case 'moderate':
        return AppColors.advisory;
      default:
        return AppColors.nominal;
    }
  }

  StatusChipVariant _chipVariant() {
    switch (item.riskLevel) {
      case 'high':
      case 'elevated':
        return StatusChipVariant.alert;
      case 'moderate':
        return StatusChipVariant.neutral;
      default:
        return StatusChipVariant.nominal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: Text(item.userRef),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Risk header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _riskColor().withValues(alpha: 0.08),
                border: Border(
                  left: BorderSide(color: _riskColor(), width: 4),
                  top: BorderSide(color: _riskColor().withValues(alpha: 0.3)),
                  right: BorderSide(color: _riskColor().withValues(alpha: 0.3)),
                  bottom: BorderSide(
                    color: _riskColor().withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusChip(
                    label: item.riskLevel.toUpperCase(),
                    variant: _chipVariant(),
                  ),
                  const SizedBox(height: 8),
                  Text(_getSummaryText(), style: AppTypography.bodyMd),
                  const SizedBox(height: 8),
                  Text(
                    'Generated ${item.generatedAt}',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Privacy notice
            Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.surfaceContainerHigh,
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing aggregated indicators only. No raw sensor data, no personal notes visible.',
                      style: AppTypography.bodySm,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // AI Attribution Drivers
            GlassCard(
              title: 'Why This Flag — AI Attribution Drivers',
              child: Column(
                children: item.factors.map((f) {
                  return AiAttributionDriver(
                    factorName: f['factor'] as String,
                    impactPercentage: f['impact'] as int,
                    explanation: f['explanation'] as String,
                    isPositiveImpact: !(f['isNegative'] as bool),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Recommended actions
            GlassCard(
              title: 'Recommended Actions',
              child: item.recommendedActions.isEmpty
                  ? const Text('No additional recommendation is available for this case.')
                  : Column(children: [
                      for (final action in item.recommendedActions)
                        Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.arrow_right, color: AppColors.primary), const SizedBox(width: 8), Expanded(child: Text(action, style: AppTypography.bodyMd))])),
                    ]),
            ),
            const SizedBox(height: 24),

            // Mark reviewed
            if (canReview) PrimaryButton(
              label: 'Mark Reviewed & Log Action',
              variant: PrimaryButtonVariant.command,
              fullWidth: true,
              onPressed: onReviewed,
            ),
          ],
        ),
      ),
    );
  }

  String _getSummaryText() {
    switch (item.riskLevel) {
      case 'high':
        return 'Elevated — Immediate welfare attention recommended. Multiple compounding duty and sleep stress factors detected over 14-day window.';
      case 'elevated':
        return 'Moderate — Watchlist. Sustained duty strain pattern detected. Proactive welfare check recommended within 48h.';
      default:
        return 'Moderate — Pattern detected. Routine welfare follow-up recommended.';
    }
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    PrimaryButtonVariant variant,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: variant == PrimaryButtonVariant.command
                ? AppColors.command
                : variant == PrimaryButtonVariant.primary
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.surface,
            border: Border.all(
              color: variant == PrimaryButtonVariant.command
                  ? AppColors.command
                  : variant == PrimaryButtonVariant.primary
                  ? AppColors.primary
                  : AppColors.borderEmphasis,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: variant == PrimaryButtonVariant.command
                    ? Colors.white
                    : variant == PrimaryButtonVariant.primary
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(
                label.toUpperCase(),
                style: AppTypography.labelMd.copyWith(
                  color: variant == PrimaryButtonVariant.command
                      ? Colors.white
                      : variant == PrimaryButtonVariant.primary
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
