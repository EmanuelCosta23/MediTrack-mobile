import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'custom_logo.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF40BFFF)),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const MediTrackLogo(size: 60),
                  const SizedBox(height: 12),
                  const Text(
                    'MediTrack',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Home'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.local_hospital),
                  title: const Text('Postos'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/postos');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.medication),
                  title: const Text('Remédios'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/remedios');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.vaccines),
                  title: const Text('Vacinas'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/vacinas');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.map),
                  title: const Text('Mapas'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/mapa');
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                // Fazer logout utilizando o AuthService
                final authService = Provider.of<AuthService>(
                  context,
                  listen: false,
                );
                await authService.logout();

                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ),
        ],
      ),
    );
  }
}
