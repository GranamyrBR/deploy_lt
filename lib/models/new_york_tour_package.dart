import 'package:json_annotation/json_annotation.dart';

part 'new_york_tour_package.g.dart';

@JsonSerializable()
class NewYorkTourPackage {
  final String id;
  final String name;
  final String? description;
  final String? shortDescription;
  final String category; // "city_tour", "cultural", "food", "shopping", "nightlife", "family", "romantic"
  final String duration; // "half_day", "full_day", "multi_day", "custom"
  final int estimatedHours;
  final double price;
  final String currency;
  final String? originalPrice;
  final double? discountPercentage;
  final int maxGroupSize;
  final int minGroupSize;
  final List<String> includedAttractions;
  final List<String> includedServices;
  final List<String> excludedServices;
  final List<String> highlights;
  final String? meetingPoint;
  final String? endingPoint;
  final String? transportation;
  final bool includesGuide;
  final bool includesMeals;
  final bool includesTickets;
  final bool includesTransportation;
  final String? guideLanguage;
  final String? difficultyLevel; // "easy", "moderate", "challenging"
  final bool isWheelchairAccessible;
  final bool isFamilyFriendly;
  final String? bestTimeToVisit;
  final String? seasonality;
  final List<String>? photos;
  final double? rating;
  final int? reviewCount;
  final List<String>? tags;
  final Map<String, dynamic>? schedule;
  final Map<String, dynamic>? cancellationPolicy;
  final Map<String, dynamic>? weatherPolicy;
  final List<String>? requirements;
  final List<String>? recommendations;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  NewYorkTourPackage({
    required this.id,
    required this.name,
    this.description,
    this.shortDescription,
    required this.category,
    required this.duration,
    required this.estimatedHours,
    required this.price,
    this.currency = 'USD',
    this.originalPrice,
    this.discountPercentage,
    required this.maxGroupSize,
    this.minGroupSize = 1,
    required this.includedAttractions,
    required this.includedServices,
    required this.excludedServices,
    required this.highlights,
    this.meetingPoint,
    this.endingPoint,
    this.transportation,
    required this.includesGuide,
    required this.includesMeals,
    required this.includesTickets,
    required this.includesTransportation,
    this.guideLanguage,
    this.difficultyLevel,
    required this.isWheelchairAccessible,
    required this.isFamilyFriendly,
    this.bestTimeToVisit,
    this.seasonality,
    this.photos,
    this.rating,
    this.reviewCount,
    this.tags,
    this.schedule,
    this.cancellationPolicy,
    this.weatherPolicy,
    this.requirements,
    this.recommendations,
    this.createdAt,
    this.updatedAt,
  });

  factory NewYorkTourPackage.fromJson(Map<String, dynamic> json) =>
      _$NewYorkTourPackageFromJson(json);

  Map<String, dynamic> toJson() => _$NewYorkTourPackageToJson(this);

  // Getters úteis
  String get formattedPrice {
    return '\$${price.toStringAsFixed(2)}';
  }

  String get formattedOriginalPrice {
    if (originalPrice == null) return '';
    return '\$${double.parse(originalPrice!).toStringAsFixed(2)}';
  }

  String get formattedDiscount {
    if (discountPercentage == null) return '';
    return '${discountPercentage!.toStringAsFixed(0)}% OFF';
  }

  String get formattedDuration {
    switch (duration) {
      case 'half_day':
        return 'Meio dia (${estimatedHours}h)';
      case 'full_day':
        return 'Dia inteiro (${estimatedHours}h)';
      case 'multi_day':
        return 'Múltiplos dias (${estimatedHours}h)';
      case 'custom':
        return 'Personalizado (${estimatedHours}h)';
      default:
        return '${estimatedHours}h';
    }
  }

  String get formattedRating {
    if (rating == null) return 'N/A';
    return '${rating!.toStringAsFixed(1)} ⭐';
  }

  String get categoryDisplay {
    switch (category) {
      case 'city_tour':
        return 'City Tour';
      case 'cultural':
        return 'Cultural';
      case 'food':
        return 'Gastronômico';
      case 'shopping':
        return 'Shopping';
      case 'nightlife':
        return 'Vida Noturna';
      case 'family':
        return 'Familiar';
      case 'romantic':
        return 'Romântico';
      case 'adventure':
        return 'Aventura';
      case 'historical':
        return 'Histórico';
      case 'art':
        return 'Arte';
      case 'architecture':
        return 'Arquitetura';
      case 'photography':
        return 'Fotografia';
      case 'music':
        return 'Música';
      case 'theater':
        return 'Teatro';
      case 'sports':
        return 'Esportes';
      default:
        return category;
    }
  }

  String get difficultyLevelDisplay {
    switch (difficultyLevel) {
      case 'easy':
        return 'Fácil';
      case 'moderate':
        return 'Moderado';
      case 'challenging':
        return 'Desafiador';
      default:
        return 'Não informado';
    }
  }

