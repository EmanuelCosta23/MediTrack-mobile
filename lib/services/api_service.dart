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

      // Se o nome for muito curto, use um endpoint para listar todos
      // ou um termo genérico "a" que normalmente retorna muitos resultados
      String searchTerm = nome.isEmpty || nome.length < 2 ? "a" : nome;

      final String url = '$baseUrl/medicamento/pesquisar/$searchTerm';
      debugPrint('Buscando medicamentos: $url');

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> result = jsonDecode(response.body);
        return corrigirEncodingJson(result);
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

  // Método para buscar postos próximos baseado na localização do usuário
  static Future<List<dynamic>> getPostosProximos(
    double latitude,
    double longitude, [
    double raio = 10.0,
  ]) async {
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse(
          '$baseUrl/posto/proximos?latitude=$latitude&longitude=$longitude&raio=$raio',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Falha ao buscar postos próximos: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erro ao buscar postos próximos: $e');
      throw Exception('Erro ao buscar postos próximos: $e');
    }
  }

  // Método para buscar posto por ID - Requer autenticação
  static Future<Map<String, dynamic>> getPostoById(String id) async {
    debugPrint('Buscando posto com ID: "$id"');

    if (id == null || id.isEmpty) {
      debugPrint('Erro ao buscar posto: ID vazio ou nulo');
      throw Exception('ID do posto vazio ou nulo');
    }

    try {
      // Primero tentamos buscar normalmente pelo ID
      final response = await http.get(
        Uri.parse('$baseUrl/posto/$id'),
        headers: await _authHeaders,
      );

      if (response.statusCode == 200) {
        final posto = jsonDecode(response.body);
        debugPrint('Posto encontrado com sucesso por ID: ${posto['nome']}');
        return posto;
      }

      // Se não encontrar pelo ID, pode ser que o nome do posto tenha sido passado como ID
      debugPrint(
        'Posto não encontrado pelo ID. Tentando buscar pelo nome: $id',
      );
      return await _buscarPostoPorNome(id);
    } catch (e) {
      debugPrint('Erro ao buscar posto: $e');

      // Tenta buscar o posto pelo nome se falhar a busca por ID
      return await _buscarPostoPorNome(id);
    }
  }

  // Método auxiliar para buscar posto por nome
  static Future<Map<String, dynamic>> _buscarPostoPorNome(
    String nomeOuIdentificador,
  ) async {
    debugPrint(
      'Tentando buscar posto pelo nome/identificador: $nomeOuIdentificador',
    );

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posto/pesquisar/$nomeOuIdentificador'),
        headers: await _authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> postos = jsonDecode(response.body);

        // Procura por um posto que corresponda ao nome
        for (var posto in postos) {
          String nomePosto = posto['nome'] ?? '';

          // Compara ignorando maiúsculas/minúsculas e espaços extras
          if (nomePosto.trim().toLowerCase() ==
                  nomeOuIdentificador.trim().toLowerCase() ||
              nomePosto.trim().toLowerCase().contains(
                nomeOuIdentificador.trim().toLowerCase(),
              )) {
            debugPrint('Posto encontrado pelo nome: ${posto['nome']}');
            return posto;
          }
        }

        throw Exception(
          'Nenhum posto encontrado com o nome: $nomeOuIdentificador',
        );
      } else {
        debugPrint('Erro ao buscar postos: ${response.statusCode}');
        throw Exception('Erro ao buscar posto pelo nome');
      }
    } catch (e) {
      debugPrint('Erro ao buscar posto pelo nome: $e');
      throw Exception(
        'Não foi possível encontrar o posto: $nomeOuIdentificador',
      );
    }
  }

  // Método para buscar medicamentos de um posto - Requer autenticação
  static Future<List<dynamic>> pesquisarMedicamentosEmPosto(
    String idPosto, [
    String? termoPesquisa,
  ]) async {
    try {
      final headers = await _authHeaders;
      String url;

      if (termoPesquisa != null && termoPesquisa.length >= 2) {
        // Buscar medicamentos pelo nome
        url = '$baseUrl/medicamento/pesquisar/$termoPesquisa';
      } else {
        // Buscar todos os medicamentos do posto
        url = '$baseUrl/posto/$idPosto';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Se estiver buscando detalhes do posto, extrair a lista de medicamentos
        if (termoPesquisa == null || termoPesquisa.isEmpty) {
          final dados = corrigirEncodingJson(responseData);
          return dados['medicamentos'] ?? [];
        }
        return corrigirEncodingJson(responseData);
      } else {
        throw Exception(
          'Falha ao pesquisar medicamentos no posto: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Erro ao pesquisar medicamentos no posto: $e');
      throw Exception('Erro ao pesquisar medicamentos no posto: $e');
    }
  }

  // Método para obter detalhes completos do posto - Requer autenticação
  static Future<Map<String, dynamic>> getPostoDetalhes(String id) async {
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/posto/pesquisar/detalhes/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> resultados = corrigirEncodingJson(
          jsonDecode(response.body),
        );
        if (resultados.isNotEmpty) {
          return resultados[0];
        } else {
          throw Exception('Nenhum detalhe encontrado para o posto');
        }
      } else {
        // Tente usar a API de pesquisa por nome como fallback
        return await _getPostoDetalhesViaPesquisa(id);
      }
    } catch (e) {
      debugPrint('Erro ao buscar detalhes do posto: $e');
      // Tente usar a API de pesquisa como fallback
      return await _getPostoDetalhesViaPesquisa(id);
    }
  }

  // Método auxiliar para buscar detalhes por pesquisa
  static Future<Map<String, dynamic>> _getPostoDetalhesViaPesquisa(
    String id,
  ) async {
    try {
      // Primeiro obter o nome do posto pelo ID
      final posto = await getPostoById(id);
      final nomePosto = posto['nome'] as String;

      // Usar o nome para pesquisar
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/posto/pesquisar/${Uri.encodeComponent(nomePosto)}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> resultados = corrigirEncodingJson(
          jsonDecode(response.body),
        );
        if (resultados.isNotEmpty) {
          // Encontre o posto com o ID correspondente
          for (final detalhe in resultados) {
            if (detalhe['id'] == id) {
              return detalhe;
            }
          }
          // Se não encontrar o ID exato, retorne o primeiro resultado
          return resultados[0];
        }
      }

      // Se todas as tentativas falharem, retorne o objeto original
      return posto;
    } catch (e) {
      debugPrint('Erro ao buscar detalhes do posto via pesquisa: $e');
      throw e;
    }
  }

  // Método para obter detalhes de um medicamento específico pelo ID
  static Future<Map<String, dynamic>> getMedicamentoById(String id) async {
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/medicamento/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Aplicar correção de encoding
        return corrigirEncodingJson(responseData);
      } else {
        throw Exception('Falha ao buscar medicamento: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erro ao buscar medicamento: $e');
      throw Exception('Erro ao buscar medicamento: $e');
    }
  }

  // Método para corrigir problemas de encoding em texto
  static String corrigirEncoding(String texto) {
    if (texto.isEmpty) return texto;

    try {
      // 1. Corrigir casos específicos conhecidos primeiro
      String resultado = texto
          .replaceAll('SÍDIO', 'SÓDIO')
          .replaceAll('POTÍSSICA', 'POTÁSSICA')
          .replaceAll('CISTEÇNA', 'CISTEÍNA');

      // 2. Tentar uma abordagem mais fundamental: decodificar texto UTF-8 que foi interpretado como Latin1
      try {
        // Esta é a solução mais correta para o problema de encoding:
        // 1. Converter o texto para bytes considerando-o como Latin1 (ISO-8859-1)
        // 2. Reinterpretar esses bytes como UTF-8
        // Isso reverte o problema de um texto UTF-8 que foi interpretado incorretamente como Latin1

        // Obter bytes como Latin1
        List<int> bytes = [];
        for (int i = 0; i < resultado.length; i++) {
          // Somente caracteres que podem estar em Latin1 (até 0xFF)
          if (resultado.codeUnitAt(i) <= 0xFF) {
            bytes.add(resultado.codeUnitAt(i));
          } else {
            // Para caracteres Unicode maiores, mantemos como estão
            // convertendo de volta para bytes UTF-8
            bytes.addAll(resultado[i].codeUnits);
          }
        }

        // Reinterpretar como UTF-8
        String corrigido = utf8.decode(bytes, allowMalformed: true);

        // Se a correção parece ter funcionado (tem menos caracteres estranhos), usar ela
        if (_qualidadeEncoding(corrigido) > _qualidadeEncoding(resultado)) {
          resultado = corrigido;
        }
      } catch (e) {
        // Se falhar a abordagem de bytes, continuar com a abordagem de substituição
        debugPrint(
          'Erro na correção de bytes: $e - continuando com substituições',
        );
      }

      // 3. Aplicar o mapeamento de substituições como fallback
      final Map<String, String> mapaCaracteres = {
        'Ã‰': 'É', // É
        'Ã©': 'é', // é
        'Ã‡': 'Ç', // Ç
        'Ã§': 'ç', // ç
        'Ã"': 'Ó', // Ó
        'Ã³': 'ó', // ó
        'Ãš': 'Ú', // Ú
        'Ãº': 'ú', // ú
        'Ã': 'Á', // Á
        'Ã¡': 'á', // á
        'Ã‚': 'Â', // Â
        'Ã¢': 'â', // â
        'Ãƒ': 'Ã', // Ã
        'Ã£': 'ã', // ã
        'ÃŠ': 'Ê', // Ê
        'Ãª': 'ê', // ê
        'Ã': 'Í', // Í
        'Ã­': 'í', // í
        'Ã"': 'Ô', // Ô
        'Ã´': 'ô', // ô
        'Ã•': 'Õ', // Õ
        'Ãµ': 'õ', // õ
        'Ã"': 'Ó', // Correção para Ó em casos como "SÓDIO"
        'Ãƒ': 'Ã', // Ã
      };

      mapaCaracteres.forEach((errado, correto) {
        resultado = resultado.replaceAll(errado, correto);
      });

      return resultado;
    } catch (e) {
      debugPrint('Erro ao corrigir encoding: $e');
      return texto;
    }
  }

  // Avalia a qualidade do encoding do texto
  static double _qualidadeEncoding(String texto) {
    // Caracteres que provavelmente não deveriam estar em um texto em português
    final caracteresEstranhos = RegExp(
      r'[Ã|Â|Æ|â|Ä|Œ|Å|š|ƒ|¢|£|¥|©|ª|®|¿|¬|»|«|‹|›|¯|¼|½|¾|Ÿ]',
    );

    // Caracteres que deveriam estar em um texto em português corretamente codificado
    final caracteresEsperados = RegExp(r'[áàâãéêíóôõúçÁÀÂÃÉÊÍÓÔÕÚÇ]');

    // Contar ocorrências
    int countEstranhos =
        RegExp(caracteresEstranhos.pattern).allMatches(texto).length;
    int countEsperados =
        RegExp(caracteresEsperados.pattern).allMatches(texto).length;

    // Quanto mais caracteres esperados e menos estranhos, melhor
    return countEsperados - countEstranhos * 1.5;
  }

  // Método para corrigir encoding em objetos JSON
  static dynamic corrigirEncodingJson(dynamic json) {
    if (json is String) {
      return corrigirEncoding(json);
    } else if (json is Map) {
      final Map<String, dynamic> novoMap = {};
      json.forEach((key, value) {
        novoMap[key] = corrigirEncodingJson(value);
      });
      return novoMap;
    } else if (json is List) {
      return json.map((item) => corrigirEncodingJson(item)).toList();
    }
    return json;
  }

  // Método para buscar postos que têm um medicamento específico disponível
  static Future<List<dynamic>> getPostosComMedicamentoDisponivel(
    String medicamentoId,
  ) async {
    try {
      final headers = await _authHeaders;

      // Log para depuração
      debugPrint('Buscando postos com medicamento ID: $medicamentoId');

      // Primeiro, vamos tentar buscar os detalhes do medicamento para confirmar que ele existe
      final medicamento = await getMedicamentoById(medicamentoId);
      debugPrint(
        'Medicamento encontrado: ${medicamento['nomeMedicamento'] ?? medicamento['produto']}',
      );

      // Verificar se o medicamento já tem informações de postos embutidas
      if (medicamento['postos'] != null && medicamento['postos'] is List) {
        final List<dynamic> postosDiretos = medicamento['postos'];
        debugPrint(
          'Postos encontrados diretamente no medicamento: ${postosDiretos.length}',
        );

        // Adicionar o ID do posto se estiver faltando
        for (var i = 0; i < postosDiretos.length; i++) {
          final posto = postosDiretos[i];
          // Se o posto não tem ID mas tem nome, fazer uma consulta auxiliar
          if ((posto['id'] == null || posto['id'].toString().isEmpty) &&
              (posto['nome'] != null || posto['nomePosto'] != null)) {
            final nomePosto = posto['nomePosto'] ?? posto['nome'];
            debugPrint('Posto sem ID, tentando buscar ID para: $nomePosto');
            try {
              // Buscar informações completas do posto pelo nome
              final postoCompleto = await _buscarIdPostoPorNome(nomePosto);
              // Adicionar o ID encontrado ao objeto original
              postosDiretos[i]['id'] = postoCompleto['id'];
              debugPrint(
                'ID encontrado para $nomePosto: ${postoCompleto['id']}',
              );
            } catch (e) {
              debugPrint(
                'Não foi possível encontrar ID para posto: $nomePosto',
              );
            }
          }
        }
        return postosDiretos;
      }

      // Se não encontrou postos na estrutura do medicamento, usar endpoint específico
      final response = await http.get(
        Uri.parse('$baseUrl/posto/com-medicamento/$medicamentoId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> postos = jsonDecode(response.body);
        debugPrint('Postos retornados pela API: ${postos.length}');

        // Verifica se os 'postos' já vêm filtrados da API ou se é necessário filtrar
        // Se o medicamento estiver na lista 'postos' do objeto raiz, vamos usar diretamente
        if (postos.isNotEmpty && postos[0]['postos'] != null) {
          List<dynamic> postosComMedicamento = postos[0]['postos'];
          debugPrint(
            'Postos já filtrados pela API: ${postosComMedicamento.length}',
          );
          return postosComMedicamento;
        }

        // Filtrar apenas os postos onde o medicamento está disponível
        final postosDisponiveis =
            postos.where((posto) {
              // Caso 1: se o JSON já contém a quantidade de estoque na raiz
              if (posto['quantidadeEstoque'] != null &&
                  posto['quantidadeEstoque'] > 0) {
                return true;
              }

              // Caso 2: Verificar na lista de medicamentos do posto
              final medicamentos = posto['medicamentos'] as List?;
              if (medicamentos == null || medicamentos.isEmpty) return false;

              for (final med in medicamentos) {
                if ((med['medicamentoId'] == medicamentoId ||
                        med['id'] == medicamentoId) &&
                    (med['quantidadeEstoque'] != null &&
                        med['quantidadeEstoque'] > 0)) {
                  return true;
                }
              }
              return false;
            }).toList();

        debugPrint(
          'Postos filtrados com medicamento disponível: ${postosDisponiveis.length}',
        );

        // Se não encontramos postos com o método principal, tentamos o fallback
        if (postosDisponiveis.isEmpty) {
          debugPrint(
            'Nenhum posto encontrado com o método principal, tentando fallback',
          );
          return await _getPostosComMedicamentoFallbackV2(
            medicamentoId,
            medicamento,
          );
        }

        return postosDisponiveis;
      } else {
        // Se o endpoint específico não existir, tente usar uma abordagem alternativa
        debugPrint(
          'Endpoint específico retornou erro: ${response.statusCode}. Usando fallback',
        );
        return await _getPostosComMedicamentoFallbackV2(
          medicamentoId,
          medicamento,
        );
      }
    } catch (e) {
      debugPrint('Erro ao buscar postos com medicamento disponível: $e');
      // Tentar abordagem alternativa
      return await _getPostosComMedicamentoFallback(medicamentoId);
    }
  }

  // Método auxiliar para buscar o ID do posto pelo nome
  static Future<Map<String, dynamic>> _buscarIdPostoPorNome(
    String nomePosto,
  ) async {
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/posto/pesquisar/${Uri.encodeComponent(nomePosto)}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> postos = jsonDecode(response.body);
        if (postos.isEmpty) throw Exception('Posto não encontrado: $nomePosto');

        // Encontrar o posto que melhor corresponde ao nome
        for (final posto in postos) {
          final nome = posto['nome'] ?? '';
          if (nome.toLowerCase().trim() == nomePosto.toLowerCase().trim()) {
            return posto;
          }
        }

        // Se não encontrou uma correspondência exata, retorne o primeiro
        return postos[0];
      } else {
        throw Exception(
          'Erro ao buscar ID do posto pelo nome: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Erro ao buscar ID do posto pelo nome: $e');
      throw e;
    }
  }

  // Método fallback melhorado para buscar postos com medicamento disponível
  static Future<List<dynamic>> _getPostosComMedicamentoFallbackV2(
    String medicamentoId,
    Map<String, dynamic> medicamento,
  ) async {
    try {
      final nomeMedicamento =
          medicamento['nomeMedicamento'] ?? medicamento['produto'] ?? '';

      debugPrint('Usando fallback V2 para medicamento: $nomeMedicamento');

      // Usar o campo 'postos' se disponível diretamente no objeto medicamento
      if (medicamento['postos'] != null && medicamento['postos'] is List) {
        final List<dynamic> postos = medicamento['postos'];
        debugPrint(
          'Postos encontrados diretamente no medicamento: ${postos.length}',
        );
        return postos;
      }

      // Se chegamos aqui, tentamos o fallback original
      return await _getPostosComMedicamentoFallback(medicamentoId);
    } catch (e) {
      debugPrint('Erro no fallback V2: $e');
      return await _getPostosComMedicamentoFallback(medicamentoId);
    }
  }

  // Método fallback para buscar postos com medicamento disponível
  static Future<List<dynamic>> _getPostosComMedicamentoFallback(
    String medicamentoId,
  ) async {
    try {
      // Primeiro, buscar as informações do medicamento para ter o nome
      final medicamento = await getMedicamentoById(medicamentoId);
      final nomeMedicamento =
          medicamento['nomeMedicamento'] ?? medicamento['produto'] ?? '';

      if (nomeMedicamento.isEmpty) {
        throw Exception('Nome do medicamento não encontrado');
      }

      // Buscar todos os postos (limitado a uma área próxima se possível)
      final postos = await getPostosProximos(
        -3.7480523, // Coordenada padrão
        -38.5676128,
        20.0, // Raio maior para ter mais resultados
      );

      // Filtrar postos que têm o medicamento disponível
      final postosDisponiveis = <Map<String, dynamic>>[];

      for (final posto in postos) {
        // Buscar medicamentos do posto
        try {
          final medicamentosPosto = await pesquisarMedicamentosEmPosto(
            posto['id'],
            nomeMedicamento,
          );

          // Verificar se o medicamento específico está disponível
          final temMedicamento = medicamentosPosto.any((med) {
            return (med['medicamentoId'] == medicamentoId ||
                    med['id'] == medicamentoId) &&
                (med['quantidadeEstoque'] != null &&
                    med['quantidadeEstoque'] > 0);
          });

          if (temMedicamento) {
            postosDisponiveis.add(posto);
          }
        } catch (e) {
          debugPrint(
            'Erro ao verificar medicamentos do posto ${posto['id']}: $e',
          );
          // Continuar com o próximo posto
          continue;
        }
      }

      return postosDisponiveis;
    } catch (e) {
      debugPrint('Erro no fallback para buscar postos com medicamento: $e');
      throw Exception('Não foi possível buscar postos com o medicamento');
    }
  }

  // Método para buscar os detalhes completos de um posto pelo ID
  static Future<Map<String, dynamic>> getPostoDetailById(String id) async {
    try {
      debugPrint('Buscando detalhes completos do posto com ID: $id');
      final response = await http.get(
        Uri.parse('$baseUrl/posto/$id'),
        headers: await _authHeaders,
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        // Correção de encoding se necessário
        final posto =
            decodedData is Map
                ? corrigirEncodingJson(decodedData)
                : decodedData;

        debugPrint('Detalhes do posto obtidos com sucesso: ${posto['nome']}');
        debugPrint(
          'Coordenadas do posto: ${posto['latitude']}, ${posto['longitude']}',
        );
        return posto;
      } else {
        debugPrint('Erro ao buscar detalhes do posto: ${response.statusCode}');
        debugPrint('Resposta: ${response.body}');
        throw Exception(
          'Falha ao buscar detalhes do posto. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Exceção ao buscar detalhes do posto: $e');
      throw Exception('Falha ao buscar detalhes do posto: $e');
    }
  }
}
