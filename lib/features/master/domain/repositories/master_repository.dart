import '../entities/instituicao_entity.dart';

abstract class MasterRepository {
  /// Aba Home: Busca o consolidado numérico das métricas de usuários e IEs
  Future<Map<String, int>> buscarMetricasGlobais();

  /// Aba Instituições: Lista todas as instituições cadastradas
  Future<List<InstituicaoEntity>> listarInstituicoes();

  /// Aba Instituições: Cria uma nova instituição no ecossistema
  Future<void> cadastrarInstituicao(InstituicaoEntity instituicao);

  /// Aba Instituições: Modifica os dados visuais ou cadastrais de uma instituição
  Future<void> editarInstituicao(InstituicaoEntity instituicao);

  /// Aba Instituições: Remove uma instituição do sistema
  Future<void> excluirInstituicao(String id);

  /// Aba Instituições (Sub-Modal): Busca usuários atrelados a uma instituição com filtro por nível
  Future<List<Map<String, dynamic>>> buscarUsuariosPorInstituicao(String instituicaoId, String nivelAcesso);

  /// Aba Instituições (Sub-Modal): Cadastra um usuário (Admin, Acess2 ou Acess3) dentro de uma instituição
  Future<void> cadastrarUsuarioNaInstituicao(Map<String, dynamic> dadosUsuario, String senha);

  /// Aba Instituições (Sub-Modal): Remove o acesso de um usuário
  Future<void> excluirUsuario(String id);

  /// Aba Auditoria: Carrega os logs operacionais filtrados ou globais
  Future<List<Map<String, dynamic>>> buscarLogsAuditoria(String filtroInstituicao);

  /// Aba Controladoria: Busca métricas operacionais (provas, questões, categorias, acessos) por IE ou Geral
  Future<Map<String, dynamic>> buscarMetricasControladoria(String filtroInstituicao);
}
