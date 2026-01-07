import 'package:json_annotation/json_annotation.dart';

part 'new_york_weather.g.dart';

@JsonSerializable()
class NewYorkWeather {
  final String id;
  final DateTime date;
  final double temperature;
  final double feelsLike;
  final double minTemperature;
  final double maxTemperature;
  final int humidity;
  final int pressure;
  final double windSpeed;
  final String windDirection;
  final String description;
  final String icon;
  final double visibility;
  final double uvIndex;
  final double precipitation;
  final String precipitationType; // "rain", "snow", "sleet", "none"
  final int cloudCover;
  final String sunrise;
  final String sunset;
  final String moonrise;
  final String moonset;
  final String moonPhase;
  final Map<String, dynamic>? hourlyForecast;
  final Map<String, dynamic>? dailyForecast;
  final String? bestTimeToVisit;
  final String? tourismRecommendation;
  final List<String>? activities;
  final List<String>? clothingRecommendations;
  final String? airQuality;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  NewYorkWeather({
    required this.id,
    required this.date,
    required this.temperature,
    required this.feelsLike,
    required this.minTemperature,
    required this.maxTemperature,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.windDirection,
    required this.description,
    required this.icon,
    required this.visibility,
    required this.uvIndex,
    required this.precipitation,
    required this.precipitationType,
    required this.cloudCover,
    required this.sunrise,
    required this.sunset,
    required this.moonrise,
    required this.moonset,
    required this.moonPhase,
    this.hourlyForecast,
    this.dailyForecast,
    this.bestTimeToVisit,
    this.tourismRecommendation,
    this.activities,
    this.clothingRecommendations,
    this.airQuality,
    this.createdAt,
    this.updatedAt,
  });

  factory NewYorkWeather.fromJson(Map<String, dynamic> json) =>
      _$NewYorkWeatherFromJson(json);

  Map<String, dynamic> toJson() => _$NewYorkWeatherToJson(this);

  // Getters úteis
  String get formattedTemperature {
    return '${temperature.round()}°C';
  }

  String get formattedFeelsLike {
    return '${feelsLike.round()}°C';
  }

  String get formattedMinMax {
    return '${minTemperature.round()}°C - ${maxTemperature.round()}°C';
  }

  String get formattedHumidity {
    return '$humidity%';
  }

  String get formattedWindSpeed {
    return '${windSpeed.toStringAsFixed(1)} km/h';
  }

  String get formattedVisibility {
    return '${visibility.toStringAsFixed(1)} km';
  }

  String get formattedUVIndex {
    return uvIndex.toStringAsFixed(1);
  }

  String get formattedPrecipitation {
    if (precipitation == 0) return '0%';
    return '${(precipitation * 100).toStringAsFixed(0)}%';
  }

  String get formattedPressure {
    return '$pressure hPa';
  }

  String get formattedCloudCover {
    return '$cloudCover%';
  }

  String get descriptionDisplay {
    switch (description.toLowerCase()) {
      case 'clear sky':
        return 'Céu limpo';
      case 'few clouds':
        return 'Poucas nuvens';
      case 'scattered clouds':
        return 'Nuvens dispersas';
      case 'broken clouds':
        return 'Nuvens quebradas';
      case 'overcast clouds':
        return 'Nublado';
      case 'light rain':
        return 'Chuva leve';
      case 'moderate rain':
        return 'Chuva moderada';
      case 'heavy rain':
        return 'Chuva forte';
      case 'light snow':
        return 'Neve leve';
      case 'moderate snow':
        return 'Neve moderada';
      case 'heavy snow':
        return 'Neve forte';
      case 'mist':
        return 'Névoa';
      case 'fog':
        return 'Neblina';
      case 'haze':
        return 'Bruma';
      case 'smoke':
        return 'Fumaça';
      case 'dust':
        return 'Poeira';
      case 'sand':
        return 'Areia';
      case 'ash':
        return 'Cinzas';
      case 'squall':
        return 'Rajada';
      case 'tornado':
        return 'Tornado';
      default:
        return description;
    }
  }

