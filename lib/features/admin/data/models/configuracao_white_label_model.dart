class ConfiguracaoWhiteLabelModel {
  final String id;
  final String nome;
  final String plano;
  final String corHexadecimal;
  final List<String> patrocinadoresUrls;

  ConfiguracaoWhiteLabelModel({
    required this.id,
    required this.nome,
    required this.plano,
    required this.corHexadecimal,
    required this.patrocinadoresUrls,
  });

  factory ConfiguracaoWhiteLabelModel.fromMap(String id, Map<String, dynamic> map) {
    return ConfiguracaoWhiteLabelModel(
      id: id,
      nome: map['nome'] ?? 'Instituição',
      plano: map['plano'] ?? 'Gratuito',
      corHexadecimal: (map['corHexadecimal'] ?? map['corHex'])?.toString() ?? '#1A73E8',
      patrocinadoresUrls: List<String>.from(map['patrocinadoresUrls'] ?? map['patrocinios'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'plano': plano,
      'corHexadecimal': corHexadecimal,
      'corHex': corHexadecimal,
      'patrocinadoresUrls': patrocinadoresUrls,
      'patrocinios': patrocinadoresUrls,
    };
  }
}