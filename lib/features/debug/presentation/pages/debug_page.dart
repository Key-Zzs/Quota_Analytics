import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_time_format.dart';
import '../../../quota/domain/entities/quota_source.dart';
import '../../../quota/presentation/controllers/quota_controller.dart';

class DebugPage extends StatelessWidget {
  const DebugPage({super.key, required this.controller});

  final QuotaController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final snapshot = controller.snapshot;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DebugCard(
              title: 'Runtime',
              children: [
                _DebugRow(label: 'App mode', value: AppConstants.appMode),
                const _DebugRow(
                  label: 'Current data source',
                  value: 'MockQuotaDataSource',
                ),
                _DebugRow(
                  label: 'Snapshot source',
                  value: snapshot?.source.label ?? 'none',
                ),
                _DebugRow(
                  label: 'Last refresh result',
                  value: controller.lastRefreshResult,
                ),
                _DebugRow(
                  label: 'Last refresh duration',
                  value: formatDuration(controller.lastRefreshDuration),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DebugCard(
              title: 'Current QuotaSnapshot',
              children: [
                SelectableText(
                  snapshot?.toDebugText() ?? 'No snapshot loaded.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _DebugCard(
              title: 'Safety notice',
              children: [
                Text('No real login'),
                Text('No token access'),
                Text('No network request'),
                Text('No cookie reading'),
                SizedBox(height: 8),
                Text(AppConstants.stageNotice),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _DebugCard extends StatelessWidget {
  const _DebugCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DebugRow extends StatelessWidget {
  const _DebugRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 150, child: Text(label)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
