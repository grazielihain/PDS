import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConfiguracaoGamificacaoPage extends StatefulWidget {
  const ConfiguracaoGamificacaoPage({super.key});

  @override
  State<ConfiguracaoGamificacaoPage> createState() =>
      _ConfiguracaoGamificacaoPageState();
}

class _ConfiguracaoGamificacaoPageState
    extends State<ConfiguracaoGamificacaoPage> {
  final _formKeyGamificacao = GlobalKey<FormState>();

  String? _categoriaSelecionada;
  final _pontosProvaController = TextEditingController(text: '10');
  final _pontosBonusController = TextEditingController(text: '5');
  bool _salvando = false;

  @override
  void dispose() {
    _pontosProvaController.dispose();
    _pontosBonusController.dispose();
    super.dispose();
  }

  /// Salva as regras dinâmicas que o Admin estipulou para o Painel
  Future<void> _salvarRegraGamificacao() async {
    if (!_formKeyGamificacao.currentState!.validate() ||
        _categoriaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Por favor, selecione uma categoria e preencha os pontos.',
          ),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      // Salva ou atualiza a regra da categoria
      await FirebaseFirestore.instance
          .collection('regras_gamificacao')
          .doc(_categoriaSelecionada)
          .set({
            'categoriaId': _categoriaSelecionada,
            'pontosPorAcerto': int.parse(_pontosProvaController.text),
            'pontosBonusConclusao': int.parse(_pontosBonusController.text),
            'atualizadoEm': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎮 Regra de Gamificação aplicada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _salvando = false);
    }
  }

  // ===========================================================================
  // 🔥 SUBTAREFA 3.2: O MOTOR DE HISTÓRICO IMUTÁVEL
  // ===========================================================================
  /// Executa o encerramento do simulado e grava os dados estáticos ("Fotografia do Momento")
  Future<void> finalizarESalvarSimuladoImutavel({
    required String alunoId,
    required String categoriaId,
    required int totalQuestoes,
    required int totalAcertos,
  }) async {
    try {
      // 1. Busca a regra vigente no momento exato da conclusão
      final docRegra = await FirebaseFirestore.instance
          .collection('regras_gamificacao')
          .doc(categoriaId)
          .get();

      int pontosPorAcertoVigente = 10; // Fallback de segurança
      int bonusConclusaoVigente = 5;

      if (docRegra.exists && docRegra.data() != null) {
        final dadosRegra = docRegra.data()!;
        pontosPorAcertoVigente = dadosRegra['pontosPorAcerto'] ?? 10;
        bonusConclusaoVigente = dadosRegra['pontosBonusConclusao'] ?? 5;
      }

      // 2. Calcula os pontos obtidos com base nas regras atuais
      int pontosProvaCalculados = totalAcertos * pontosPorAcertoVigente;
      int pontosGamificacaoCalculados =
          pontosProvaCalculados + bonusConclusaoVigente;

      // 3. GRAVAÇÃO IMUTÁVEL: Clona os valores diretamente no documento do histórico.
      // Se o Admin mudar as regras no painel amanhã, este registro antigo não será alterado!
      await FirebaseFirestore.instance.collection('historico_simulados').add({
        'alunoId': alunoId,
        'categoriaId': categoriaId,
        'totalQuestoes': totalQuestoes,
        'totalAcertos': totalAcertos,
        'dataConclusao': FieldValue.serverTimestamp(),

        // 🛡️ O SEGREDO DA IMUTABILIDADE PEDIDA NA SPRINT:
        'pontosProva': pontosProvaCalculados, // Valor fixo gravado em pedra
        'pontosGamificacao':
            pontosGamificacaoCalculados, // Valor fixo gravado em pedra
        'regrasAplicadasNaEpoca': {
          'pontosPorAcerto': pontosPorAcertoVigente,
          'pontosBonusConclusao': bonusConclusaoVigente,
        },
      });

      debugPrint('🛡️ Histórico Imutável gravado com sucesso no Firestore!');
    } catch (e) {
      debugPrint('Erro crítico ao salvar histórico imutável: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motor de Gamificação'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Interface administrativa de configuração de pontos
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKeyGamificacao,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎯 Atribuição de Bônus por Categoria',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Configure a quantidade de pontos obtidos por acerto e o bônus final de conclusão recebido pelos alunos.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const Divider(height: 24),

                      // Dropdown que busca as categorias reais do banco para vincular os pontos (Subtarefa 3.1)
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('categorias')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: LinearProgressIndicator(),
                            );
                          }

                          final itensDrop = snapshot.data!.docs.map((doc) {
                            final dados = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text(
                                dados['nome'] ?? 'Categoria Sem Nome',
                              ),
                            );
                          }).toList();

                          return DropdownButtonFormField<String>(
                            value: _categoriaSelecionada,
                            decoration: const InputDecoration(
                              labelText: 'Selecione a Categoria Alvo',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: itensDrop,
                            onChanged: (val) =>
                                setState(() => _categoriaSelecionada = val),
                          );
                        },
                      ),

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _pontosProvaController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Pontos por Acerto',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.check_circle_outline),
                              ),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Obrigatório'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _pontosBonusController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Bônus de Conclusão',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.card_giftcard),
                              ),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Obrigatório'
                                  : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _salvando ? null : _salvarRegraGamificacao,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade700,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.flash_on),
                          label: const Text(
                            'Aplicar Regras de Pontuação',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
