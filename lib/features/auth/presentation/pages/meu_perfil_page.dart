import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rumo_quiz/shared/widgets/organisms/menu_lateral_organism.dart';
import '../../domain/models/usuario_model.dart';

class MeuPerfilPage extends StatefulWidget {
  const MeuPerfilPage({super.key});

  @override
  State<MeuPerfilPage> createState() => __MeuPerfilPageState();
}

class __MeuPerfilPageState extends State<MeuPerfilPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _instituicaoController = TextEditingController();

  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  final List<String> _listaAvatares = [
    '🐱',
    '🐶',
    '🦊',
    '🦁',
    '🐰',
    '🐼',
    '🐨',
    '🐯',
    '🐻',
    '🐵',
  ];
  String _avatarSelecionado = '🐱';
  bool _carregando = true;

  // 🟢 ESTADOS DO OLHO MÁGICO (Meu Perfil)
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
            _avatarSelecionado = usuario.avatarEmoji;
            _instituicaoController.text = usuario.instituicao;
            _carregando = false;
          });
        } else {
          setState(() {
            _nomeController.text = 'Estudante Cadastrado';
            _instituicaoController.text = 'Sua Instituição de Ensino';
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
    try {
      final usuario = UsuarioModel(
        uid: user.uid,
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        avatarEmoji: _avatarSelecionado,
        instituicao: _instituicaoController.text.trim(),
      );
      await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .set(usuario.toMap(), SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso! 🎉')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
      }
    }
  }

  Future<void> _alterarSenhaFirebase() async {
    if (_novaSenhaController.text != _confirmarSenhaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A nova senha e a confirmação não conferem!'),
        ),
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
    _instituicaoController.dispose();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      // 🟢 ADICIONADO O MENU LATERAL FIXO AQUI TAMBÉM
      drawer: const MenuLateralOrganism(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // INDICADOR VISUAL DO PERFIL
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.blue.shade50,
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

                // CARD 1: INFORMAÇÕES PESSOAIS
                _buildCardContainer(
                  titulo: 'Informações Pessoais',
                  icone: Icons.person_outline,
                  children: [
                    _buildTextField(
                      controller: _nomeController,
                      label: 'Nome de Usuário (Aparecerá no certificado)',
                      icon: Icons.account_circle,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _instituicaoController,
                      label: 'Sua Instituição de Ensino',
                      icon: Icons.school_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'E-mail Cadastrado',
                      icon: Icons.email_outlined,
                      enabled: false,
                    ),
                    const SizedBox(height: 20),
                    _buildBotaoSalvar(onPressed: _salvarDadosPerfil),
                  ],
                ),
                const SizedBox(height: 24),

                // 🔐 CARD 2: ALTERAR SENHA COM OLHO MÁGICO
                _buildCardContainer(
                  titulo: 'Alterar Senha',
                  icone: Icons.lock_open_outlined,
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
                    _buildBotaoSalvar(onPressed: _alterarSenhaFirebase),
                  ],
                ),
                const SizedBox(height: 24),

                // CARD 3: ESCOLHA SEU AVATAR
                _buildCardContainer(
                  titulo: 'Escolha seu Avatar',
                  icone: Icons.face_retouching_natural,
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
                      itemCount: _listaAvatares.length,
                      itemBuilder: (context, index) {
                        final avatar = _listaAvatares[index];
                        final isSelected = _avatarSelecionado == avatar;
                        return InkWell(
                          onTap: () =>
                              setState(() => _avatarSelecionado = avatar),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue.shade50
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue.shade600
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
                    _buildBotaoSalvar(onPressed: _salvarDadosPerfil),
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
              Icon(icone, color: Colors.blue.shade700, size: 24),
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

  // 🟢 COMPONENTE INPUT ATUALIZADO PARA SUPORTAR O OLHO MÁGICO
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
        // Adiciona o olho mágico apenas se for campo de senha
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

  Widget _buildBotaoSalvar({required VoidCallback onPressed}) {
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
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
