class CollectionPoint {
  final int id;
  final String nome;
  final String endereco;
  final List<String> tiposResiduos;
  final double latitude;
  final double longitude;

  CollectionPoint({
    required this.id,
    required this.nome,
    required this.endereco,
    required this.tiposResiduos,
    required this.latitude,
    required this.longitude,
  });

  factory CollectionPoint.fromJson(Map<String, dynamic> json) {
    return CollectionPoint(
      id: json['id'],
      nome: json['nome'],
      endereco: json['endereco'],
      tiposResiduos: List<String>.from(json['tipos_residuos']),
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
    );
  }
}