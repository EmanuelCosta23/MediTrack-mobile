import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  // Strings para mensagens de erro
  String? _emailError;
  String? _senhaError;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // Método para limpar os erros quando os campos são alterados
  void _limparErros() {
    setState(() {
      _emailError = null;
      _senhaError = null;
    });
  }

  Future<void> _login() async {
    // Limpar mensagens de erro anteriores
    _limparErros();

    // Validações básicas
    bool camposPreenchidos = true;

    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = 'Preencha este campo';
      });
      camposPreenchidos = false;
    }

    if (_senhaController.text.isEmpty) {
      setState(() {
        _senhaError = 'Preencha este campo';
      });
      camposPreenchidos = false;
    }

    if (!camposPreenchidos) {
      return;
    }

    try {
      // Acessar o serviço de autenticação
      final authService = Provider.of<AuthService>(context, listen: false);

      // Realizar login
      await authService.login(_emailController.text, _senhaController.text);

      if (!mounted) return;

      // Se chegou aqui, o login foi bem-sucedido
      // Navegar para a tela inicial
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;

      // Mostrar erro nos campos em vez do SnackBar
      setState(() {
        _emailError = 'Usuário ou senha incorretos';
        _senhaError = 'Usuário ou senha incorretos';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verificar se o serviço de autenticação está carregando
    final authService = Provider.of<AuthService>(context);
    final bool isLoading = authService.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF0080FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // App Title
                const Text(
                  'MediTrack',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Email TextField
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Color(0xFF0080FF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.email,
                      color: Color(0xFF0080FF),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                    errorText: _emailError,
                    errorStyle: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => _limparErros(),
                ),
                const SizedBox(height: 15),

                // Password TextField
                TextField(
                  controller: _senhaController,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    labelStyle: const TextStyle(color: Color(0xFF0080FF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock,
                      color: Color(0xFF0080FF),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                    errorText: _senhaError,
                    errorStyle: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  obscureText: true,
                  onChanged: (_) => _limparErros(),
                ),
                const SizedBox(height: 10),

                // Forgot Password and Sign Up Links Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Forgot Password Link (Left Aligned)
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgot-password');
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Esqueci a senha'),
                    ),

                    // Sign Up Link (Right Aligned)
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cadastre-se'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Login Button
                isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                    : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: const Color(0xFF0080FF),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
