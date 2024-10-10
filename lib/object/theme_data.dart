class ThemeItem {
  String title;
  ThemeType type;

  ThemeItem({required this.title, required this.type});
}

enum ThemeType {
  lightMode,
  darkMode,
}

extension ThemeTypeExtension on ThemeType {
  String get themeTitle {
    switch (this) {
      case ThemeType.lightMode:
        return '浅色主题';
      case ThemeType.darkMode:
        return '深色主题';
    }
  }

  String get jsonFileName {
    switch (this) {
      case ThemeType.lightMode:
        return 'day.json';
      case ThemeType.darkMode:
        return 'night.json';
    }
  }
}
