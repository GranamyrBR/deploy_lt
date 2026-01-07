import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/new_york_attraction.dart';
import '../models/new_york_tour_package.dart';
import '../models/new_york_weather.dart';
import '../services/new_york_service.dart';
import '../providers/google_maps_provider.dart';
import '../widgets/base_screen_layout.dart';
import '../widgets/google_maps_widget.dart';
import '../config/app_theme.dart';


// Providers
final newYorkServiceProvider = Provider<NewYorkService>((ref) {
  return NewYorkService();
});

// Provider estável para atrações que não muda constantemente
final attractionsProvider = FutureProvider.family<List<NewYorkAttraction>, String>((ref, filterKey) async {
  final service = ref.read(newYorkServiceProvider);
  // Parse filterKey para extrair parâmetros
  final parts = filterKey.split('|');
  final category = parts.length > 0 && parts[0] != 'null' ? parts[0] : null;
  final neighborhood = parts.length > 1 && parts[1] != 'null' ? parts[1] : null;
  final limit = parts.length > 2 ? int.tryParse(parts[2]) ?? 20 : 20;
  final sortBy = parts.length > 3 && parts[3] != 'null' ? parts[3] : null;
  
  return await service.getAttractions(
    category: category,
    neighborhood: neighborhood,
    limit: limit,
    sortBy: sortBy,
  );
});

// Provider estável para pacotes que não muda constantemente
final tourPackagesProvider = FutureProvider.family<List<NewYorkTourPackage>, String>((ref, filterKey) async {
  final service = ref.read(newYorkServiceProvider);
  // Parse filterKey para extrair parâmetros
  final parts = filterKey.split('|');
  final category = parts.length > 0 && parts[0] != 'null' ? parts[0] : null;
  final duration = parts.length > 1 && parts[1] != 'null' ? parts[1] : null;
  final maxPrice = parts.length > 2 ? double.tryParse(parts[2]) : null;
  final groupSize = parts.length > 3 ? int.tryParse(parts[3]) : null;
  final familyFriendly = parts.length > 4 ? parts[4] == 'true' : null;
  
  return await service.getTourPackages(
    category: category,
    duration: duration,
    maxPrice: maxPrice,
    groupSize: groupSize,
    familyFriendly: familyFriendly,
  );
});

final weatherProvider = FutureProvider<NewYorkWeather>((ref) async {
  final service = ref.read(newYorkServiceProvider);
  return await service.getCurrentWeather();
});

// Provider para APIs gratuitas do Google Maps (Fase 1)
final googleMapsProvider = ChangeNotifierProvider<GoogleMapsProvider>((ref) {
  return GoogleMapsProvider();
});

class NewYorkScreen extends ConsumerStatefulWidget {
  const NewYorkScreen({super.key});

  @override
  ConsumerState<NewYorkScreen> createState() => _NewYorkScreenState();
}

