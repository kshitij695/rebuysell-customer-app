import 'package:flutter/material.dart';
import 'screens/main_nav_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ReBuySellApp());
}

class ReBuySellApp extends StatelessWidget {
  const ReBuySellApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReBuySell',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const MainNavScreen(),
    );
  }
}
