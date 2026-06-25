import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCategoriasTab extends StatefulWidget {
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
  State<AdminCategoriasTab> createState() => _AdminCategoriasTabState();
}

class _AdminCategoriasTabState extends State<AdminCategoriasTab> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool get _isAdmin => widget.roleCriador == 'Admin';

  // ──────────────────────────── CRUD CATEGORIAS ────────────────────────────

  Future<void> _criarCategoria(String nome) async {
    final existentes = await _db
        .collection('categorias')
        .where('instituicaoId', isEqualTo: widget.instituicaoId)
        .get();
    if (existentes.docs.length >= 20) {
      throw Exception('Limite de 20 categorias por instituição atingido.');
    }
    final ref = _db.collection('categorias').doc();
    final dados = {
      'nome': nome.trim(),
      'instituicaoId': widget.instituicaoId,
      'dataCriacao': FieldValue.serverTimestamp(),
    };
    await ref.set(dados);
    await widget.onAuditoria(
      'CRIAR',
      'Admin / Categorias',
      'Criou a categoria "$nome"',
      'Nenhum',
      dados.toString(),
    );
  }

  Future<void> _editarCategoria(String docId, String nomeAntigo, String nomeNovo) async {
    await _db.collection('categorias').doc(docId).update({
      'nome': nomeNovo.trim(),
    });
    await widget.onAuditoria(
      'ALTERAR',
      'Admin / Categorias',
      'Editou a categoria de "$nomeAntigo" para "$nomeNovo"',
      nomeAntigo,
      nomeNovo,
    );
  }

  Future<void> _excluirCategoria(String docId, String nome) async {
    await _db.collection('categorias').doc(docId).delete();
    await widget.onAuditoria(
      'EXCLUIR',
      'Admin / Categorias',
      'Excluiu a categoria "$nome"',
      nome,
      'Excluído',
    );
  }

  // ──────────────────────────── CRUD ASSUNTOS ──────────────────────────────

  Future<void> _criarAssunto(String categoriaId, String nome) async {
    final existentes = await _db
        .collection('assuntos')
        .where('instituicaoId', isEqualTo: widget.instituicaoId)
        .get();
    if (existentes.docs.length >= 30) {
      throw Exception('Limite de 30 assuntos por instituição atingido.');
    }
    final ref = _db.collection('assuntos').doc();
    final dados = {
      'nome': nome.trim(),
      'categoriaId': categoriaId,
      'instituicaoId': widget.instituicaoId,
      'dataCriacao': FieldValue.serverTimestamp(),
    };
    await ref.set(dados);
    await widget.onAuditoria(
      'CRIAR',
      'Admin / Assuntos',
      'Criou o assunto "$nome"',
      'Nenhum',
      dados.toString(),
    );
  }

  Future<void> _editarAssunto(String docId, String nomeAntigo, String nomeNovo) async {
    await _db.collection('assuntos').doc(docId).update({
      'nome': nomeNovo.trim(),
    });
    await widget.onAuditoria(
      'ALTERAR',
      'Admin / Assuntos',
      'Editou o assunto de "$nomeAntigo" para "$nomeNovo"',
      nomeAntigo,
      nomeNovo,
    );
  }

  Future<void> _excluirAssunto(String docId, String nome) async {
    await _db.collection('assuntos').doc(docId).delete();
    await widget.onAuditoria(
      'EXCLUIR',
      'Admin / Assuntos',
      'Excluiu o assunto "$nome"',
      nome,
      'Excluído',
    );
  }

  // ──────────────────────────── CRUD TIPOS SIMULADO ─────────────────────────

  Future<void> _criarTipoSimulado(
    String categoriaId,
    Map<String, dynamic> dados,
  ) async {
    final ref = _db.collection('tipos_simulado').doc();
    final payload = {
      ...dados,
      'categoriaId': categoriaId,
      'instituicaoId': widget.instituicaoId,
      'dataCriacao': FieldValue.serverTimestamp(),
    };
    await ref.set(payload);
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
    await _db.collection('tipos_simulado').doc(docId).update(novo);
    await widget.onAuditoria(
      'ALTERAR',
      'Admin / Tipos de Simulado',
      'Editou tipo de simulado (modo: ${novo['modo']})',
      antigo.toString(),
      novo.toString(),
    );
  }

  Future<void> _excluirTipoSimulado(String docId, String descricao) async {
    await _db.collection('tipos_simulado').doc(docId).delete();
    await widget.onAuditoria(
      'EXCLUIR',
      'Admin / Tipos de Simulado',
      'Excluiu tipo de simulado "$descricao"',
      descricao,
      'Excluído',
    );
  }

  // ──────────────────────────── HELPERS UI ─────────────────────────────────

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

  // ──────────────────────────── DIALOGS ─────────────────────────────────────

  Future<void> _abrirDialogCategoria({String? docId, String? nomeAtual}) async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController(text: nomeAtual ?? '');
    bool salvando = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(docId == null ? 'Nova Categoria' : 'Editar Categoria'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo obrigatório' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: salvando
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setS(() => salvando = true);
                      try {
                        if (docId == null) {
                          await _criarCategoria(ctrl.text);
                          _showSuccess('Categoria criada!');
                        } else {
                          await _editarCategoria(docId, nomeAtual ?? '', ctrl.text);
                          _showSuccess('Categoria atualizada!');
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        _showError('Erro: $e');
                        setS(() => salvando = false);
                      }
                    },
              child: salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
  }

  Future<void> _abrirDialogAssunto(
    String categoriaId, {
    String? docId,
    String? nomeAtual,
  }) async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController(text: nomeAtual ?? '');
    bool salvando = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(docId == null ? 'Novo Assunto' : 'Editar Assunto'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo obrigatório' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: salvando
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setS(() => salvando = true);
                      try {
                        if (docId == null) {
                          await _criarAssunto(categoriaId, ctrl.text);
                          _showSuccess('Assunto criado!');
                        } else {
                          await _editarAssunto(docId, nomeAtual ?? '', ctrl.text);
                          _showSuccess('Assunto atualizado!');
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        _showError('Erro: $e');
                        setS(() => salvando = false);
                      }
                    },
              child: salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
  }

  Future<void> _abrirDialogTipoSimulado(
    String categoriaId, {
    String? docId,
    Map<String, dynamic>? dadosAtuais,
  }) async {
    final formKey = GlobalKey<FormState>();
    final qtdCtrl = TextEditingController(
      text: dadosAtuais?['quantidadeMaxima']?.toString() ?? '',
    );

    String modo = dadosAtuais?['modo'] ?? 'assunto';
    List<Map<String, dynamic>> assuntosPorQtd = List<Map<String, dynamic>>.from(
      dadosAtuais?['assuntosPorQuantidade'] ?? [],
    );
    bool salvando = false;

    // Carrega assuntos da categoria para o modo 'completo'
    List<QueryDocumentSnapshot> assuntosDisponiveis = [];
    try {
      final snap = await _db
          .collection('assuntos')
          .where('categoriaId', isEqualTo: categoriaId)
          .where('instituicaoId', isEqualTo: widget.instituicaoId)
          .get();
      assuntosDisponiveis = snap.docs;
    } catch (_) {}

    // Mapa de quantidade por assuntoId para modo completo
    final Map<String, TextEditingController> qtdPorAssunto = {};
    for (final a in assuntosDisponiveis) {
      final existente = assuntosPorQtd
          .where((e) => e['assuntoId'] == a.id)
          .toList();
      qtdPorAssunto[a.id] = TextEditingController(
        text: existente.isNotEmpty
            ? existente.first['quantidade'].toString()
            : '',
      );
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          int somaAtual = 0;
          if (modo == 'completo') {
            for (final ctrl in qtdPorAssunto.values) {
              somaAtual += int.tryParse(ctrl.text) ?? 0;
            }
          }

          return AlertDialog(
            title: Text(
              docId == null ? 'Novo Tipo de Simulado' : 'Editar Tipo de Simulado',
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Modo do Simulado',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    RadioGroup<String>(
                      groupValue: modo,
                      onChanged: (v) => setS(() => modo = v!),
                      child: Column(
                        children: const [
                          RadioListTile<String>(
                            title: Text('Por Assunto'),
                            value: 'assunto',
                            contentPadding: EdgeInsets.zero,
                          ),
                          RadioListTile<String>(
                            title: Text('Prova Completa'),
                            value: 'completo',
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: qtdCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Quantidade Máxima *',
                      ),
                      onChanged: (_) => setS(() {}),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Campo obrigatório';
                        }
                        if ((int.tryParse(v) ?? 0) <= 0) {
                          return 'Informe um valor positivo';
                        }
                        return null;
                      },
                    ),
                    if (modo == 'completo') ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Questões por Assunto',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      if (assuntosDisponiveis.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Nenhum assunto cadastrado nesta categoria.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        )
                      else ...[
                        ...assuntosDisponiveis.map((a) {
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
                                    controller: qtdPorAssunto[a.id],
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: '0',
                                      isDense: true,
                                    ),
                                    onChanged: (_) => setS(() {}),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        Builder(builder: (_) {
                          final maxQtd = int.tryParse(qtdCtrl.text) ?? 0;
                          final excede = maxQtd > 0 && somaAtual > maxQtd;
                          return Text(
                            'Soma atual: $somaAtual / $maxQtd',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: excede ? Colors.red : Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          );
                        }),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: salvando
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        final maxQtd = int.parse(qtdCtrl.text.trim());

                        if (modo == 'completo') {
                          final assuntosComQtd = assuntosDisponiveis
                              .where((a) {
                                final v = int.tryParse(
                                  qtdPorAssunto[a.id]?.text ?? '',
                                ) ?? 0;
                                return v > 0;
                              })
                              .toList();

                          if (assuntosComQtd.length < 2) {
                            _showError(
                              'Prova Completa requer pelo menos 2 assuntos com quantidade.',
                            );
                            return;
                          }

                          int soma = 0;
                          for (final a in assuntosDisponiveis) {
                            soma += int.tryParse(
                                  qtdPorAssunto[a.id]?.text ?? '',
                                ) ??
                                0;
                          }
                          if (soma > maxQtd) {
                            _showError(
                              'A soma ($soma) excede a quantidade máxima ($maxQtd).',
                            );
                            return;
                          }
                        }

                        setS(() => salvando = true);

                        final listaAssuntosPorQtd = modo == 'completo'
                            ? assuntosDisponiveis
                                .where((a) {
                                  final v = int.tryParse(
                                    qtdPorAssunto[a.id]?.text ?? '',
                                  ) ?? 0;
                                  return v > 0;
                                })
                                .map((a) => {
                                  'assuntoId': a.id,
                                  'quantidade': int.parse(
                                    qtdPorAssunto[a.id]!.text,
                                  ),
                                })
                                .toList()
                            : <Map<String, dynamic>>[];

                        final payload = {
                          'modo': modo,
                          'quantidadeMaxima': maxQtd,
                          'assuntosPorQuantidade': listaAssuntosPorQtd,
                        };

                        try {
                          if (docId == null) {
                            await _criarTipoSimulado(categoriaId, payload);
                            _showSuccess('Tipo de simulado criado!');
                          } else {
                            await _editarTipoSimulado(
                              docId,
                              dadosAtuais ?? {},
                              payload,
                            );
                            _showSuccess('Tipo de simulado atualizado!');
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          _showError('Erro: $e');
                          setS(() => salvando = false);
                        }
                      },
                child: salvando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );

    qtdCtrl.dispose();
    for (final c in qtdPorAssunto.values) {
      c.dispose();
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

  // ──────────────────────────── BUILD ────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categorias e Conteúdo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isAdmin)
                FilledButton.icon(
                  onPressed: _abrirDialogCategoria,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nova Categoria'),
                ),
            ],
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
            stream: _db
                .collection('categorias')
                .where('instituicaoId', isEqualTo: widget.instituicaoId)
                .snapshots(),
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
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, i) =>
                    _buildCategoriaCard(docs[i]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaCard(QueryDocumentSnapshot catDoc) {
    final dados = catDoc.data() as Map<String, dynamic>;
    final nome = dados['nome'] ?? 'Sem nome';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const Icon(Icons.folder_outlined),
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
    // Verifica se há assuntos ou tipos cadastrados (avisa mas permite)
    final assuntosSnap = await _db
        .collection('assuntos')
        .where('categoriaId', isEqualTo: docId)
        .where('instituicaoId', isEqualTo: widget.instituicaoId)
        .get();
    final tiposSnap = await _db
        .collection('tipos_simulado')
        .where('categoriaId', isEqualTo: docId)
        .where('instituicaoId', isEqualTo: widget.instituicaoId)
        .get();

    final totalVinculados = assuntosSnap.docs.length + tiposSnap.docs.length;
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
          stream: _db
              .collection('assuntos')
              .where('categoriaId', isEqualTo: categoriaId)
              .where('instituicaoId', isEqualTo: widget.instituicaoId)
              .snapshots(),
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
    // Protege exclusão se houver questões vinculadas ao assunto
    try {
      final questoesSnap = await _db
          .collection('questoes')
          .where('assuntoId', isEqualTo: docId)
          .where('instituicaoId', isEqualTo: widget.instituicaoId)
          .get();
      if (questoesSnap.docs.isNotEmpty) {
        _showError(
          'Não é possível excluir "$nome": existem ${questoesSnap.docs.length} questão(ões) vinculadas. Remova-as antes.',
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
          stream: _db
              .collection('tipos_simulado')
              .where('categoriaId', isEqualTo: categoriaId)
              .where('instituicaoId', isEqualTo: widget.instituicaoId)
              .snapshots(),
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
                        ? Text(
                            '${listaAssuntos.length} assuntos configurados',
                            style: const TextStyle(fontSize: 11),
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
