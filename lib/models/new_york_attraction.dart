import 'package:json_annotation/json_annotation.dart';

part 'new_york_attraction.g.dart';

@JsonSerializable()
class NewYorkAttraction {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? category; // tourist_attraction, museum, park, etc.
  final String? neighborhood; // Manhattan, Brooklyn, etc.
  final double? rating;
  final int? reviewCount;
  final String? priceLevel; // $, $$, $$$, $$$$
  final String? openingHours;
  final String? phone;
  final String? website;
  final List<String>? photos;
  final List<String>? tags; // ["family-friendly", "romantic", "cultural", etc.]
  final Map<String, dynamic>? pricing;
  final String? bestTimeToVisit;
  final int? estimatedDuration; // em minutos
  final bool? isWheelchairAccessible;
  final bool? isFamilyFriendly;
  final String? seasonality; // "year-round", "spring", "summer", "fall", "winter"
  final String? crowdLevel; // "low", "medium", "high"
  final List<String>? nearbyAttractions;
  final Map<String, dynamic>? weatherInfo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  NewYorkAttraction({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.latitude,
    this.longitude,
    this.category,
    this.neighborhood,
    this.rating,
    this.reviewCount,
    this.priceLevel,
    this.openingHours,
    this.phone,
    this.website,
    this.photos,
    this.tags,
    this.pricing,
    this.bestTimeToVisit,
    this.estimatedDuration,
    this.isWheelchairAccessible,
    this.isFamilyFriendly,
    this.seasonality,
    this.crowdLevel,
    this.nearbyAttractions,
    this.weatherInfo,
    this.createdAt,
    this.updatedAt,
  });

  factory NewYorkAttraction.fromJson(Map<String, dynamic> json) =>
      _$NewYorkAttractionFromJson(json);

  Map<String, dynamic> toJson() => _$NewYorkAttractionToJson(this);

  // Getters úteis
  String get formattedRating {
    if (rating == null) return 'N/A';
    return '${rating!.toStringAsFixed(1)} ⭐';
  }

  String get formattedPrice {
    if (priceLevel == null) return 'Preço não informado';
    return priceLevel!;
  }

  String get formattedDuration {
    if (estimatedDuration == null) return 'Duração não informada';
    if (estimatedDuration! < 60) {
      return '$estimatedDuration min';
    } else {
      final hours = estimatedDuration! ~/ 60;
      final minutes = estimatedDuration! % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}min';
      }
    }
  }

  String get formattedAddress {
    if (address == null) return 'Endereço não informado';
    return address!;
  }

  bool get isPopular => rating != null && rating! >= 4.0;

  bool get isBudgetFriendly => priceLevel == '\$' || priceLevel == '\$\$';

  bool get isPremium => priceLevel == '\$\$\$\$';

  String get categoryDisplay {
    switch (category) {
      case 'tourist_attraction':
        return 'Atração Turística';
      case 'museum':
        return 'Museu';
      case 'park':
        return 'Parque';
      case 'landmark':
        return 'Marco Histórico';
      case 'entertainment':
        return 'Entretenimento';
      case 'shopping':
        return 'Shopping';
      case 'restaurant':
        return 'Restaurante';
      case 'theater':
        return 'Teatro';
      case 'gallery':
        return 'Galeria';
      case 'monument':
        return 'Monumento';
      default:
        return category ?? 'Outro';
    }
  }

  String get neighborhoodDisplay {
    switch (neighborhood) {
      case 'Manhattan':
        return 'Manhattan';
      case 'Brooklyn':
        return 'Brooklyn';
      case 'Queens':
        return 'Queens';
      case 'Bronx':
        return 'Bronx';
      case 'Staten Island':
        return 'Staten Island';
      case 'Midtown':
        return 'Midtown Manhattan';
      case 'Downtown':
        return 'Downtown Manhattan';
      case 'Uptown':
        return 'Uptown Manhattan';
      case 'Times Square':
        return 'Times Square';
      case 'Central Park':
        return 'Central Park';
      case 'Financial District':
        return 'Financial District';
      case 'SoHo':
        return 'SoHo';
      case 'Chelsea':
        return 'Chelsea';
      case 'Greenwich Village':
        return 'Greenwich Village';
      case 'Upper East Side':
        return 'Upper East Side';
      case 'Upper West Side':
        return 'Upper West Side';
      case 'Harlem':
        return 'Harlem';
      case 'Williamsburg':
        return 'Williamsburg';
      case 'DUMBO':
        return 'DUMBO';
      default:
        return neighborhood ?? 'Nova York';
    }
  }

  String get crowdLevelDisplay {
    switch (crowdLevel) {
      case 'low':
        return 'Baixo';
      case 'medium':
        return 'Médio';
      case 'high':
        return 'Alto';
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

  NewYorkAttraction copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    String? category,
    String? neighborhood,
    double? rating,
    int? reviewCount,
    String? priceLevel,
    String? openingHours,
    String? phone,
    String? website,
    List<String>? photos,
    List<String>? tags,
    Map<String, dynamic>? pricing,
    String? bestTimeToVisit,
    int? estimatedDuration,
    bool? isWheelchairAccessible,
    bool? isFamilyFriendly,
    String? seasonality,
    String? crowdLevel,
    List<String>? nearbyAttractions,
    Map<String, dynamic>? weatherInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NewYorkAttraction(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      neighborhood: neighborhood ?? this.neighborhood,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      priceLevel: priceLevel ?? this.priceLevel,
      openingHours: openingHours ?? this.openingHours,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      photos: photos ?? this.photos,
      tags: tags ?? this.tags,
      pricing: pricing ?? this.pricing,
      bestTimeToVisit: bestTimeToVisit ?? this.bestTimeToVisit,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      isWheelchairAccessible: isWheelchairAccessible ?? this.isWheelchairAccessible,
      isFamilyFriendly: isFamilyFriendly ?? this.isFamilyFriendly,
      seasonality: seasonality ?? this.seasonality,
      crowdLevel: crowdLevel ?? this.crowdLevel,
      nearbyAttractions: nearbyAttractions ?? this.nearbyAttractions,
      weatherInfo: weatherInfo ?? this.weatherInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 
