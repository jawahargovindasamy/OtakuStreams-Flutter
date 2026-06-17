import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'core/api_client.dart';
import 'providers/data_provider.dart';
import 'providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OtakuStreamsApp());
}

class OtakuStreamsApp extends StatefulWidget {
  const OtakuStreamsApp({super.key});

  @override
  State<OtakuStreamsApp> createState() => _OtakuStreamsAppState();
}

class _OtakuStreamsAppState extends State<OtakuStreamsApp> {
  late final ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: _apiClient),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<DataProvider>(
          create: (context) => DataProvider(),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp.router(
            title: 'OtakuStreams',
            themeMode: auth.themeMode,
            darkTheme: AppTheme.darkTheme,
            theme: AppTheme.lightTheme,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
