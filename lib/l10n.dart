import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _localizedValues = {
    'fr': {
      'title': 'Paramètres',
      'dark_mode': 'Mode Sombre',
      'language': 'Langue',
      'dashboard': 'Tableau de bord',
      'statistics': 'Statistiques',
      'history': 'Historique',
      'settings': 'Paramètres',
      'help': 'Aide & Support',
      'logout': 'Déconnexion',
    },
    'en': {
      'title': 'Settings',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'dashboard': 'Dashboard',
      'statistics': 'Statistics',
      'history': 'History',
      'settings': 'Settings',
      'help': 'Help & Support',
      'logout': 'Logout',
    },
    'ar': {
      'title': 'الإعدادات',
      'dark_mode': 'الوضع الداكن',
      'language': 'اللغة',
      'dashboard': 'لوحة القيادة',
      'statistics': 'الإحصائيات',
      'history': 'السجل',
      'settings': 'الإعدادات',
      'help': 'مساعدة ودعم',
      'logout': 'تسجيل الخروج',
    },
  };

  String get title => _localizedValues[locale.languageCode]!['title']!;
  String get darkMode => _localizedValues[locale.languageCode]!['dark_mode']!;
  String get language => _localizedValues[locale.languageCode]!['language']!;
  String get dashboard => _localizedValues[locale.languageCode]!['dashboard']!;
  String get statistics => _localizedValues[locale.languageCode]!['statistics']!;
  String get history => _localizedValues[locale.languageCode]!['history']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get help => _localizedValues[locale.languageCode]!['help']!;
  String get logout => _localizedValues[locale.languageCode]!['logout']!;
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'fr', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
