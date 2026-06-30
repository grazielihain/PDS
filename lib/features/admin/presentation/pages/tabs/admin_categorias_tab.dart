import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rumo_quiz/shared/widgets/tab_page_header.dart';
import '../../providers/admin_provider.dart';

class AdminCategoriasTab extends ConsumerStatefulWidget {
  final String instituicaoId;
  final String roleCriador;
  final Future<void> Function(String, String, String, String, String)
  onAuditoria;

  const AdminCategoriasTab({
    super.key,
    required this.instituicaoId,
    required this.roleCriador,
    required this.onAuditoria,
  });

  @override
  ConsumerState<AdminCategoriasTab> createState() => _AdminCategoriasTabState();
}

class _AdminCategoriasTabState extends ConsumerState<AdminCategoriasTab> {
  bool get _isAdmin => widget.roleCriador == 'Admin';

  late final Stream<QuerySnapshot> _categoriasStream;
  final Map<String, Stream<QuerySnapshot>> _assuntosStreams = {};
  final Map<String, Stream<QuerySnapshot>> _tiposStreams = {};
  final Map<String, bool> _expanded = {};

  @override
  void initState() {
    super.initState();
    _categoriasStream = ref.read(adminDataSourceProvider).streamCategorias(widget.instituicaoId);
  }

  // Cada categoria tem sua própria stream de assuntos para evitar que
  // múltiplos StreamBuilders compartilhem uma broadcast stream e o segundo
  // assinante fique preso em ConnectionState.waiting sem receber dados.
  Stream<QuerySnapshot> _getAssuntosStream(String categoriaId) =>
      _assuntosStreams.putIfAbsent(
        categoriaId,
        () => ref.read(adminDataSourceProvider).streamAssuntos(widget.instituicaoId),
      );

  Stream<QuerySnapshot> _getTiposStream(String categoriaId) =>
      _tiposStreams.putIfAbsent(
        categoriaId,
        () => ref.read(adminDataSourceProvider).streamTiposSimulado(categoriaId, widget.instituicaoId),
      );

  // CRUD CATEGORIAS 
  
  Future<void> _criarCategoria(String nome) async {
    await ref.read(adminDataSourceProvider).criarCategoria(nome, widget.instituicaoId);
    await widget.onAuditoria(
      'CRIAR',
      'Admin / Categorias',
      'Criou a categoria "$nome"',
      'Nenhum',
      '{nome: $nome, instituicaoId: ${widget.instituicaoId}}',
    );
  }

  Future<void> _editarCategoria(String docId, String nomeAntigo, String nomeNovo) async {
    await ref.read(adminDataSourceProvider).editarCategoria(docId, nomeNovo);
    await widget.onAuditoria(
      'ALTERAR',
      'Admin / Categorias',
      'Editou a categoria de "$nomeAntigo" para "$nomeNovo"',
      nomeAntigo,
      nomeNovo,
    );
  }

  Future<void> _excluirCategoria(String docId, String nome) async {
    await ref.read(adminDataSourceProvider).excluirCategoria(docId);
    await widget.onAuditoria(
      'EXCLUIR',
      'Admin / Categorias',
      'Excluiu a categoria "$nome"',
      nome,
      'Excluído',
    );
  }

  // CRUD ASSUNTOS 

  Future<void> _criarAssunto(String categoriaId, String nome) async {
    await ref.read(adminDataSourceProvider).criarAssunto(categoriaId, nome, widget.instituicaoId);
    await widget.onAuditoria(
      'CRIAR',
      'Admin / Assuntos',
      'Criou o assunto "$nome"',
      'Nenhum',
      '{nome: $nome, categoriaId: $categoriaId, instituicaoId: ${widget.instituicaoId}}',
    );
  }

  Future<void> _editarAssunto(String docId, String nomeAntigo, String nomeNovo) async {
    await ref.read(adminDataSourceProvider).editarAssunto(docId, nomeNovo);
    await widget.onAuditoria(
      'ALTERAR',
      'Admin / Assuntos',
      'Editou o assunto de "$nomeAntigo" para "$nomeNovo"',
      nomeAntigo,
      nomeNovo,
    );
  }

  Future<void> _excluirAssunto(String docId, String nome) async {
    await ref.read(adminDataSourceProvider).excluirAssunto(docId);
    await widget.onAuditoria(
      'EXCLUIR',
      'Admin / Assuntos',
      'Excluiu o assunto "$nome"',
      nome,
      'Excluído',
    );
  }

