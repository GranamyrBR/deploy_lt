import 'service_model.dart';
import 'product_model.dart';

class ServiceCatalog {
  static final List<Service> _services = [
    // Transfer Services
    Service(
      id: 'transfer_airport_hotel',
      name: 'Transfer Aeroporto - Hotel',
      description: 'Transfer privativo do aeroporto para hotel em NYC',
      type: ServiceType.transfer,
      category: ServiceCategory.private,
      basePrice: 180.0,
      commissionRate: 10.0,
      duration: '1-2 horas',
      includes: 'Motorista bilíngue, assistência com bagagem, água mineral',
      excludes: 'Gorjetas, extras pessoais',
      minPassengers: 1,
      maxPassengers: 4,
      requiresAdvanceBooking: true,
      advanceBookingDays: 2,
      createdAt: DateTime.now(),
    ),
    Service(
      id: 'transfer_hotel_airport',
      name: 'Transfer Hotel - Aeroporto',
      description: 'Transfer privativo do hotel para aeroporto em NYC',
      type: ServiceType.transfer,
      category: ServiceCategory.private,
      basePrice: 160.0,
      commissionRate: 10.0,
      duration: '1-2 horas',
      includes: 'Motorista bilíngue, assistência com bagagem',
      excludes: 'Gorjetas, extras pessoais',
      minPassengers: 1,
      maxPassengers: 4,
      requiresAdvanceBooking: true,
      advanceBookingDays: 2,
      createdAt: DateTime.now(),
    ),
    
    // City Tours
    Service(
      id: 'city_tour_nyc_4h',
      name: 'City Tour NYC - 4 horas',
      description: 'Tour panorâmico por Manhattan com paradas principais',
      type: ServiceType.cityTour,
      category: ServiceCategory.private,
      basePrice: 320.0,
      commissionRate: 15.0,
      duration: '4 horas',
      includes: 'Van privativa, motorista guia bilíngue, paradas para fotos',
      excludes: 'Ingressos, refeições, gorjetas',
      minPassengers: 1,
      maxPassengers: 12,
      requiresAdvanceBooking: true,
      advanceBookingDays: 1,
      createdAt: DateTime.now(),
    ),
    Service(
      id: 'city_tour_nyc_8h',
      name: 'City Tour NYC - 8 horas',
      description: 'Tour completo de NYC incluindo Brooklyn e Queens',
      type: ServiceType.cityTour,
      category: ServiceCategory.private,
      basePrice: 580.0,
      commissionRate: 15.0,
      duration: '8 horas',
      includes: 'Van privativa, motorista guia bilíngue, paradas para fotos e caminhadas',
      excludes: 'Ingressos, refeições, gorjetas',
      minPassengers: 1,
      maxPassengers: 12,
      requiresAdvanceBooking: true,
      advanceBookingDays: 1,
      createdAt: DateTime.now(),
    ),
    
    // Excursions
    Service(
      id: 'washington_dc_tour',
      name: 'Excursão Washington DC',
      description: 'Tour de 1 dia para Washington DC saindo de NYC',
      type: ServiceType.excursion,
      category: ServiceCategory.private,
      basePrice: 1200.0,
      commissionRate: 12.0,
      duration: '12-14 horas',
      includes: 'Van privativa, motorista guia bilíngue, paradas nos principais monumentos',
      excludes: 'Ingressos, refeições, gorjetas',
      minPassengers: 4,
      maxPassengers: 12,
      requiresAdvanceBooking: true,
      advanceBookingDays: 3,
      createdAt: DateTime.now(),
    ),
    Service(
      id: 'philadelphia_tour',
      name: 'Excursão Philadelphia',
      description: 'Tour de 1 dia para Philadelphia saindo de NYC',
      type: ServiceType.excursion,
      category: ServiceCategory.private,
      basePrice: 850.0,
      commissionRate: 12.0,
      duration: '10-12 horas',
      includes: 'Van privativa, motorista guia bilíngue, visita ao centro histórico',
      excludes: 'Ingressos, refeições, gorjetas',
      minPassengers: 4,
      maxPassengers: 12,
      requiresAdvanceBooking: true,
      advanceBookingDays: 2,
      createdAt: DateTime.now(),
    ),
    
    // Guide Services
    Service(
      id: 'guide_spanish_4h',
      name: 'Guia de Turismo - Espanhol',
      description: 'Guia profissional falante de espanhol por 4 horas',
      type: ServiceType.guide,
      category: ServiceCategory.private,
      basePrice: 280.0,
      commissionRate: 10.0,
      duration: '4 horas',
      includes: 'Guia profissional falante de espanhol',
      excludes: 'Transporte, ingressos, refeições',
      minPassengers: 1,
      maxPassengers: 20,
      requiresAdvanceBooking: true,
      advanceBookingDays: 1,
      createdAt: DateTime.now(),
    ),
    Service(
      id: 'guide_portuguese_4h',
      name: 'Guia de Turismo - Português',
      description: 'Guia profissional falante de português por 4 horas',
      type: ServiceType.guide,
      category: ServiceCategory.private,
      basePrice: 300.0,
      commissionRate: 10.0,
      duration: '4 horas',
      includes: 'Guia profissional falante de português',
      excludes: 'Transporte, ingressos, refeições',
      minPassengers: 1,
      maxPassengers: 20,
      requiresAdvanceBooking: true,
      advanceBookingDays: 1,
      createdAt: DateTime.now(),
    ),
  ];