  String get precipitationTypeDisplay {
    switch (precipitationType) {
      case 'rain':
        return 'Chuva';
      case 'snow':
        return 'Neve';
      case 'sleet':
        return 'Granizo';
      case 'none':
        return 'Sem precipitação';
      default:
        return precipitationType;
    }
  }

  String get windDirectionDisplay {
    switch (windDirection) {
      case 'N':
        return 'Norte';
      case 'NNE':
        return 'Norte-Nordeste';
      case 'NE':
        return 'Nordeste';
      case 'ENE':
        return 'Leste-Nordeste';
      case 'E':
        return 'Leste';
      case 'ESE':
        return 'Leste-Sudeste';
      case 'SE':
        return 'Sudeste';
      case 'SSE':
        return 'Sul-Sudeste';
      case 'S':
        return 'Sul';
      case 'SSW':
        return 'Sul-Sudoeste';
      case 'SW':
        return 'Sudoeste';
      case 'WSW':
        return 'Oeste-Sudoeste';
      case 'W':
        return 'Oeste';
      case 'WNW':
        return 'Oeste-Noroeste';
      case 'NW':
        return 'Noroeste';
      case 'NNW':
        return 'Norte-Noroeste';
      default:
        return windDirection;
    }
  }

  String get moonPhaseDisplay {
    switch (moonPhase) {
      case 'new':
        return 'Lua Nova';
      case 'waxing_crescent':
        return 'Lua Crescente';
      case 'first_quarter':
        return 'Quarto Crescente';
      case 'waxing_gibbous':
        return 'Lua Crescente Gibosa';
      case 'full':
        return 'Lua Cheia';
      case 'waning_gibbous':
        return 'Lua Minguante Gibosa';
      case 'last_quarter':
        return 'Quarto Minguante';
      case 'waning_crescent':
        return 'Lua Minguante';
      default:
        return moonPhase;
    }
  }

  // Análise de condições para turismo
  bool get isGoodForTourism {
    return temperature >= 10 && 
           temperature <= 30 && 
           precipitation < 0.3 && 
           windSpeed < 20 &&
           visibility > 5;
  }

  bool get isExcellentForTourism {
    return temperature >= 15 && 
           temperature <= 25 && 
           precipitation < 0.1 && 
           windSpeed < 15 &&
           visibility > 8 &&
           cloudCover < 50;
  }

  bool get isBadForTourism {
    return temperature < 0 || 
           temperature > 35 || 
           precipitation > 0.7 || 
           windSpeed > 30 ||
           visibility < 2;
  }

  String get tourismRating {
    if (isExcellentForTourism) return 'Excelente';
    if (isGoodForTourism) return 'Boa';
    if (isBadForTourism) return 'Ruim';
    return 'Regular';
  }

  String get tourismRatingColor {
    if (isExcellentForTourism) return '#4CAF50'; // Verde
    if (isGoodForTourism) return '#8BC34A'; // Verde claro
    if (isBadForTourism) return '#F44336'; // Vermelho
    return '#FF9800'; // Laranja
  }

  List<String> get recommendedActivities {
    List<String> activities = [];
    
    if (temperature >= 20 && precipitation < 0.2) {
      activities.addAll(['Caminhada no Central Park', 'Passeio de barco', 'Visita ao Top of the Rock']);
    }
    
    if (temperature >= 15 && precipitation < 0.3) {
      activities.addAll(['Times Square', 'Broadway', 'Shopping']);
    }
    
    if (precipitation > 0.5) {
      activities.addAll(['Museus', 'Teatros', 'Shopping centers']);
    }
    
    if (temperature < 10) {
      activities.addAll(['Museus', 'Restaurantes', 'Teatros']);
    }
    
    if (activities.isEmpty) {
      activities.add('Atividades indoor recomendadas');
    }
    
    return activities;
  }