  // CRUD TIPOS SIMULADO 

  Future<void> _criarTipoSimulado(
    String categoriaId,
    Map<String, dynamic> dados,
  ) async {
    final payload = {
      ...dados,
      'categoriaId': categoriaId,
      'instituicaoId': widget.instituicaoId,
    };
    await ref.read(adminDataSourceProvider).criarTipoSimulado(payload);
    await widget.onAuditoria(
      'CRIAR',
      'Admin / Tipos de Simulado',
      'Criou tipo de simulado (modo: ${dados['modo']})',
      'Nenhum',
      payload.toString(),
    );
  }

  Future<void> _editarTipoSimulado(
    String docId,
    Map<String, dynamic> antigo,
    Map<String, dynamic> novo,
  ) async {
    await ref.read(adminDataSourceProvider).editarTipoSimulado(docId, novo);
    await widget.onAuditoria(
      'ALTERAR',
      'Admin / Tipos de Simulado',
      'Editou tipo de simulado (modo: ${novo['modo']})',
      antigo.toString(),
      novo.toString(),
    );
  }

  Future<void> _excluirTipoSimulado(String docId, String descricao) async {
    await ref.read(adminDataSourceProvider).excluirTipoSimulado(docId);
    await widget.onAuditoria(
      'EXCLUIR',
      'Admin / Tipos de Simulado',
      'Excluiu tipo de simulado "$descricao"',
      descricao,
      'Excluído',
    );
  }

  // HELPERS UI 

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // DIALOGS 

  Future<void> _abrirDialogCategoria({String? docId, String? nomeAtual}) async {
    final salvo = await showDialog<bool>(
      context: context,
      builder: (_) => _NomeDialog(
        title: docId == null ? 'Nova Categoria' : 'Editar Categoria',
        nomeAtual: nomeAtual ?? '',
        onSave: (nome) => docId == null
            ? _criarCategoria(nome)
            : _editarCategoria(docId, nomeAtual ?? '', nome),
      ),
    );
    if (salvo == true && mounted) {
      _showSuccess(docId == null ? 'Categoria criada!' : 'Categoria atualizada!');
    }
  }

  Future<void> _abrirDialogAssunto(
    String categoriaId, {
    String? docId,
    String? nomeAtual,
  }) async {
    final salvo = await showDialog<bool>(
      context: context,
      builder: (_) => _NomeDialog(
        title: docId == null ? 'Novo Assunto' : 'Editar Assunto',
        nomeAtual: nomeAtual ?? '',
        onSave: (nome) => docId == null
            ? _criarAssunto(categoriaId, nome)
            : _editarAssunto(docId, nomeAtual ?? '', nome),
      ),
    );
    if (salvo == true && mounted) {
      _showSuccess(docId == null ? 'Assunto criado!' : 'Assunto atualizado!');
    }
  }

  Future<void> _abrirDialogTipoSimulado(
    String categoriaId, {
    String? docId,
    Map<String, dynamic>? dadosAtuais,
  }) async {
    List<QueryDocumentSnapshot> assuntosDisponiveis = [];
    try {
      final snap = await ref
          .read(adminDataSourceProvider)
          .streamAssuntos(widget.instituicaoId)
          .first;
      assuntosDisponiveis = snap.docs
          .where((d) => (d.data() as Map<String, dynamic>)['categoriaId'] == categoriaId)
          .toList();
    } catch (_) {}

    if (!mounted) return;

    final salvo = await showDialog<bool>(
      context: context,
      builder: (_) => _TipoSimuladoDialog(
        isEdit: docId != null,
        dadosAtuais: dadosAtuais,
        assuntosDisponiveis: assuntosDisponiveis,
        onSave: (payload) => docId == null
            ? _criarTipoSimulado(categoriaId, payload)
            : _editarTipoSimulado(docId, dadosAtuais ?? {}, payload),
      ),
    );
    if (salvo == true && mounted) {
      _showSuccess(
          docId == null ? 'Tipo de simulado criado!' : 'Tipo de simulado atualizado!');
    }
  }

