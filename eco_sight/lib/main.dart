import 'package:eco_sight/screens/providers/clima_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


import 'screens/dashboard_screen.dart';
import 'screens/clima_screen.dart';
import 'screens/mapa_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Carrega o .env (não falha se faltar, mas loga)
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ClimaProvider>(create: (_) => ClimaProvider()),
      ],
      child: const EcoWatchApp(),
    ),
  );
}

class EcoWatchApp extends StatefulWidget {
  const EcoWatchApp({super.key});

  @override
  State<EcoWatchApp> createState() => _EcoWatchAppState();
}

class _EcoWatchAppState extends State<EcoWatchApp> {
  int _index = 0;

  // REMOVA const nas telas que dependem de Provider para evitar caching agressivo
  final List<Widget> _screens = [
    const DashboardScreen(),
    const ClimaScreen(),
    const MapaScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "EcoWatch",
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF168600),
      ),
      home: Scaffold(
        body: _screens[_index],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
            BottomNavigationBarItem(icon: Icon(Icons.cloud), label: "Clima"),
            BottomNavigationBarItem(icon: Icon(Icons.map), label: "Mapa"),
          ],
        ),
      ),
    );
  }
}
