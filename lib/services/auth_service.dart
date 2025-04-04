import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService with ChangeNotifier {
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';

  String? _token;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  // Getters
  String? get token => _token;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  // Inicializar o serviço carregando dados do armazenamento local
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userDataString = prefs.getString(_userDataKey);

    if (token != null && userDataString != null) {
      _token = token;
      _userData = jsonDecode(userDataString);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Realizar login
  Future<void> login(String email, String senha) async {
    _isLoading = true;
    notifyListeners();

    try {
      final resposta = await ApiService.login(email: email, senha: senha);

      // Extrair token e dados do usuário
      _token = resposta['token'];
      _userData = resposta['usuario'];

      // Salvar em SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, _token!);
      await prefs.setString(_userDataKey, jsonEncode(_userData));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow; // Propagar o erro para ser tratado na UI
    }
  }

  // Realizar logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    // Limpar dados em memória
    _token = null;
    _userData = null;

    // Limpar dados armazenados
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);

    _isLoading = false;
    notifyListeners();
  }

  // Obter headers para requisições autenticadas
  Map<String, String> get authHeaders {
    return {
      'Content-Type': 'application/json',
      'Accept': '*/*',
      'Authorization': 'Bearer $_token',
    };
  }
}
