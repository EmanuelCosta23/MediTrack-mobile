import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';

class VacinaScreen extends StatefulWidget {
  const VacinaScreen({super.key});

  @override
  State<VacinaScreen> createState() => _VacinaScreenState();
}

class _VacinaScreenState extends State<VacinaScreen> {
  final List<String> _vacinas = [
    // Vacinas disponíveis no SUS e rede privada
    'BCG',
    'Hepatite A',
    'Hepatite B',
    'Penta (DTP/Hib/Hep. B)',
    'Pneumocócica 10 valente',
    'Vacina Inativada Poliomielite (VIP)',
    'Vacina Oral Poliomielite (VOP)',
    'Vacina Rotavírus Humano (VRH)',
    'Meningocócica C (conjugada)',
    'Febre amarela',
    'Tríplice viral (Sarampo, Caxumba e Rubéola)',
    'Tetraviral (Sarampo, Caxumba, Rubéola e Varicela)',
    'DTP (tríplice bacteriana)',
    'Varicela',
    'HPV quadrivalente',
    'dT (dupla adulto)',
    'dTpa (DTP adulto)',
    'Meningocócica ACWY (conjugada)',
    'Gripe (Influenza)',
    'COVID-19',

    // Disponíveis principalmente na rede privada ou em situações específicas
    'Herpes Zoster',
    'Pneumocócica 13 valente',
    'Pneumocócica 23 valente',
    'Dengue',
    'Raiva',
    'Influenza Quadrivalente',
    'Meningocócica B (recombinante)',
    'HPV nonavalente',
    'Febre Tifoide',
    'Haemophilus influenzae tipo b (Hib)',
    'Rotavírus Pentavalente',
    'Hepatite A e B combinadas',
    'Difteria e Tétano infantil (DT)',
    'Vírus Sincicial Respiratório (VSR)',
    'Cólera oral',
    'Encefalite Japonesa',
    'HPV bivalente',
    'DTPA + Polio inativada',
    'Hexavalente (DTPa + Hib + HB + VIP)',
    'DTPA + Hib',
    'Poliomielite 1, 2 e 3 (inativada)',
    'Meningocócica AC (conjugada)',
    'Meningocócica ACWY (polissacarídica)',
    'Febre Amarela (atenuada)',
    'Influenza (inativada, fragmentada)',
    'Hepatite A infantil',
    'Hepatite A adulto',
    'Varicela (atenuada)',
    'Sarampo (atenuada)',
    'Rubéola (atenuada)',
  ];

  String _searchQuery = '';
  List<String> _filteredVacinas = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredVacinas = _vacinas;
  }

  void _filterVacinas(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredVacinas = _vacinas;
      } else {
        _filteredVacinas =
            _vacinas
                .where(
                  (vacina) =>
                      vacina.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  void _mostrarDetalhesVacina(String vacina) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Informações da Vacina',
              style: TextStyle(
                color: Color(0xFF40BFFF),
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
                  vacina,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Público:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Consulte a faixa etária recomendada',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  'Descrição:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Consulte um profissional de saúde para mais informações.',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Fechar',
                  style: TextStyle(
                    color: Color(0xFF40BFFF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vacinas', style: TextStyle(color: Colors.white)),
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
              onChanged: _filterVacinas,
              decoration: InputDecoration(
                hintText: 'Pesquisar vacinas...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF40BFFF)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF40BFFF)),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 20,
                ),
              ),
            ),
          ),

          // Lista de vacinas
          Expanded(
            child:
                _filteredVacinas.isEmpty
                    ? const Center(
                      child: Text(
                        'Nenhuma vacina encontrada.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _filteredVacinas.length,
                      itemBuilder: (context, index) {
                        final vacina = _filteredVacinas[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 6.0),
                          child: InkWell(
                            onTap: () {
                              _mostrarDetalhesVacina(vacina);
                            },
                            borderRadius: BorderRadius.circular(4),
                            splashColor: Color(0xFF40BFFF).withOpacity(0.1),
                            highlightColor: Color(0xFF40BFFF).withOpacity(0.05),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 10.0,
                              ),
                              child: Row(
                                children: [
                                  // Ícone de vacina
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF40BFFF,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.vaccines,
                                      color: Color(0xFF40BFFF),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Informações da vacina
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          vacina,
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
