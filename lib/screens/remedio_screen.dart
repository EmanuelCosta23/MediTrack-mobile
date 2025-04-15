import 'package:flutter/material.dart';
import 'package:meditrack/services/api_service.dart';
import '../widgets/sidebar.dart';

class RemedioScreen extends StatefulWidget {
  const RemedioScreen({super.key});

  @override
  State<RemedioScreen> createState() => _RemedioScreenState();
}

class _RemedioScreenState extends State<RemedioScreen> {
  bool _isLoading = true;
  List<dynamic> _medicamentos = [];
  String _searchQuery = '';
  String _erro = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarMedicamentos();
  }

  Future<void> _carregarMedicamentos() async {
    setState(() {
      _isLoading = true;
      _erro = '';
    });

    try {
      // Carrega a lista de medicamentos usando um termo genérico
      // Usando 'a' em vez de string vazia para garantir resultados
      final List<dynamic> medicamentos = await ApiService.pesquisarMedicamentos(
        'a',
      );

      setState(() {
        _medicamentos = medicamentos;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar medicamentos: $e');
      setState(() {
        _erro =
            'Não foi possível carregar os medicamentos. Verifique sua conexão e tente novamente.';
        _isLoading = false;
      });
    }
  }

  Future<void> _pesquisarMedicamentos(String query) async {
    if (query.isEmpty) {
      _carregarMedicamentos();
      return;
    }

    if (query.length < 2) {
      return; // Não busca se tiver menos de 2 caracteres
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final List<dynamic> medicamentos = await ApiService.pesquisarMedicamentos(
        query,
      );

      setState(() {
        _medicamentos = medicamentos;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao pesquisar medicamentos: $e');
      setState(() {
        _isLoading = false;
      });
      // Mantém os medicamentos atuais em caso de erro
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao pesquisar medicamentos. Tente novamente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _corrigirNomeMedicamento(String nome) {
    if (nome.isEmpty) return nome;
    return ApiService.corrigirEncoding(nome);
  }

  void _mostrarDetalhesMedicamento(Map<String, dynamic> medicamento) async {
    final String medicamentoId =
        medicamento['id'] ?? medicamento['medicamentoId'] ?? '';

    if (medicamentoId.isEmpty) {
      // Se não encontrar o ID, mostrar mensagem de erro
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível obter detalhes deste medicamento.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
      // Buscar os detalhes completos do medicamento usando o ID
      final medicamentoDetalhes = await ApiService.getMedicamentoById(
        medicamentoId,
      );

      // Fechar o loading
      Navigator.pop(context);

      // Formatação da data de vencimento
      String dataVencimento = 'Não informada';
      if (medicamentoDetalhes['dataVencimento'] != null ||
          medicamentoDetalhes['vencimento'] != null) {
        try {
          final data = DateTime.parse(
            medicamentoDetalhes['dataVencimento'] ??
                medicamentoDetalhes['vencimento'],
          );
          dataVencimento =
              '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
        } catch (e) {
          dataVencimento =
              medicamentoDetalhes['dataVencimento']?.toString() ??
              medicamentoDetalhes['vencimento']?.toString() ??
              'Não informada';
        }
      }

      // Correção do nome do medicamento
      final nomeMedicamento = _corrigirNomeMedicamento(
        medicamentoDetalhes['nomeMedicamento'] ??
            medicamentoDetalhes['produto'] ??
            medicamento['nomeMedicamento'] ??
            medicamento['produto'] ??
            'Nome não disponível',
      );

      // Status do checkbox para "necessita receita"
      final necessitaReceita =
          medicamentoDetalhes['necessitaReceita'] ??
          medicamentoDetalhes['necessita_receita'] ??
          false;

      // Exibir o modal com as informações completas
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
                      medicamentoDetalhes['tipoMedicamento'] ??
                          medicamentoDetalhes['tipo'] ??
                          'Não informado',
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
                      medicamentoDetalhes['loteMedicamento'] ??
                          medicamentoDetalhes['lote'] ??
                          'Não informado',
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
    } catch (e) {
      // Fechar o loading
      Navigator.pop(context);

      // Em caso de erro, mostrar um modal simplificado com as informações básicas disponíveis
      debugPrint('Erro ao buscar detalhes do medicamento: $e');

      // Usar os dados disponíveis da lista
      final nomeMedicamento = _corrigirNomeMedicamento(
        medicamento['nomeMedicamento'] ??
            medicamento['produto'] ??
            'Nome não disponível',
      );

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(
                'Informações Básicas',
                style: TextStyle(
                  color: Color(0xFF0080FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 10),
                  const Text(
                    'Detalhes completos não disponíveis no momento.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Medicamentos',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0080FF),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: true,
      ),
      drawer: const Sidebar(),
      body: Column(
        children: [
          // Barra de pesquisa
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar medicamentos...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0080FF)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF0080FF)),
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
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0080FF),
                      ),
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
                            onPressed: _carregarMedicamentos,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0080FF),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    )
                    : _medicamentos.isEmpty
                    ? const Center(
                      child: Text(
                        'Nenhum medicamento encontrado.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _medicamentos.length,
                      itemBuilder: (context, index) {
                        final medicamento = _medicamentos[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 6.0),
                          child: InkWell(
                            onTap: () {
                              _mostrarDetalhesMedicamento(medicamento);
                            },
                            borderRadius: BorderRadius.circular(4),
                            splashColor: Color(0xFF0080FF).withOpacity(0.1),
                            highlightColor: Color(0xFF0080FF).withOpacity(0.05),
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
                                      borderRadius: BorderRadius.circular(6),
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
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                        // Indicador de que é clicável
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Toque para ver detalhes',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
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
}
