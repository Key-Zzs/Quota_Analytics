import 'package:flutter/material.dart';

import '../../data/mock_settings_repository.dart';
import '../../domain/entities/refresh_interval.dart';
import '../widgets/refresh_interval_selector.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.repository});

  final MockSettingsRepository repository;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _autoRefreshEnabled;
  late RefreshInterval _refreshInterval;

  @override
  void initState() {
    super.initState();
    _autoRefreshEnabled = widget.repository.autoRefreshEnabled;
    _refreshInterval = widget.repository.refreshInterval;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Automatic refresh'),
                subtitle: const Text('In-memory mock setting only'),
                value: _autoRefreshEnabled,
                onChanged: (value) {
                  setState(() {
                    widget.repository.setAutoRefreshEnabled(value);
                    _autoRefreshEnabled = widget.repository.autoRefreshEnabled;
                    _refreshInterval = widget.repository.refreshInterval;
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: RefreshIntervalSelector(
                  selected: _refreshInterval,
                  onChanged: (interval) {
                    setState(() {
                      widget.repository.setRefreshInterval(interval);
                      _autoRefreshEnabled =
                          widget.repository.autoRefreshEnabled;
                      _refreshInterval = widget.repository.refreshInterval;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current selection',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('Auto refresh: ${_autoRefreshEnabled ? 'On' : 'Off'}'),
                Text('Interval: ${_refreshInterval.label}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: colorScheme.surfaceContainerHighest,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Stage 1 only stores settings in memory / mock mode.'),
          ),
        ),
      ],
    );
  }
}
