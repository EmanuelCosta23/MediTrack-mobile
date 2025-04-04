import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';

class RouteGuard {
  // Rotas públicas que não requerem autenticação
  static const List<String> publicRoutes = [
    '/login',
    '/signup',
    '/forgot-password',
  ];

  // Verificar se uma rota requer autenticação
  static bool requiresAuth(String routeName) {
    return !publicRoutes.contains(routeName);
  }

  // Rota para redirecionamento em caso de não autenticado
  static const String loginRoute = '/login';

  // Função para verificar autenticação e redirecionar se necessário
  static Route<dynamic> onGenerateRoute(
    RouteSettings settings,
    Map<String, WidgetBuilder> routes,
    BuildContext context,
  ) {
    final routeName = settings.name;
    final authService = Provider.of<AuthService>(context, listen: false);

    // Verificar se a rota requer autenticação
    if (routeName != null &&
        requiresAuth(routeName) &&
        !authService.isAuthenticated) {
      // Usuário não autenticado tentando acessar rota protegida
      return MaterialPageRoute(
        builder: routes[loginRoute]!,
        settings: const RouteSettings(name: loginRoute),
      );
    }

    // Rota existe e o usuário tem permissão
    if (routeName != null && routes.containsKey(routeName)) {
      return MaterialPageRoute(builder: routes[routeName]!, settings: settings);
    }

    // Fallback para rota não encontrada
    return MaterialPageRoute(
      builder:
          (context) =>
              const Scaffold(body: Center(child: Text('Rota não encontrada'))),
    );
  }
}
