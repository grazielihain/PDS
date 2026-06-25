import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class HistoricoSimuladoPage extends StatefulWidget {
  const HistoricoSimuladoPage({super.key});

  @override
  State<HistoricoSimuladoPage> createState() => _HistoricoSimuladoPageState();
}

class _HistoricoSimuladoPageState extends State<HistoricoSimuladoPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Estados de Filtro
  String _filtroSelecionado = 'ultimas'; // 'ultimas' ou 'categoria'
  String _categoriaSelecionada = 'Todas';

  List<String> _categoriasDisponiveis = ['Todas'];
  bool _carregandoCategorias = true;

  @override
  void initState() {
    super.initState();
    _carregarCategoriasDoHistorico();
  }

  /// 📉 Otimizado para Plano Gratuito: Acessa a rota linear da subcoleção do usuário logado
  Future<void> _carregarCategoriasDoHistorico() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _carregandoCategorias = false);
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .collection('historico_simulados')
          .get();

      final categorias = snapshot.docs
          .map((doc) => doc.data()['categoria'] as String?)
          .where((cat) => cat != null && cat.isNotEmpty)
          .map((cat) => cat!)
          .toSet()
          .toList();

      // Ordena as categorias alfabeticamente para melhor UX
      categorias.sort();

      setState(() {
        _categoriasDisponiveis = ['Todas', ...categorias];
        _carregandoCategorias = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar categorias do histórico: $e');
      setState(() => _carregandoCategorias = false);
    }
  }

  Query _montarQueryHistorico() {
    final user = _auth.currentUser;

    // Se não houver usuário, joga para uma coleção fantasma vazia para evitar crash
    if (user == null) {
      return _firestore
          .collection('usuarios')
          .doc('anonimo')
          .collection('historico_simulados');
    }

    // Caminho linear direto da subcoleção de simulados do usuário logado
    Query query = _firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('historico_simulados');

    // Se o filtro for por categoria específica
    if (_filtroSelecionado == 'categoria' && _categoriaSelecionada != 'Todas') {
      query = query.where('categoria', isEqualTo: _categoriaSelecionada);
    }

    return query;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 📑 CABEÇALHO DA ABA
              Padding(
                padding: const EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  top: 32.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Histórico de Provas',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Acompanhe seu desempenho acadêmico, filtre exames anteriores e gerencie sua pontuação.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(),
                    ),
                  ],
                ),
              ),

              // 🔍 CARD DE FILTROS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.filter_alt_outlined,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Filtrar Resultados',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('10 Últimas Provas'),
                            selected: _filtroSelecionado == 'ultimas',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _filtroSelecionado = 'ultimas';
                                  _categoriaSelecionada = 'Todas';
                                });
                              }
                            },
                          ),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: const Text('Por Categoria'),
                            selected: _filtroSelecionado == 'categoria',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _filtroSelecionado = 'categoria';
                                });
                              }
                            },
                          ),
                        ],
                      ),

                      if (_filtroSelecionado == 'categoria') ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Selecione a Categoria desejada:',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        _carregandoCategorias
                            ? const LinearProgressIndicator()
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    // 🔥 CORREÇÃO DE SEGURANÇA: Garante que o valor selecionado exista na lista antes de renderizar
                                    value:
                                        _categoriasDisponiveis.contains(
                                          _categoriaSelecionada,
                                        )
                                        ? _categoriaSelecionada
                                        : 'Todas',
                                    isExpanded: true,
                                    items: _categoriasDisponiveis.map((cat) {
                                      return DropdownMenuItem(
                                        value: cat,
                                        child: Text(cat),
                                      );
                                    }).toList(),
                                    onChanged: (String? novaCategoria) {
                                      if (novaCategoria != null) {
                                        setState(() {
                                          _categoriaSelecionada = novaCategoria;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 📊 LISTA DE CARD DE PROVAS
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _montarQueryHistorico().snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      // 🔥 UX MELHORADA: Se o erro for falta de índice, avisa de forma limpa no console/tela
                      final erroStr = snapshot.error.toString();
                      if (erroStr.contains('FAILED_PRECONDITION')) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              'Configurando índices de busca no banco de dados. Volte em instantes!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        );
                      }
                      return Center(
                        child: Text(
                          'Erro ao carregar dados: ${snapshot.error}',
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Sort client-side (avoid composite index: where + orderBy on different fields)
                    var documentos = List<QueryDocumentSnapshot>.from(
                      snapshot.data?.docs ?? [],
                    )..sort((a, b) {
                      final aTs = (a.data() as Map<String, dynamic>)['dataHora'] as Timestamp?;
                      final bTs = (b.data() as Map<String, dynamic>)['dataHora'] as Timestamp?;
                      if (aTs == null && bTs == null) return 0;
                      if (aTs == null) return 1;
                      if (bTs == null) return -1;
                      return bTs.compareTo(aTs);
                    });

                    if (_filtroSelecionado == 'ultimas') {
                      documentos = documentos.take(10).toList();
                    }

                    if (documentos.isEmpty) {
                      return Center(
                        child: Text(
                          'Nenhuma prova encontrada para este filtro.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 8.0,
                      ),
                      itemCount: documentos.length,
                      itemBuilder: (context, index) {
                        final dados =
                            documentos[index].data() as Map<String, dynamic>;

                        final categoria = dados['categoria'] ?? 'Geral';
                        final tipoProva =
                            dados['tipoProva'] ?? 'Simulado Completo';
                        final assunto = dados['assunto'];

                        final acertos = dados['acertos'] ?? 0;
                        final totalQuestoes = dados['totalQuestoes'] ?? 0;

                        final notaObtida =
                            (dados['notaObtida'] as num?)?.toDouble() ??
                            (dados['NotaObtida'] as num?)?.toDouble() ??
                            (dados['pontosProva'] as num?)?.toDouble() ??
                            0.0;

                        final pontosGamificacao =
                            dados['pontosGamificacao'] ?? 0;

                        String dataHoraFormatada = 'Data indisponível';
                        final campoData =
                            dados['dataHora'] ?? dados['dataConclusao'];
                        if (campoData != null && campoData is Timestamp) {
                          dataHoraFormatada = DateFormat(
                            'dd/MM/yyyy - HH:mm',
                          ).format(campoData.toDate());
                        }

                        final percentual = totalQuestoes > 0
                            ? (acertos / totalQuestoes) * 100
                            : 0.0;
                        final isPorAssunto =
                            tipoProva.toString().toLowerCase().contains(
                              'assunto',
                            ) ||
                            assunto != null;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        categoria.toString().toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.blue.shade800,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      dataHoraFormatada,
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                Text(
                                  isPorAssunto
                                      ? 'Prova por Assunto: ${assunto ?? "Especificado"}'
                                      : 'Simulado de Categoria Completa',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 14),

                                Row(
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 60,
                                          height: 60,
                                          child: CircularProgressIndicator(
                                            value: percentual / 100,
                                            backgroundColor:
                                                Colors.grey.shade100,
                                            color: percentual >= 70
                                                ? Colors.green
                                                : Colors.orange,
                                            strokeWidth: 6,
                                          ),
                                        ),
                                        Text(
                                          '${percentual.toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Acertos: $acertos de $totalQuestoes questões',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Status: Concluído',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Nota: ${notaObtida.toStringAsFixed(1)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueAccent,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            '+$pontosGamificacao XP',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.green,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.0),
                                  child: Divider(height: 1),
                                ),

                                Row(
                                  children: [
                                    const Spacer(),
                                    TextButton.icon(
                                      icon: const Icon(
                                        Icons.analytics_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Ver Detalhes'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.blue.shade700,
                                        textStyle: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      onPressed: () {
                                        context.go(
                                          '/resultado',
                                          extra: dados,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
