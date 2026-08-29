import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/network/mock_network_service.dart';
import 'core/theme/app_theme.dart';
import 'features/camera/presentation/bloc/camera_bloc.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'features/sync/data/datasources/sync_local_datasource.dart';
import 'features/sync/data/repositories/sync_repository_impl.dart';
import 'features/sync/presentation/bloc/sync_bloc.dart';
import 'features/sync/presentation/bloc/sync_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set dark status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize local persistent storage (Hive)
  final localDataSource = SyncLocalDataSource();
  await localDataSource.init();

  // Create Network and Repository instances
  final networkService = MockNetworkService();
  final syncRepository = SyncRepositoryImpl(
    localDataSource: localDataSource,
    networkService: networkService,
  );

  runApp(SnapSyncApp(syncRepository: syncRepository));
}

class SnapSyncApp extends StatelessWidget {
  final SyncRepositoryImpl syncRepository;

  const SnapSyncApp({super.key, required this.syncRepository});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CameraBloc>(
          create: (context) => CameraBloc(),
        ),
        BlocProvider<SyncBloc>(
          create: (context) => SyncBloc(repository: syncRepository)..add(LoadSyncQueueEvent()),
        ),
      ],
      child: MaterialApp(
        title: 'SnapSync Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
