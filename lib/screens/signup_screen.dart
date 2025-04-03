import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController =
      TextEditingController();
  final TextEditingController _dataNascimentoController =
      TextEditingController();

  // Vamos criar controladores para a visualização formatada
  final TextEditingController _cpfVisualController = TextEditingController();
  final TextEditingController _dataVisualController = TextEditingController();

  // Variáveis para armazenar os erros
  String? _nomeError;
  String? _cpfError;
  String? _emailError;
  String? _senhaError;
  String? _confirmarSenhaError;
  String? _dataNascimentoError;

  // Verificar se as senhas coincidem
  bool _senhasCoincidentes = true;

  @override
  void initState() {
    super.initState();
    // Adicionar listener para verificar senhas em tempo real
    _senhaController.addListener(_verificarSenhas);
    _confirmarSenhaController.addListener(_verificarSenhas);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _dataNascimentoController.dispose();
    _cpfVisualController.dispose();
    _dataVisualController.dispose();
    super.dispose();
  }

  // Método para verificar se as senhas coincidem
  void _verificarSenhas() {
    if (_confirmarSenhaController.text.isEmpty) {
      setState(() {
        _senhasCoincidentes = true;
        _confirmarSenhaError = null;
      });
      return;
    }

    setState(() {
      final senhasIguais =
          _senhaController.text == _confirmarSenhaController.text;
      _senhasCoincidentes = senhasIguais;
      _confirmarSenhaError = senhasIguais ? null : 'As senhas não coincidem';
    });
  }

  // Método para limpar erros de um campo específico
  void _limparErro(String campo) {
    setState(() {
      switch (campo) {
        case 'nome':
          _nomeError = null;
          break;
        case 'cpf':
          _cpfError = null;
          break;
        case 'email':
          _emailError = null;
          break;
        case 'senha':
          _senhaError = null;
          break;
        case 'dataNascimento':
          _dataNascimentoError = null;
          break;
      }
    });
  }

  // Função para formatar o CPF visualmente
  void _formatarCPF(String value) {
    // Remove todos os caracteres não numéricos
    String cpfNumerico = value.replaceAll(RegExp(r'[^\d]'), '');

    // Limita a 11 dígitos
    if (cpfNumerico.length > 11) {
      cpfNumerico = cpfNumerico.substring(0, 11);
    }

    // Formata o CPF com pontos e traço
    String cpfFormatado = cpfNumerico;
    if (cpfNumerico.length > 3) {
      cpfFormatado =
          '${cpfNumerico.substring(0, 3)}.${cpfNumerico.substring(3)}';
    }
    if (cpfNumerico.length > 6) {
      cpfFormatado =
          '${cpfFormatado.substring(0, 7)}.${cpfNumerico.substring(6)}';
    }
    if (cpfNumerico.length > 9) {
      cpfFormatado =
          '${cpfFormatado.substring(0, 11)}-${cpfNumerico.substring(9)}';
    }

    // Atualiza o controller visual com o texto formatado
    _cpfVisualController.value = TextEditingValue(
      text: cpfFormatado,
      selection: TextSelection.fromPosition(
        TextPosition(offset: cpfFormatado.length),
      ),
    );

    // Mantém apenas os números no controller real
    _cpfController.text = cpfNumerico;

    // Limpar erro do CPF quando o usuário começar a digitar
    _limparErro('cpf');
  }

  // Função para formatar a data de nascimento visualmente
  void _formatarData(String value) {
    // Remove todos os caracteres não numéricos
    String dataNumerico = value.replaceAll(RegExp(r'[^\d]'), '');

    // Limita a 8 dígitos
    if (dataNumerico.length > 8) {
      dataNumerico = dataNumerico.substring(0, 8);
    }

    // Formata a data com barras
    String dataFormatada = dataNumerico;
    if (dataNumerico.length > 2) {
      dataFormatada =
          '${dataNumerico.substring(0, 2)}/${dataNumerico.substring(2)}';
    }
    if (dataNumerico.length > 4) {
      dataFormatada =
          '${dataFormatada.substring(0, 5)}/${dataNumerico.substring(4)}';
    }

    // Atualiza o controller visual
    _dataVisualController.value = TextEditingValue(
      text: dataFormatada,
      selection: TextSelection.fromPosition(
        TextPosition(offset: dataFormatada.length),
      ),
    );

    // Mantém apenas os números no controller real
    _dataNascimentoController.text = dataNumerico;

    // Limpar erro da data quando o usuário começar a digitar
    _limparErro('dataNascimento');
  }

  void _cadastrarUsuario() async {
    // Validações básicas - Limpar erros anteriores
    setState(() {
      _nomeError = null;
      _cpfError = null;
      _emailError = null;
      _senhaError = null;
      _dataNascimentoError = null;
    });

    bool formValido = true;

    // Verificar nome
    if (_nomeController.text.isEmpty) {
      setState(() {
        _nomeError = 'Preencha o nome completo';
      });
      formValido = false;
    }

    // Verificar CPF
    if (_cpfController.text.isEmpty) {
      setState(() {
        _cpfError = 'Preencha o CPF';
      });
      formValido = false;
    } else if (_cpfController.text.length != 11) {
      setState(() {
        _cpfError = 'CPF deve conter 11 dígitos';
      });
      formValido = false;
    }

    // Verificar email
    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = 'Preencha o email';
      });
      formValido = false;
    } else if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(_emailController.text)) {
      setState(() {
        _emailError = 'Email inválido';
      });
      formValido = false;
    }

    // Verificar senha
    if (_senhaController.text.isEmpty) {
      setState(() {
        _senhaError = 'Preencha a senha';
      });
      formValido = false;
    } else if (_senhaController.text.length < 6) {
      setState(() {
        _senhaError = 'A senha deve ter pelo menos 6 caracteres';
      });
      formValido = false;
    }

    // Verificar confirmar senha
    if (_confirmarSenhaController.text.isEmpty) {
      setState(() {
        _confirmarSenhaError = 'Confirme sua senha';
      });
      formValido = false;
    } else if (!_senhasCoincidentes) {
      formValido = false;
      // O erro já está definido no método _verificarSenhas
    }

    // Verificar data de nascimento
    if (_dataNascimentoController.text.isEmpty) {
      setState(() {
        _dataNascimentoError = 'Preencha a data de nascimento';
      });
      formValido = false;
    } else if (_dataNascimentoController.text.length != 8) {
      setState(() {
        _dataNascimentoError = 'Data de nascimento inválida';
      });
      formValido = false;
    }

    if (!formValido) {
      return;
    }

    // Formatar a data no formato ISO para a API
    final String dia = _dataNascimentoController.text.substring(0, 2);
    final String mes = _dataNascimentoController.text.substring(2, 4);
    final String ano = _dataNascimentoController.text.substring(4);
    final String dataNascimento = '$ano-$mes-${dia}T00:00:00.000Z';

    // Mostrando um indicador de carregamento
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // Chamar o serviço de API para cadastrar o usuário
      final resposta = await ApiService.cadastrarUsuario(
        nomeCompleto: _nomeController.text,
        cpf: _cpfController.text, // Apenas números, sem formatação
        email: _emailController.text,
        senha: _senhaController.text,
        dataNascimento: dataNascimento,
      );

      // Fechar o diálogo de carregamento
      Navigator.of(context).pop();

      // Mostrar diálogo de sucesso
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible:
            false, // Impede que o diálogo seja fechado ao clicar fora
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Cadastro Realizado com Sucesso',
              style: TextStyle(
                color: Color(0xFF0080FF),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Usuário cadastrado com sucesso!',
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () {
                    // Fechar o diálogo e voltar para a tela de login
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // Volta para a tela de login
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Color(0xFF0080FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Fechar o diálogo de carregamento
      Navigator.of(context).pop();

      // Exibir mensagem de erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao cadastrar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0080FF),
      appBar: AppBar(
        title: const Text('Cadastro'),
        backgroundColor: const Color(0xFF0080FF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
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
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Crie sua conta',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Full Name TextField
                TextField(
                  controller: _nomeController,
                  decoration: InputDecoration(
                    labelText: 'Nome Completo',
                    labelStyle: const TextStyle(color: Color(0xFF0080FF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.person,
                      color: Color(0xFF0080FF),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                    errorText: _nomeError,
                    errorStyle: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  keyboardType: TextInputType.name,
                  onChanged: (_) => _limparErro('nome'),
                ),
                const SizedBox(height: 15),

                // CPF TextField - Usando o controller visual para exibição formatada
                TextField(
                  controller: _cpfVisualController,
                  decoration: InputDecoration(
                    labelText: 'CPF',
                    labelStyle: const TextStyle(color: Color(0xFF0080FF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.badge,
                      color: Color(0xFF0080FF),
                    ),
                    hintText: '000.000.000-00',
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                    errorText: _cpfError,
                    errorStyle: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: _formatarCPF,
                ),
                const SizedBox(height: 15),

                // Data de Nascimento TextField - Usando o controller visual
                TextField(
                  controller: _dataVisualController,
                  decoration: InputDecoration(
                    labelText: 'Data de Nascimento',
                    labelStyle: const TextStyle(color: Color(0xFF0080FF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF0080FF),
                    ),
                    hintText: 'DD/MM/AAAA',
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                    errorText: _dataNascimentoError,
                    errorStyle: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: _formatarData,
                ),
                const SizedBox(height: 15),

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
                  onChanged: (_) => _limparErro('email'),
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
                  onChanged: (_) => _limparErro('senha'),
                ),
                const SizedBox(height: 15),

                // Confirm Password TextField
                TextField(
                  controller: _confirmarSenhaController,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Senha',
                    labelStyle: const TextStyle(color: Color(0xFF0080FF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF0080FF),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                    errorText: _confirmarSenhaError,
                    errorStyle: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 30),

                // Sign Up Button
                ElevatedButton(
                  onPressed: _cadastrarUsuario,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: const Color(0xFF0080FF),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Cadastrar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),

                // Already have an account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Já possui uma conta?',
                      style: TextStyle(color: Colors.white),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Faça login'),
                    ),
                  ],
                ),
                // Adicionar espaço extra no final para scroll
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
