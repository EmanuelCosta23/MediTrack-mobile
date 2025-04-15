import 'package:flutter/material.dart';
import 'package:meditrack/services/api_service.dart';

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
      final postoDetalhes = await ApiService.getPostoById(widget.id);

      // Log para depuração
      debugPrint('Dados do posto (getPostoById): ${postoDetalhes.toString()}');

      // Definir dados iniciais
      setState(() {
        _postoDetalhes = postoDetalhes;
        _isLoading = false;
      });

      try {
        // Carregar detalhes adicionais do posto
        final detalhesCompletos = await ApiService.getPostoDetalhes(widget.id);
        debugPrint(
          'Detalhes completos do posto: ${detalhesCompletos.toString()}',
        );

        // Atualizar com informações adicionais se existirem
        setState(() {
          // Mesclar os detalhes obtidos anteriormente com os novos
          _postoDetalhes = {
            ..._postoDetalhes,
            ...detalhesCompletos,
            // Manter os medicamentos da primeira chamada
            'medicamentos': _postoDetalhes['medicamentos'],
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
        _carregarMedicamentos();
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
    }
  }

  Future<void> _carregarMedicamentos() async {
    try {
      final medicamentos = await ApiService.pesquisarMedicamentosEmPosto(
        widget.id,
      );

      if (mounted) {
        setState(() {
          _medicamentos = medicamentos;
        });
      }
    } catch (e) {
      // Não altera o estado de erro se apenas os medicamentos falharem
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLoading
              ? 'Carregando...'
              : (_postoDetalhes['nome'] ?? widget.nome),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0080FF),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
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
                                // Implementação futura para abrir mapa
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Funcionalidade em desenvolvimento',
                                    ),
                                    backgroundColor: Color(0xFF0080FF),
                                  ),
                                );
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
                                final int estoque =
                                    medicamento['quantidadeEstoque'] ?? 0;

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
                                                if (estoque == 0)
                                                  const Text(
                                                    'Produto não disponível',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  )
                                                else if (estoque <= 5)
                                                  const Text(
                                                    'Últimas unidades disponíveis',
                                                    style: TextStyle(
                                                      color: Colors.orange,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  )
                                                else
                                                  Text(
                                                    'Disponível',
                                                    style: TextStyle(
                                                      color: Colors.green[700],
                                                      fontWeight:
                                                          FontWeight.bold,
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
  void _mostrarDetalhesMedicamento(Map<String, dynamic> medicamento) {
    // Formatação da data de vencimento
    String dataVencimento = 'Não informada';
    if (medicamento['dataVencimento'] != null) {
      try {
        final data = DateTime.parse(medicamento['dataVencimento']);
        dataVencimento =
            '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
      } catch (e) {
        dataVencimento = medicamento['dataVencimento'].toString();
      }
    }

    // Correção do nome do medicamento
    final nomeMedicamento = _corrigirNomeMedicamento(
      medicamento['nomeMedicamento'] ?? 'Nome não disponível',
    );

    // Status do checkbox para "necessita receita"
    final necessitaReceita = medicamento['necessitaReceita'] ?? false;

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
                    medicamento['tipoMedicamento'] ?? 'Não informado',
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
                    medicamento['loteMedicamento'] ?? 'Não informado',
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

                  // Necessita receita (checkbox)
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
                      Checkbox(
                        value: necessitaReceita,
                        onChanged: null, // Checkbox apenas para visualização
                        activeColor: Color(0xFF0080FF),
                      ),
                      Text(
                        necessitaReceita ? 'Sim' : 'Não',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),

                  // Estoque disponível
                  const SizedBox(height: 12),
                  Text(
                    'Quantidade em Estoque:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${medicamento['quantidadeEstoque'] ?? 0} unidades',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Fechar',
                  style: TextStyle(
                    color: Color(0xFF0080FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
