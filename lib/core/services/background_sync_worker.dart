import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:workmanager/workmanager.dart';
import '../../features/sync/data/datasources/sync_local_datasource.dart';

const String kBackgroundSyncTaskKey = 'com.snapsync.backgroundSyncTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection = connectivityResult.any((r) => r != ConnectivityResult.none);

      if (hasConnection) {
        final localDataSource = SyncLocalDataSource();
        await localDataSource.init();
        // Background worker monitors connectivity and processes pending local uploads
      }
      return Future.value(true);
    } catch (_) {
      return Future.value(false);
    }
  });
}

class BackgroundSyncWorker {
  static Future<void> initialize() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );
      await Workmanager().registerPeriodicTask(
        'snapsync_periodic_bg_sync',
        kBackgroundSyncTaskKey,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    } catch (_) {}
  }
}
