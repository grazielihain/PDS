import '../../domain/entities/user_entity.dart';

abstract class AuthState {
  const AuthState();
}

// Estado Inicial: tela de login
class AuthInitial extends AuthState {
  const AuthInitial();
}

// Estado de Carregamento: Quando clica em entrar e espera o Firebase
class AuthLoading extends AuthState {
  const AuthLoading();
}

// Estado de Sucesso
class AuthSuccess extends AuthState {
  final UserEntity user;
  const AuthSuccess(this.user);
}

// Estado de Erro: Quando o e-mail/senha estão errados ou caiu a internet
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}