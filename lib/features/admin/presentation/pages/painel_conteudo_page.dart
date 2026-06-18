import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../shared/widgets/organisms/menu_lateral_organism.dart';

class PainelConteudoPage extends ConsumerStatefulWidget {
  const PainelConteudoPage({super.key});

  @override
  ConsumerState<PainelConteudoPage> createState() => _PainelConteudoPageState();
}

class _PainelConteudoPageState extends ConsumerState<PainelConteudoPage> {
  // --- CHAVES DOS FORMULÁRIOS ---
  final _formKeyCategoria = GlobalKey<FormState>();
  final _formKeyProva = GlobalKey<FormState>();
  final _formKeyMensagem = GlobalKey<FormState>();

  // --- CONTROLADORES SUBTAREFA 1.1 ---
  final _categoriaController = TextEditingController();
  final _assuntosController = TextEditingController();

  // --- CONTROLADORES SUBTAREFA 1.2 ---
  bool _modoCompleto = false;
  bool _modoAssunto = false;
  final _qtdMaxQuestoesController = TextEditingController(text: '20');
  final _qtdQuestoesDistribuidasController = TextEditingController(text: '0');
  String _erroValidacaoProva = '';

  // --- CONTROLADORES SUBTAREFA 1.3 ---
  final _msgMinAcertosController = TextEditingController(text: '0');
  final _msgMaxAcertosController = TextEditingController(text: '50');
  final _feedbackTextoController = TextEditingController();
  String _mascoteSelecionado = '🦁 Leão Académico';
  PlatformFile? _midiaSelecionada;
  bool _carregandoMidia = false;

  final List<String> _mascotesPreDefinidos = [
    '🦁 Leão Académico',
    '🦉 Coruja Sabichona',
    '🦊 Raposa Estrategista',
    '🐬 Golfinho Gênio',
    'Personalizado (Upload)',
  ];

  @override
  void dispose() {
    _categoriaController.dispose();
    _assuntosController.dispose();
    _qtdMaxQuestoesController.dispose();
    _qtdQuestoesDistribuidasController.dispose();
    _msgMinAcertosController.dispose();
    _msgMaxAcertosController.dispose();
    _feedbackTextoController.dispose();
    super.dispose();
  }

  // --- LÓGICA DA SUBTAREFA 1.2 ---
  void _validarConfiguracaoProva() {
    setState(() {
      _erroValidacaoProva = '';
      if (_modoCompleto && _modoAssunto) {
        _erroValidacaoProva =
            '⚠️ Não é permitido selecionar o Modo Completo e o Modo Assunto simultaneamente.';
        return;
      }
      final maxQuestoes = int.tryParse(_qtdMaxQuestoesController.text) ?? 0;
      final questoesDistribuidas =
          int.tryParse(_qtdQuestoesDistribuidasController.text) ?? 0;

      if (questoesDistribuidas > maxQuestoes) {
        _erroValidacaoProva =
            '❌ A quantidade de questões distribuídas ($questoesDistribuidas) não pode ultrapassar o limite máximo permitido ($maxQuestoes).';
      }
    });
  }

  // --- LÓGICA DA SUBTAREFA 1.1 ---
  Future<void> _salvarCategoria(String tipoAcesso) async {
    if (tipoAcesso != 'Admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⛔ Erro: Apenas Administradores podem criar categorias.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!_formKeyCategoria.currentState!.validate()) return;

    try {
      final listaAssuntos = _assuntosController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      await FirebaseFirestore.instance.collection('categorias').add({
        'nome': _categoriaController.text.trim(),
        'assuntos': listaAssuntos,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎯 Categoria salva!'),
            backgroundColor: Colors.green,
          ),
        );
        _categoriaController.clear();
        _assuntosController.clear();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
    }
  }

  // --- LÓGICA DA SUBTAREFA 1.3 ---
  Future<void> _selecionarMidia() async {
    try {
      final resultado = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (resultado != null && resultado.files.isNotEmpty) {
        final arquivo = resultado.files.first;
        const limiteBytes = 2 * 1024 * 1024; // 2MB

        if (arquivo.size > limiteBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '❌ O tamanho máximo permitido é de 2MB. Seu arquivo tem ${(arquivo.size / (1024 * 1024)).toStringAsFixed(2)}MB.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        setState(() {
          _midiaSelecionada = arquivo;
          _mascoteSelecionado = 'Personalizado (Upload)';
        });
      }
    } catch (e) {
      debugPrint('Erro ao selecionar arquivo: $e');
    }
  }

