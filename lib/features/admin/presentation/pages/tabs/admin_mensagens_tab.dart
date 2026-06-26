import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_provider.dart';

class AdminMensagensTab extends ConsumerStatefulWidget {
  final String instituicaoId;
  final String mascoteUrl;
  final bool somenteLeitura;
  final Future<void> Function(String, String, String, String, String)
  onAuditoria;

  const AdminMensagensTab({
    super.key,
    required this.instituicaoId,
    required this.mascoteUrl,
    required this.onAuditoria,
    this.somenteLeitura = false,
  });

  @override
  ConsumerState<AdminMensagensTab> createState() => _AdminMensagensTabState();
}

class _AdminMensagensTabState extends ConsumerState<AdminMensagensTab> {
  // Controle do formulário
  bool _mostrarFormulario = false;
  String? _editandoId;

  final _formKey = GlobalKey<FormState>();
  final _deController = TextEditingController();
  final _ateController = TextEditingController();
  final _textoController = TextEditingController();

  String _tipoImagem = 'nenhuma'; // 'nenhuma' | 'mascote' | 'upload'
  Uint8List? _imagemBytes;
  String? _imagemNome;
  String? _imagemUrlAtual; // usado na edição

  bool _salvando = false;

  @override
  void dispose() {
    _deController.dispose();
    _ateController.dispose();
    _textoController.dispose();
    super.dispose();
  }

  void _abrirFormularioNovo() {
    _limparFormulario();
    setState(() => _mostrarFormulario = true);
  }

  void _abrirFormularioEdicao(DocumentSnapshot doc) {
    final dados = doc.data() as Map<String, dynamic>;
    _editandoId = doc.id;
    _deController.text = (dados['de'] as num).toStringAsFixed(0);
    _ateController.text = (dados['ate'] as num).toStringAsFixed(0);
    _textoController.text = dados['texto'] ?? '';
    _tipoImagem = dados['tipoImagem'] ?? 'nenhuma';
    _imagemUrlAtual = dados['imagemUrl'] as String?;
    _imagemBytes = null;
    _imagemNome = null;
    setState(() => _mostrarFormulario = true);
  }

  void _limparFormulario() {
    _editandoId = null;
    _deController.clear();
    _ateController.clear();
    _textoController.clear();
    _tipoImagem = 'nenhuma';
    _imagemBytes = null;
    _imagemNome = null;
    _imagemUrlAtual = null;
  }

  void _cancelarFormulario() {
    _limparFormulario();
    setState(() => _mostrarFormulario = false);
  }

  Future<void> _selecionarImagem() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (resultado == null || resultado.files.isEmpty) return;

    final arquivo = resultado.files.first;
    if (arquivo.bytes == null) return;

