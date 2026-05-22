import 'package:flutter/material.dart';

import '../../domain/entities/refresh_interval.dart';

class RefreshIntervalSelector extends StatelessWidget {
  const RefreshIntervalSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final RefreshInterval selected;
  final ValueChanged<RefreshInterval> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<RefreshInterval>(
      initialValue: selected,
      decoration: const InputDecoration(
        labelText: 'Refresh interval',
        border: OutlineInputBorder(),
      ),
      items: RefreshInterval.values
          .map(
            (interval) => DropdownMenuItem<RefreshInterval>(
              value: interval,
              child: Text(interval.label),
            ),
          )
          .toList(),
      onChanged: (interval) {
        if (interval != null) {
          onChanged(interval);
        }
      },
    );
  }
}
