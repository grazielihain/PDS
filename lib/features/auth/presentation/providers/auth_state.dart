import '../../domain/entities/user_entity.dart';

abstract class AuthState {
  const AuthState();
}

// Estado Inicial: Quando o usuário acabou de abrir a tela de login
class AuthInitial extends AuthState {
  const AuthInitial();
}

// Estado de Carregamento: Quando o usuário clicou em entrar e espera o Firebase
class AuthLoading extends AuthState {
  const AuthLoading();
}

// Estado de Sucesso: Quando o login deu certo e temos os dados do usuário em mãos
class AuthSuccess extends AuthState {
  final UserEntity user;
  const AuthSuccess(this.user);
}

// Estado de Erro: Quando o e-mail/senha estão errados ou caiu a internet
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}