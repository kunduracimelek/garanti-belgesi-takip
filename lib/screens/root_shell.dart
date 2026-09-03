import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'warranties/warranties_screen.dart';
import 'settings/settings_screen.dart';

/// Uygulamanın kök gezinme iskeleti.
/// Not: Orijinal tasarımdaki "Dolap" (gıda/SKT takibi) sekmesi, gıda son
/// kullanma tarihi takibi kaldırıldığı için buradan çıkarılmıştır.
/// Uygulama artık yalnızca ürün garantilerine odaklanır.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    WarrantiesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Ana Sayfa'),
          NavigationDestination(icon: Icon(Icons.verified_user_outlined), selectedIcon: Icon(Icons.verified_user_rounded), label: 'Garantiler'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Ayarlar'),
        ],
      ),
    );
  }
}
