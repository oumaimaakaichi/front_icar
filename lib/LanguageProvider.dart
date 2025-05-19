import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LanguageProvider extends ChangeNotifier {
  // La langue par défaut est l'anglais
  Locale _locale = Locale('en');

  // Getter pour la langue
  Locale get locale => _locale;

  // Méthode pour changer la langue
  void changeLanguage(Locale locale) {
    _locale = locale;
    notifyListeners(); // Notifie tous les écouteurs que l'état a changé
    Get.updateLocale(locale); // Met à jour la langue avec GetX
  }
}
