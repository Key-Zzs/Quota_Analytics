import 'package:flutter/material.dart';

import 'app.dart';
import 'features/background_refresh/data/services/background_task_dispatcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundTaskDispatcher.initialize();
  runApp(const QuotaAnalyticsApp());
}
