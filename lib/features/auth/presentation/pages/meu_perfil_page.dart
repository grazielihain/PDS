import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rumo_quiz/features/auth/presentation/providers/white_label_notifier.dart';
import '../../domain/models/usuario_model.dart';

class MeuPerfilPage extends ConsumerStatefulWidget {
  const MeuPerfilPage({super.key});

  @override
  ConsumerState<MeuPerfilPage> createState() => _MeuPerfilPageState();
}

class _MeuPerfilPageState extends ConsumerState<MeuPerfilPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  String _instituicaoDoUsuario = '';

  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  // 🐱 LISTA ORIGINAL PRESERVADA INTACTA
  final List<String> _listaAvataresOficial = [
    '🐱',
    '🐶',
    '🦊',
    '🦁',
    '🐰',
    '🐼',
    '🐨',
    '🐯',
    '🐧',
    '🦆',
  ];

  String _avatarSelecionado = '🐱';
  bool _carregando = true;

  bool _ocultarSenhaAtual = true;
  bool _ocultarNovaSenha = true;
  bool _ocultarConfirmarSenha = true;

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  Future<void> _carregarDadosUsuario() async {
    final user = _auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      try {
        final doc = await _firestore.collection('usuarios').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final usuario = UsuarioModel.fromMap(doc.data()!, doc.id);
          setState(() {
            _nomeController.text = usuario.nome;
            _avatarSelecionado =
                _listaAvataresOficial.contains(usuario.avatarEmoji)
                    ? usuario.avatarEmoji
                    : '🐱';
            _instituicaoDoUsuario = usuario.instituicao;
            _carregando = false;
          });
        } else {
          setState(() {
            _nomeController.text = user.displayName ?? 'Estudante Cadastrado';
            _instituicaoDoUsuario = '';
            _carregando = false;
          });
        }
      } catch (e) {
        setState(() => _carregando = false);
      }
    }
  }

  Future<void> _salvarDadosPerfil() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_nomeController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nome e Email não podem ficar vazios! ⚠️'),
        ),
      );
      return;
    }

    try {
      final novoEmail = _emailController.text.trim();
      final novoNome = _nomeController.text.trim();

      await user.updateDisplayName(novoNome);

      bool emailAlterado = false;
      if (novoEmail != user.email) {
        // Envia e-mail de verificação antes de aplicar a alteração
        await user.verifyBeforeUpdateEmail(novoEmail);
        emailAlterado = true;
      }

      // Correção técnica: Mantemos no Firestore o email autenticado real do usuário.
      // Se ele solicitou a alteração, salvamos o e-mail atual até que ele valide o link.
      final usuario = UsuarioModel(
        uid: user.uid,
        nome: novoNome,
        email: emailAlterado ? user.email! : novoEmail,
        avatarEmoji: _avatarSelecionado,
        instituicao: _instituicaoDoUsuario,
      );

      await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .set(usuario.toMap(), SetOptions(merge: true));

      // Atualiza o estado da tela para refletir o nome alterado imediatamente no cabeçalho
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              emailAlterado
                  ? 'Nome e Avatar salvos! Verifique sua caixa de entrada no e-mail "$novoEmail" para validar a alteração de login. 📧'
                  : 'Perfil atualizado com sucesso! 🎉',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar dados: $e')));
      }
    }
  }

  Future<void> _alterarSenhaFirebase() async {
    if (_senhaAtualController.text.isEmpty ||
        _novaSenhaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os campos de senha!')),
      );
      return;
    }

    if (_novaSenhaController.text != _confirmarSenhaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A nova senha e a confirmação não conferem!'),
        ),
      );
      return;
    }

    if (_novaSenhaController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A nova senha deve ter pelo menos 6 caracteres! ⚠️')),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _senhaAtualController.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_novaSenhaController.text.trim());

      _senhaAtualController.clear();
      _novaSenhaController.clear();
      _confirmarSenhaController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha alterada com sucesso! 🔐')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao alterar senha: $e')));
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 🎨 LEITURA SEGURA COM FALLBACK PARA EVITAR ERROS DE COMPILAÇÃO
    final dynamic estadoWhiteLabel = ref.watch(whiteLabelProvider);

    String nomeInstituicao = 'Sistema de Ensino Rumo Quiz';
    Color corPrimariaExibicao = Colors.blue.shade700;
    Color corSecundariaExibicao = Colors.blue.shade50;
    Color corBordaExibicao = Colors.blue.shade200;

    try {
      if (estadoWhiteLabel != null) {
        if (estadoWhiteLabel.toString().contains('nome')) {
          nomeInstituicao =
              estadoWhiteLabel.nomeDaInstituicao ?? nomeInstituicao;
        } else if (estadoWhiteLabel.toString().contains('instituicao')) {
          nomeInstituicao = estadoWhiteLabel.nomeInstituicao ?? nomeInstituicao;
        }

        String? hexObtido;
        if (estadoWhiteLabel.toString().contains('corPrimariaHex')) {
          hexObtido = estadoWhiteLabel.corPrimariaHex;
        } else if (estadoWhiteLabel.toString().contains('primaryColorHex')) {
          hexObtido = estadoWhiteLabel.primaryColorHex;
        }

        if (hexObtido != null && hexObtido.isNotEmpty) {
          final stringLimpa = hexObtido.replaceAll('#', '0xFF');
          final valorInteiro = int.tryParse(stringLimpa);
          if (valorInteiro != null) {
            corPrimariaExibicao = Color(valorInteiro);
            corSecundariaExibicao = Color(valorInteiro).withOpacity(0.12);
            corBordaExibicao = Color(valorInteiro).withOpacity(0.4);
          }
        }
      }
    } catch (_) {}

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meu Perfil',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gerencie suas informações pessoais, personalize seu avatar e mantenha a segurança da sua conta.',
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
                Center(
                  child: Column(
                    children: [
                      Text(
                        nomeInstituicao.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: corPrimariaExibicao,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: corBordaExibicao,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: corSecundariaExibicao,
                          child: Text(
                            _avatarSelecionado,
                            style: const TextStyle(fontSize: 55),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _nomeController.text.isEmpty
                            ? 'Estudante'
                            : _nomeController.text,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildCardContainer(
                  titulo: 'Informações Pessoais',
                  icone: Icons.person_outline,
                  corDoIcone: corPrimariaExibicao,
                  children: [
                    _buildTextField(
                      controller: _nomeController,
                      label: 'Nome de Usuário (Aparecerá no certificado)',
                      icon: Icons.account_circle,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'E-mail Cadastrado',
                      icon: Icons.email_outlined,
                      enabled: true,
                    ),
                    const SizedBox(height: 20),
                    _buildBotaoSalvar(
                      onPressed: _salvarDadosPerfil,
                      corDeFundo: corPrimariaExibicao,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildCardContainer(
                  titulo: 'Escolha seu Avatar',
                  icone: Icons.face_retouching_natural,
                  corDoIcone: corPrimariaExibicao,
                  children: [
                    const Text(
                      'Selecione um dos 10 animais fofos abaixo para personalizar a sua conta:',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 120,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: _listaAvataresOficial.length,
                      itemBuilder: (context, index) {
                        final avatar = _listaAvataresOficial[index];
                        final isSelected = _avatarSelecionado == avatar;
                        return InkWell(
                          onTap: () =>
                              setState(() => _avatarSelecionado = avatar),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? corSecundariaExibicao
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? corPrimariaExibicao
                                    : Colors.grey.shade300,
                                width: isSelected ? 2.5 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              avatar,
                              style: const TextStyle(fontSize: 38),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildBotaoSalvar(
                      onPressed: _salvarDadosPerfil,
                      corDeFundo: corPrimariaExibicao,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildCardContainer(
                  titulo: 'Alterar Senha',
                  icone: Icons.lock_open_outlined,
                  corDoIcone: corPrimariaExibicao,
                  children: [
                    _buildTextField(
                      controller: _senhaAtualController,
                      label: 'Senha Atual',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: _ocultarSenhaAtual,
                      onToggleVisibility: () {
                        setState(
                          () => _ocultarSenhaAtual = !_ocultarSenhaAtual,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _novaSenhaController,
                      label: 'Nova Senha',
                      icon: Icons.fiber_new_outlined,
                      isPassword: true,
                      obscureText: _ocultarNovaSenha,
                      onToggleVisibility: () {
                        setState(() => _ocultarNovaSenha = !_ocultarNovaSenha);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _confirmarSenhaController,
                      label: 'Confirmar Nova Senha',
                      icon: Icons.lock_reset_outlined,
                      isPassword: true,
                      obscureText: _ocultarConfirmarSenha,
                      onToggleVisibility: () {
                        setState(
                          () =>
                              _ocultarConfirmarSenha = !_ocultarConfirmarSenha,
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildBotaoSalvar(
                      onPressed: _alterarSenhaFirebase,
                      corDeFundo: corPrimariaExibicao,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContainer({
    required String titulo,
    required IconData icone,
    required Color corDoIcone,
    required List<Widget> children,
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
              Icon(icone, color: corDoIcone, size: 24),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? obscureText : false,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade600,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: !enabled,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildBotaoSalvar({
    required VoidCallback onPressed,
    required Color corDeFundo,
  }) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.save_outlined, size: 18),
        label: const Text(
          'Alterar / Salvar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: corDeFundo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}