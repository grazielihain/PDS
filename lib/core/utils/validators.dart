class Validators {
  /// Valida se um campo obrigatório foi preenchido
  static String? requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'O campo $fieldName é obrigatório.';
    }
    return null;
  }

  /// Valida se o formato do e-mail é válido utilizando Expressão Regular (RegEx)
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'O e-mail é obrigatório.';
    }

    // RegEx padrão para validação de e-mails estruturados (ex: nome@dominio.com)
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Insira um e-mail válido.';
    }

    return null;
  }

  /// Valida se a password cumpre os requisitos mínimos de segurança
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'A password é obrigatória.';
    }

    if (value.length < 6) {
      return 'A password deve ter pelo menos 6 caracteres.';
    }

    return null;
  }
}