    // Validar tamanho: max 2 MB
    if (arquivo.bytes!.lengthInBytes > 2 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arquivo muito grande. Máximo permitido: 2 MB.'),
          ),
        );
      }
      return;
    }

    setState(() {
      _imagemBytes = arquivo.bytes;
      _imagemNome = arquivo.name;
    });
  }

  /// Valida se o range [de, ate] não sobrepõe ranges já cadastrados.
  Future<String?> _validarSobreposicao(double de, double ate) async {
    final snap = await ref
        .read(adminDataSourceProvider)
        .streamMensagens(widget.instituicaoId)
        .first;

    for (final doc in snap.docs) {
      if (doc.id == _editandoId) continue; // ignora o próprio registro
      final dados = doc.data() as Map<String, dynamic>;
      final existeDe = (dados['de'] as num).toDouble();
      final existeAte = (dados['ate'] as num).toDouble();
      // Sobreposição: os intervalos se cruzam
      if (de < existeAte && ate > existeDe) {
        return 'O intervalo $de%–$ate% sobrepõe o range já cadastrado '
            '${existeDe.toStringAsFixed(0)}%–${existeAte.toStringAsFixed(0)}%.';
      }
    }
    return null;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final de = double.tryParse(_deController.text.trim());
    final ate = double.tryParse(_ateController.text.trim());

    if (de == null || ate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe valores numéricos válidos.')),
      );
      return;
    }

    if (de >= ate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('"De" deve ser menor que "Até".'),
        ),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      // Verificar sobreposição
      final erroSobreposicao = await _validarSobreposicao(de, ate);
      if (erroSobreposicao != null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(erroSobreposicao)));
        }
        return;
      }

      String imagemUrl = _imagemUrlAtual ?? '';

      // Upload se necessário
      if (_tipoImagem == 'upload' && _imagemBytes != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final ext = _imagemNome?.split('.').last ?? 'jpg';
        final msgId = _editandoId ?? 'new_$timestamp';
        final path = 'mensagens/$msgId/$timestamp.$ext';
        imagemUrl = await ref.read(adminDataSourceProvider).uploadImagem(
          bytes: _imagemBytes!,
          storagePath: path,
          contentType: 'image/$ext',
        );
      } else if (_tipoImagem == 'mascote') {
        imagemUrl = widget.mascoteUrl;
      } else if (_tipoImagem == 'nenhuma') {
        imagemUrl = '';
      }

      final dados = {
        'instituicaoId': widget.instituicaoId,
        'de': de,
        'ate': ate,
        'texto': _textoController.text.trim(),
        'tipoImagem': _tipoImagem,
        'imagemUrl': imagemUrl,
      };

      if (_editandoId != null) {
        final snap = await ref
            .read(adminDataSourceProvider)
            .streamMensagens(widget.instituicaoId)
            .first;
        final docAntigo = snap.docs.where((d) => d.id == _editandoId).firstOrNull;
        await ref.read(adminDataSourceProvider).editarMensagem(_editandoId!, dados);

        await widget.onAuditoria(
          'ALTERAR',
          'Admin Mensagens de Resultado',
          'Editou mensagem para range $de%–$ate%',
          docAntigo?.data()?.toString() ?? 'Nenhum',
          dados.toString(),
        );
      } else {
        await ref.read(adminDataSourceProvider).criarMensagem(dados);

        await widget.onAuditoria(
          'CRIAR',
          'Admin Mensagens de Resultado',
          'Criou mensagem para range $de%–$ate%',
          'Nenhum (Novo Registro)',
          dados.toString(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mensagem salva com sucesso!')),
        );
        _cancelarFormulario();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
      }
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
        content: Text(
          'Excluir a mensagem do intervalo '
          '${(dados['de'] as num).toStringAsFixed(0)}%–'
          '${(dados['ate'] as num).toStringAsFixed(0)}%?',
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
      await ref.read(adminDataSourceProvider).excluirMensagem(doc.id);

      await widget.onAuditoria(
        'EXCLUIR',
        'Admin Mensagens de Resultado',
        'Excluiu mensagem do range '
            '${(dados['de'] as num).toStringAsFixed(0)}%–'
            '${(dados['ate'] as num).toStringAsFixed(0)}%',
        dados.toString(),
        'Registro removido',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mensagem excluída.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
      }
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mensagens de Resultado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (!_mostrarFormulario && !widget.somenteLeitura) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _abrirFormularioNovo,
              icon: const Icon(Icons.add),
              label: const Text('Nova Mensagem'),
            ),
          ],
          const SizedBox(height: 12),

          // Formulário inline
          if (_mostrarFormulario && !widget.somenteLeitura) _buildFormulario(),

          const SizedBox(height: 16),

          // Lista de mensagens
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
                _editandoId == null ? 'Nova Mensagem' : 'Editar Mensagem',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Intervalo de pontuação
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _deController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'De (%)',
                        hintText: '0',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Obrigatório';
                        }
                        final n = double.tryParse(v.trim());
                        if (n == null) return 'Número inválido';
                        if (n < 0 || n > 100) return '0 a 100';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _ateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Até (%)',
                        hintText: '100',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Obrigatório';
                        }
                        final n = double.tryParse(v.trim());
                        if (n == null) return 'Número inválido';
                        if (n < 0 || n > 100) return '0 a 100';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Texto da mensagem
              TextFormField(
                controller: _textoController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Texto da mensagem *',
                  hintText: 'Ex: Parabéns! Você atingiu um ótimo resultado.',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),

              // Seleção de imagem
              const Text(
                'Imagem da mensagem:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              RadioGroup<String>(
                groupValue: _tipoImagem,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _tipoImagem = v;
                    if (v != 'upload') _imagemBytes = null;
                  });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Opção 1: sem imagem
                    const RadioListTile<String>(
                      value: 'nenhuma',
                      title: Text('Sem imagem'),
                    ),
                    // Opção 2: mascote
                    RadioListTile<String>(
                      value: 'mascote',
                      title: const Text('Usar mascote da instituição'),
                      // desativado visualmente quando não há mascote
                      subtitle: widget.mascoteUrl.isEmpty
                          ? const Text(
                              'Nenhum mascote cadastrado na identidade da instituição.',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            )
                          : null,
                    ),
                    if (_tipoImagem == 'mascote' && widget.mascoteUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 52, bottom: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.mascoteUrl,
                            height: 80,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, _) => const Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    // Opção 3: upload
                    const RadioListTile<String>(
                      value: 'upload',
                      title: Text('Fazer upload de imagem'),
                    ),
                  ],
                ),
              ),
              if (_tipoImagem == 'upload')
                Padding(
                  padding: const EdgeInsets.only(left: 52, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _selecionarImagem,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Selecionar imagem (PNG/JPG ≤ 2 MB)'),
                      ),
                      if (_imagemBytes != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.memory(
                                _imagemBytes!,
                                height: 72,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _imagemNome ?? '',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 18,
                              ),
                              onPressed: () => setState(() {
                                _imagemBytes = null;
                                _imagemNome = null;
                              }),
                            ),
                          ],
                        ),
                      ] else if (_imagemUrlAtual != null &&
                          _imagemUrlAtual!.isNotEmpty &&
                          _editandoId != null) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Imagem atual (mantida se não substituir):',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            _imagemUrlAtual!,
                            height: 72,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.broken_image),
                          ),
                        ),
                      ],
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
                        : Text(_editandoId == null ? 'Salvar' : 'Atualizar'),
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
          .streamMensagens(widget.instituicaoId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Erro ao carregar mensagens: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final rawDocs = snapshot.data?.docs ?? [];
        final docs = List<QueryDocumentSnapshot>.from(rawDocs)
          ..sort((a, b) {
            final aDe = ((a.data() as Map<String, dynamic>)['de'] as num?)?.toDouble() ?? 0;
            final bDe = ((b.data() as Map<String, dynamic>)['de'] as num?)?.toDouble() ?? 0;
            return aDe.compareTo(bDe);
          });
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Nenhuma mensagem cadastrada.',
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
            final de = (dados['de'] as num).toStringAsFixed(0);
            final ate = (dados['ate'] as num).toStringAsFixed(0);
            final texto = dados['texto'] as String? ?? '';
            final tipoImagem = dados['tipoImagem'] as String? ?? 'nenhuma';
            final imagemUrl = dados['imagemUrl'] as String? ?? '';

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: _buildMiniaturaImagem(tipoImagem, imagemUrl),
                title: Text(
                  'De $de% até $ate%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  texto,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: widget.somenteLeitura
                    ? null
                    : Row(
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

  Widget _buildMiniaturaImagem(String tipoImagem, String imagemUrl) {
    if (tipoImagem == 'nenhuma' || imagemUrl.isEmpty) {
      return const CircleAvatar(
        backgroundColor: Colors.grey,
        child: Icon(Icons.image_not_supported, color: Colors.white, size: 20),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        imagemUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 48,
          height: 48,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
        ),
      ),
    );
  }
}
