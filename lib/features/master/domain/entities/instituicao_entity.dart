class InstituicaoEntity {
  final String id;
  final String nome;
  final String corPrimaria;
  final String? logoUrl;
  final DateTime? dataCriacao;

  const InstituicaoEntity({
    required this.id,
    required this.nome,
    required this.corPrimaria,
    this.logoUrl,
    this.dataCriacao,
  });
}
