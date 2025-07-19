class ReviewModel {
  final int id;
  final int nbrEtoile;
  final String? commentaire;
  final int clientId;
  final int technicienId;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.nbrEtoile,
    this.commentaire,
    required this.clientId,
    required this.technicienId,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'],
      nbrEtoile: json['nbr_etoile'],
      commentaire: json['commentaire'],
      clientId: json['client_id'],
      technicienId: json['technicien_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}