class _NewYorkScreenState extends ConsumerState<NewYorkScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';
  String _selectedNeighborhood = 'all';
  String _selectedDuration = 'all';
  double _maxPrice = 500.0;
  int _groupSize = 2;
  bool _familyFriendly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Nova York - Assistente de Viagens',
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWeatherTab(),
                _buildAttractionsTab(),
                _buildTourPackagesTab(),
                _buildRecommendationsTab(),
                _buildGoogleMapsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue,
            AppTheme.primaryBlue.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.location_city,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🗽 Nova York',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A cidade que nunca dorme - Ajude seus clientes a descobrir NYC',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryBlue,
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        tabs: const [
          Tab(icon: Icon(Icons.wb_sunny), text: 'Clima'),
          Tab(icon: Icon(Icons.place), text: 'Atrações'),
          Tab(icon: Icon(Icons.card_travel), text: 'Pacotes'),
          Tab(icon: Icon(Icons.recommend), text: 'Recomendações'),
          Tab(icon: Icon(Icons.map), text: 'Google Maps'),
        ],
      ),
    );
  }

  Widget _buildWeatherTab() {
    return Consumer(
      builder: (context, ref, child) {
        final weatherAsync = ref.watch(weatherProvider);
        
        return weatherAsync.when(
          data: (weather) => _buildWeatherContent(weather),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorWidget('Erro ao carregar clima: $error'),
        );
      },
    );
  }

  Widget _buildWeatherContent(NewYorkWeather weather) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeatherCard(weather),
          const SizedBox(height: 16),
          _buildTourismRecommendationCard(weather),
          const SizedBox(height: 16),
          _buildActivitiesCard(weather),
          const SizedBox(height: 16),
          _buildClothingCard(weather),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(NewYorkWeather weather) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getWeatherIcon(weather.description),
                  size: 48,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weather.formattedTemperature,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        weather.descriptionDisplay,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getTourismRatingColor(weather.tourismRating),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    weather.tourismRating,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildWeatherDetails(weather),
            if (weather.hourlyForecast != null) ...[
              const SizedBox(height: 16),
              _buildHourlyForecast(weather),
            ],
            if (weather.dailyForecast != null) ...[
              const SizedBox(height: 16),
              _buildDailyForecast(weather),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetails(NewYorkWeather weather) {
    return Column(
      children: [
        _buildWeatherRow('Sensação Térmica', weather.formattedFeelsLike, Icons.thermostat),
        _buildWeatherRow('Min/Max', weather.formattedMinMax, Icons.height),
        _buildWeatherRow('Umidade', weather.formattedHumidity, Icons.water_drop),
        _buildWeatherRow('Vento', '${weather.formattedWindSpeed} ${weather.windDirectionDisplay}', Icons.air),
        _buildWeatherRow('Visibilidade', weather.formattedVisibility, Icons.visibility),
        _buildWeatherRow('Precipitação', weather.formattedPrecipitation, Icons.cloud),
        _buildWeatherRow('Nascer do Sol', weather.sunrise, Icons.wb_sunny),
        _buildWeatherRow('Pôr do Sol', weather.sunset, Icons.nightlight_round),
      ],
    );
  }

  Widget _buildWeatherRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTourismRecommendationCard(NewYorkWeather weather) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.recommend, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                const Text(
                  'Recomendação para Turismo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              weather.tourismRecommendationDisplay,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              weather.bestTimeToVisitDisplay,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesCard(NewYorkWeather weather) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attractions, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                const Text(
                  'Atividades Recomendadas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...weather.recommendedActivities.map((activity) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(activity)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildClothingCard(NewYorkWeather weather) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.checkroom, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                const Text(
                  'Roupas Recomendadas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(weather.clothingRecommendations ?? weather.clothingRecommendationsComputed).map((clothing) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(clothing)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAttractionsTab() {
    return Column(
      children: [
        _buildAttractionsFilters(),
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final filterKey = '${_selectedCategory == 'all' ? 'null' : _selectedCategory}|${_selectedNeighborhood == 'all' ? 'null' : _selectedNeighborhood}|20|null';
              
              final attractionsAsync = ref.watch(attractionsProvider(filterKey));
              
              return attractionsAsync.when(
                data: (attractions) => _buildAttractionsList(attractions),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorWidget('Erro ao carregar atrações: $error'),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAttractionsFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Categoria',
                  _selectedCategory,
                  {
                    'all': 'Todas',
                    'tourist_attraction': 'Atrações Turísticas',
                    'museum': 'Museus',
                    'park': 'Parques',
                    'landmark': 'Marcos Históricos',
                    'entertainment': 'Entretenimento',
                    'shopping': 'Shopping',
                    'restaurant': 'Restaurantes',
                  },
                  (value) => setState(() => _selectedCategory = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  'Bairro',
                  _selectedNeighborhood,
                  {
                    'all': 'Todos',
                    'Manhattan': 'Manhattan',
                    'Brooklyn': 'Brooklyn',
                    'Queens': 'Queens',
                    'Times Square': 'Times Square',
                    'Central Park': 'Central Park',
                    'Financial District': 'Financial District',
                    'SoHo': 'SoHo',
                    'Chelsea': 'Chelsea',
                    'Upper East Side': 'Upper East Side',
                    'Upper West Side': 'Upper West Side',
                  },
                  (value) => setState(() => _selectedNeighborhood = value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    Map<String, String> options,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: options.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (newValue) => onChanged(newValue!),
          ),
        ),
      ],
    );
  }

  Widget _buildAttractionsList(List<NewYorkAttraction> attractions) {
    if (attractions.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma atração encontrada com os filtros selecionados',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: attractions.length,
      itemBuilder: (context, index) {
        final attraction = attractions[index];
        return _buildAttractionCard(attraction);
      },
    );
  }

  Widget _buildAttractionCard(NewYorkAttraction attraction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attraction.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        attraction.neighborhoodDisplay,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (attraction.isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Popular',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (attraction.description != null) ...[
              Text(
                attraction.description!,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                if (attraction.rating != null) ...[
                  Text(
                    attraction.formattedRating,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Text(
                  attraction.formattedPrice,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  attraction.formattedDuration,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    attraction.formattedAddress,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (attraction.tags != null && attraction.tags!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: attraction.tags!.take(3).map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTourPackagesTab() {
    return Column(
      children: [
        _buildTourPackagesFilters(),
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final filterKey = '${_selectedCategory == 'all' ? 'null' : _selectedCategory}|${_selectedDuration == 'all' ? 'null' : _selectedDuration}|${_maxPrice.toString()}|${_groupSize.toString()}|${_familyFriendly.toString()}';
              
              final packagesAsync = ref.watch(tourPackagesProvider(filterKey));
              
              return packagesAsync.when(
                data: (packages) => _buildTourPackagesList(packages),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorWidget('Erro ao carregar pacotes: $error'),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTourPackagesFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Categoria',
                  _selectedCategory,
                  {
                    'all': 'Todas',
                    'city_tour': 'City Tour',
                    'cultural': 'Cultural',
                    'food': 'Gastronômico',
                    'shopping': 'Shopping',
                    'nightlife': 'Vida Noturna',
                    'family': 'Familiar',
                    'romantic': 'Romântico',
                  },
                  (value) => setState(() => _selectedCategory = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  'Duração',
                  _selectedDuration,
                  {
                    'all': 'Todas',
                    'half_day': 'Meio Dia',
                    'full_day': 'Dia Inteiro',
                    'multi_day': 'Múltiplos Dias',
                  },
                  (value) => setState(() => _selectedDuration = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preço Máximo: \$${_maxPrice.toInt()}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Slider(
                      value: _maxPrice,
                      min: 50,
                      max: 500,
                      divisions: 45,
                      onChanged: (value) => setState(() => _maxPrice = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tamanho do Grupo: $_groupSize',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Slider(
                      value: _groupSize.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      onChanged: (value) => setState(() => _groupSize = value.toInt()),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: _familyFriendly,
                onChanged: (value) => setState(() => _familyFriendly = value!),
              ),
              const Text('Apenas Family-Friendly'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTourPackagesList(List<NewYorkTourPackage> packages) {
    if (packages.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum pacote encontrado com os filtros selecionados',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final package = packages[index];
        return _buildTourPackageCard(package);
      },
    );
  }

  Widget _buildTourPackageCard(NewYorkTourPackage package) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        package.categoryDisplay,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (package.hasDiscount) ...[
                      Text(
                        package.formattedOriginalPrice,
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          package.formattedDiscount,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    Text(
                      package.formattedPrice,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (package.shortDescription != null) ...[
              Text(
                package.shortDescription!,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  package.formattedDuration,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.group, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  package.groupSizeDisplay,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                if (package.rating != null) ...[
                  Text(
                    package.formattedRating,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (package.highlights.isNotEmpty) ...[
              Text(
                'Destaques:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: package.highlights.take(3).map((highlight) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    highlight,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                )).toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (package.includesGuide)
                  _buildFeatureChip('Guia', Icons.person),
                if (package.includesMeals)
                  _buildFeatureChip('Refeições', Icons.restaurant),
                if (package.includesTickets)
                  _buildFeatureChip('Ingressos', Icons.confirmation_number),
                if (package.includesTransportation)
                  _buildFeatureChip('Transporte', Icons.directions_bus),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.green),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecommendationCard(
            '🎯 Pacote Ideal para Primeira Viagem',
            'Para clientes que visitam NYC pela primeira vez, recomendamos:\n\n'
            '• City Tour Clássico (dia inteiro)\n'
            '• Estátua da Liberdade + Ellis Island\n'
            '• Times Square à noite\n'
            '• Central Park\n'
            '• Empire State Building\n\n'
            'Duração: 3-4 dias\n'
            'Orçamento: \$300-500 por pessoa',
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildRecommendationCard(
            '💕 Pacote Romântico',
            'Perfeito para casais e lua de mel:\n\n'
            '• Tour romântico privativo\n'
            '• Jantar no Top of the Rock\n'
            '• Passeio de barco no pôr do sol\n'
            '• Broadway show\n'
            '• Brooklyn Bridge à noite\n\n'
            'Duração: 2-3 dias\n'
            'Orçamento: \$500-800 por pessoa',
            Colors.pink,
          ),
          const SizedBox(height: 16),
          _buildRecommendationCard(
            '👨‍👩‍👧‍👦 Pacote Familiar',
            'Ideal para famílias com crianças:\n\n'
            '• Museus interativos (Natural History, Intrepid)\n'
            '• Central Park com atividades\n'
            '• Times Square (moderado)\n'
            '• Bronx Zoo\n'
            '• Coney Island (verão)\n\n'
            'Duração: 4-5 dias\n'
            'Orçamento: \$400-600 por pessoa',
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildRecommendationCard(
            '🎨 Pacote Cultural',
            'Para amantes de arte e cultura:\n\n'
            '• Metropolitan Museum\n'
            '• MoMA\n'
            '• Guggenheim\n'
            '• Broadway shows\n'
            '• Lincoln Center\n'
            '• Chelsea Galleries\n\n'
            'Duração: 3-4 dias\n'
            'Orçamento: \$350-550 por pessoa',
            Colors.purple,
          ),
          const SizedBox(height: 16),
          _buildRecommendationCard(
            '🍕 Pacote Gastronômico',
            'Para foodies e amantes da culinária:\n\n'
            '• Tour gastronômico\n'
            '• Little Italy\n'
            '• Chinatown\n'
            '• Chelsea Market\n'
            '• Restaurantes estrelados\n'
            '• Food trucks\n\n'
            'Duração: 2-3 dias\n'
            'Orçamento: \$250-400 por pessoa',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(String title, String content, Color color) {
    return Card(
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: color, width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String description) {
    switch (description.toLowerCase()) {
      case 'clear sky':
        return Icons.wb_sunny;
      case 'few clouds':
      case 'scattered clouds':
      case 'broken clouds':
        return Icons.cloud;
      case 'overcast clouds':
        return Icons.cloud_queue;
      case 'light rain':
      case 'moderate rain':
      case 'heavy rain':
        return Icons.grain;
      case 'light snow':
      case 'moderate snow':
      case 'heavy snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
        return Icons.opacity;
      default:
        return Icons.wb_sunny;
    }
  }

  Color _getTourismRatingColor(String rating) {
    switch (rating) {
      case 'Excelente':
        return Colors.green;
      case 'Boa':
        return Colors.lightGreen;
      case 'Regular':
        return Colors.orange;
      case 'Ruim':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildHourlyForecast(NewYorkWeather weather) {
    if (weather.hourlyForecast == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Previsão Horária (24h)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: weather.hourlyForecast!.length,
            itemBuilder: (context, index) {
              final hour = weather.hourlyForecast!.keys.elementAt(index);
              final data = weather.hourlyForecast![hour] as Map<String, dynamic>;
              
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      hour,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      _getWeatherIcon(data['description']),
                      size: 24,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data['temp'].round()}°C',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(data['pop'] * 100).round()}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailyForecast(NewYorkWeather weather) {
    if (weather.dailyForecast == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Previsão Semanal',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...weather.dailyForecast!.entries.map((entry) {
          final day = entry.key;
          final data = entry.value as Map<String, dynamic>;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  _getWeatherIcon(data['description']),
                  size: 24,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['description'],
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        '${data['temp_min'].round()}°C - ${data['temp_max'].round()}°C',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(data['pop'] * 100).round()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'UV: ${data['uvi'].toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // =====================================================
  // GOOGLE MAPS TAB (APIs GRATUITAS - FASE 1)
  // =====================================================

  Widget _buildGoogleMapsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final googleMaps = ref.watch(googleMapsProvider);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGoogleMapsHeader(),
              const SizedBox(height: 16),
              _buildGeocodingSection(googleMaps),
              const SizedBox(height: 16),
              _buildDirectionsSection(googleMaps),
              const SizedBox(height: 16),
              _buildDistanceMatrixSection(googleMaps),
              const SizedBox(height: 16),
              _buildOptimizedRouteSection(googleMaps),
              const SizedBox(height: 16),
              _buildUsageStatsSection(googleMaps),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGoogleMapsHeader() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.map,
                    color: AppTheme.primaryBlue,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🗺️ Google Maps APIs (Gratuitas)',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fase 1: Geocoding, Directions e Distance Matrix',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'APIs totalmente gratuitas: Geocoding (2.500/dia), Directions (2.500/dia), Distance Matrix (100/dia)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeocodingSection(GoogleMapsProvider googleMaps) {
    final TextEditingController addressController = TextEditingController();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                const Text(
                  '🌍 Geocoding API',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      hintText: 'Digite um endereço (ex: Times Square, NYC)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: googleMaps.isLoadingCoordinates
                      ? null
                      : () {
                          if (addressController.text.isNotEmpty) {
                            googleMaps.getCoordinates(addressController.text);
                          }
                        },
                  child: googleMaps.isLoadingCoordinates
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Buscar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (googleMaps.coordinates != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✅ Coordenadas encontradas:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Latitude: ${googleMaps.coordinates!['latitude']}'),
                    Text('Longitude: ${googleMaps.coordinates!['longitude']}'),
                    if (googleMaps.coordinates!['formatted_address'] != null)
                      Text('Endereço: ${googleMaps.coordinates!['formatted_address']}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GoogleMapsWidget(
                coordinates: googleMaps.coordinates,
                title: '📍 Localização no Mapa',
                height: 250,
              ),
            ],
            if (googleMaps.coordinatesError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '❌ ${googleMaps.coordinatesError}',
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionsSection(GoogleMapsProvider googleMaps) {
    final TextEditingController originController = TextEditingController();
    final TextEditingController destinationController = TextEditingController();
    String selectedMode = 'driving';
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                const Text(
                  '🗺️ Directions API',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: originController,
              decoration: const InputDecoration(
                hintText: 'Origem (ex: Times Square)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: destinationController,
              decoration: const InputDecoration(
                hintText: 'Destino (ex: Central Park)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedMode,
              decoration: const InputDecoration(
                labelText: 'Modo de transporte',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'driving', child: Text('Carro')),
                DropdownMenuItem(value: 'walking', child: Text('A pé')),
                DropdownMenuItem(value: 'bicycling', child: Text('Bicicleta')),
                DropdownMenuItem(value: 'transit', child: Text('Transporte público')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedMode = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: googleMaps.isLoadingDirections
                    ? null
                    : () {
                        if (originController.text.isNotEmpty && destinationController.text.isNotEmpty) {
                          googleMaps.getDirections(
                            origin: originController.text,
                            destination: destinationController.text,
                            mode: selectedMode,
                          );
                        }
                      },
                child: googleMaps.isLoadingDirections
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Calcular Rota'),
              ),
            ),
            const SizedBox(height: 12),
            if (googleMaps.directions != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✅ Rota calculada:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Distância: ${googleMaps.directions!['distance']}'),
                    Text('Duração: ${googleMaps.directions!['duration']}'),
                    Text('De: ${googleMaps.directions!['start_address']}'),
                    Text('Para: ${googleMaps.directions!['end_address']}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GoogleMapsWidget(
                directions: googleMaps.directions,
                title: '🗺️ Rota no Mapa',
                height: 300,
              ),
            ],
            if (googleMaps.directionsError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '❌ ${googleMaps.directionsError}',
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceMatrixSection(GoogleMapsProvider googleMaps) {
    final TextEditingController attractionsController = TextEditingController();
    String selectedMode = 'driving';
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.grid_on, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                const Text(
                  '📏 Distance Matrix API',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: attractionsController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Digite atrações separadas por vírgula\nEx: Times Square, Central Park, Empire State Building',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedMode,
              decoration: const InputDecoration(
                labelText: 'Modo de transporte',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'driving', child: Text('Carro')),
                DropdownMenuItem(value: 'walking', child: Text('A pé')),
                DropdownMenuItem(value: 'bicycling', child: Text('Bicicleta')),
                DropdownMenuItem(value: 'transit', child: Text('Transporte público')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedMode = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: googleMaps.isLoadingDistanceMatrix
                    ? null
                    : () {
                        if (attractionsController.text.isNotEmpty) {
                          final attractions = attractionsController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          if (attractions.isNotEmpty) {
                            googleMaps.getDistanceMatrix(
                              origins: attractions,
                              destinations: attractions,
                              mode: selectedMode,
                            );
                          }
                        }
                      },
                child: googleMaps.isLoadingDistanceMatrix
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Calcular Distâncias'),
              ),
            ),
            const SizedBox(height: 12),
            if (googleMaps.distanceMatrix != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✅ Distâncias calculadas:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...googleMaps.distanceMatrix!.take(5).map((distance) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${distance['origin']} → ${distance['destination']}: ${distance['distance']} (${distance['duration']})',
                        style: const TextStyle(fontSize: 12),
                      ),
                    )),
                    if (googleMaps.distanceMatrix!.length > 5)
                      Text(
                        '... e mais ${googleMaps.distanceMatrix!.length - 5} resultados',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (googleMaps.distanceMatrixError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '❌ ${googleMaps.distanceMatrixError}',
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizedRouteSection(GoogleMapsProvider googleMaps) {
    final TextEditingController attractionsController = TextEditingController();
    final TextEditingController startingPointController = TextEditingController();
    String selectedMode = 'driving';
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                const Text(
                  '🎯 Rota Otimizada',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: attractionsController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Digite atrações separadas por vírgula\nEx: Times Square, Central Park, Empire State Building',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: startingPointController,
              decoration: const InputDecoration(
                hintText: 'Ponto de partida (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedMode,
              decoration: const InputDecoration(
                labelText: 'Modo de transporte',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'driving', child: Text('Carro')),
                DropdownMenuItem(value: 'walking', child: Text('A pé')),
                DropdownMenuItem(value: 'bicycling', child: Text('Bicicleta')),
                DropdownMenuItem(value: 'transit', child: Text('Transporte público')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedMode = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: googleMaps.isLoadingOptimizedRoute
                    ? null
                    : () {
                        if (attractionsController.text.isNotEmpty) {
                          final attractions = attractionsController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          if (attractions.isNotEmpty) {
                            googleMaps.optimizeTourRoute(
                              attractions: attractions,
                              startingPoint: startingPointController.text.isNotEmpty 
                                  ? startingPointController.text 
                                  : null,
                              mode: selectedMode,
                            );
                          }
                        }
                      },
                child: googleMaps.isLoadingOptimizedRoute
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Otimizar Rota'),
              ),
            ),
            const SizedBox(height: 12),
            if (googleMaps.optimizedRoute != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✅ Rota otimizada:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Total de atrações: ${googleMaps.optimizedRoute!['total_attractions']}'),
                    Text('Modo: ${googleMaps.optimizedRoute!['mode']}'),
                    const SizedBox(height: 8),
                    const Text(
                      'Ordem otimizada:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    ...(googleMaps.optimizedRoute!['optimized_route'] as List<String>).asMap().entries.map((entry) {
                      final index = entry.key;
                      final attraction = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '${index + 1}. $attraction',
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
            if (googleMaps.optimizedRouteError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '❌ ${googleMaps.optimizedRouteError}',
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsageStatsSection(GoogleMapsProvider googleMaps) {
    final stats = googleMaps.getUsageStats();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                const Text(
                  '📊 Estatísticas de Uso',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tamanho do cache: ${stats['cache_size']}'),
                  const SizedBox(height: 8),
                  const Text(
                    'Últimas chamadas:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  ...(stats['last_calls'] as Map<String, String>).entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '${entry.key}: ${entry.value}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => googleMaps.clearCache(),
                    child: const Text('Limpar Cache'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => googleMaps.clearAll(),
                    child: const Text('Limpar Tudo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 
