import 'package:json_annotation/json_annotation.dart';
import '../utils/currency_utils.dart';

part 'car.g.dart';

@JsonSerializable()
class Car {
  final int id;
  final String make;
  final String model;
  final int year;
  @JsonKey(name: 'license_plate')
  final String licensePlate;
  @JsonKey(name: 'photo_url')
  final String? photoUrl;
  final int? capacity;
  @JsonKey(name: 'has_wifi', defaultValue: false)
  final bool hasWifi;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'price_usd')
  final double? priceUsd;
  @JsonKey(name: 'price_updated_at')
  final DateTime? priceUpdatedAt;
  @JsonKey(name: 'price_source')
  final String? priceSource;
  @JsonKey(name: 'price_status')
  final String? priceStatus;

  Car({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
    this.photoUrl,
    this.capacity,
    required this.hasWifi,
    required this.createdAt,
    required this.updatedAt,
    this.priceUsd,
    this.priceUpdatedAt,
    this.priceSource,
    this.priceStatus,
  });

  factory Car.fromJson(Map<String, dynamic> json) => _$CarFromJson(json);
  Map<String, dynamic> toJson() => _$CarToJson(this);

  String get displayName => '$make $model ($licensePlate)';
  
  String get formattedPrice {
    if (priceUsd == null) return 'Preço não disponível';
    return CurrencyUtils.formatCurrency(priceUsd!);
  }
  
  String get priceStatusDisplay {
    switch (priceStatus) {
      case 'current':
        return 'Atualizado';
      case 'outdated':
        return 'Desatualizado';
      case 'estimated':
        return 'Estimado';
      default:
        return 'Não definido';
    }
  }
  
  bool get hasPrice => priceUsd != null && priceUsd! > 0;
}
