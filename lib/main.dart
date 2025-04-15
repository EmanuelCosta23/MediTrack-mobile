import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/vacina_screen.dart';
import 'screens/remedio_screen.dart';
import 'services/auth_service.dart';
import 'services/route_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar o serviço de autenticação
  final authService = AuthService();
  await authService.initialize();

  runApp(
    ChangeNotifierProvider.value(value: authService, child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Definir as rotas do aplicativo
    final Map<String, WidgetBuilder> appRoutes = {
      '/login': (context) => const LoginScreen(),
      '/signup': (context) => const SignUpScreen(),
      '/forgot-password': (context) => const ForgotPasswordScreen(),
      '/home': (context) => const HomeScreen(),
      '/vacinas': (context) => const VacinaScreen(),
      '/remedios': (context) => const RemedioScreen(),
    };

    return MaterialApp(
      title: 'MediTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0080FF),
          primary: const Color(0xFF0080FF),
        ),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: const Color(0xFF0080FF),
            backgroundColor: Colors.white,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF0080FF)),
        ),
      ),
      // Configurar o gerenciador de rotas para verificar autenticação
      initialRoute:
          Provider.of<AuthService>(context).isAuthenticated
              ? '/home'
              : '/login',
      onGenerateRoute:
          (settings) =>
              RouteGuard.onGenerateRoute(settings, appRoutes, context),
    );
  }
}
