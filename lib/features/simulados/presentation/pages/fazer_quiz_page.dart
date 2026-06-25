import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../providers/simulado_provider.dart';
import '../providers/quiz_session_provider.dart';

class FazerQuizPage extends ConsumerStatefulWidget {
  const FazerQuizPage({super.key});

  @override
  ConsumerState<FazerQuizPage> createState() => _FazerQuizPageState();
}

class _FazerQuizPageState extends ConsumerState<FazerQuizPage> {
  bool _carregandoPerfil = true;
  String? _instituicaoId;

  List<QueryDocumentSnapshot> _categorias = [];
  String? _categoriaSelecionada;

  List<QueryDocumentSnapshot> _tiposSimulado = [];
  String? _tipoSelecionado;
  String _modoProva = 'completa';
  int _qtdMaxima = 10;
  int _tipoQtdMax = 10;

  List<QueryDocumentSnapshot> _assuntosDisponiveis = [];
  String? _assuntoSelecionado;
  int _qtdQuestoes = 10;
  final _qtdController = TextEditingController(text: '10');

  bool _comTempo = false;
  int _tempoMinutos = 60;
  final _tempoController = TextEditingController(text: '60');

  String? _nomeCategoriaSelecionada;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  @override
  void dispose() {
    _qtdController.dispose();
    _tempoController.dispose();
    super.dispose();
  }

  Future<void> _carregarPerfil() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _carregandoPerfil = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      final dados = doc.data();
      _instituicaoId = dados?['instituicaoId'] as String?;

