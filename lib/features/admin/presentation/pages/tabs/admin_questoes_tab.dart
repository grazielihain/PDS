// ignore_for_file: deprecated_member_use
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_provider.dart';

class AdminQuestoesTab extends ConsumerStatefulWidget {
  final String instituicaoId;
  final String roleCriador;
  final Future<void> Function(String, String, String, String, String)
      onAuditoria;

  const AdminQuestoesTab({
    super.key,
    required this.instituicaoId,
    required this.roleCriador,
    required this.onAuditoria,
  });

  @override
  ConsumerState<AdminQuestoesTab> createState() => _AdminQuestoesTabState();
}

class _AdminQuestoesTabState extends ConsumerState<AdminQuestoesTab> {
  final _auth = FirebaseAuth.instance;

  // Filtros
  bool _apenasMinhas = false;
  String? _filtroCategId;
  String? _filtroAssuntoId;

  // Categorias e assuntos para filtros e labels de cards
  List<Map<String, dynamic>> _categorias = [];
  List<Map<String, dynamic>> _assuntosFiltro = [];
  List<Map<String, dynamic>> _todosAssuntos = [];

  // Formulário visível
  bool _formularioAberto = false;
  bool _salvando = false;

  // Dados do formulário
  final _formKey = GlobalKey<FormState>();
  String? _editandoId;
  String? _formCategoriaId;
  String? _formAssuntoId;
  final _refController = TextEditingController();
  final _textoController = TextEditingController();
  final _justificativaController = TextEditingController();
  final _pontosController = TextEditingController(text: '1');
  List<TextEditingController> _alternativasControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  int? _respostaCorretaIndex;
  List<Map<String, dynamic>> _assuntosForm = [];

  // Imagens
  List<String> _imagensExistentes = [];
  List<_ImagemPendente> _imagensPendentes = [];

  late Stream<QuerySnapshot> _questoesStream;

  @override
  void initState() {
    super.initState();
    _questoesStream = _buildQuestoesStream();
    _carregarCategorias();
    _carregarTodosAssuntos();
  }

  Stream<QuerySnapshot> _buildQuestoesStream() {
    final uid = _auth.currentUser?.uid ?? '';
    return ref.read(adminDataSourceProvider).streamQuestoes(
      instituicaoId: widget.instituicaoId,
      categoriaId: _filtroCategId,
      assuntoId: _filtroAssuntoId,
      criadoPor: _apenasMinhas ? uid : null,
    );
  }

