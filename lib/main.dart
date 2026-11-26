import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/gaiji_repository.dart';
import 'screens/home_shell.dart';
import 'state/gaiji_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = GaijiRepository();
  await repository.init();

  // 配色（ステータスバー）
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(GaijiApp(repository: repository));
}

class GaijiApp extends StatelessWidget {
  const GaijiApp({super.key, required this.repository});

  final GaijiRepository repository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GaijiProvider(repository)..load(),
      child: MaterialApp(
        title: '古字アルバム',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('ja', 'JP'),
        supportedLocales: const [Locale('ja', 'JP'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          // 端末の文字サイズを尊重しつつ、極端な拡大は抑制
          final mq = MediaQuery.of(context);
          final scale = mq.textScaler.clamp(
            minScaleFactor: 0.9,
            maxScaleFactor: 1.3,
          );
          return MediaQuery(
            data: mq.copyWith(textScaler: scale),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const HomeShell(),
      ),
    );
  }
}