  Future<bool> _confirmarExclusao(String mensagem) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    return confirmar ?? false;
  }

  // BUILD 

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tabPageHeader(
          'Categorias',
          'Gerencie as categorias e assuntos do banco de questões.',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isAdmin)
                  FilledButton.icon(
                    onPressed: _abrirDialogCategoria,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nova Categoria'),
                  ),
                if (!_isAdmin)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(
                      'Modo somente leitura. Apenas o Admin pode criar, editar ou excluir.',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: _categoriasStream,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(
                        child: Text('Erro ao carregar: ${snap.error}'),
                      );
                    }
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            'Nenhuma categoria cadastrada.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: docs.map(_buildCategoriaCard).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriaCard(QueryDocumentSnapshot catDoc) {
    final dados = catDoc.data() as Map<String, dynamic>;
    final nome = dados['nome'] ?? 'Sem nome';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const Icon(Icons.folder_outlined),
        onExpansionChanged: (expanded) =>
            setState(() => _expanded[catDoc.id] = expanded),
        title: Row(
          children: [
            Expanded(
              child: Text(
                nome,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (_isAdmin) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Editar categoria',
                onPressed: () => _abrirDialogCategoria(
                  docId: catDoc.id,
                  nomeAtual: nome,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                tooltip: 'Excluir categoria',
                onPressed: () => _onExcluirCategoria(catDoc.id, nome),
              ),
            ],
          ],
        ),
        children: [
          if (_expanded[catDoc.id] == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSecaoAssuntos(catDoc.id),
                  const Divider(height: 32),
                  _buildSecaoTiposSimulado(catDoc.id),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onExcluirCategoria(String docId, String nome) async {
    final ds = ref.read(adminDataSourceProvider);
    final assuntosSnap = await ds.streamAssuntos(widget.instituicaoId).first;
    final tiposSnap = await ds.streamTiposSimulado(docId, widget.instituicaoId).first;

    final assuntosVinculados = assuntosSnap.docs
        .where((d) => (d.data() as Map<String, dynamic>)['categoriaId'] == docId)
        .length;
    final totalVinculados = assuntosVinculados + tiposSnap.docs.length;
    final aviso = totalVinculados > 0
        ? '\n\nATENCAO: Existem $totalVinculados registro(s) vinculado(s) a esta categoria (assuntos e/ou tipos de simulado).'
        : '';

    final ok = await _confirmarExclusao(
      'Deseja excluir a categoria "$nome"?$aviso',
    );
    if (!ok) return;

    try {
      await _excluirCategoria(docId, nome);
      _showSuccess('Categoria excluída.');
    } catch (e) {
      _showError('Erro ao excluir: $e');
    }
  }

  Widget _buildSecaoAssuntos(String categoriaId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Assuntos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            if (_isAdmin)
              TextButton.icon(
                onPressed: () => _abrirDialogAssunto(categoriaId),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Novo Assunto', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: _getAssuntosStream(categoriaId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const LinearProgressIndicator();
            }
            if (snap.hasError) {
              return Text(
                'Erro: ${snap.error}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              );
            }
            final docs = (snap.data?.docs ?? [])
                .where((d) => (d.data() as Map<String, dynamic>)['categoriaId'] == categoriaId)
                .toList();
            if (docs.isEmpty) {
              return const Text(
                'Nenhum assunto cadastrado.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              );
            }
            return Column(
              children: docs.map((doc) {
                final dados = doc.data() as Map<String, dynamic>;
                final nome = dados['nome'] as String? ?? 'Sem nome';
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: const Icon(Icons.label_outline, size: 16),
                  title: Text(nome, style: const TextStyle(fontSize: 13)),
                  trailing: _isAdmin
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              tooltip: 'Editar assunto',
                              onPressed: () => _abrirDialogAssunto(
                                categoriaId,
                                docId: doc.id,
                                nomeAtual: nome,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: Colors.red,
                              ),
                              tooltip: 'Excluir assunto',
                              onPressed: () => _onExcluirAssunto(doc.id, nome),
                            ),
                          ],
                        )
                      : null,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _onExcluirAssunto(String docId, String nome) async {
    try {
      final possuiQuestoes = await ref
          .read(adminDataSourceProvider)
          .assuntoPossuiQuestoes(docId, widget.instituicaoId);
      if (possuiQuestoes) {
        _showError(
          'Não é possível excluir "$nome": existem questões vinculadas. Remova-as antes.',
        );
        return;
      }
    } catch (e) {
      _showError('Erro ao verificar dependências: $e');
      return;
    }

    final ok = await _confirmarExclusao('Deseja excluir o assunto "$nome"?');
    if (!ok) return;
    try {
      await _excluirAssunto(docId, nome);
      _showSuccess('Assunto excluído.');
    } catch (e) {
      _showError('Erro ao excluir: $e');
    }
  }

  Widget _buildSecaoTiposSimulado(String categoriaId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tipos de Simulado',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            if (_isAdmin)
              TextButton.icon(
                onPressed: () => _abrirDialogTipoSimulado(categoriaId),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Novo Tipo', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: _getTiposStream(categoriaId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const LinearProgressIndicator();
            }
            if (snap.hasError) {
              return Text(
                'Erro: ${snap.error}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              );
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Text(
                'Nenhum tipo de simulado cadastrado.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final doc = docs[i];
                final dados = doc.data() as Map<String, dynamic>;
                final modo = dados['modo'] == 'completo'
                    ? 'Prova Completa'
                    : 'Por Assunto';
                final qtd = dados['quantidadeMaxima'] ?? 0;
                final listaAssuntos = List<Map<String, dynamic>>.from(
                  dados['assuntosPorQuantidade'] ?? [],
                );

                return Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      dados['modo'] == 'completo'
                          ? Icons.library_books_outlined
                          : Icons.quiz_outlined,
                      size: 20,
                    ),
                    title: Text(
                      '$modo — Máx. $qtd questões',
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: dados['modo'] == 'completo' && listaAssuntos.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: listaAssuntos.map((a) {
                                final nome = (a['assuntoNome'] as String?)
                                            ?.isNotEmpty ==
                                        true
                                    ? a['assuntoNome'] as String
                                    : a['assuntoId'] as String? ?? '?';
                                final qtdA = a['quantidade'] as int? ?? 0;
                                return Text(
                                  '• $nome: $qtdA ${qtdA == 1 ? 'questão' : 'questões'}',
                                  style: const TextStyle(fontSize: 11),
                                );
                              }).toList(),
                            ),
                          )
                        : null,
                    trailing: _isAdmin
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                tooltip: 'Editar',
                                onPressed: () => _abrirDialogTipoSimulado(
                                  categoriaId,
                                  docId: doc.id,
                                  dadosAtuais: dados,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: Colors.red,
                                ),
                                tooltip: 'Excluir',
                                onPressed: () => _onExcluirTipoSimulado(
                                  doc.id,
                                  '$modo — $qtd questões',
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _onExcluirTipoSimulado(String docId, String descricao) async {
    final ok = await _confirmarExclusao(
      'Deseja excluir o tipo de simulado "$descricao"?',
    );
    if (!ok) return;
    try {
      await _excluirTipoSimulado(docId, descricao);
      _showSuccess('Tipo de simulado excluído.');
    } catch (e) {
      _showError('Erro ao excluir: $e');
    }
  }
}

// Dialog: Nome (Categoria / Assunto)

class _NomeDialog extends StatefulWidget {
  final String title;
  final String nomeAtual;
  final Future<void> Function(String nome) onSave;

  const _NomeDialog({
    required this.title,
    required this.nomeAtual,
    required this.onSave,
  });

  @override
  State<_NomeDialog> createState() => _NomeDialogState();
}

class _NomeDialogState extends State<_NomeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ctrl;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.nomeAtual);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _ctrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo obrigatório' : null,
            ),
            if (_erro != null) ...[
              const SizedBox(height: 8),
              Text(
                _erro!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _salvando
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() {
                    _salvando = true;
                    _erro = null;
                  });
                  try {
                    await widget.onSave(_ctrl.text);
                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context, true);
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        _salvando = false;
                        _erro = 'Erro: $e';
                      });
                    }
                  }
                },
          child: _salvando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}

// Dialog: Tipo de Simulado

class _TipoSimuladoDialog extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? dadosAtuais;
  final List<QueryDocumentSnapshot> assuntosDisponiveis;
  final Future<void> Function(Map<String, dynamic> payload) onSave;

  const _TipoSimuladoDialog({
    required this.isEdit,
    required this.dadosAtuais,
    required this.assuntosDisponiveis,
    required this.onSave,
  });

  @override
  State<_TipoSimuladoDialog> createState() => _TipoSimuladoDialogState();
}

