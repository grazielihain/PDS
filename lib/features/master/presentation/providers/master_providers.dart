import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/master_repository_impl.dart';
import '../../domain/entities/instituicao_entity.dart';
import '../../domain/repositories/master_repository.dart';

final masterRepositoryProvider = Provider<MasterRepository>((ref) {
  return MasterRepositoryImpl();
});

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
      usuariosDaInstituicao: usuariosDaInstituicao ?? this.usuariosDaInstituicao,
      metricasControladoria: metricasControladoria ?? this.metricasControladoria,
      logsAuditoria: logsAuditoria ?? this.logsAuditoria,
    );
  }
}

class MasterNotifier extends StateNotifier<MasterDashboardState> {
  final MasterRepository _repository;

  MasterNotifier(this._repository) : super(const MasterDashboardState());

  Future<void> carregarHome({bool forceRefresh = false}) async {
    if (state.metricasGlobais.isNotEmpty && !forceRefresh) return;
    state = state.copyWith(isLoading: true, erro: null);
    try {
      final metricas = await _repository.buscarMetricasGlobais();
      state = state.copyWith(isLoading: false, metricasGlobais: metricas);
    } catch (e) {
      state = state.copyWith(isLoading: false, erro: 'Falha ao carregar métricas: $e');
    }
  }

  Future<void> carregarInstituicoes({bool forceRefresh = false}) async {
    if (state.instituicoes.isNotEmpty && !forceRefresh) return;
    state = state.copyWith(isLoading: true, erro: null);
    try {
      final lista = await _repository.listarInstituicoes();
      state = state.copyWith(isLoading: false, instituicoes: lista);
    } catch (e) {
      state = state.copyWith(isLoading: false, erro: 'Falha ao buscar instituições: $e');
    }
  }

  // Mudado logoUrl para dynamic para receber a String ou o PlatformFile vindo da UI
  Future<void> criarInstituicao(String nome, String corHex, dynamic logoParam, String customId) async {
    state = state.copyWith(isLoading: true, erro: null);
    try {
      final corFormatada = corHex.replaceAll('#', '');
      final idFinal = customId.trim().isNotEmpty ? customId.trim() : DateTime.now().millisecondsSinceEpoch.toString();

      // Criamos a entidade básica. O seu MasterRepositoryImpl precisará interceptar 
      // se logoUrl for na verdade um PlatformFile e efetuar o upload antes de salvar no banco.
      final nova = InstituicaoEntity(
        id: idFinal,
        nome: nome,
        corPrimaria: corFormatada,
        logoUrl: logoParam is String ? logoParam : null, 
      );

      // Repasse o arquivo em uma sobrecarga ou certifique-se que o seu contrato cadastrarInstituicao 
      // ou um método específico faça o upload se passar o parametro dinâmico.
      // Caso queira passar o PlatformFile direto ao repository, adapte a assinatura do repositório para aceitar dynamic no logo.
      await _repository.cadastrarInstituicao(nova, arquivoLogo: logoParam);
      
      state = state.copyWith(isLoading: false);
      await carregarInstituicoes(forceRefresh: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, erro: 'Erro ao criar instituição: $e');
    }
  }

  // Mudado de String? para dynamic logoParam
  Future<void> atualizarInstituicao(String id, String nome, String corHex, dynamic logoParam) async {
    try {
      final editada = InstituicaoEntity(
        id: id,
        nome: nome,
        corPrimaria: corHex,
        logoUrl: logoParam is String ? logoParam : null,
      );
      
      await _repository.editarInstituicao(editada, arquivoLogo: logoParam);
      await carregarInstituicoes(forceRefresh: true);
    } catch (e) {
      state = state.copyWith(erro: 'Erro ao editar instituição: $e');
    }
  }

  Future<void> deletarInstituicao(String id) async {
    try {
      await _repository.excluirInstituicao(id);
      final novaLista = state.instituicoes.where((i) => i.id != id).toList();
      state = state.copyWith(instituicoes: novaLista);
    } catch (e) {
      state = state.copyWith(erro: 'Erro ao remover instituição: $e');
    }
  }

  Future<void> carregarUsuariosDaInstituicao(String instituicaoId, String filtroNivel) async {
    try {
      final users = await _repository.buscarUsuariosPorInstituicao(instituicaoId, filtroNivel);
      state = state.copyWith(usuariosDaInstituicao: users);
    } catch (e) {
      state = state.copyWith(erro: 'Erro ao carregar usuários da IE: $e');
    }
  }

  Future<void> adicionarUsuarioNaInstituicao(Map<String, dynamic> dados, String senha) async {
    try {
      await _repository.cadastrarUsuarioNaInstituicao(dados, senha);
      final novosUsuarios = await _repository.buscarUsuariosPorInstituicao(dados['instituicaoId'], 'Todos');
      state = state.copyWith(usuariosDaInstituicao: novosUsuarios);
    } catch (e) {
      state = state.copyWith(erro: 'Erro ao cadastrar usuário: $e');
    }
  }

  Future<void> atualizarUsuarioNaInstituicao(Map<String, dynamic> dados) async {
    try {
      await _repository.editarUsuarioNaInstituicao(dados);
      final novosUsuarios = await _repository.buscarUsuariosPorInstituicao(dados['instituicaoId'], 'Todos');
      state = state.copyWith(usuariosDaInstituicao: novosUsuarios);
    } catch (e) {
      state = state.copyWith(erro: 'Erro ao editar usuário: $e');
    }
  }

  Future<void> removerUsuario(String id, String instituicaoId) async {
    try {
      await _repository.excluirUsuario(id);
      final novosUsuarios = await _repository.buscarUsuariosPorInstituicao(instituicaoId, 'Todos');
      state = state.copyWith(usuariosDaInstituicao: novosUsuarios);
    } catch (e) {
      state = state.copyWith(erro: 'Erro ao remover usuário: $e');
    }
  }

  Future<void> carregarControladoria(String filtroIE, {bool forceRefresh = false}) async {
    if (state.metricasControladoria.isNotEmpty && !forceRefresh) return;
    state = state.copyWith(isLoading: true, erro: null);
    try {
      final data = await _repository.buscarMetricasControladoria(filtroIE);
      state = state.copyWith(isLoading: false, metricasControladoria: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, erro: 'Erro na controladoria: $e');
    }
  }

  Future<void> carregarLogsAuditoria(String filtroIE, {bool forceRefresh = false}) async {
    if (state.logsAuditoria.isNotEmpty && !forceRefresh) return;
    state = state.copyWith(isLoading: true, erro: null);
    try {
      final logs = await _repository.buscarLogsAuditoria(filtroIE);
      state = state.copyWith(isLoading: false, logsAuditoria: logs);
    } catch (e) {
      state = state.copyWith(isLoading: false, erro: 'Erro ao ler logs: $e');
    }
  }
}

final masterProvider = StateNotifierProvider<MasterNotifier, MasterDashboardState>((ref) {
  final repo = ref.read(masterRepositoryProvider);
  return MasterNotifier(repo);
});

final masterAbaAtivaProvider = StateProvider<int>((ref) => 0);