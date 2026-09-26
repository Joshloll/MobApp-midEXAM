import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'screens/home_screen.dart';
import 'services/inventory_store.dart';
import 'services/server_settings.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServerSettings.load();
  runApp(DryGoodsApp());
}

class DryGoodsApp extends StatelessWidget {
  DryGoodsApp({super.key, InventoryStore? store})
    : store = store ?? InventoryStore();

  final InventoryStore store;

  @override
  Widget build(BuildContext context) {
    return InventoryScope(
      store: store,
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
