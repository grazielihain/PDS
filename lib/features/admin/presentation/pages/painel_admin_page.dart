import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rumo_quiz/features/admin/data/models/configuracao_white_label_model.dart';

// ⚠️ IMPORTANTE: Importe aqui os seus componentes visuais de Header, Menu e Rodapé!
// import 'package:rumo_quiz/core/presentation/widgets/meu_menu_lateral.dart';
// import 'package:rumo_quiz/core/presentation/widgets/meu_rodape_customizado.dart';

class PainelAdminPage extends StatefulWidget {
  final String substituicaoInstituicaoId;

  const PainelAdminPage({Key? key, required this.substituicaoInstituicaoId})
    : super(key: key);

  @override
  State<PainelAdminPage> createState() => _PainelAdminPageState();
}

class _PainelAdminPageState extends State<PainelAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _corController = TextEditingController();
  final _nomeController = TextEditingController();

  // 🔥 Novos controllers para suportar Logo da Instituição e Mascote via URL string
  final _logoUrlController = TextEditingController();
  final _mascoteUrlController = TextEditingController();
  final _novoPatrocinadorController = TextEditingController();

  bool _isLoading = true;
  List<String> _patrocinadores = [];

  @override
  void initState() {
    super.initState();
    _carregarDadosWhiteLabel();
  }

  @override
  void dispose() {
    _corController.dispose();
    _nomeController.dispose();
    _logoUrlController.dispose();
    _mascoteUrlController.dispose();
    _novoPatrocinadorController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosWhiteLabel() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('instituicoes')
          .doc(widget.substituicaoInstituicaoId)
          .get();

      if (doc.exists && doc.data() != null) {
        final dadosCrus = doc.data()!;
        final config = ConfiguracaoWhiteLabelModel.fromMap(doc.id, dadosCrus);

        setState(() {
          _nomeController.text = config.nome;
          _corController.text = config.corHexadecimal;
          _patrocinadores = config.patrocinadoresUrls;

          // Carrega as chaves do Firestore se elas já existirem no documento
          _logoUrlController.text = dadosCrus['logoUrl']?.toString() ?? '';
          _mascoteUrlController.text =
              dadosCrus['mascoteUrl']?.toString() ?? '';
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados do Admin: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🔥 Método para adicionar novos patrocinadores aplicando a trava estrita de 5 itens no rodapé
  void _adicionarPatrocinador() {
    final linkText = _novoPatrocinadorController.text.trim();
    if (linkText.isEmpty) return;

    if (_patrocinadores.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Limite atingido! O rodapé aceita no máximo 5 mídias/patrocinadores. ⚠️',
          ),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() {
      _patrocinadores.add(linkText);
      _novoPatrocinadorController.clear();
    });
  }

  // REGRA 1: Botão explícito de salvar para proteger o limite do Firebase Spark Plan
  Future<void> _salvarDados() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final config = ConfiguracaoWhiteLabelModel(
        id: widget.substituicaoInstituicaoId,
        nome: _nomeController.text.trim(),
        plano: 'Premium',
        corHexadecimal: _corController.text.trim(),
        patrocinadoresUrls: _patrocinadores,
      );

      // Converte o modelo em mapa e anexa as variáveis dinâmicas de Logo e Mascote
      final dadosParaSalvar = config.toMap();
      dadosParaSalvar['logoUrl'] = _logoUrlController.text.trim();
      dadosParaSalvar['mascoteUrl'] = _mascoteUrlController.text.trim();

      await FirebaseFirestore.instance
          .collection('instituicoes')
          .doc(widget.substituicaoInstituicaoId)
          .set(dadosParaSalvar, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas com sucesso! 🎉')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar no banco: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // REGRA 3: Trava estrita de no máximo 5 mídias + Autopreencher / Fallback
    List<String> carrosselExibicao = List.from(_patrocinadores);
    if (carrosselExibicao.isEmpty) {
      carrosselExibicao.addAll([
        'Logo Rumo Quiz',
        'Logo ${widget.substituicaoInstituicaoId}',
      ]);
    }
    if (carrosselExibicao.length > 5) {
      carrosselExibicao = carrosselExibicao.sublist(0, 5);
    }

    return Scaffold(
      // 🛠️ INTEGRAÇÃO DO FIGMA: Substitua pelos componentes globais do seu app
      // drawer: MeuMenuLateralCustomizado(role: 'Admin', nome: 'Administrador'),
      appBar: AppBar(
        title: Text(
          _nomeController.text.isEmpty ? 'Painel Admin' : _nomeController.text,
        ),
        // Se a cor do banco estiver carregada, pinta o cabeçalho dinamicamente
        backgroundColor:
            _corController.text.startsWith('#') &&
                _corController.text.length == 7
            ? Color(int.parse(_corController.text.replaceFirst('#', '0xFF')))
            : Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Text(
                      'Customização White Label',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome da Instituição',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _corController,
                      decoration: const InputDecoration(
                        labelText: 'Cor Primária Hexadecimal (Ex: #1A73E8)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v!.isEmpty) return 'Campo obrigatório';
                        if (!v.startsWith('#') || v.length != 7)
                          return 'Use o padrão #RRGGBB';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 🏢 NOVOS CAMPOS: Configuração de Logo e Mascote Principais (Livres do teto de quantidade)
                    TextFormField(
                      controller: _logoUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL da Logo Principal da Instituição',
                        helperText:
                            'Link da imagem para cabeçalhos e relatórios',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mascoteUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL do Mascote da Instituição',
                        helperText:
                            'Link da imagem do mascote para gamificação',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),

                    const Text(
                      'Gerenciar Rodapé de Patrocinadores (Max 5 marcas)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Input de inserção dinâmica de links de patrocínio
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _novoPatrocinadorController,
                            decoration: const InputDecoration(
                              labelText: 'URL do Patrocinador do Rodapé',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _adicionarPatrocinador,
                          icon: const Icon(Icons.add),
                          tooltip: 'Adicionar ao rodapé',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Preview do Rodapé Atual:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: carrosselExibicao.length,
                        itemBuilder: (context, index) {
                          final itemText = carrosselExibicao[index];
                          final isUrlReal = itemText.startsWith('http');

                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Center(
                                  child: isUrlReal
                                      ? Text(
                                          'Mídia [${index + 1}]',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        )
                                      : Text(itemText),
                                ),
                                if (_patrocinadores.contains(itemText)) ...[
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => setState(
                                      () => _patrocinadores.remove(itemText),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _salvarDados,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Salvar Configurações',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      // 🛠️ INTEGRAÇÃO DO FIGMA: Substitua pelo seu rodapé global passando a lista de mídias travas
      // bottomNavigationBar: MeuRodapeCustomizado(marcas: carrosselExibicao),
    );
  }
}
