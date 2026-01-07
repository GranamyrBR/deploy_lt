import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lecotour_dashboard/models/agency.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AgencyProviderState {
  final List<Agency> agencies;
  final bool isLoading;
  final String? errorMessage;

  AgencyProviderState({
    this.agencies = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  AgencyProviderState copyWith({
    List<Agency>? agencies,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AgencyProviderState(
      agencies: agencies ?? this.agencies,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AgencyNotifier extends StateNotifier<AgencyProviderState> {
  final SupabaseClient _supabase;

  AgencyNotifier(this._supabase) : super(AgencyProviderState()) {
    fetchAgencies();
  }

  Future<void> fetchAgencies() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final response = await _supabase
          .from('account')
          .select()
          .order('name', ascending: true);

      final agencies = (response as List<dynamic>)
          .map((data) => Agency.fromJson(data as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        agencies: agencies,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao buscar agências: $e',
      );
    }
  }

  Future<bool> addAgency({
    required String name,
    required String? email,
    required String? phone,
    required String? address,
    required String? cityName,
    required String? stateCode,
    required String? countryCode,
    required String? zipCode,
    required String? website,
    required String? contactPerson,
    required double? commissionRate,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Validar dados obrigatórios
      if (name.trim().isEmpty) {
        state = state.copyWith(
          isLoading: false, 
          errorMessage: 'Nome é obrigatório'
        );
        return false;
      }

      // Inserir nova agência no Supabase
      final response = await _supabase.from('account').insert({
        'name': name.trim(),
        'email': email?.trim().isEmpty == true ? null : email?.trim(),
        'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
        'address': address?.trim().isEmpty == true ? null : address?.trim(),
        'city_name': cityName?.trim().isEmpty == true ? null : cityName?.trim(),
        'state_code': stateCode?.trim().isEmpty == true ? null : stateCode?.trim(),
        'country_code': countryCode?.trim().isEmpty == true ? null : countryCode?.trim(),
        'zip_code': zipCode?.trim().isEmpty == true ? null : zipCode?.trim(),
        'website': website?.trim().isEmpty == true ? null : website?.trim(),
        'contact_person': contactPerson?.trim().isEmpty == true ? null : contactPerson?.trim(),
        'commission_rate': commissionRate,
        'is_active': true,
      }).select().single();

      // Criar objeto Agency a partir da resposta
      final newAgency = Agency.fromJson(response);
      
      // Atualizar a lista de agências
      final updatedAgencies = [...state.agencies, newAgency];
      updatedAgencies.sort((a, b) => a.name.compareTo(b.name));
      
      state = state.copyWith(
        agencies: updatedAgencies,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        errorMessage: 'Erro ao adicionar agência: $e'
      );
      return false;
    }
  }

  Future<bool> updateAgency({
    required int agencyId,
    required String name,
    required String? email,
    required String? phone,
    required String? address,
    required String? cityName,
    required String? stateCode,
    required String? countryCode,
    required String? zipCode,
    required String? website,
    required String? contactPerson,
    required double? commissionRate,
    required bool isActive,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Validar dados obrigatórios
      if (name.trim().isEmpty) {
        state = state.copyWith(
          isLoading: false, 
          errorMessage: 'Nome é obrigatório'
        );
        return false;
      }

      // Atualizar agência no Supabase
      await _supabase.from('account').update({
        'name': name.trim(),
        'email': email?.trim().isEmpty == true ? null : email?.trim(),
        'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
        'address': address?.trim().isEmpty == true ? null : address?.trim(),
        'city_name': cityName?.trim().isEmpty == true ? null : cityName?.trim(),
        'state_code': stateCode?.trim().isEmpty == true ? null : stateCode?.trim(),
        'country_code': countryCode?.trim().isEmpty == true ? null : countryCode?.trim(),
        'zip_code': zipCode?.trim().isEmpty == true ? null : zipCode?.trim(),
        'website': website?.trim().isEmpty == true ? null : website?.trim(),
        'contact_person': contactPerson?.trim().isEmpty == true ? null : contactPerson?.trim(),
        'commission_rate': commissionRate,
        'is_active': isActive,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', agencyId);

      // Recarregar dados para garantir sincronização
      await fetchAgencies();
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        errorMessage: 'Erro ao atualizar agência: $e'
      );
      return false;
    }
  }

  Future<bool> deleteAgency(int agencyId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Remover a agência
      await _supabase.from('account').delete().eq('id', agencyId);
      
      // Remover da lista local
      final updatedAgencies = state.agencies.where((a) => a.id != agencyId).toList();
      
      state = state.copyWith(
        agencies: updatedAgencies,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        errorMessage: 'Erro ao excluir agência: $e'
      );
      return false;
    }
  }

  Future<bool> toggleAgencyStatus(int agencyId) async {
    try {
      final agency = state.agencies.firstWhere((a) => a.id == agencyId);
      return await updateAgency(
        agencyId: agencyId,
        name: agency.name,
        email: agency.email,
        phone: agency.phone,
        address: agency.address,
        cityName: agency.cityName,
        stateCode: agency.stateCode,
        countryCode: agency.countryCode,
        zipCode: agency.zipCode,
        website: agency.website,
        contactPerson: agency.contactPerson,
        commissionRate: agency.commissionRate,
        isActive: !agency.isActive,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Erro ao alterar status da agência: $e'
      );
      return false;
    }
  }
}

final agencyProvider =
    StateNotifierProvider<AgencyNotifier, AgencyProviderState>((ref) {
  final supabase = Supabase.instance.client;
  return AgencyNotifier(supabase);
}); 
