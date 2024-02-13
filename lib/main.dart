import 'package:flutter/material.dart';
import 'package:appranti_360/pages/home.dart';
import 'package:window_manager/window_manager.dart';
import 'package:appranti_360/utils.dart';
import 'package:flutter/services.dart';


// void main() => runApp(Appranti360App());
void main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  // // Must add this line.
  // await windowManager.ensureInitialized();
  //
  // WindowOptions windowOptions = WindowOptions(
  //   // size: Size(1280, 1024),
  //   center: true,
  //   fullScreen: true,
  //   backgroundColor: Colors.transparent,
  //   skipTaskbar: false,
  //   titleBarStyle: TitleBarStyle.hidden,
  // );
  // windowManager.waitUntilReadyToShow(windowOptions, () async {
  //   await windowManager.show();
  //   await windowManager.focus();
  // });

  try {
    Config config = await readConfig();
    // print('Server address: ${config.serverAddress}');
    runApp(Appranti360App(config: config,));
  } catch (e) {
    print('Error reading config: $e');
    SystemNavigator.pop(); // This will close the application
  }
}

final class Appranti360App extends StatelessWidget {
  final Config config;

  Appranti360App({super.key, required this.config});
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      title: 'Appranti 360 - Civil',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.limeAccent),
        useMaterial3: true,
      ),
      home: Appranti360HomePage(title: 'Appranti 360 - Civil', scaffoldMessengerKey: _scaffoldMessengerKey, config: config),
    );
  }
}

final class Appranti360ApppState extends ChangeNotifier {

}