      if (_instituicaoId != null && _instituicaoId!.isNotEmpty) {
        await _carregarCategorias();
      }
    } catch (e) {
      debugPrint('Erro ao carregar perfil: $e');
    } finally {
      setState(() => _carregandoPerfil = false);
    }
  }

  Future<void> _carregarCategorias() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('categorias')
          .where('instituicaoId', isEqualTo: _instituicaoId)
          .get();
      final docs = List<QueryDocumentSnapshot>.from(snap.docs)
        ..sort((a, b) {
          final an = (a.data() as Map<String, dynamic>)['nome'] as String? ?? '';
          final bn = (b.data() as Map<String, dynamic>)['nome'] as String? ?? '';
          return an.compareTo(bn);
        });
      setState(() => _categorias = docs);
    } catch (e) {
      debugPrint('Erro ao carregar categorias: $e');
    }
  }

  Future<void> _aoSelecionarCategoria(String catId) async {
    final catDoc = _categorias.where((d) => d.id == catId).firstOrNull;
    final catNome = catDoc != null
        ? ((catDoc.data() as Map<String, dynamic>)['nome'] as String? ?? catId)
        : catId;

    setState(() {
      _categoriaSelecionada = catId;
      _nomeCategoriaSelecionada = catNome;
      _tiposSimulado = [];
      _tipoSelecionado = null;
      _assuntosDisponiveis = [];
      _assuntoSelecionado = null;
      _modoProva = 'completa';
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('tipos_simulado')
          .where('categoriaId', isEqualTo: catId)
          .where('instituicaoId', isEqualTo: _instituicaoId)
          .get();
      setState(() => _tiposSimulado = snap.docs);
    } catch (e) {
      debugPrint('Erro ao carregar tipos de simulado: $e');
    }
  }

  Future<void> _aoSelecionarTipo(String tipoId) async {
    final doc = _tiposSimulado.firstWhere((d) => d.id == tipoId);
    final dados = doc.data() as Map<String, dynamic>;
    final modo = dados['modo'] as String? ?? 'completa';
    final qtd = (dados['quantidadeMaxima'] as num? ?? 10).toInt();

    setState(() {
      _tipoSelecionado = tipoId;
      _modoProva = modo;
      _tipoQtdMax = qtd > 0 ? qtd : 10;
      _qtdMaxima = _tipoQtdMax;
      _qtdQuestoes = _qtdMaxima;
      _qtdController.text = '$_qtdQuestoes';
      _assuntosDisponiveis = [];
      _assuntoSelecionado = null;
      _comTempo = false;
      _tempoMinutos = 60;
      _tempoController.text = '60';
    });

    if (modo == 'assunto') {
      await _carregarAssuntos();
    }
  }

  Future<void> _carregarAssuntos() async {
    if (_instituicaoId == null || _categoriaSelecionada == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('assuntos')
          .where('categoriaId', isEqualTo: _categoriaSelecionada)
          .where('instituicaoId', isEqualTo: _instituicaoId)
          .get();
      final docs = List<QueryDocumentSnapshot>.from(snap.docs)
        ..sort((a, b) {
          final an = (a.data() as Map<String, dynamic>)['nome'] as String? ?? '';
          final bn = (b.data() as Map<String, dynamic>)['nome'] as String? ?? '';
          return an.compareTo(bn);
        });
      setState(() {
        _assuntosDisponiveis = docs;
        if (docs.isNotEmpty) _aoSelecionarAssunto(docs.first.id);
      });
    } catch (e) {
      debugPrint('Erro ao carregar assuntos: $e');
    }
  }

  void _aoSelecionarAssunto(String assuntoId) {
    setState(() => _assuntoSelecionado = assuntoId);
    final questoesAsync = ref.read(listaQuestoesFirestoreProvider(_instituicaoId!));
    questoesAsync.whenData((questoes) {
      final count = questoes.where((q) =>
        q.categoriaId == _categoriaSelecionada && q.assuntoId == assuntoId,
      ).length;
      if (mounted) {
        setState(() {
          _qtdMaxima = count > 0
              ? (_tipoQtdMax > 0 ? _tipoQtdMax.clamp(1, count) : count)
              : 0;
          _qtdQuestoes = _qtdMaxima;
          _qtdController.text = '$_qtdQuestoes';
        });
      }
    });
  }

  void _iniciarQuiz() {
    if (_instituicaoId == null || _categoriaSelecionada == null || _tipoSelecionado == null) return;
    if (_modoProva == 'assunto' && _assuntoSelecionado == null) return;

    final questoesAsync = ref.read(listaQuestoesFirestoreProvider(_instituicaoId!));

    questoesAsync.when(
      data: (questoes) {
        // Verifica se há questões para a seleção específica
        final questoesFiltradas = questoes.where((q) {
          final bCat = q.categoriaId == _categoriaSelecionada;
          if (_modoProva == 'assunto' && _assuntoSelecionado != null) {
            return bCat && q.assuntoId == _assuntoSelecionado;
          }
          return bCat;
        }).toList();

        if (questoesFiltradas.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _modoProva == 'assunto'
                    ? 'Nenhuma questão cadastrada para este assunto. Contate o administrador.'
                    : 'Nenhuma questão cadastrada para esta categoria. Contate o administrador.',
              ),
              backgroundColor: Colors.orange.shade700,
            ),
          );
          return;
        }

        final qtd = _modoProva == 'assunto'
            ? (int.tryParse(_qtdController.text) ?? _qtdQuestoes).clamp(1, _qtdMaxima)
            : _qtdQuestoes;

        ref.read(quizSessionProvider.notifier).iniciarSimulado(
          categoriaId: _categoriaSelecionada!,
          categoriaNome: _nomeCategoriaSelecionada ?? _categoriaSelecionada!,
          modoProva: _modoProva,
          assunto: _modoProva == 'assunto' ? _assuntoSelecionado : null,
          questoesDisponiveisNoBanco: questoes,
          qtdSolicitada: qtd,
          tempoMinutos: _comTempo ? _tempoMinutos : null,
        );

        context.go('/executar-simulado');
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aguarde — carregando questões...')),
        );
      },
      error: (e, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar questões: $e')),
        );
      },
    );
  }

  bool get _podeContinuar {
    if (_tipoSelecionado == null) return false;
    if (_modoProva == 'assunto') {
      return _assuntoSelecionado != null && _qtdMaxima > 0;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_carregandoPerfil) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_instituicaoId == null || _instituicaoId!.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('Instituição não encontrada no cadastro do usuário.'),
        ),
      );
    }

    // Pre-fetch questions while user is configuring (free background load)
    ref.watch(listaQuestoesFirestoreProvider(_instituicaoId!));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configurar Quiz',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Escolha as opções abaixo para iniciar sua prova.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  // PASSO 1: Categoria
                  _buildStepCard(
                    step: '1',
                    title: 'Categoria',
                    child: _categorias.isEmpty
                        ? Text(
                            'Nenhuma categoria disponível para sua instituição.',
                            style: TextStyle(color: Colors.grey.shade500),
                          )
                        : DropdownButtonFormField<String>(
                            key: const ValueKey('cat_dropdown'),
                            initialValue: _categoriaSelecionada,
                            decoration: _inputDecoration('Selecione a categoria'),
                            hint: const Text('Selecione a categoria'),
                            isExpanded: true,
                            items: _categorias.map((doc) {
                              final d = doc.data() as Map<String, dynamic>;
                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text(d['nome'] as String? ?? doc.id),
                              );
                            }).toList(),
                            onChanged: (id) {
                              if (id != null) _aoSelecionarCategoria(id);
                            },
                          ),
                  ),

                  // PASSO 2: Modo de prova
                  if (_categoriaSelecionada != null) ...[
                    const SizedBox(height: 16),
                    _buildStepCard(
                      step: '2',
                      title: 'Modo de Prova',
                      child: _tiposSimulado.isEmpty
                          ? Text(
                              'Nenhum tipo de prova cadastrado para esta categoria.',
                              style: TextStyle(color: Colors.grey.shade500),
                            )
                          : DropdownButtonFormField<String>(
                              key: ValueKey('tipo_$_categoriaSelecionada'),
                              initialValue: _tipoSelecionado,
                              decoration: _inputDecoration('Selecione o modo de prova'),
                              hint: const Text('Selecione o modo de prova'),
                              isExpanded: true,
                              items: _tiposSimulado.map((doc) {
                                final d = doc.data() as Map<String, dynamic>;
                                final modo = d['modo'] as String? ?? 'completa';
                                final qtd = d['quantidadeMaxima'] ?? 0;
                                return DropdownMenuItem<String>(
                                  value: doc.id,
                                  child: Text(
                                    '${modo == 'assunto' ? 'Por Assunto' : 'Prova Completa'} — Máx. $qtd questões',
                                  ),
                                );
                              }).toList(),
                              onChanged: (id) {
                                if (id != null) _aoSelecionarTipo(id);
                              },
                            ),
                    ),
                  ],

                  // PASSO 3: Assunto e Quantidade (somente modo assunto)
                  if (_tipoSelecionado != null && _modoProva == 'assunto') ...[
                    const SizedBox(height: 16),
                    _buildStepCard(
                      step: '3',
                      title: 'Assunto e Quantidade',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _assuntosDisponiveis.isEmpty
                              ? Text(
                                  'Nenhum assunto disponível para esta categoria.',
                                  style: TextStyle(color: Colors.grey.shade500),
                                )
                              : DropdownButtonFormField<String>(
                                  key: ValueKey('assunto_$_tipoSelecionado'),
                                  initialValue: _assuntoSelecionado,
                                  decoration: _inputDecoration('Selecione o assunto'),
                                  isExpanded: true,
                                  items: _assuntosDisponiveis.map((doc) {
                                    final d = doc.data() as Map<String, dynamic>;
                                    return DropdownMenuItem<String>(
                                      value: doc.id,
                                      child: Text(d['nome'] as String? ?? doc.id),
                                    );
                                  }).toList(),
                                  onChanged: (id) {
                                    if (id != null) _aoSelecionarAssunto(id);
                                  },
                                ),
                          const SizedBox(height: 20),
                          if (_qtdMaxima == 0 && _assuntoSelecionado != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: Colors.orange.shade700, size: 18),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Nenhuma questão cadastrada para este assunto. Contate o administrador.',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (_assuntoSelecionado != null) ...[
                            TextFormField(
                              controller: _qtdController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: _inputDecoration('Quantidade de questões').copyWith(
                                labelText: 'Quantidade de questões',
                                helperText: 'Máximo disponível: $_qtdMaxima questões',
                                helperStyle: TextStyle(color: Colors.grey.shade600),
                              ),
                              onChanged: (v) {
                                final n = int.tryParse(v) ?? 1;
                                setState(() {
                                  _qtdQuestoes = n.clamp(1, _qtdMaxima);
                                  if (n > _qtdMaxima) {
                                    _qtdController.text = '$_qtdMaxima';
                                    _qtdController.selection = TextSelection.fromPosition(
                                      TextPosition(offset: _qtdController.text.length),
                                    );
                                  }
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Tempo de Prova — disponível para qualquer tipo/modo
                  if (_tipoSelecionado != null) ...[
                    const SizedBox(height: 16),
                    _buildStepCard(
                      step: _modoProva == 'assunto' ? '4' : '3',
                      title: 'Tempo de Prova',
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: _comTempo,
                            onChanged: (v) => setState(() => _comTempo = v),
                            title: const Text('Prova com cronômetro'),
                            subtitle: Text(
                              _comTempo
                                  ? 'Cronômetro regressivo ativado'
                                  : 'Sem limite de tempo',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (_comTempo) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _tempoController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: _inputDecoration('').copyWith(
                                labelText: 'Minutos de prova',
                                helperText: 'Mínimo: 5 minutos. Sem limite máximo.',
                                helperStyle: TextStyle(color: Colors.grey.shade600),
                                suffixText: 'min',
                              ),
                              onChanged: (v) {
                                final n = int.tryParse(v) ?? 5;
                                setState(() => _tempoMinutos = n < 5 ? 5 : n);
                              },
                              validator: (v) {
                                final n = int.tryParse(v ?? '') ?? 0;
                                if (n < 5) return 'O tempo mínimo é de 5 minutos';
                                return null;
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_circle_filled, size: 22),
                      label: const Text(
                        'Iniciar Prova',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: _podeContinuar ? _iniciarQuiz : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String step,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E3A8A),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  step,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}
