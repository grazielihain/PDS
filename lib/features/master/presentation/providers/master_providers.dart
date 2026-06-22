import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/master_repository_impl.dart';
import '../../domain/entities/instituicao_entity.dart';
import '../../domain/repositories/master_repository.dart';

// 1. Injeta a implementação do repositório no escopo do Riverpod
final masterRepositoryProvider = Provider<MasterRepository>((ref) {
  return MasterRepositoryImpl();
});

// 2. Modelo de Estado customizado para encapsular os dados do painel Master
class MasterDashboardState {
  final bool isLoading;
  final String? erro;
  final Map<String, int> metricasGlobais;
  final List<InstituicaoEntity> instituicoes;
  final List<Map<String, dynamic>> usuariosDaInstituicao;
  final Map<String, dynamic> metricasControladoria;
  final List<Map<String, dynamic>> logsAuditoria;

  const MasterDashboardState({
    this.isLoading = false,
    this.erro,
    this.metricasGlobais = const {},
    this.instituicoes = const [],
    this.usuariosDaInstituicao = const [],
    this.metricasControladoria = const {},
    this.logsAuditoria = const [],
  });

  MasterDashboardState copyWith({
    bool? isLoading,
    String? erro,
    Map<String, int>? metricasGlobais,
    List<InstituicaoEntity>? instituicoes,
    List<Map<String, dynamic>>? usuariosDaInstituicao,
    Map<String, dynamic>? metricasControladoria,
    List<Map<String, dynamic>>? logsAuditoria,
  }) {
    return MasterDashboardState(
      isLoading: isLoading ?? this.isLoading,
      erro: erro,
      metricasGlobais: metricasGlobais ?? this.metricasGlobais,
      instituicoes: instituicoes ?? this.instituicoes,
      usuariosDaInstituicao:
          usuariosDaInstituicao ?? this.usuariosDaInstituicao,
      metricasControladoria:
          metricasControladoria ?? this.metricasControladoria,
      logsAuditoria: logsAuditoria ?? this.logsAuditoria,
    );
  }
}

// 3. O Controlador que gerencia as ações e modifica o estado
class MasterNotifier extends StateNotifier<MasterDashboardState> {
  final MasterRepository _repository;

  MasterNotifier(this._repository) : super(const MasterDashboardState());

  /// Aba Home: Carrega os dados consolidando as métricas limpas
  Future<void> carregarHome({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, erro: null);
    try {
      final metricas = await _repository.buscarMetricasGlobais();
      state = state.copyWith(isLoading: false, metricasGlobais: metricas);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        erro: 'Falha ao carregar métricas: $e',
      );
    }
  }

  /// Aba Instituições: Lista todas as IEs registradas
  Future<void> carregarInstituicoes({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, erro: null);
    try {
      final lista = await _repository.listarInstituicoes();
      state = state.copyWith(isLoading: false, instituicoes: lista);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        erro: 'Falha ao buscar instituições: $e',
      );
    }
  }

  /// Aba Instituições: Cria uma nova IE aceitando o ID Customizado do banco
  Future<void> criarInstituicao(
    String nome,
    String corHex,
    String? logoUrl, {
    String? customId,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final nova = InstituicaoEntity(
        id: customId ?? '', // Se vier preenchido, o repositório usará este ID no documento NoSQL
        nome: nome,
        corPrimaria: corHex,
        logoUrl: logoUrl,
      );
      await _repository.cadastrarInstituicao(nova);
      await carregarInstituicoes(forceRefresh: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        erro: 'Erro ao criar instituição: $e',
      );
    }
  }

  /// Aba Instituições: Atualiza dados visuais de uma IE
  Future<void> atualizarInstituicao(
    String id,
    String nome,
    String corHex,
    String? logoUrl,
  ) async {
    try {
      final editada = InstituicaoEntity(
        id: id,
        nome: nome,
        corPrimaria: corHex,
        logoUrl: logoUrl,
      );
      await _repository.editarInstituicao(editada);
      await carregarInstituicoes(forceRefresh: true);
    } catch (e) {
      state = state.copyWith(erro: 'Erro ao editar instituição: $e');
    }
  }

  /// Aba Instituições: Remove uma instituição
  Future<void> deletarInstituicao(String id) async {
    try {
      await _repository.excluirInstituicao(id);
      final novaLista = state.instituicoes.where((i) => i.id != id).toList();
      state = state.copyWith(instituicoes: novaLista);
    } catch (e) {
      state = state.copyWith(erro: 'Erro ao remover instituição: $e');
    }
  }

  /// Sub-Modal: Carrega a listagem de usuários vinculados de uma IE específica
  Future<void> carregarUsuariosDaInstituicao(
    String instituicaoId,
    String filtroNivel,
  ) async {
    try {
      final users = await _repository.buscarUsuariosPorInstituicao(
        instituicaoId,
        filtroNivel,
      );
      state = state.copyWith(usuariosDaInstituicao: users);
    } catch (e) {
      state = state.copyWith(erro: 'Erro ao carregar usuários da IE: $e');
    }
  }

  /// Sub-Modal: Cria o usuário na esteira da instituição
  Future<void> adicionarUsuarioNaInstituicao(
    Map<String, dynamic> dados,
    String senha,
  ) async {
    try {
      await _repository.cadastrarUsuarioNaInstituicao(dados, senha);
      await carregarUsuariosDaInstituicao(dados['instituicaoId'], 'Todos');
    } catch (e) {
      state = state.copyWith(erro: 'Erro ao cadastrar usuário: $e');
    }
  }

  /// Sub-Modal: Remove um usuário de uma instituição
  Future<void> removerUsuario(String id, String instituicaoId) async {
    try {
      await _repository.excluirUsuario(id);
      await carregarUsuariosDaInstituicao(instituicaoId, 'Todos');
    } catch (e) {
      state = state.copyWith(erro: 'Erro ao remover usuário: $e');
    }
  }

  /// Aba Controladoria: Carrega contadores operacionais filtrados
  Future<void> carregarControladoria(
    String filtroIE, {
    bool forceRefresh = false,
  }) async {
    state = state.copyWith(isLoading: true, erro: null);
    try {
      final data = await _repository.buscarMetricasControladoria(filtroIE);
      state = state.copyWith(isLoading: false, metricasControladoria: data);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        erro: 'Erro na controladoria: $e',
      );
    }
  }

  /// Aba Auditoria: Carrega os logs mais recentes aplicando o limite grátis
  Future<void> carregarLogsAuditoria(
    String filtroIE, {
    bool forceRefresh = false,
  }) async {
    state = state.copyWith(isLoading: true, erro: null);
    try {
      final logs = await _repository.buscarLogsAuditoria(filtroIE);
      state = state.copyWith(isLoading: false, logsAuditoria: logs);
    } catch (e) {
      state = state.copyWith(isLoading: false, erro: 'Erro ao ler logs: $e');
    }
  }
}

// 4. Provedor global exposto que as telas e componentes usarão para observar o painel Master
final masterProvider =
    StateNotifierProvider<MasterNotifier, MasterDashboardState>((ref) {
  final repo = ref.read(masterRepositoryProvider);
  return MasterNotifier(repo);
});