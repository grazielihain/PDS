import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rumo_quiz/features/auth/presentation/providers/white_label_notifier.dart';
import '../providers/auth_notifier.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _ocultarSenha = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // 🟢 FUNÇÃO ENCAIXADA AQUI: Abre a caixinha de recuperar senha
  void _exibirModalRecuperarSenha(BuildContext context, WidgetRef ref) {
    final emailRecuperacaoController = TextEditingController();
    final formModalKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Recuperar Senha'),
          content: Form(
            key: formModalKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Digite seu e-mail cadastrado. Enviaremos um link para você redefinir sua senha.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailRecuperacaoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email),
                    hintText: 'exemplo@escola.com',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu e-mail';
                    }
                    if (!value.contains('@')) return 'Insira um e-mail válido';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formModalKey.currentState!.validate()) {
                  ref
                      .read(authNotifierProvider.notifier)
                      .recuperarSenha(emailRecuperacaoController.text.trim());
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Se o e-mail existir, o link de recuperação foi enviado!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.school, size: 80, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    'Rumo Quiz',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Insira seu e-mail'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _senhaController,
                    obscureText: _ocultarSenha,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _ocultarSenha
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _ocultarSenha = !_ocultarSenha),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Insira sua senha'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _exibirModalRecuperarSenha(context, ref),
                      child: const Text('Esqueci minha senha'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() => _isLoading = true);
                        try {
                          // 1. Executa o login real de forma segura usando FirebaseAuth
                          final UserCredential credential = await FirebaseAuth.instance
                              .signInWithEmailAndPassword(
                            email: _emailController.text.trim(),
                            password: _senhaController.text.trim(),
                          );

                          final User? user = credential.user;
                          if (user == null) throw Exception("Falha ao autenticar usuário.");

                          // Captura o documento do usuário no Firestore
                          final docUser = await FirebaseFirestore.instance
                              .collection('usuarios')
                              .doc(user.uid)
                              .get();

                          if (!docUser.exists) throw Exception("Cadastro não encontrado no banco de dados.");
                          final dadosUsuario = docUser.data() ?? {};

                          final String instituicaoId = dadosUsuario['instituicaoId'] ?? 'ulbra-01';
                          final String roleLimpa = (dadosUsuario['role'] ?? 'Acess3').toString().trim().toLowerCase();

                          // 2. Dispara o Log de Auditoria obrigatório na coleção histórica
                          await FirebaseFirestore.instance.collection('login_logs').add({
                            'usuarioId': user.uid,
                            'email': user.email,
                            'role': roleLimpa,
                            'instituicaoId': instituicaoId,
                            'timestamp': FieldValue.serverTimestamp(),
                            'platform': 'Flutter Application',
                          });

                          // Inicializa as propriedades visuais da instituição na memória RAM do app
                          await ref
                              .read(whiteLabelProvider.notifier)
                              .inicializarIdentidade(instituicaoId, '');

                          // 3. Redirecionamento dinâmico baseado em papéis e tratamento de primeiro login
                          if (context.mounted) {
                            if (roleLimpa == 'master') {
                              context.go('/master-home');
                            } 
                            else if (roleLimpa == 'admin' || roleLimpa == 'acess2') {
                              context.go('/admin'); // Corrigido para bater com app_router.dart
                            } 
                            else {
                              // Interceptação de primeiro login para contas Acess3 (Alunos)
                              final bool primeiroLogin = dadosUsuario['primeiroLogin'] ?? false;
                              if (primeiroLogin) {
                                await FirebaseFirestore.instance
                                    .collection('usuarios')
                                    .doc(user.uid)
                                    .update({'primeiroLogin': false});
                              }
                              context.go('/quiz-selection');
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll('Exception: ', ''),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Entrar', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
