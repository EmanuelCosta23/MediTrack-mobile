import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/phone_illustration.dart'; // Importando novamente o widget de ilustração
import '../widgets/custom_logo.dart'; // Importando a nova logo personalizada

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
      // Usando um gradiente para o fundo
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF40BFFF), // Azul mais claro embaixo
              Color(0xFF0080FF), // Azul mais escuro no topo
            ],
            stops: [0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Logo e título "MediTrack"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Nova logo redesenhada com cores brancas para destacar
                      const MediTrackLogo(size: 56),
                      const SizedBox(width: 12),

                      // Título com "Medi" em cor diferente
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Medi',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            TextSpan(
                              text: 'Track',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Color(
                                  0xFF0080FF,
                                ), // cor turquesa similar à imagem
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Subtítulo
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Acesse ou crie sua conta para encontrar todos seus remédios!',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Ilustração do telefone - voltando para a versão personalizada
                  Center(child: PhoneIllustration(size: 220)),

                  const SizedBox(height: 40),

                  // Área do formulário com fundo branco semitransparente
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Email TextField
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'Digite seu e-mail',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            labelText: 'Email',
                            labelStyle: const TextStyle(
                              color: Color(0xFF0080FF),
                            ),
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
                            hintText: 'Digite sua senha',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            labelText: 'Senha',
                            labelStyle: const TextStyle(
                              color: Color(0xFF0080FF),
                            ),
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

                        // Esqueci a senha (alinhado à direita)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/forgot-password');
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Esqueci minha senha'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Login Button
                  isLoading
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                      : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Color(
                            0xFF4CD2DC,
                          ), // mesma cor do "Track"
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          elevation: 3,
                          shadowColor: Colors.black.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Acessar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                  const SizedBox(height: 15),

                  // Link para cadastro
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cadastre sua conta'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
