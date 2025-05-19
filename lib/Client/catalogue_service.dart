import 'dart:convert';
import 'package:car_mobile/Client/catalogue_model.dart';
import 'package:http/http.dart' as http;


class CatalogueService {
  static const String baseUrl = 'http://localhost:8000/api';

  Future<List<Catalogue>> fetchCatalogues() async {
    final response = await http.get(Uri.parse('$baseUrl/catalogues'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((item) => Catalogue.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load catalogues');
    }
  }
}