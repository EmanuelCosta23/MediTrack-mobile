import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class ApiService {
  // URL base da API - ajuste para o IP correto do seu servidor quando estiver rodando localmente
  static const String baseUrl =
      'http://10.0.2.2:8080/api'; // 10.0.2.2 é o IP do localhost para o Android Emulator

  // Método para cadastrar um novo usuário
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
        headers: {'Content-Type': 'application/json', 'Accept': '*/*'},
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
        return jsonDecode(response.body);
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

  // Método para realizar login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuario/login'),
        headers: {'Content-Type': 'application/json', 'Accept': '*/*'},
        body: jsonEncode({'email': email, 'senha': senha}),
      );

      if (response.statusCode == 200) {
        // Se a resposta for bem-sucedida, retorna o token e os dados do usuário
        return jsonDecode(response.body);
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
}