  @override
  void dispose() {
    _refController.dispose();
    _textoController.dispose();
    _justificativaController.dispose();
    _pontosController.dispose();
    for (final c in _alternativasControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _carregarTodosAssuntos() async {
    try {
      final snap = await ref
          .read(adminDataSourceProvider)
          .streamAssuntos(widget.instituicaoId)
          .first;
      if (mounted) {
        setState(() {
          _todosAssuntos = snap.docs
              .map((d) => {'id': d.id, 'nome': (d.data() as Map<String, dynamic>)['nome'] ?? d.id})
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _carregarCategorias() async {
    try {
      final snap = await ref
          .read(adminDataSourceProvider)
          .streamCategorias(widget.instituicaoId)
          .first;
      if (mounted) {
        setState(() {
          _categorias = snap.docs
              .map((d) => {'id': d.id, 'nome': (d.data() as Map<String, dynamic>)['nome'] ?? d.id})
              .toList();
        });
      }
    } catch (e) {
      _mostrarErro('Erro ao carregar categorias: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _carregarAssuntos(
      String categoriaId) async {
    final snap = await ref
        .read(adminDataSourceProvider)
        .streamAssuntos(widget.instituicaoId)
        .first;
    return snap.docs
        .where((d) => (d.data() as Map<String, dynamic>)['categoriaId'] == categoriaId)
        .map((d) => {'id': d.id, 'nome': (d.data() as Map<String, dynamic>)['nome'] ?? d.id})
        .toList();
  }

  void _mostrarErro(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _mostrarSucesso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  void _abrirFormularioNovo() {
    _limparFormulario();
    setState(() => _formularioAberto = true);
  }

  void _limparFormulario() {
    _editandoId = null;
    _formCategoriaId = null;
    _formAssuntoId = null;
    _refController.clear();
    _textoController.clear();
    _justificativaController.clear();
    _pontosController.text = '1';
    for (final c in _alternativasControllers) {
      c.dispose();
    }
    _alternativasControllers = [
      TextEditingController(),
      TextEditingController(),
    ];
    _respostaCorretaIndex = null;
    _assuntosForm = [];
    _imagensExistentes = [];
    _imagensPendentes = [];
  }

  Future<void> _abrirFormularioEditar(
      String id, Map<String, dynamic> dados) async {
    _limparFormulario();
    _editandoId = id;
    _formCategoriaId = dados['categoriaId'] as String?;
    _formAssuntoId = dados['assuntoId'] as String?;
    _refController.text = dados['referencia'] ?? '';
    _textoController.text = dados['texto'] ?? '';
    _justificativaController.text = dados['justificativa'] ?? '';
    _pontosController.text = (dados['pontos'] ?? 1).toString();
    _respostaCorretaIndex = dados['respostaCorretaIndex'] as int?;
    _imagensExistentes = List<String>.from(dados['imagens'] ?? []);

    final alts = List<String>.from(dados['alternativas'] ?? ['', '']);
    for (final c in _alternativasControllers) {
      c.dispose();
    }
    _alternativasControllers =
        alts.map((a) => TextEditingController(text: a)).toList();

    if (_formCategoriaId != null) {
      try {
        _assuntosForm = await _carregarAssuntos(_formCategoriaId!);
      } catch (e) {
        _assuntosForm = [];
        _formAssuntoId = null;
        _mostrarErro('Erro ao carregar assuntos: $e');
      }
    }

    setState(() => _formularioAberto = true);
  }

  Future<void> _selecionarImagens() async {
    final total = _imagensExistentes.length + _imagensPendentes.length;
    if (total >= 4) {
      _mostrarErro('Limite de 4 imagens atingido.');
      return;
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
        allowMultiple: true,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final disponiveis = 4 - total;
      final selecionadas = result.files.take(disponiveis).toList();
      final List<_ImagemPendente> novas = [];

      for (final file in selecionadas) {
        if (file.bytes == null) continue;
        final tamanhoMb = file.bytes!.length / (1024 * 1024);
        if (tamanhoMb > 2) {
          _mostrarErro('A imagem "${file.name}" excede 2MB e foi ignorada.');
          continue;
        }
        novas.add(_ImagemPendente(
          nome: file.name,
          bytes: file.bytes!,
          ext: file.extension ?? 'jpg',
        ));
      }

      setState(() => _imagensPendentes.addAll(novas));
    } catch (e) {
      _mostrarErro('Erro ao selecionar imagens: $e');
    }
  }

  Future<List<String>> _uploadImagensPendentes(String questaoId) async {
    final urls = <String>[];
    for (final img in _imagensPendentes) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'questoes/$questaoId/$timestamp.${img.ext}';
      final url = await ref.read(adminDataSourceProvider).uploadImagem(
        bytes: img.bytes,
        storagePath: path,
        contentType: 'image/${img.ext}',
      );
      urls.add(url);
    }
    return urls;
  }

  Future<void> _salvarQuestao() async {
    if (!_formKey.currentState!.validate()) return;

    if (_formCategoriaId == null) {
      _mostrarErro('Selecione uma categoria.');
      return;
    }
    if (_formAssuntoId == null) {
      _mostrarErro('Selecione um assunto.');
      return;
    }
    if (_respostaCorretaIndex == null) {
      _mostrarErro('Marque a alternativa correta.');
      return;
    }

    final alternativas =
        _alternativasControllers.map((c) => c.text.trim()).toList();
    if (alternativas.any((a) => a.isEmpty)) {
      _mostrarErro('Preencha todas as alternativas.');
      return;
    }

    setState(() => _salvando = true);

    try {
      final uid = _auth.currentUser?.uid ?? '';

      final dados = {
        'categoriaId': _formCategoriaId,
        'assuntoId': _formAssuntoId,
        'instituicaoId': widget.instituicaoId,
        'referencia': _refController.text.trim(),
        'texto': _textoController.text.trim(),
        'alternativas': alternativas,
        'respostaCorretaIndex': _respostaCorretaIndex,
        'justificativa': _justificativaController.text.trim(),
        'pontos': int.tryParse(_pontosController.text.trim()) ?? 1,
        'criadoPor': uid,
      };

      if (_editandoId == null) {
        final questaoId = await ref.read(adminDataSourceProvider).criarQuestao(dados);
        final urlsNovas = await _uploadImagensPendentes(questaoId);
        final todasImagens = [..._imagensExistentes, ...urlsNovas];
        if (todasImagens.isNotEmpty) {
          await ref.read(adminDataSourceProvider).editarQuestao(questaoId, {'imagens': todasImagens});
        }
        await widget.onAuditoria(
          'CRIAR',
          'Admin Questoes',
          'Criou questão: "${_textoController.text.trim().substring(0, _textoController.text.trim().length.clamp(0, 60))}..."',
          'Nenhum (Novo Registro)',
          dados.toString(),
        );
        _mostrarSucesso('Questão criada com sucesso!');
      } else {
        final urlsNovas = await _uploadImagensPendentes(_editandoId!);
        final todasImagens = [..._imagensExistentes, ...urlsNovas];
        dados['imagens'] = todasImagens;
        await ref.read(adminDataSourceProvider).editarQuestao(_editandoId!, dados);
        await widget.onAuditoria(
          'ALTERAR',
          'Admin Questoes',
          'Alterou questão ID: $_editandoId',
          'Registro anterior',
          dados.toString(),
        );
        _mostrarSucesso('Questão atualizada com sucesso!');
      }

      setState(() {
        _formularioAberto = false;
        _salvando = false;
      });
      _limparFormulario();
    } catch (e) {
      setState(() => _salvando = false);
      _mostrarErro('Erro ao salvar questão: $e');
    }
  }

  Future<void> _confirmarExcluir(String id, String texto, List<String> imagens) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Questão'),
        content: Text(
          'Tem certeza que deseja excluir esta questão?\n\n"${texto.length > 80 ? '${texto.substring(0, 80)}...' : texto}"',
        ),
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
    if (confirmar != true) return;

    try {
      for (final url in imagens) {
        try {
          await FirebaseStorage.instance.refFromURL(url).delete();
        } catch (_) {}
      }
      await ref.read(adminDataSourceProvider).excluirQuestao(id);
      await widget.onAuditoria(
        'EXCLUIR',
        'Admin Questoes',
        'Excluiu questão ID: $id — "$texto"',
        texto,
        'Registro excluído',
      );
      _mostrarSucesso('Questão excluída.');
    } catch (e) {
      _mostrarErro('Erro ao excluir: $e');
    }
  }

  bool _podeEditar(Map<String, dynamic> dados) {
    if (widget.roleCriador == 'Admin') return true;
    final uid = _auth.currentUser?.uid ?? '';
    return dados['criadoPor'] == uid;
  }

  String _nomeCategoria(String? id) {
    if (id == null) return '';
    return _categorias.firstWhere(
          (c) => c['id'] == id,
          orElse: () => {'nome': id},
        )['nome'] as String;
  }

  String _nomeAssunto(String? id) {
    if (id == null) return '';
    return _todosAssuntos.firstWhere(
          (a) => a['id'] == id,
          orElse: () => {'nome': id},
        )['nome'] as String;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 700;

      if (isMobile && _formularioAberto) {
        return _buildFormulario(colorScheme);
      }

      return Column(
        children: [
          Container(
            color: colorScheme.surfaceContainerLow,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _formularioAberto ? null : _abrirFormularioNovo,
              icon: const Icon(Icons.add),
              label: const Text('Incluir Questão'),
            ),
          ),
          _buildBarraFiltros(colorScheme),
          if (_formularioAberto)
            Flexible(
              flex: 2,
              child: _buildFormulario(colorScheme),
            ),
          Expanded(child: _buildListaQuestoes(colorScheme)),
        ],
      );
    });
  }

  Widget _buildBarraFiltros(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerLow,
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: _apenasMinhas,
                          onChanged: (v) => setState(() {
                            _apenasMinhas = v;
                            _questoesStream = _buildQuestoesStream();
                          }),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _apenasMinhas ? 'Minhas Questões' : 'Todas',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<String>(
                        initialValue: _filtroCategId,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null,
                              child: Text('Todas as categorias')),
                          ..._categorias.map((c) => DropdownMenuItem(
                                value: c['id'] as String,
                                child: Text(c['nome'] as String),
                              )),
                        ],
                        onChanged: (v) async {
                          setState(() {
                            _filtroCategId = v;
                            _filtroAssuntoId = null;
                            _assuntosFiltro = [];
                            _questoesStream = _buildQuestoesStream();
                          });
                          if (v != null) {
                            final assuntos = await _carregarAssuntos(v);
                            if (mounted) {
                              setState(() => _assuntosFiltro = assuntos);
                            }
                          }
                        },
                      ),
                    ),
                    if (_filtroCategId != null)
                      SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<String>(
                          initialValue: _filtroAssuntoId,
                          decoration: const InputDecoration(
                            labelText: 'Assunto',
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem(
                                value: null,
                                child: Text('Todos os assuntos')),
                            ..._assuntosFiltro.map((a) => DropdownMenuItem(
                                  value: a['id'] as String,
                                  child: Text(a['nome'] as String),
                                )),
                          ],
                          onChanged: (v) => setState(() {
                            _filtroAssuntoId = v;
                            _questoesStream = _buildQuestoesStream();
                          }),
                        ),
                      ),
        ],
      ),
    );
  }

  Widget _buildFormulario(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  _editandoId == null
                      ? Icons.add_circle_outline
                      : Icons.edit_outlined,
                  color: cs.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  _editandoId == null ? 'Nova Questão' : 'Editar Questão',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: cs.onPrimaryContainer),
                  onPressed: () {
                    setState(() => _formularioAberto = false);
                    _limparFormulario();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDropdownsCategoriaAssunto(),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _refController,
                    decoration: const InputDecoration(
                      labelText: 'Referência (tema/ano/livro)',
                      hintText: 'Ex: ENEM 2022, Cap. 3 Biologia',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _textoController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Texto da questão *',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Informe o texto da questão'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildSecaoImagens(cs),
                  const SizedBox(height: 16),
                  _buildSecaoAlternativas(cs),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _justificativaController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Justificativa (opcional)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: 140,
                    child: TextFormField(
                      controller: _pontosController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Pontos *',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Obrigatório';
                        }
                        if (int.tryParse(v.trim()) == null) {
                          return 'Número inteiro';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _salvando
                            ? null
                            : () {
                                setState(() => _formularioAberto = false);
                                _limparFormulario();
                              },
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _salvando ? null : _salvarQuestao,
                        child: _salvando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(_editandoId == null
                                ? 'Salvar Questão'
                                : 'Atualizar Questão'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownsCategoriaAssunto() {
    return Wrap(
      spacing: 14,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            key: ValueKey(_formCategoriaId),
            initialValue: _formCategoriaId,
            decoration: const InputDecoration(labelText: 'Categoria *'),
            hint: const Text('Selecione'),
            items: _categorias
                .map((c) => DropdownMenuItem(
                      value: c['id'] as String,
                      child: Text(c['nome'] as String),
                    ))
                .toList(),
            onChanged: (v) async {
              setState(() {
                _formCategoriaId = v;
                _formAssuntoId = null;
                _assuntosForm = [];
              });
              if (v != null) {
                try {
                  final assuntos = await _carregarAssuntos(v);
                  if (mounted) setState(() => _assuntosForm = assuntos);
                } catch (e) {
                  if (mounted) setState(() => _formAssuntoId = null);
                  _mostrarErro('Erro ao carregar assuntos: $e');
                }
              }
            },
            validator: (v) => v == null ? 'Selecione a categoria' : null,
          ),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            key: ValueKey('assunto_${_formCategoriaId}_$_formAssuntoId'),
            initialValue: _formAssuntoId,
            decoration: const InputDecoration(labelText: 'Assunto *'),
            hint: const Text('Selecione'),
            items: _assuntosForm
                .map((a) => DropdownMenuItem(
                      value: a['id'] as String,
                      child: Text(a['nome'] as String),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _formAssuntoId = v),
            validator: (v) => v == null ? 'Selecione o assunto' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSecaoImagens(ColorScheme cs) {
    final total = _imagensExistentes.length + _imagensPendentes.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Imagens ($total/4)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: total >= 4 ? null : _selecionarImagens,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('Adicionar imagens'),
            ),
          ],
        ),
        if (total > 0) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._imagensExistentes.asMap().entries.map((entry) {
                return _buildPreviewImagemUrl(
                  entry.value,
                  onRemover: () => setState(
                      () => _imagensExistentes.removeAt(entry.key)),
                );
              }),
              ..._imagensPendentes.asMap().entries.map((entry) {
                return _buildPreviewImagemBytes(
                  entry.value,
                  onRemover: () => setState(
                      () => _imagensPendentes.removeAt(entry.key)),
                );
              }),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewImagemUrl(String url,
      {required VoidCallback onRemover}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, st) => Container(
              width: 90,
              height: 90,
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image),
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemover,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewImagemBytes(_ImagemPendente img,
      {required VoidCallback onRemover}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            img.bytes,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemover,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
        Positioned(
          bottom: 2,
          left: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(140),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Novo',
              style: TextStyle(color: Colors.white, fontSize: 9),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecaoAlternativas(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Alternativas',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Text(
              '(${_alternativasControllers.length}/6) — marque a correta',
              style:
                  TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Column(
          children: List.generate(_alternativasControllers.length, (i) {
            final isCorreta = _respostaCorretaIndex == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Radio<int>(
                    value: i,
                    groupValue: _respostaCorretaIndex,
                    onChanged: (v) =>
                        setState(() => _respostaCorretaIndex = v),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _alternativasControllers[i],
                      decoration: InputDecoration(
                        labelText:
                            'Alternativa ${String.fromCharCode(65 + i)}',
                        suffixIcon: isCorreta
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : null,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Preencha a alternativa'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Remover alternativa',
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.red),
                    onPressed: _alternativasControllers.length <= 2
                        ? null
                        : () {
                            setState(() {
                              _alternativasControllers[i].dispose();
                              _alternativasControllers.removeAt(i);
                              if (_respostaCorretaIndex != null) {
                                if (_respostaCorretaIndex == i) {
                                  _respostaCorretaIndex = null;
                                } else if (_respostaCorretaIndex! > i) {
                                  _respostaCorretaIndex =
                                      _respostaCorretaIndex! - 1;
                                }
                              }
                            });
                          },
                  ),
                ],
              ),
            );
          }),
        ),
        TextButton.icon(
          onPressed: _alternativasControllers.length >= 6
              ? null
              : () {
                  setState(() =>
                      _alternativasControllers.add(TextEditingController()));
                },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Adicionar alternativa'),
        ),
      ],
    );
  }

  Widget _buildListaQuestoes(ColorScheme cs) {
    return StreamBuilder<QuerySnapshot>(
      stream: _questoesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Erro ao carregar questões: ${snapshot.error}'));
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
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.quiz_outlined,
                    size: 56, color: cs.onSurfaceVariant.withAlpha(100)),
                const SizedBox(height: 12),
                Text(
                  'Nenhuma questão encontrada.',
                  style: TextStyle(
                      color: cs.onSurfaceVariant, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'Altere os filtros ou crie uma nova questão.',
                  style: TextStyle(
                      color: cs.onSurfaceVariant.withAlpha(170),
                      fontSize: 13),
                ),
              ],
            ),
          );
        }

        return Scrollbar(
          thumbVisibility: true,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              return _buildCardQuestao(
                  doc.id, doc.data() as Map<String, dynamic>, cs);
            },
          ),
        );
      },
    );
  }

  Widget _buildCardQuestao(
      String id, Map<String, dynamic> dados, ColorScheme cs) {
    final texto = dados['texto'] as String? ?? '';
    final alternativas = List<String>.from(dados['alternativas'] ?? []);
    final respostaIdx = dados['respostaCorretaIndex'] as int?;
    final pontos = dados['pontos'] ?? 1;
    final imagens = List<String>.from(dados['imagens'] ?? []);
    final catNome = _nomeCategoria(dados['categoriaId'] as String?);
    final assuntoNome = _nomeAssunto(dados['assuntoId'] as String?);
    final podeEditar = _podeEditar(dados);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (catNome.isNotEmpty)
                        Chip(
                          label: Text(catNome,
                              style: const TextStyle(fontSize: 11)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: cs.secondaryContainer,
                        ),
                      if (assuntoNome.isNotEmpty)
                        Chip(
                          label: Text(assuntoNome,
                              style: const TextStyle(fontSize: 11)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: cs.primaryContainer,
                        ),
                      Chip(
                        label: Text('$pontos pt${pontos != 1 ? "s" : ""}',
                            style: const TextStyle(fontSize: 11)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: cs.tertiaryContainer,
                      ),
                    ],
                  ),
                ),
                if (podeEditar) ...[
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _abrirFormularioEditar(id, dados),
                  ),
                  IconButton(
                    tooltip: 'Excluir',
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: Colors.red),
                    onPressed: () => _confirmarExcluir(id, texto, imagens),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            _TextoExpansivel(texto: texto),
            if (imagens.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: imagens.length,
                  separatorBuilder: (context, idx) => const SizedBox(width: 6),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      imagens[i],
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => Container(
                        width: 64,
                        height: 64,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 20),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (alternativas.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...alternativas.asMap().entries.map((entry) {
                final i = entry.key;
                final alt = entry.value;
                final isCorreta = respostaIdx == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isCorreta
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: isCorreta ? Colors.green : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${String.fromCharCode(65 + i)}) $alt',
                          style: TextStyle(
                            fontSize: 13,
                            color: isCorreta
                                ? Colors.green.shade700
                                : cs.onSurface,
                            fontWeight: isCorreta
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _TextoExpansivel extends StatefulWidget {
  final String texto;
  const _TextoExpansivel({required this.texto});

  @override
  State<_TextoExpansivel> createState() => _TextoExpansivelState();
}

class _TextoExpansivelState extends State<_TextoExpansivel> {
  bool _expandido = false;
  static const int _limite = 160;

  @override
  Widget build(BuildContext context) {
    final curto = widget.texto.length <= _limite;
    return GestureDetector(
      onTap: curto ? null : () => setState(() => _expandido = !_expandido),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _expandido || curto
                ? widget.texto
                : '${widget.texto.substring(0, _limite)}...',
            style: const TextStyle(fontSize: 14),
          ),
          if (!curto)
            Text(
              _expandido ? 'ver menos' : 'ver mais',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class _ImagemPendente {
  final String nome;
  final Uint8List bytes;
  final String ext;

  const _ImagemPendente({
    required this.nome,
    required this.bytes,
    required this.ext,
  });
}