  String get seasonalityDisplay {
    switch (seasonality) {
      case 'year-round':
        return 'Ano todo';
      case 'spring':
        return 'Primavera';
      case 'summer':
        return 'Verão';
      case 'fall':
        return 'Outono';
      case 'winter':
        return 'Inverno';
      default:
        return 'Não informado';
    }
  }

  bool get hasDiscount => discountPercentage != null && discountPercentage! > 0;

  bool get isPopular => rating != null && rating! >= 4.0;

  bool get isBudgetFriendly => price < 100;

  bool get isPremium => price > 200;

  String get groupSizeDisplay {
    if (minGroupSize == 1 && maxGroupSize == 1) {
      return 'Individual';
    } else if (minGroupSize == maxGroupSize) {
      return 'Grupo de $maxGroupSize pessoas';
    } else {
      return '$minGroupSize-$maxGroupSize pessoas';
    }
  }

  String get transportationDisplay {
    if (transportation == null) return 'Não incluído';
    switch (transportation) {
      case 'walking':
        return 'A pé';
      case 'subway':
        return 'Metrô';
      case 'bus':
        return 'Ônibus';
      case 'taxi':
        return 'Táxi';
      case 'limo':
        return 'Limousine';
      case 'boat':
        return 'Barco';
      case 'helicopter':
        return 'Helicóptero';
      default:
        return transportation!;
    }
  }

  String get guideLanguageDisplay {
    if (guideLanguage == null) return 'Não incluído';
    switch (guideLanguage) {
      case 'pt-BR':
        return 'Português';
      case 'en':
        return 'Inglês';
      case 'es':
        return 'Espanhol';
      case 'fr':
        return 'Francês';
      case 'de':
        return 'Alemão';
      case 'it':
        return 'Italiano';
      case 'zh':
        return 'Chinês';
      case 'ja':
        return 'Japonês';
      default:
        return guideLanguage!;
    }
  }

  NewYorkTourPackage copyWith({
    String? id,
    String? name,
    String? description,
    String? shortDescription,
    String? category,
    String? duration,
    int? estimatedHours,
    double? price,
    String? currency,
    String? originalPrice,
    double? discountPercentage,
    int? maxGroupSize,
    int? minGroupSize,
    List<String>? includedAttractions,
    List<String>? includedServices,
    List<String>? excludedServices,
    List<String>? highlights,
    String? meetingPoint,
    String? endingPoint,
    String? transportation,
    bool? includesGuide,
    bool? includesMeals,
    bool? includesTickets,
    bool? includesTransportation,
    String? guideLanguage,
    String? difficultyLevel,
    bool? isWheelchairAccessible,
    bool? isFamilyFriendly,
    String? bestTimeToVisit,
    String? seasonality,
    List<String>? photos,
    double? rating,
    int? reviewCount,
    List<String>? tags,
    Map<String, dynamic>? schedule,
    Map<String, dynamic>? cancellationPolicy,
    Map<String, dynamic>? weatherPolicy,
    List<String>? requirements,
    List<String>? recommendations,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NewYorkTourPackage(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      originalPrice: originalPrice ?? this.originalPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      maxGroupSize: maxGroupSize ?? this.maxGroupSize,
      minGroupSize: minGroupSize ?? this.minGroupSize,
      includedAttractions: includedAttractions ?? this.includedAttractions,
      includedServices: includedServices ?? this.includedServices,
      excludedServices: excludedServices ?? this.excludedServices,
      highlights: highlights ?? this.highlights,
      meetingPoint: meetingPoint ?? this.meetingPoint,
      endingPoint: endingPoint ?? this.endingPoint,
      transportation: transportation ?? this.transportation,
      includesGuide: includesGuide ?? this.includesGuide,
      includesMeals: includesMeals ?? this.includesMeals,
      includesTickets: includesTickets ?? this.includesTickets,
      includesTransportation: includesTransportation ?? this.includesTransportation,
      guideLanguage: guideLanguage ?? this.guideLanguage,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      isWheelchairAccessible: isWheelchairAccessible ?? this.isWheelchairAccessible,
      isFamilyFriendly: isFamilyFriendly ?? this.isFamilyFriendly,
      bestTimeToVisit: bestTimeToVisit ?? this.bestTimeToVisit,
      seasonality: seasonality ?? this.seasonality,
      photos: photos ?? this.photos,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      tags: tags ?? this.tags,
      schedule: schedule ?? this.schedule,
      cancellationPolicy: cancellationPolicy ?? this.cancellationPolicy,
      weatherPolicy: weatherPolicy ?? this.weatherPolicy,
      requirements: requirements ?? this.requirements,
      recommendations: recommendations ?? this.recommendations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 
