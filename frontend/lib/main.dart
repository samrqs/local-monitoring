import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';

import 'screens/dashboard_screen.dart';
import 'screens/clima_screen.dart';
import 'screens/mapa_screen.dart';
import 'screens/providers/clima_provider.dart';
import 'screens/providers/mapa_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carregar .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    debugPrint("⚠ .env não encontrado, seguindo sem ele");
  }

  // Tentar obter localização antes de rodar app
  Position? pos;
  try {
    pos = await Geolocator.getCurrentPosition();
  } catch (e) {
    debugPrint("⚠ Falha ao obter localização inicial: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ClimaProvider()
            ..carregarClima(
              pos?.latitude ?? -23.5505,   // fallback São Paulo
              pos?.longitude ?? -46.6333,
            ),
        ),
        ChangeNotifierProvider(create: (_) => MapaProvider()),
      ],
      child: const EcoSightApp(),
    ),
  );
}

class EcoSightApp extends StatefulWidget {
  const EcoSightApp({super.key});

  @override
  State<EcoSightApp> createState() => _EcoSightAppState();
}

class _EcoSightAppState extends State<EcoSightApp> {
  int _index = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    ClimaScreen(),
    MapaScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "EcoSight",
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
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
