import 'package:flutter/material.dart';
import 'package:appranti_360/pages/appranti360PosteInformatique.dart';
import 'package:appranti_360/pages/appranti360Camera.dart';
import 'package:appranti_360/utils.dart';

final class Appranti360HomePage extends StatefulWidget {
  final Config config;

  const Appranti360HomePage({super.key, required this.title, required this.scaffoldMessengerKey, required this.config});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  @override
  State<Appranti360HomePage> createState() => _Appranti360HomePageState(config: config);
}

final class _Appranti360HomePageState extends State<Appranti360HomePage> {
  final Config config;
  var selectedIndex = 0; // Index de la page sélectionnée
  _Appranti360HomePageState({required this.config});
  // visibilité de la NavigationRail
  bool _isRailVisible = true;

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    var colorScheme = Theme.of(context).colorScheme;
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = Appranti360CameraPage();
        break;
      case 1:
        page = Appranti360PosteInformatiquePage(config: config,);
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    // The container for the current page, with its background color and subtle switching animation.
    var mainArea = ColoredBox(
      color: colorScheme.surfaceVariant,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: page,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        // title: Text(widget.title),
        actions: [
          Text(widget.title,  style: const TextStyle(
            fontSize: 20.0, // Set your desired font size
            fontWeight: FontWeight.bold, // Set your desired font weight
            fontFamily: 'system-ui', // Set your desired font family
            // You can also set other text style properties here
          ),),
          IconButton(
            icon: _isRailVisible ? Icon(Icons.fullscreen) : Icon(Icons.fullscreen_exit_sharp),
            onPressed: () {
              setState(() {
                if (_isRailVisible) {
                  _isRailVisible = false;
                } else {
                  _isRailVisible = true;
                }
              });
            },
          ),
          Spacer(), // Adds space to the right of the button
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 450) {
            // Use a more mobile-friendly layout with BottomNavigationBar on narrow screens.
            return Column(
              children: [
                Expanded(child: mainArea),
                SafeArea(
                  child: Visibility(
                    visible: _isRailVisible,
                    child: BottomNavigationBar(
                    items: [
                      BottomNavigationBarItem(
                          icon: const Icon(Icons.camera_alt_sharp),
                          label: 'Appranti-360 - Caméra',
                          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                          tooltip: ''),
                      BottomNavigationBarItem(
                          icon: const Icon(Icons.file_copy_outlined),
                          label: 'Appranti-360 - Fichier',
                          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                          tooltip: ''),
                    ],
                    currentIndex: selectedIndex,
                    onTap: (value) {
                      setState(() {
                        selectedIndex = value;
                      });
                    },
                  ),
                ),),
              ],
            );
          } else {
            return Row(
              children: [
                SafeArea(
                  child: Visibility(
                    visible: _isRailVisible,
                    child: NavigationRail(
                    extended: constraints.maxWidth >= 600,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.camera_alt_sharp),
                        label: Text('Appranti-360 - Caméra'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.file_copy_outlined),
                        label: Text('Appranti-360 - Fichier'),
                      ),
                    ],
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (value) {
                      setState(() {
                        selectedIndex = value;
                      });
                    },
                  ),
                ),),
                Expanded(child: mainArea),
              ],
            );
          }
        },
      ),
    );
  }
}
