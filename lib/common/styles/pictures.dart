class ThemeData {
  final String themeName;
  final String primaryColor;
  final String secondaryColor;
  final String backgroundColor;
  final String textColor;

  ThemeData({
    required this.themeName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.textColor,
  });
}

// Example usage
final lightTheme = ThemeData(
  themeName: 'Light',
  primaryColor: '#FFFFFF',
  secondaryColor: '#F0F0F0',
  backgroundColor: '#FFFFFF',
  textColor: '#000000',
);

final darkTheme = ThemeData(
  themeName: 'Dark',
  primaryColor: '#000000',
  secondaryColor: '#1A1A1A',
  backgroundColor: '#000000',
  textColor: '#FFFFFF',
);