  static final List<Product> _products = [
    // Tickets - Attractions
    Product(
      id: 'ticket_statue_liberty',
      name: 'Estátua da Liberdade - Ingresso',
      description: 'Ingresso para visitar a Estátua da Liberdade incluindo Ellis Island',
      type: ProductType.ticket,
      category: ProductCategory.attraction,
      basePrice: 25.0,
      commissionRate: 5.0,
      provider: 'National Park Service',
      location: 'Liberty Island, NYC',
      duration: '3-4 horas',
      validity: 'Válido por 1 dia',
      terms: 'Não reembolsável, válido na data selecionada',
      requiresReservation: true,
      advanceBookingDays: 7,
      isRefundable: false,
      createdAt: DateTime.now(),
    ),
    Product(
      id: 'ticket_empire_state',
      name: 'Empire State Building - Ingresso',
      description: 'Ingresso para observatório do Empire State Building',
      type: ProductType.ticket,
      category: ProductCategory.attraction,
      basePrice: 44.0,
      commissionRate: 8.0,
      provider: 'Empire State Building',
      location: '350 5th Ave, NYC',
      duration: '1-2 horas',
      validity: 'Válido por 1 dia',
      terms: 'Reembolsável até 24h antes',
      requiresReservation: true,
      advanceBookingDays: 1,
      isRefundable: true,
      refundPercentage: 80.0,
      createdAt: DateTime.now(),
    ),
    Product(
      id: 'ticket_one_world',
      name: 'One World Observatory - Ingresso',
      description: 'Ingresso para o observatório One World Trade Center',
      type: ProductType.ticket,
      category: ProductCategory.attraction,
      basePrice: 39.0,
      commissionRate: 8.0,
      provider: 'One World Observatory',
      location: 'One World Trade Center, NYC',
      duration: '1-2 horas',
      validity: 'Válido por 1 dia',
      terms: 'Reembolsável até 24h antes',
      requiresReservation: true,
      advanceBookingDays: 1,
      isRefundable: true,
      refundPercentage: 90.0,
      createdAt: DateTime.now(),
    ),
    
    // Tickets - Shows
    Product(
      id: 'ticket_broadway_show',
      name: 'Broadway Show - Ingresso',
      description: 'Ingresso para show da Broadway (escolha do cliente)',
      type: ProductType.ticket,
      category: ProductCategory.show,
      basePrice: 120.0,
      commissionRate: 10.0,
      provider: 'Broadway',
      location: 'Theater District, NYC',
      duration: '2-3 horas',
      validity: 'Válido na data do show',
      terms: 'Não reembolsável após confirmação',
      requiresReservation: true,
      advanceBookingDays: 14,
      isRefundable: false,
      createdAt: DateTime.now(),
    ),
    
    // Tickets - Museums
    Product(
      id: 'ticket_moma',
      name: 'MoMA - Museu de Arte Moderna',
      description: 'Ingresso para o Museu de Arte Moderna de Nova York',
      type: ProductType.ticket,
      category: ProductCategory.museum,
      basePrice: 25.0,
      commissionRate: 5.0,
      provider: 'MoMA',
      location: '11 W 53rd St, NYC',
      duration: '2-3 horas',
      validity: 'Válido por 1 dia',
      terms: 'Reembolsável até 48h antes',
      requiresReservation: false,
      isRefundable: true,
      refundPercentage: 100.0,
      createdAt: DateTime.now(),
    ),
    Product(
      id: 'ticket_met_museum',
      name: 'Metropolitan Museum - Ingresso',
      description: 'Ingresso para o Metropolitan Museum of Art',
      type: ProductType.ticket,
      category: ProductCategory.museum,
      basePrice: 30.0,
      commissionRate: 5.0,
      provider: 'Met Museum',
      location: '1000 5th Ave, NYC',
      duration: '3-4 horas',
      validity: 'Válido por 3 dias',
      terms: 'Reembolsável até 24h antes',
      requiresReservation: false,
      isRefundable: true,
      refundPercentage: 100.0,
      createdAt: DateTime.now(),
    ),
    
    // Transportation
    Product(
      id: 'ticket_metrocard_7day',
      name: 'MetroCard - 7 dias',
      description: 'MetroCard ilimitado por 7 dias para metrô e ônibus de NYC',
      type: ProductType.ticket,
      category: ProductCategory.transport,
      basePrice: 33.0,
      commissionRate: 0.0,
      provider: 'MTA',
      location: 'Nova York',
      duration: '7 dias',
      validity: 'Válido por 7 dias consecutivos',
      terms: 'Não reembolsável',
      requiresReservation: false,
      isRefundable: false,
      createdAt: DateTime.now(),
    ),
  ];

  static List<Service> getServices() => List.from(_services);
  static List<Product> getProducts() => List.from(_products);
  
  static List<Service> getServicesByType(ServiceType type) {
    return _services.where((service) => service.type == type).toList();
  }
  
  static List<Product> getProductsByType(ProductType type) {
    return _products.where((product) => product.type == type).toList();
  }
  
  static List<Service> getServicesByCategory(ServiceCategory category) {
    return _services.where((service) => service.category == category).toList();
  }
  
  static List<Product> getProductsByCategory(ProductCategory category) {
    return _products.where((product) => product.category == category).toList();
  }
  
  static Service? getServiceById(String id) {
    try {
      return _services.firstWhere((service) => service.id == id);
    } catch (e) {
      return null;
    }
  }
  
  static Product? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }
  
  static List<Service> searchServices(String query) {
    query = query.toLowerCase();
    return _services.where((service) => 
      service.name.toLowerCase().contains(query) ||
      service.description.toLowerCase().contains(query) ||
      service.type.toString().toLowerCase().contains(query)
    ).toList();
  }
  
  static List<Product> searchProducts(String query) {
    query = query.toLowerCase();
    return _products.where((product) => 
      product.name.toLowerCase().contains(query) ||
      product.description.toLowerCase().contains(query) ||
      (product.provider != null && product.provider!.toLowerCase().contains(query))
    ).toList();
  }
}