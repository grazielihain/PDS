import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_provider.dart';

class AdminGamificacaoTab extends ConsumerStatefulWidget {
  final String instituicaoId;
  final Future<void> Function(String, String, String, String, String)
  onAuditoria;

  const AdminGamificacaoTab({
    super.key,
    required this.instituicaoId,
    required this.onAuditoria,
  });

  @override
  ConsumerState<AdminGamificacaoTab> createState() => _AdminGamificacaoTabState();
}

class _AdminGamificacaoTabState extends ConsumerState<AdminGamificacaoTab> {
  // ── Controle de formulário ──────────────────────────────────────────────────
  bool _mostrarFormulario = false;
  String? _editandoId;

  final _formKey = GlobalKey<FormState>();
  final _pontosController = TextEditingController();

  // Dados dos dropdowns (formulário — filtrados por categoria selecionada)
  List<QueryDocumentSnapshot> _categorias = [];
  List<QueryDocumentSnapshot> _tiposSimulado = [];
  List<QueryDocumentSnapshot> _assuntos = [];

  // Caches completos para resolver nomes nos cards da lista
  List<QueryDocumentSnapshot> _todosTiposSimulado = [];
  List<QueryDocumentSnapshot> _todosAssuntos = [];

  String? _categoriaSelecionadaId;
  String? _tipoSimuladoSelecionadoId;
  String? _assuntoSelecionadoId;
  String? _modoTipoSimulado; // 'assunto' | 'completo'

