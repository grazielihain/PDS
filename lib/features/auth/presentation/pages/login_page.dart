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
                    if (!value.contains('@')) {
                      return 'Insira um e-mail válido';
                    }
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
                  Image.asset(
                    'assets/images/logo_rumo_quiz.png',
                    height: 130,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.school, size: 80, color: Colors.blue),
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

                  // 🟢 LOCAL DE ENCAIXE DO CLIQUE: Associado à nossa nova função
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _exibirModalRecuperarSenha(
                        context,
                        ref,
                      ), // 👈 Chamando o Modal aqui!
                      child: const Text('Esqueci minha senha'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          // 1. Executa o login real chamando o repositório através do DataSource
                          // (Isso valida se o e-mail e senha existem no Firebase)
                          final userModel = await ref
                              .read(authDataSourceProvider)
                              .loginWithEmailAndPassword(
                                _emailController.text.trim(),
                                _senhaController.text.trim(),
                              );

                          // 2. Se o login deu certo, dispara o Log de Auditoria obrigatoriamente
                          await ref
                              .read(whiteLabelProvider.notifier)
                              .inicializarIdentidade(
                                userModel.institutionId,
                                '',
                              );
                          // 3. Direciona o utilizador com base no perfil (Role)
                          if (context.mounted) {
                            final role = userModel.role.toLowerCase().trim();
                            if (role == 'master') {
                              context.go('/master-painel');
                            } else if (role == 'admin' || role == 'acess2') {
                              context.go(
                                '/admin',
                                extra: {
                                  'instituicaoId': userModel.institutionId,
                                },
                              );
                            } else {
                              // Verifica primeiro login para Acess3
                              final uid = FirebaseAuth.instance.currentUser?.uid;
                              if (uid != null) {
                                final doc = await FirebaseFirestore.instance
                                    .collection('usuarios')
                                    .doc(uid)
                                    .get();
                                final isPrimeiro = doc.data()?['primeiroLogin'] as bool? ?? false;
                                if (isPrimeiro && context.mounted) {
                                  await showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Bem-vindo(a)!'),
                                      content: const Text(
                                        'Este é o seu primeiro acesso.\n\n'
                                        'Por segurança, recomendamos que você altere sua senha em "Meu Perfil" assim que possível.',
                                      ),
                                      actions: [
                                        FilledButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Entendido'),
                                        ),
                                      ],
                                    ),
                                  );
                                  await FirebaseFirestore.instance
                                      .collection('usuarios')
                                      .doc(uid)
                                      .update({'primeiroLogin': false});
                                }
                              }
                              if (context.mounted) context.go('/quiz-selection');
                            }
                          }
                        } catch (e) {
                          // Se a senha estiver errada ou o usuário não existir, mostra o erro na tela
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
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Entrar', style: TextStyle(fontSize: 16)),
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