  Future<void> _salvarRegraFeedback() async {
    if (!_formKeyMensagem.currentState!.validate()) return;
    setState(() => _carregandoMidia = true);

    try {
      String? urlMidiaFinal = _midiaSelecionada != null
          ? 'mock_storage_url_da_imagem'
          : null;

      await FirebaseFirestore.instance.collection('regras_feedback').add({
        'minPorcentagem': int.parse(_msgMinAcertosController.text),
        'maxPorcentagem': int.parse(_msgMaxAcertosController.text),
        'mensagem': _feedbackTextoController.text.trim(),
        'mascote': _mascoteSelecionado,
        'urlMidia': urlMidiaFinal,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Regra e mascote salvos!'),
            backgroundColor: Colors.green,
          ),
        );
        _feedbackTextoController.clear();
        setState(() {
          _midiaSelecionada = null;
          _mascoteSelecionado = _mascotesPreDefinidos.first;
          _msgMinAcertosController.text = '0';
          _msgMaxAcertosController.text = '50';
        });
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
    } finally {
      setState(() => _carregandoMidia = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuarioAsync = ref.watch(usuarioStreamProvider);
    final dadosUsuario = usuarioAsync.value as Map<String, dynamic>?;
    final String tipoAcesso = (dadosUsuario?['role'] ?? 'Acesso')
        .toString()
        .trim();
    final bool eAdmin = tipoAcesso == 'Admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Administrativo de Conteúdo'),
        backgroundColor: eAdmin ? Colors.blue.shade800 : Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // CARD SUBTAREFA 1.1: CATEGORIAS
            // ==========================================
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKeyCategoria,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '📁 Gerenciamento de Categorias',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (!eAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '🔒 Bloqueado p/ Acess2',
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _categoriaController,
                        enabled: eAdmin,
                        decoration: const InputDecoration(
                          labelText: 'Nome da Categoria',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Insira o nome'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _assuntosController,
                        enabled: eAdmin,
                        decoration: const InputDecoration(
                          labelText: 'Assuntos (Separados por vírgula)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Insira os assuntos'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: eAdmin
                              ? () => _salvarCategoria(tipoAcesso)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.save),
                          label: const Text('Salvar Categoria em 1 Etapa'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ==========================================
            // CARD SUBTAREFA 1.2: TIPO DE PROVA
            // ==========================================
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKeyProva,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚙️ Configuração de Tipo de Prova',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      CheckboxListTile(
                        title: const Text(
                          'Modo Completo (Simulado Abrangente)',
                        ),
                        value: _modoCompleto,
                        onChanged: (val) => setState(() {
                          _modoCompleto = val ?? false;
                          _validarConfiguracaoProva();
                        }),
                      ),
                      CheckboxListTile(
                        title: const Text('Modo Assunto (Focado)'),
                        value: _modoAssunto,
                        onChanged: (val) => setState(() {
                          _modoAssunto = val ?? false;
                          _validarConfiguracaoProva();
                        }),
                      ),
                      const Divider(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _qtdMaxQuestoesController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Qtd Máxima Prova',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => _validarConfiguracaoProva(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _qtdQuestoesDistribuidasController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Qtd Distribuída',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => _validarConfiguracaoProva(),
                            ),
                          ),
                        ],
                      ),
                      if (_erroValidacaoProva.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _erroValidacaoProva.contains('❌')
                                ? Colors.red.shade50
                                : Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _erroValidacaoProva,
                            style: TextStyle(
                              color: _erroValidacaoProva.contains('❌')
                                  ? Colors.red.shade900
                                  : Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed:
                              _erroValidacaoProva.isEmpty &&
                                  (_modoCompleto || _modoAssunto)
                              ? () {}
                              : null,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Confirmar Configuração'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ==========================================
            // CARD SUBTAREFA 1.3: MENSAGENS E MASCOTES (AQUI!)
            // ==========================================
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKeyMensagem,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🏆 Mensagens de Desempenho e Mascotes',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _msgMinAcertosController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Acertos Mínimos (%)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _msgMaxAcertosController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Acertos Máximos (%)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _mascoteSelecionado,
                        decoration: const InputDecoration(
                          labelText: 'Selecione o Mascote',
                          border: OutlineInputBorder(),
                        ),
                        items: _mascotesPreDefinidos
                            .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)),
                            )
                            .toList(),
                        onChanged: (val) => setState(
                          () => _mascoteSelecionado =
                              val ?? _mascotesPreDefinidos.first,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _carregandoMidia ? null : _selecionarMidia,
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: Text(
                          _midiaSelecionada == null
                              ? 'Upload de Mídia Customizada (Máx 2MB)'
                              : 'Alterar Mídia (${(_midiaSelecionada!.size / 1024).toStringAsFixed(1)} KB)',
                        ),
                      ),
                      if (_midiaSelecionada != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '📄 Arquivo pronto: ${_midiaSelecionada!.name}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _feedbackTextoController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Mensagem de Feedback Motivacional',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Insira o texto'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _carregandoMidia
                              ? null
                              : _salvarRegraFeedback,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                          ),
                          icon: _carregandoMidia
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_alt),
                          label: Text(
                            _carregandoMidia
                                ? 'A Processar...'
                                : 'Gravar Regra de Feedback',
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
