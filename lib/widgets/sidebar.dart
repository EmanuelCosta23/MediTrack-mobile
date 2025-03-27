import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF0080FF)),
            child: const Center(
              child: Text(
                'MediTrack',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
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
                    // Navegação futura
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.medication),
                  title: const Text('Remédios'),
                  onTap: () {
                    Navigator.pop(context);
                    // Navegação futura
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.vaccines),
                  title: const Text('Vacinas'),
                  onTap: () {
                    Navigator.pop(context);
                    // Navegação futura
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.map),
                  title: const Text('Mapas'),
                  onTap: () {
                    Navigator.pop(context);
                    // Navegação futura para mapas
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
              onTap: () {
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
