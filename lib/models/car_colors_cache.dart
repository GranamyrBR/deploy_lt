class CarColorsCache {
  static const List<String> commonColors = [
    'Todas',
    'Preto',
    'Branco',
    'Prata',
    'Cinza',
    'Azul',
    'Vermelho',
    'Verde',
    'Amarelo',
    'Laranja',
    'Rosa',
    'Roxo',
    'Marrom',
    'Bege',
    'Dourado',
    'Champagne',
  ];

  static List<String> getColors() {
    return commonColors;
  }

  static String getDefaultColor() {
    return 'Todas';
  }
} 