  bool _carregandoCategorias = false;
  bool _carregandoTipos = false;
  bool _carregandoAssuntos = false;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
    _carregarTodosParaLabels();
  }

  @override
  void dispose() {
    _pontosController.dispose();
    super.dispose();
  }

  // ── Carregamentos ───────────────────────────────────────────────────────────

  Future<void> _carregarCategorias() async {
    setState(() => _carregandoCategorias = true);
    try {
      final snap = await ref
          .read(adminDataSourceProvider)
          .streamCategorias(widget.instituicaoId)
          .first;
      if (mounted) setState(() => _categorias = snap.docs);
    } catch (e) {
      _mostrarErro('Erro ao carregar categorias: $e');
    } finally {
      if (mounted) setState(() => _carregandoCategorias = false);
    }
  }

  Future<void> _carregarTodosParaLabels() async {
    try {
      final ds = ref.read(adminDataSourceProvider);
      final results = await Future.wait([
        ds.streamTiposSimulado('').first,
        ds.streamAssuntos(widget.instituicaoId).first,
      ]);
      // tipos_simulado filtrado por instituição não existe no datasource diretamente;
      // usamos stream de categorias para obter todos via query separada
      final tiposSnap = await ds.streamCategorias(widget.instituicaoId).first;
      final List<QueryDocumentSnapshot> todosTipos = [];
      for (final cat in tiposSnap.docs) {
        final tipos = await ds.streamTiposSimulado(cat.id).first;
        todosTipos.addAll(tipos.docs);
      }
      if (mounted) {
        setState(() {
          _todosTiposSimulado = todosTipos;
          _todosAssuntos = results[1].docs;
        });
      }
    } catch (_) {}
  }

  Future<void> _carregarTiposSimulado(String categoriaId) async {
    setState(() {
      _carregandoTipos = true;
      _tiposSimulado = [];
      _tipoSimuladoSelecionadoId = null;
      _modoTipoSimulado = null;
      _assuntos = [];
      _assuntoSelecionadoId = null;
    });
    try {
      final snap = await ref
          .read(adminDataSourceProvider)
          .streamTiposSimulado(categoriaId)
          .first;
      if (mounted) setState(() => _tiposSimulado = snap.docs);
    } catch (e) {
      _mostrarErro('Erro ao carregar tipos de simulado: $e');
    } finally {
      if (mounted) setState(() => _carregandoTipos = false);
    }
  }

  Future<void> _carregarAssuntos(String categoriaId) async {
    setState(() {
      _carregandoAssuntos = true;
      _assuntos = [];
      _assuntoSelecionadoId = null;
    });
    try {
      final snap = await ref
          .read(adminDataSourceProvider)
          .streamAssuntos(widget.instituicaoId)
          .first;
      if (mounted) {
        setState(() {
          _assuntos = snap.docs
              .where((d) => (d.data() as Map<String, dynamic>)['categoriaId'] == categoriaId)
              .toList();
        });
      }
    } catch (e) {
      _mostrarErro('Erro ao carregar assuntos: $e');
    } finally {
      if (mounted) setState(() => _carregandoAssuntos = false);
    }
  }

  // ── Formulário ──────────────────────────────────────────────────────────────

  void _abrirFormularioNovo() {
    _limparFormulario();
    setState(() => _mostrarFormulario = true);
  }

  void _abrirFormularioEdicao(DocumentSnapshot doc) {
    final dados = doc.data() as Map<String, dynamic>;
    _editandoId = doc.id;
    _pontosController.text = (dados['pontosBonus'] ?? 1).toString();

    _categoriaSelecionadaId = dados['categoriaId'] as String?;
    _tipoSimuladoSelecionadoId = dados['tipoSimuladoId'] as String?;
    _modoTipoSimulado = dados['modo'] as String?;
    _assuntoSelecionadoId = dados['assuntoId'] as String?;

    // Recarrega listas dependentes para preencher corretamente os dropdowns
    if (_categoriaSelecionadaId != null) {
      _carregarTiposSimuladoParaEdicao(_categoriaSelecionadaId!, dados);
    }

    setState(() => _mostrarFormulario = true);
  }

  Future<void> _carregarTiposSimuladoParaEdicao(
    String categoriaId,
    Map<String, dynamic> dados,
  ) async {
    setState(() => _carregandoTipos = true);
    try {
      final ds = ref.read(adminDataSourceProvider);
      final snapTipos = await ds.streamTiposSimulado(categoriaId).first;

      List<QueryDocumentSnapshot> assuntosDocs = [];
      if ((dados['modo'] as String?) == 'assunto') {
        final snapAssuntos = await ds.streamAssuntos(widget.instituicaoId).first;
        assuntosDocs = snapAssuntos.docs
            .where((d) => (d.data() as Map<String, dynamic>)['categoriaId'] == categoriaId)
            .toList();
      }

      if (mounted) {
        setState(() {
          _tiposSimulado = snapTipos.docs;
          _assuntos = assuntosDocs;
        });
      }
    } catch (e) {
      _mostrarErro('Erro ao carregar dados para edição: $e');
    } finally {
      if (mounted) setState(() => _carregandoTipos = false);
    }
  }

  void _limparFormulario() {
    _editandoId = null;
    _pontosController.clear();
    _categoriaSelecionadaId = null;
    _tipoSimuladoSelecionadoId = null;
    _modoTipoSimulado = null;
    _assuntoSelecionadoId = null;
    _tiposSimulado = [];
    _assuntos = [];
  }

  void _cancelarFormulario() {
    _limparFormulario();
    setState(() => _mostrarFormulario = false);
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_categoriaSelecionadaId == null) {
      _mostrarErro('Selecione uma categoria.');
      return;
    }
    if (_tipoSimuladoSelecionadoId == null) {
      _mostrarErro('Selecione um tipo de simulado.');
      return;
    }
    if (_modoTipoSimulado == 'assunto' && _assuntoSelecionadoId == null) {
      _mostrarErro('Selecione um assunto.');
      return;
    }

    setState(() => _salvando = true);
    try {
      final dados = {
        'instituicaoId': widget.instituicaoId,
        'categoriaId': _categoriaSelecionadaId,
        'tipoSimuladoId': _tipoSimuladoSelecionadoId,
        'modo': _modoTipoSimulado,
        'assuntoId':
            _modoTipoSimulado == 'assunto' ? _assuntoSelecionadoId : null,
        'pontosBonus': int.parse(_pontosController.text.trim()),
      };

      if (_editandoId != null) {
        final snap = await ref
            .read(adminDataSourceProvider)
            .streamGamificacao(widget.instituicaoId)
            .first;
        final docAntigo = snap.docs.where((d) => d.id == _editandoId).firstOrNull;
        await ref.read(adminDataSourceProvider).editarRegraGamificacao(_editandoId!, dados);

        await widget.onAuditoria(
          'ALTERAR',
          'Admin Gamificação',
          'Editou regra de gamificação (${_pontosController.text} pontos)',
          docAntigo?.data()?.toString() ?? 'Nenhum',
          dados.toString(),
        );
      } else {
        await ref.read(adminDataSourceProvider).criarRegraGamificacao(dados);

        await widget.onAuditoria(
          'CRIAR',
          'Admin Gamificação',
          'Criou regra de gamificação (${_pontosController.text} pontos bônus)',
          'Nenhum (Novo Registro)',
          dados.toString(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Regra salva com sucesso!')),
        );
        _cancelarFormulario();
      }
    } catch (e) {
      _mostrarErro('Erro ao salvar regra: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _excluir(DocumentSnapshot doc) async {
    final dados = doc.data() as Map<String, dynamic>;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text(
          'Excluir esta regra de gamificação?\n\n'
          'Atenção: pontuação já acumulada pelos alunos não será afetada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    try {
      await ref.read(adminDataSourceProvider).excluirRegraGamificacao(doc.id);
      await widget.onAuditoria(
        'EXCLUIR',
        'Admin Gamificação',
        'Excluiu regra de gamificação',
        dados.toString(),
        'Registro removido',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Regra excluída.')));
      }
    } catch (e) {
      _mostrarErro('Erro ao excluir: $e');
    }
  }

  void _mostrarErro(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Helpers de label ────────────────────────────────────────────────────────

  String _labelCategoria(String id) {
    final doc = _categorias.where((d) => d.id == id).firstOrNull;
    if (doc == null) return id;
    final dados = doc.data() as Map<String, dynamic>;
    return dados['nome'] as String? ?? id;
  }

  String _labelTipoSimulado(String id) {
    final doc = _todosTiposSimulado.where((d) => d.id == id).firstOrNull;
    if (doc == null) return id;
    final dados = doc.data() as Map<String, dynamic>;
    final modo = dados['modo'] as String? ?? 'completo';
    final qtd = dados['quantidadeMaxima'] ?? 0;
    return '${modo == 'completo' ? 'Prova Completa' : 'Por Assunto'} — Máx. $qtd';
  }

  String _labelAssunto(String id) {
    final doc = _todosAssuntos.where((d) => d.id == id).firstOrNull;
    if (doc == null) return id;
    final dados = doc.data() as Map<String, dynamic>;
    return dados['nome'] as String? ?? id;
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Regras de Gamificação',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (!_mostrarFormulario) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _abrirFormularioNovo,
              icon: const Icon(Icons.add),
              label: const Text('Nova Regra'),
            ),
          ],
          const SizedBox(height: 12),

          if (_mostrarFormulario) _buildFormulario(),

          const SizedBox(height: 16),

          _buildLista(),
        ],
      ),
    );
  }

  Widget _buildFormulario() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _editandoId == null ? 'Nova Regra de Pontos' : 'Editar Regra',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Dropdown Categoria
              _carregandoCategorias
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _categoriaSelecionadaId, // controlled dropdown — initialValue would break reactive updates
                      decoration: const InputDecoration(
                        labelText: 'Categoria *',
                      ),
                      items: _categorias.map((doc) {
                        final dados = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text(dados['nome'] as String? ?? doc.id),
                        );
                      }).toList(),
                      onChanged: (id) {
                        if (id == null) return;
                        setState(() => _categoriaSelecionadaId = id);
                        _carregarTiposSimulado(id);
                      },
                      validator: (v) =>
                          v == null ? 'Selecione uma categoria' : null,
                    ),
              const SizedBox(height: 12),

              // Dropdown Tipo de Simulado (dependente de categoria)
              if (_categoriaSelecionadaId != null)
                _carregandoTipos
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: _tipoSimuladoSelecionadoId, // controlled dropdown
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Simulado *',
                        ),
                        items: _tiposSimulado.map((doc) {
                          final dados = doc.data() as Map<String, dynamic>;
                          final modo = dados['modo'] as String? ?? 'completo';
                          final qtd = dados['quantidadeMaxima'] ?? 0;
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text('${modo == 'completo' ? 'Prova Completa' : 'Por Assunto'} — Máx. $qtd'),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id == null) return;
                          final doc =
                              _tiposSimulado.where((d) => d.id == id).first;
                          final dados = doc.data() as Map<String, dynamic>;
                          final modo = dados['modo'] as String? ?? 'completo';
                          setState(() {
                            _tipoSimuladoSelecionadoId = id;
                            _modoTipoSimulado = modo;
                            _assuntoSelecionadoId = null;
                          });
                          if (modo == 'assunto') {
                            _carregarAssuntos(_categoriaSelecionadaId!);
                          } else {
                            setState(() {
                              _assuntos = [];
                              _assuntoSelecionadoId = null;
                            });
                          }
                        },
                        validator: (v) =>
                            v == null ? 'Selecione um tipo de simulado' : null,
                      ),

              // Dropdown Assunto (somente quando modo == 'assunto')
              if (_modoTipoSimulado == 'assunto') ...[
                const SizedBox(height: 12),
                _carregandoAssuntos
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: _assuntoSelecionadoId, // controlled dropdown
                        decoration: const InputDecoration(
                          labelText: 'Assunto *',
                        ),
                        items: _assuntos.map((doc) {
                          final dados = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text(dados['nome'] as String? ?? doc.id),
                          );
                        }).toList(),
                        onChanged: (id) =>
                            setState(() => _assuntoSelecionadoId = id),
                        validator: (v) =>
                            v == null ? 'Selecione um assunto' : null,
                      ),
              ],

              const SizedBox(height: 12),

              // Campo Pontos Bônus
              TextFormField(
                controller: _pontosController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Pontos de Bônus *',
                  hintText: 'Ex: 10',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 1) return 'Mínimo 1 ponto';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Nota informativa
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.amber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Alterar esta regra não afeta pontuação já acumulada pelos alunos.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Botões
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _salvando ? null : _cancelarFormulario,
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _salvando ? null : _salvar,
                    child: _salvando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _editandoId == null ? 'Criar Regra' : 'Atualizar',
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLista() {
    return StreamBuilder<QuerySnapshot>(
      stream: ref
          .read(adminDataSourceProvider)
          .streamGamificacao(widget.instituicaoId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Erro ao carregar regras: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final rawDocs = snapshot.data?.docs ?? [];
        final docs = List<QueryDocumentSnapshot>.from(rawDocs)
          ..sort((a, b) {
            final aTs = (a.data() as Map<String, dynamic>)['dataCriacao'] as Timestamp?;
            final bTs = (b.data() as Map<String, dynamic>)['dataCriacao'] as Timestamp?;
            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return bTs.compareTo(aTs);
          });
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Nenhuma regra de gamificação cadastrada.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final dados = doc.data() as Map<String, dynamic>;
            final pontos = dados['pontosBonus'] ?? 0;
            final modo = dados['modo'] as String? ?? 'completo';
            final catId = dados['categoriaId'] as String? ?? '';
            final tipoId = dados['tipoSimuladoId'] as String? ?? '';
            final assId = dados['assuntoId'] as String?;
            final ts = dados['dataCriacao'] as Timestamp?;
            final dataStr = ts != null
                ? ts.toDate().toLocal().toString().substring(0, 16)
                : '--';

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    '$pontos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                title: Text(
                  _labelCategoria(catId),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tipo: ${_labelTipoSimulado(tipoId)}'
                      ' • Modo: ${modo == 'assunto' ? 'Por assunto' : 'Completo'}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (modo == 'assunto' && assId != null)
                      Text(
                        'Assunto: ${_labelAssunto(assId)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    Text(
                      'Criado em: $dataStr',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                      tooltip: 'Editar',
                      onPressed: () => _abrirFormularioEdicao(doc),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      tooltip: 'Excluir',
                      onPressed: () => _excluir(doc),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