class _TipoSimuladoDialogState extends State<_TipoSimuladoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _qtdCtrl;
  late final Map<String, TextEditingController> _qtdPorAssunto;
  late String _modo;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _modo = widget.dadosAtuais?['modo'] ?? 'assunto';
    _qtdCtrl = TextEditingController(
      text: widget.dadosAtuais?['quantidadeMaxima']?.toString() ?? '',
    );
    final assuntosPorQtd = List<Map<String, dynamic>>.from(
      widget.dadosAtuais?['assuntosPorQuantidade'] ?? [],
    );
    _qtdPorAssunto = {
      for (final a in widget.assuntosDisponiveis)
        a.id: TextEditingController(
          text: assuntosPorQtd
                  .where((e) => e['assuntoId'] == a.id)
                  .firstOrNull?['quantidade']
                  ?.toString() ??
              '',
        ),
    };
  }

  @override
  void dispose() {
    _qtdCtrl.dispose();
    for (final c in _qtdPorAssunto.values) {
      c.dispose();
    }
    super.dispose();
  }

  int get _somaAtual {
    if (_modo != 'completo') return 0;
    return _qtdPorAssunto.values
        .fold(0, (acc, c) => acc + (int.tryParse(c.text) ?? 0));
  }

  Future<void> _onSalvar() async {
    if (!_formKey.currentState!.validate()) return;
    final maxQtd = int.parse(_qtdCtrl.text.trim());

    if (_modo == 'completo') {
      final comQtd = widget.assuntosDisponiveis
          .where((a) => (int.tryParse(_qtdPorAssunto[a.id]?.text ?? '') ?? 0) > 0)
          .length;
      if (comQtd < 2) {
        setState(() =>
            _erro = 'Prova Completa requer pelo menos 2 assuntos com quantidade.');
        return;
      }
      if (_somaAtual != maxQtd) {
        setState(() => _erro =
            'A soma das questões por assunto ($_somaAtual) deve ser igual ao total máximo ($maxQtd).');
        return;
      }
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    final lista = _modo == 'completo'
        ? widget.assuntosDisponiveis
            .where((a) => (int.tryParse(_qtdPorAssunto[a.id]?.text ?? '') ?? 0) > 0)
            .map((a) => {
                  'assuntoId': a.id,
                  'assuntoNome':
                      (a.data() as Map<String, dynamic>)['nome'] ?? '',
                  'quantidade': int.parse(_qtdPorAssunto[a.id]!.text),
                })
            .toList()
        : <Map<String, dynamic>>[];

    final payload = {
      'modo': _modo,
      'quantidadeMaxima': maxQtd,
      'assuntosPorQuantidade': lista,
    };

    try {
      await widget.onSave(payload);
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _salvando = false;
          _erro = 'Erro: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final somaAtual = _somaAtual;
    final maxQtd = int.tryParse(_qtdCtrl.text) ?? 0;
    final excede = maxQtd > 0 && somaAtual > maxQtd;

    return AlertDialog(
      title: Text(widget.isEdit ? 'Editar Tipo de Simulado' : 'Novo Tipo de Simulado'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Modo do Simulado',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              RadioGroup<String>(
                groupValue: _modo,
                onChanged: (v) => setState(() => _modo = v!),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Por Assunto'),
                      value: 'assunto',
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<String>(
                      title: const Text('Prova Completa'),
                      value: 'completo',
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qtdCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Quantidade Máxima *'),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
                  if ((int.tryParse(v) ?? 0) <= 0) return 'Informe um valor positivo';
                  return null;
                },
              ),
              if (_modo == 'completo') ...[
                const SizedBox(height: 16),
                const Text(
                  'Questões por Assunto',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                if (widget.assuntosDisponiveis.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Nenhum assunto cadastrado nesta categoria.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  )
                else ...[
                  ...widget.assuntosDisponiveis.map((a) {
                    final dados = a.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              dados['nome'] ?? a.id,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              controller: _qtdPorAssunto[a.id],
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                hintText: '0',
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Text(
                    'Soma atual: $somaAtual / $maxQtd',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: excede ? Colors.red : Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
              if (_erro != null) ...[
                const SizedBox(height: 8),
                Text(
                  _erro!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _salvando ? null : _onSalvar,
          child: _salvando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
