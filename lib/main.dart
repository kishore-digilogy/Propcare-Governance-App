import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/property/presentation/bloc/property_bloc.dart';
import 'injection_container.dart' as di;

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Keep native splash visible until app is ready
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialise DI + Hive
  await di.initDependencies();

  // Remove native splash — our animated splash page takes over
  FlutterNativeSplash.remove();

  runApp(const PropCareApp());
}

class PropCareApp extends StatelessWidget {
  const PropCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => di.sl<AuthBloc>()),
        BlocProvider<PropertyBloc>(create: (_) => di.sl<PropertyBloc>()),
      ],
      child: MaterialApp.router(
        title: 'PropCare Governance',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: appRouter,
      ),
    );
  }
}
