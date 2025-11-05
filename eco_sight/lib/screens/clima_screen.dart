import 'package:eco_sight/screens/providers/clima_provider.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class ClimaScreen extends StatefulWidget {
  const ClimaScreen({super.key});

  @override
  State<ClimaScreen> createState() => _ClimaScreenState();
}

class _ClimaScreenState extends State<ClimaScreen> {
  String status = "Aguardando localização...";

  @override
  void initState() {
    super.initState();
    _buscarLocalizacao();
  }

  Future<void> _buscarLocalizacao() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => status = "Serviço de GPS desativado");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() => status = "Permissão negada permanentemente");
      return;
    }

    final pos = await Geolocator.getCurrentPosition();
    setState(() => status = "Localização encontrada!");

    // chama API via provider
    // ignore: use_build_context_synchronously
    final climaProvider = context.read<ClimaProvider>();
    await climaProvider.carregarClima(pos.latitude, pos.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final climaProvider = context.watch<ClimaProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Clima em Tempo Real")),
      body: Center(
        child: climaProvider.loading
            ? const CircularProgressIndicator()
            : climaProvider.clima == null
                ? Text(status)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${climaProvider.clima!.temperatura.toStringAsFixed(1)}°C",
                        style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        climaProvider.clima!.descricao,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 10),
                      Text("Umidade: ${climaProvider.clima!.umidade}%"),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _buscarLocalizacao,
                        child: const Text("Atualizar"),
                      )
                    ],
                  ),
      ),
    );
  }
}
