import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;

  // O UseCase exige receber um Repositório para funcionar (Injeção de Dependência)
  LoginUseCase(this._repository);

  /// Função que executa a regra de login (Princípio da responsabilidade única)
  Future<UserEntity> execute({
    required String email,
    required String password,
  }) async {
    // Pode ter outras regras de validação antes de chamar o banco
    return await _repository.loginWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}
