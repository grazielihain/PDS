class AppConstants {
  // --- IDENTIFICAÇÃO DO SISTEMA ---
  static const String appName = 'Rumo Quiz';
  static const String appVersion = '1.1.0';

  // --- ROTAS DO FIRESTORE (Nomes das Coleções NoSQL) ---
  static const String collectionUsers = 'usuarios';
  static const String collectionInstitutions = 'instituicoes';
  static const String collectionCategories = 'categorias';
  static const String collectionQuizzes = 'provas';
  static const String collectionQuestions = 'questoes';
  static const String collectionHistory = 'historicos';
  static const String collectionAuditoria = 'auditoria';
  static const String collectionGamificacao = 'gamificacao';
  static const String collectionLoginLogs = 'loginLogs';

  // --- CONFIGURAÇÕES DE ARQUIVOS (STORAGE) ---
  static const int maxFileSizeInBytes = 2 * 1024 * 1024; // Limite estrito de 2MB por imagem (Prompt 1)
  static const List<String> allowedFileExtensions = ['png', 'jpg', 'jpeg'];
}
