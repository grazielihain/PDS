class AppConstants {
  // --- IDENTIFICAÇÃO DO SISTEMA ---
  static const String appName = 'Rumo Quiz';
  static const String appVersion = '1.0.0';

  // --- ROTAS DO FIRESTORE (Nomes das Coleções no Banco de Dados) ---
  // Centralizando garante que o ecossistema NoSQL fique blindado contra erros de digitação
  static const String collectionUsers = 'usuarios';
  static const String collectionInstitutions = 'instituicoes';
  static const String collectionQuestions = 'questoes';
  static const String collectionQuizzes = 'simulados';
  static const String collectionHistory = 'historicos';

  // --- CHAVES DOS PERFIS DE ACESSO (Roles de Segurança) ---
  // Usadas para trancar e libertar telas dependendo do tipo de utilizador
  static const String roleMaster = 'Master';
  static const String roleAdmin = 'Admin';
  static const String roleAccess2 = 'Acess2'; // Professor / Criador de Questões
  static const String roleAccess3 = 'Acess3'; // Aluno / Estudante

  // --- CONFIGURAÇÕES DE REGRAS DE NEGÓCIO ---
  static const int maxImageSizeInBytes = 2097152; // Limite de 2MB para uploads de imagens
  static const int quizWarningTimeInSeconds = 300; // Alerta do cronômetro aos 5 minutos 
}