  List<String> get clothingRecommendationsComputed {
    List<String> clothing = [];
    
    if (temperature < 5) {
      clothing.addAll(['Casaco pesado', 'Gorro', 'Luvas', 'Cachecol']);
    } else if (temperature < 15) {
      clothing.addAll(['Casaco', 'Cachecol', 'Calças compridas']);
    } else if (temperature < 25) {
      clothing.addAll(['Jaqueta leve', 'Camisa de manga longa']);
    } else {
      clothing.addAll(['Camisa de manga curta', 'Shorts', 'Protetor solar']);
    }
    
    if (precipitation > 0.3) {
      clothing.add('Guarda-chuva');
    }
    
    if (windSpeed > 15) {
      clothing.add('Casaco corta-vento');
    }
    
    return clothing;
  }

  String get bestTimeToVisitDisplay {
    if (bestTimeToVisit == null) {
      // Calcular baseado nas condições atuais
      if (isExcellentForTourism) {
        return 'Agora é um excelente momento!';
      } else if (isGoodForTourism) {
        return 'Condições boas para turismo';
      } else if (isBadForTourism) {
        return 'Melhor aguardar condições melhores';
      } else {
        return 'Condições regulares';
      }
    }
    return bestTimeToVisit!;
  }

  String get tourismRecommendationDisplay {
    if (tourismRecommendation != null) {
      return tourismRecommendation!;
    }
    
    if (isExcellentForTourism) {
      return 'Perfeito para atividades ao ar livre e passeios turísticos!';
    } else if (isGoodForTourism) {
      return 'Bom para turismo, mas monitore as condições.';
    } else if (isBadForTourism) {
      return 'Recomendamos atividades indoor ou reagendar para outro dia.';
    } else {
      return 'Condições variáveis, prepare-se para mudanças no clima.';
    }
  }

  NewYorkWeather copyWith({
    String? id,
    DateTime? date,
    double? temperature,
    double? feelsLike,
    double? minTemperature,
    double? maxTemperature,
    int? humidity,
    int? pressure,
    double? windSpeed,
    String? windDirection,
    String? description,
    String? icon,
    double? visibility,
    double? uvIndex,
    double? precipitation,
    String? precipitationType,
    int? cloudCover,
    String? sunrise,
    String? sunset,
    String? moonrise,
    String? moonset,
    String? moonPhase,
    Map<String, dynamic>? hourlyForecast,
    Map<String, dynamic>? dailyForecast,
    String? bestTimeToVisit,
    String? tourismRecommendation,
    List<String>? activities,
    List<String>? clothingRecommendations,
    String? airQuality,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NewYorkWeather(
      id: id ?? this.id,
      date: date ?? this.date,
      temperature: temperature ?? this.temperature,
      feelsLike: feelsLike ?? this.feelsLike,
      minTemperature: minTemperature ?? this.minTemperature,
      maxTemperature: maxTemperature ?? this.maxTemperature,
      humidity: humidity ?? this.humidity,
      pressure: pressure ?? this.pressure,
      windSpeed: windSpeed ?? this.windSpeed,
      windDirection: windDirection ?? this.windDirection,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      visibility: visibility ?? this.visibility,
      uvIndex: uvIndex ?? this.uvIndex,
      precipitation: precipitation ?? this.precipitation,
      precipitationType: precipitationType ?? this.precipitationType,
      cloudCover: cloudCover ?? this.cloudCover,
      sunrise: sunrise ?? this.sunrise,
      sunset: sunset ?? this.sunset,
      moonrise: moonrise ?? this.moonrise,
      moonset: moonset ?? this.moonset,
      moonPhase: moonPhase ?? this.moonPhase,
      hourlyForecast: hourlyForecast ?? this.hourlyForecast,
      dailyForecast: dailyForecast ?? this.dailyForecast,
      bestTimeToVisit: bestTimeToVisit ?? this.bestTimeToVisit,
      tourismRecommendation: tourismRecommendation ?? this.tourismRecommendation,
      activities: activities ?? this.activities,
      clothingRecommendations: clothingRecommendations ?? this.clothingRecommendations,
      airQuality: airQuality ?? this.airQuality,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 
