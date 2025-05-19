class Catalogue {
  final int id;
  final String entreprise;
  final String typeVoiture;
  final String nomPiece;
  final String? photoPiece;

  Catalogue({
    required this.id,
    required this.entreprise,
    required this.typeVoiture,
    required this.nomPiece,
    this.photoPiece,
  });

  factory Catalogue.fromJson(Map<String, dynamic> json) {
    return Catalogue(
      id: json['id'],
      entreprise: json['entreprise'],
      typeVoiture: json['type_voiture'],
      nomPiece: json['nom_piece'],
      photoPiece: json['photo_piece'],
    );
  }
}