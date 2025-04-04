import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // URL base da API - ajuste para o IP correto do seu servidor quando estiver rodando localmente
  static const String baseUrl =
      'http://10.0.2.2:8080/api'; // 10.0.2.2 é o IP do localhost para o Android Emulator

  // Headers padrão para requisições não autenticadas
  static Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': '*/*',
  };

  // Headers para requisições autenticadas
  static Future<Map<String, String>> get _authHeaders async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('Usuário não autenticado');
    }

    return {
      'Content-Type': 'application/json',
      'Accept': '*/*',
      'Authorization': 'Bearer $token',
    };
  }

  // Método para cadastrar um novo usuário - Não requer autenticação
  static Future<Map<String, dynamic>> cadastrarUsuario({
    required String nomeCompleto,
    required String cpf,
    required String email,
    required String senha,
    required String dataNascimento,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuario/cadastro'),
        headers: _defaultHeaders,
        body: jsonEncode({
          'nomeCompleto': nomeCompleto,
          'cpf': cpf,
          'email': email,
          'senha': senha,
          'dataNascimento': dataNascimento,
        }),
      );

      if (response.statusCode == 200) {
        // Se a resposta for bem-sucedida, retorna os dados do usuário
        final userData = jsonDecode(response.body) as Map<String, dynamic>;
        return userData;
      } else {
        // Se a resposta não for bem-sucedida, lança uma exceção
        throw Exception('Falha ao cadastrar usuário: ${response.body}');
      }
    } catch (e) {
      // Captura qualquer erro durante a requisição
      debugPrint('Erro ao cadastrar usuário: $e');
      throw Exception('Erro ao cadastrar usuário: $e');
    }
  }

  // Método para realizar login - Não requer autenticação
  static Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuario/login'),
        headers: _defaultHeaders,
        body: jsonEncode({'email': email, 'senha': senha}),
      );

      if (response.statusCode == 200) {
        // Se a resposta for bem-sucedida, retorna o token e os dados do usuário
        return jsonDecode(response.body);
      } else if (response.statusCode == 401 &&
          response.body.contains("Email ainda não validado")) {
        // Se o erro for de email não validado, tente fazer login novamente após um pequeno atraso
        // Isso é um workaround para o caso de o email ainda não estar verificado
        await Future.delayed(const Duration(seconds: 1));
        return login(email: email, senha: senha);
      } else {
        // Se a resposta não for bem-sucedida, lança uma exceção
        throw Exception('Falha ao realizar login: ${response.body}');
      }
    } catch (e) {
      // Captura qualquer erro durante a requisição
      debugPrint('Erro ao realizar login: $e');
      throw Exception('Erro ao realizar login: $e');
    }
  }

  // Método para obter dados do usuário - Requer autenticação
  static Future<Map<String, dynamic>> getDadosUsuario() async {
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/usuario'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Falha ao obter dados do usuário: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erro ao obter dados do usuário: $e');
      throw Exception('Erro ao obter dados do usuário: $e');
    }
  }

  // Método para pesquisar medicamentos - Requer autenticação
  static Future<List<dynamic>> pesquisarMedicamentos(String nome) async {
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/medicamento/pesquisar/$nome'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Falha ao pesquisar medicamentos: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erro ao pesquisar medicamentos: $e');
      throw Exception('Erro ao pesquisar medicamentos: $e');
    }
  }

  // Método para obter medicamentos favoritos - Requer autenticação
  static Future<List<dynamic>> getMedicamentosFavoritos() async {
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/medicamento/favoritos'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Falha ao obter medicamentos favoritos: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Erro ao obter medicamentos favoritos: $e');
      throw Exception('Erro ao obter medicamentos favoritos: $e');
    }
  }

  // Método para favoritar/desfavoritar um medicamento - Requer autenticação
  static Future<void> favoritarMedicamento(String medicamentoId) async {
    try {
      final headers = await _authHeaders;
      final response = await http.post(
        Uri.parse('$baseUrl/medicamento/favoritar/$medicamentoId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Falha ao favoritar medicamento: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erro ao favoritar medicamento: $e');
      throw Exception('Erro ao favoritar medicamento: $e');
    }
  }

  // Método para pesquisar postos de saúde - Requer autenticação
  static Future<List<dynamic>> pesquisarPostos(String nome) async {
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/posto/pesquisar/$nome'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Falha ao pesquisar postos: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erro ao pesquisar postos: $e');
      throw Exception('Erro ao pesquisar postos: $e');
    }
  }
}
