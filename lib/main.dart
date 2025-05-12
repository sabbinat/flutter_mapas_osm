import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'viewmodels/location_viewmodel.dart';
import 'views/map_view.dart';

void main() {

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // Hace la barra de estado transparente
    statusBarIconBrightness: Brightness.light, // Para íconos de barra claros si lo prefieres
  ));

  runApp(
    ChangeNotifierProvider(
      create: (_) => LocationViewModel()..fetchLocation(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapa OSM',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: const MapView(),
      ),
    );
  }
}
