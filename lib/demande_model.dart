class Demande {
  final int id;
  final int? atelierId;
  final String dateMaintenance;
  final Map<String, dynamic> voiture;
  final Map<String, dynamic> servicePanne;
  final Map<String, dynamic> client;

  Demande({
    required this.id,
    this.atelierId,
    required this.dateMaintenance,
    required this.voiture,
    required this.servicePanne,
    required this.client,
  });

  factory Demande.fromJson(Map<String, dynamic> json) {
    return Demande(
      id: json['id'],
      atelierId: json['atelier_id'],
      dateMaintenance: json['date_maintenance'],
      voiture: json['voiture'],
      servicePanne: json['service_panne'],
      client: json['client'],
    );
  }
}