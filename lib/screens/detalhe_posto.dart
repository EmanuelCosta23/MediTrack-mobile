import 'package:flutter/material.dart';
import 'package:meditrack/services/api_service.dart';
import 'mapa_posto_screen.dart';
import 'home_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class DetalhePosto extends StatefulWidget {
  final String nome;
  final String endereco;
  final String id;

  const DetalhePosto({
    super.key,
    required this.nome,
    required this.endereco,
    required this.id,
  });

  @override
  State<DetalhePosto> createState() => _DetalhePostoState();
}

class _DetalhePostoState extends State<DetalhePosto> {
  bool _isLoading = true;
  Map<String, dynamic> _postoDetalhes = {};
  List<dynamic> _medicamentos = [];
  String _searchQuery = '';
  String _erro = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarDadosPosto();
  }

  Future<void> _carregarDadosPosto() async {
    setState(() {
      _isLoading = true;
      _erro = '';
    });

    try {
      // Carregar detalhes do posto - primeiro a chamada principal
      debugPrint('Buscando posto com ID/Nome: ${widget.id}');
      final postoDetalhes = await ApiService.getPostoById(widget.id);

      // Log para depuração
      debugPrint('Dados do posto recebidos: ${postoDetalhes.keys.toList()}');

      // Se o ID passado for um nome, atualizar o ID com o real
      String postoId = widget.id;
      if (postoDetalhes['id'] != null &&
          postoDetalhes['id'].toString().isNotEmpty) {
        postoId = postoDetalhes['id'].toString();
        debugPrint('ID real do posto encontrado: $postoId');
      }

      // Definir dados iniciais
      setState(() {
        _postoDetalhes = postoDetalhes;
        _isLoading = false;
      });

      try {
        // Carregar detalhes adicionais do posto com o ID correto
        final detalhesCompletos = await ApiService.getPostoDetalhes(postoId);
        debugPrint(
          'Detalhes completos do posto: ${detalhesCompletos.keys.toList()}',
        );

        // Atualizar com informações adicionais se existirem
        setState(() {
          // Mesclar os detalhes obtidos anteriormente com os novos
          _postoDetalhes = {
            ..._postoDetalhes,
            ...detalhesCompletos,
            // Manter os medicamentos da primeira chamada se existirem
            'medicamentos':
                _postoDetalhes['medicamentos'] ??
                detalhesCompletos['medicamentos'],
          };
        });
      } catch (e) {
        // Se falhar em obter detalhes adicionais, continue com os dados básicos
        debugPrint(
          'Aviso: Não foi possível carregar detalhes adicionais do posto: $e',
        );
      }

      // Carregar medicamentos do posto (se não vieram na resposta inicial)
      if (_postoDetalhes['medicamentos'] == null ||
          (_postoDetalhes['medicamentos'] as List).isEmpty) {
        _carregarMedicamentos(postoId);
      } else {
        setState(() {
          _medicamentos = _postoDetalhes['medicamentos'] as List;
        });
      }
    } catch (e) {
      setState(() {
        _erro =
            'Não foi possível carregar os dados do posto. Verifique sua conexão e tente novamente.';
        _isLoading = false;
      });
      debugPrint('Erro ao carregar detalhes do posto: $e');
    }
  }

  Future<void> _carregarMedicamentos([String? postoId]) async {
    try {
      // Primeiro, buscar os detalhes completos do posto
      final postoDetalhes = await ApiService.getPostoById(postoId ?? widget.id);
      debugPrint('Dados do posto carregados: ${postoDetalhes.keys.toList()}');

      // Extrair a lista de medicamentos do posto
      List<dynamic> medicamentos = [];
      if (postoDetalhes['medicamentos'] != null &&
          postoDetalhes['medicamentos'] is List) {
        medicamentos = postoDetalhes['medicamentos'] as List;
        debugPrint('Medicamentos encontrados no posto: ${medicamentos.length}');

        // Verificar a estrutura dos dados
        if (medicamentos.isNotEmpty) {
          debugPrint(
            'Estrutura do primeiro medicamento: ${medicamentos[0].keys.toList()}',
          );
        }
      }

      if (mounted) {
        setState(() {
          _medicamentos = medicamentos;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Não foi possível carregar os medicamentos. Tente novamente.',
            ),
            action: SnackBarAction(
              label: 'Tentar novamente',
              textColor: Colors.white,
              onPressed: _carregarMedicamentos,
            ),
            backgroundColor: const Color(0xFF0080FF),
          ),
        );
      }
      debugPrint('Erro ao carregar medicamentos: $e');
    }
  }

  Future<void> _pesquisarMedicamentos(String query) async {
    if (query.isEmpty) {
      // Se a pesquisa estiver vazia, carrega todos os medicamentos
      try {
        final medicamentos = await ApiService.pesquisarMedicamentosEmPosto(
          widget.id,
        );
        setState(() {
          _medicamentos = medicamentos;
        });
      } catch (e) {
        // Mantém os medicamentos atuais em caso de erro
      }
      return;
    }

    if (query.length < 2) {
      return; // Não busca se tiver menos de 2 caracteres
    }

    try {
      final medicamentos = await ApiService.pesquisarMedicamentosEmPosto(
        widget.id,
        query,
      );
      setState(() {
        _medicamentos = medicamentos;
      });
    } catch (e) {
      // Mantém os medicamentos atuais em caso de erro
    }
  }

  String _formatarEndereco(Map<String, dynamic> posto) {
    final rua = posto['rua'] ?? '';
    final numero = posto['numero'] ?? '';
    final bairro = posto['bairro'] ?? '';

    return '$rua, $numero${bairro.isNotEmpty ? ' - $bairro' : ''}';
  }

  bool _temDadosExtras() {
    return _getTelefone() != null || _getLinhasOnibus() != null;
  }

  String? _getTelefone() {
    if (_postoDetalhes['telefone'] != null) {
      return _postoDetalhes['telefone'].toString();
    } else if (_postoDetalhes['telefonePosto'] != null) {
      return _postoDetalhes['telefonePosto'].toString();
    } else {
      return null;
    }
  }

  String? _getLinhasOnibus() {
    if (_postoDetalhes['linhasOnibus'] != null) {
      return _postoDetalhes['linhasOnibus'].toString();
    } else if (_postoDetalhes['linhasOnibusPosto'] != null) {
      return _postoDetalhes['linhasOnibusPosto'].toString();
    } else {
      return null;
    }
  }

  String _corrigirNomeMedicamento(String nome) {
    if (nome.isEmpty) return nome;

    // Usar a função de correção sistemática do ApiService
    return ApiService.corrigirEncoding(nome);
  }

  String _getDisponibilidadeText(Map<String, dynamic> medicamento) {
    // Debug log para verificar os dados do medicamento
    debugPrint(
      'Verificando disponibilidade para medicamento: ${medicamento['nomeMedicamento'] ?? medicamento['produto']}',
    );
    debugPrint('Dados do medicamento: ${medicamento.keys.toList()}');

    // Check if quantidadeEstoque exists and is greater than 0
    final quantidadeEstoque = medicamento['quantidadeEstoque'] ?? 0;
    debugPrint('Quantidade em estoque: $quantidadeEstoque');

    final disponivel = quantidadeEstoque > 0;
    debugPrint('Disponível: $disponivel');

    if (disponivel) {
      return 'Disponível';
    } else {
      return 'Indisponível';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MediTrack', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0080FF),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Botão Home
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              // Navegação para a home resetando a pilha de navegação
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false, // Remove todas as rotas anteriores
              );
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF0080FF)),
              )
              : _erro.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _erro,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _carregarDadosPosto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0080FF),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Informações do posto (cabeçalho)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    color: const Color(0xFF0080FF),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _postoDetalhes['nome'] ?? widget.nome,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                _formatarEndereco(_postoDetalhes),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                // Verificar se temos as coordenadas do posto
                                double? latitude;
                                double? longitude;
                                double? distancia;

                                // Verificar todas as possibilidades de nomes para as coordenadas
                                if (_postoDetalhes['latitude'] != null &&
                                    _postoDetalhes['longitude'] != null) {
                                  latitude = double.tryParse(
                                    _postoDetalhes['latitude'].toString(),
                                  );
                                  longitude = double.tryParse(
                                    _postoDetalhes['longitude'].toString(),
                                  );
                                } else if (_postoDetalhes['latitudePosto'] !=
                                        null &&
                                    _postoDetalhes['longitudePosto'] != null) {
                                  latitude = double.tryParse(
                                    _postoDetalhes['latitudePosto'].toString(),
                                  );
                                  longitude = double.tryParse(
                                    _postoDetalhes['longitudePosto'].toString(),
                                  );
                                }

                                // Verificar distância
                                if (_postoDetalhes['distancia'] != null) {
                                  distancia =
                                      _postoDetalhes['distancia'] is double
                                          ? _postoDetalhes['distancia']
                                          : double.tryParse(
                                            _postoDetalhes['distancia']
                                                .toString(),
                                          );
                                }

                                if (latitude != null && longitude != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => MapaPostoScreen(
                                            nome:
                                                _postoDetalhes['nome'] ??
                                                widget.nome,
                                            endereco: _formatarEndereco(
                                              _postoDetalhes,
                                            ),
                                            latitude: latitude!,
                                            longitude: longitude!,
                                            distancia: distancia,
                                          ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Não foi possível obter as coordenadas do posto',
                                      ),
                                      backgroundColor: Color(0xFF0080FF),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.map_outlined,
                                      color: Color(0xFF0080FF),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Ver no mapa',
                                      style: TextStyle(
                                        color: Color(0xFF0080FF),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Detalhes adicionais (telefone, linhas de ônibus)
                  if (_temDadosExtras())
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      color: Colors.grey[200],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Verificar várias possibilidades para o campo telefone
                          if (_getTelefone() != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    size: 18,
                                    color: Color(0xFF0080FF),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Telefone: ${_getTelefone()}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),

                          // Verificar várias possibilidades para as linhas de ônibus
                          if (_getLinhasOnibus() != null)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.directions_bus,
                                  size: 18,
                                  color: Color(0xFF0080FF),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Linhas de ônibus: ${_getLinhasOnibus()}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                  // Barra de pesquisa
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Pesquisar medicamentos...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF0080FF),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Color(0xFF0080FF),
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 20,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                        _pesquisarMedicamentos(value);
                      },
                    ),
                  ),

                  // Lista de medicamentos (scrollável)
                  Expanded(
                    child:
                        _medicamentos.isEmpty
                            ? const Center(
                              child: Text(
                                'Nenhum medicamento encontrado neste posto.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              itemCount: _medicamentos.length,
                              itemBuilder: (context, index) {
                                final medicamento = _medicamentos[index];
                                // Verificar a disponibilidade baseada no estoque
                                final quantidadeEstoque =
                                    medicamento['quantidadeEstoque'] ?? 0;
                                final bool disponivel = quantidadeEstoque > 0;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 6.0),
                                  child: InkWell(
                                    onTap: () {
                                      _mostrarDetalhesMedicamento(medicamento);
                                    },
                                    borderRadius: BorderRadius.circular(4),
                                    splashColor: Color(
                                      0xFF0080FF,
                                    ).withOpacity(0.1),
                                    highlightColor: Color(
                                      0xFF0080FF,
                                    ).withOpacity(0.05),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0,
                                        vertical: 10.0,
                                      ),
                                      child: Row(
                                        children: [
                                          // Ícone de remédio
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF0080FF,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Icon(
                                              Icons.medication,
                                              color: Color(0xFF0080FF),
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 10),

                                          // Informações do medicamento
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _corrigirNomeMedicamento(
                                                    medicamento['nomeMedicamento'] ??
                                                        medicamento['produto'] ??
                                                        'Nome não disponível',
                                                  ),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),

                                                // Status de disponibilidade
                                                Text(
                                                  _getDisponibilidadeText(
                                                    medicamento,
                                                  ),
                                                  style: TextStyle(
                                                    color:
                                                        disponivel
                                                            ? Colors.green[700]
                                                            : Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),

                                                // Indicador de que é clicável
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      'Toque para detalhes',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 11,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Icon(
                                                      Icons.info_outline,
                                                      size: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Método para exibir o modal com detalhes do medicamento
  void _mostrarDetalhesMedicamento(Map<String, dynamic> medicamento) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(color: Color(0xFF0080FF)),
          ),
    );

    try {
      // Obter o ID do medicamento
      final String medicamentoId =
          medicamento['medicamentoId'] ?? medicamento['id'] ?? '';

      debugPrint('ID do medicamento: $medicamentoId');

      if (medicamentoId.isEmpty) {
        // Fechar o loading
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível identificar o medicamento.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Buscar os detalhes completos do medicamento na tabela de medicamentos
      final medicamentoCompleto = await ApiService.getMedicamentoById(
        medicamentoId,
      );

      debugPrint(
        'Detalhes do medicamento carregados: ${medicamentoCompleto.keys.join(', ')}',
      );

      // Agora consultar a disponibilidade diretamente no posto
      int estoque = 0;
      try {
        // Esta é uma chamada separada para buscar especificamente os medicamentos do posto
        debugPrint(
          'Buscando disponibilidade no posto ${widget.id} para medicamento $medicamentoId',
        );

        // Buscar todas as informações do posto para ter dados de medicamentos
        final postoDetalhes = await ApiService.getPostoById(widget.id);

        if (postoDetalhes['medicamentos'] != null &&
            postoDetalhes['medicamentos'] is List) {
          final medicamentosPosto = postoDetalhes['medicamentos'] as List;

          // Procurar o medicamento específico na lista de medicamentos do posto
          for (final med in medicamentosPosto) {
            if ((med['medicamentoId'] == medicamentoId ||
                med['id'] == medicamentoId)) {
              estoque = med['quantidadeEstoque'] ?? 0;
              debugPrint('Encontrada quantidade em estoque no posto: $estoque');
              break;
            }
          }
        } else {
          debugPrint('Buscando apenas relacionamento medicamento_posto');
        }
      } catch (e) {
        debugPrint('Erro ao verificar disponibilidade no posto: $e');
      }

      // Fechar o loading
      Navigator.pop(context);

      // Formatação da data de vencimento
      String dataVencimento = 'Não informada';
      if (medicamentoCompleto['vencimento'] != null) {
        try {
          final data = DateTime.parse(medicamentoCompleto['vencimento']);
          dataVencimento =
              '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
        } catch (e) {
          dataVencimento = medicamentoCompleto['vencimento'].toString();
        }
      }

      // Correção do nome do medicamento
      final nomeMedicamento = _corrigirNomeMedicamento(
        medicamentoCompleto['produto'] ??
            medicamento['nomeMedicamento'] ??
            'Nome não disponível',
      );

      // Verificar disponibilidade - só está disponível se tiver estoque > 0
      final bool disponivel = estoque > 0;

      // Atualizar medicamento para refletir o estoque real para consistência com o popup
      medicamento['quantidadeEstoque'] = estoque;

      debugPrint(
        'Disponibilidade do medicamento $medicamentoId: $disponivel (estoque: $estoque)',
      );

      // Status para "necessita receita"
      final necessitaReceita =
          medicamentoCompleto['necessita_receita'] ?? false;

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(
                'Detalhes do Medicamento',
                style: TextStyle(
                  color: Color(0xFF0080FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nome do produto
                    Text(
                      'Nome:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      nomeMedicamento,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tipo
                    Text(
                      'Tipo:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      medicamentoCompleto['tipoMedicamento'] ?? 'Não informado',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),

                    // Lote
                    Text(
                      'Lote:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      medicamentoCompleto['lote'] ?? 'Não informado',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),

                    // Data de vencimento
                    Text(
                      'Data de Vencimento:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(dataVencimento, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 12),

                    // // Status de disponibilidade
                    // Row(
                    //   children: [
                    //     Text(
                    //       'Disponibilidade:',
                    //       style: TextStyle(
                    //         fontWeight: FontWeight.bold,
                    //         fontSize: 14,
                    //         color: Colors.grey[600],
                    //       ),
                    //     ),
                    //     const SizedBox(width: 8),
                    //     Text(
                    //       disponivel ? 'Disponível' : 'Indisponível',
                    //       style: TextStyle(
                    //         color: disponivel ? Colors.green : Colors.red,
                    //         fontSize: 16,
                    //         fontWeight: FontWeight.bold,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    const SizedBox(height: 12),

                    // Necessita receita (texto colorido sem checkbox)
                    Row(
                      children: [
                        Text(
                          'Necessita Receita:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          necessitaReceita ? 'Sim' : 'Não',
                          style: TextStyle(
                            color: necessitaReceita ? Colors.red : Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0080FF),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 40),
                    ),
                    child: const Text('Fechar'),
                  ),
                ),
              ],
            ),
      );
    } catch (e) {
      // Fechar o loading
      Navigator.pop(context);

      debugPrint('Erro ao buscar detalhes do medicamento: $e');

      // Mostrar uma mensagem de erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar detalhes do medicamento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class DetalhePostoScreen extends StatelessWidget {
  final String? nome;
  final String? endereco;
  final double? latitude;
  final double? longitude;
  final double? distancia;

  const DetalhePostoScreen({
    super.key,
    this.nome,
    this.endereco,
    this.latitude,
    this.longitude,
    this.distancia,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Posto'),
        backgroundColor: const Color(0xFF0080FF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome do posto
            Text(
              nome ?? 'Posto de Saúde',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0080FF),
              ),
            ),
            const SizedBox(height: 24),

            // Endereço
            _buildInfoSection(
              'Endereço',
              endereco ?? 'Endereço não disponível',
              Icons.location_on,
            ),
            const SizedBox(height: 16),

            // Distância
            if (distancia != null)
              _buildInfoSection(
                'Distância',
                '${distancia!.toStringAsFixed(1)} km',
                Icons.directions_walk,
              ),
            const SizedBox(height: 24),

            // Botão para ver rotas
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (latitude != null && longitude != null) {
                    final url = Uri.parse(
                      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Não foi possível abrir o Google Maps',
                            ),
                          ),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(Icons.directions, color: Colors.white),
                label: const Text('Ver Rotas no Google Maps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0080FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF0080FF), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0080FF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(content, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
