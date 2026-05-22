import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_time_format.dart';
import '../../domain/entities/parser_confidence.dart';
import '../../domain/entities/quota_snapshot.dart';
import '../../domain/entities/quota_source.dart';
import '../controllers/quota_controller.dart';
import '../widgets/quota_card.dart';
import '../widgets/quota_empty_view.dart';
import '../widgets/quota_error_view.dart';

class QuotaHomePage extends StatelessWidget {
  const QuotaHomePage({super.key, required this.controller});

  final QuotaController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final snapshot = controller.snapshot;

        if (controller.status == QuotaPageStatus.loading && snapshot == null) {
          return const _InitialLoadingView();
        }

        if (controller.status == QuotaPageStatus.error) {
          return QuotaErrorView(
            message: controller.errorMessage ?? 'Unknown mock error',
            onRetry: () => unawaited(controller.loadLatestSnapshot()),
          );
        }

        if (snapshot == null) {
          return QuotaEmptyView(
            onRefresh: () => unawaited(controller.refresh()),
          );
        }

        return _QuotaDashboard(snapshot: snapshot, controller: controller);
      },
    );
  }
}

class _InitialLoadingView extends StatelessWidget {
  const _InitialLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading mock quota...'),
        ],
      ),
    );
  }
}

class _QuotaDashboard extends StatelessWidget {
  const _QuotaDashboard({required this.snapshot, required this.controller});

  final QuotaSnapshot snapshot;
  final QuotaController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ModeBanner(isLoading: controller.isLoading),
        const SizedBox(height: 12),
        Text(
          AppConstants.appSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        QuotaCard(window: snapshot.fiveHourWindow),
        const SizedBox(height: 12),
        QuotaCard(window: snapshot.weeklyWindow),
        const SizedBox(height: 12),
        _CreditsCard(snapshot: snapshot),
        const SizedBox(height: 12),
        _MetadataCard(snapshot: snapshot, controller: controller),
      ],
    );
  }
}

class _ModeBanner extends StatelessWidget {
  const _ModeBanner({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppConstants.stageNotice,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (isLoading) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                color: colorScheme.onSecondaryContainer,
                backgroundColor: colorScheme.onSecondaryContainer.withValues(
                  alpha: 0.16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CreditsCard extends StatelessWidget {
  const _CreditsCard({required this.snapshot});

  final QuotaSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final total = snapshot.creditsTotal;
    final remaining = snapshot.creditsRemaining;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Credits', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              remaining == null ? '--' : remaining.toStringAsFixed(2),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              total == null
                  ? 'Remaining credits'
                  : 'Remaining of ${total.toStringAsFixed(2)} total credits',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text('Source: ${snapshot.source.label}'),
          ],
        ),
      ),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.snapshot, required this.controller});

  final QuotaSnapshot snapshot;
  final QuotaController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Metadata', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _MetadataRow(label: 'Account', value: snapshot.accountLabel),
            _MetadataRow(label: 'Data source', value: snapshot.source.label),
            _MetadataRow(
              label: 'Parser confidence',
              value: snapshot.parserConfidence.label,
            ),
            _MetadataRow(
              label: 'Last updated',
              value: formatDateTime(snapshot.capturedAt),
            ),
            _MetadataRow(
              label: 'Next suggested refresh',
              value: formatDateTime(snapshot.nextSuggestedRefreshAt),
            ),
            _MetadataRow(
              label: 'Last refresh result',
              value: controller.lastRefreshResult,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
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
