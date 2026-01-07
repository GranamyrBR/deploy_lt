import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account_employee.dart';
import '../models/account_employee_dto.dart';

// Use autoDispose to prevent caching the results for too long
final accountEmployeesProvider = FutureProvider.autoDispose.family<List<AccountEmployee>, int>((ref, accountId) async {
  print('DEBUG: Fetching employees for account $accountId');
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('account_employee')
      .select('*')
      .eq('account_id', accountId)
      .order('name');
  
  print('DEBUG: Found ${response.length} employees for account $accountId');
  
  return (response as List)
      .map((json) => AccountEmployee.fromJson(json as Map<String, dynamic>))
      .toList();
});

final addAccountEmployeeProvider = FutureProvider.family<void, AccountEmployee>((ref, employee) async {
  final supabase = Supabase.instance.client;
  
  // Convert to DTO to ensure we don't include the ID field
  final dto = AccountEmployeeDto.fromAccountEmployee(employee);
  
  // Get the map with the correct field names for the database
  final employeeData = dto.toMap();
  
  // Debug print to check the data
  print('DEBUG: Employee data for insert: $employeeData');
  
  try {
    await supabase.from('account_employee').insert(employeeData);
    print('DEBUG: Employee inserted successfully');
  } catch (e) {
    print('DEBUG: Error inserting employee: $e');
    rethrow;
  }
});

final updateAccountEmployeeProvider = FutureProvider.family<void, AccountEmployee>((ref, employee) async {
  final supabase = Supabase.instance.client;
  
  // Create a clean map with the correct field names
  final Map<String, dynamic> employeeData = {
    'account_id': employee.accountId,
    'name': employee.name,
    'position_id': employee.positionId,
    'department_id': employee.departmentId,
    'email': employee.email,
    'phone': employee.phone,
    'whatsapp': employee.whatsapp,
    'is_primary_contact': employee.isPrimaryContact,
    'is_decision_maker': employee.isDecisionMaker,
    'is_active': employee.isActive,
    'hierarchy_level': employee.hierarchyLevel,
    'preferred_contact_method': employee.preferredContactMethod,
    'notes': employee.notes,
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  };
  
  // Debug print to check the data
  print('DEBUG: Employee data for update: $employeeData');
  
  await supabase
      .from('account_employee')
      .update(employeeData)
      .eq('id', employee.id);
});

final deleteAccountEmployeeProvider = FutureProvider.family<void, int>((ref, employeeId) async {
  final supabase = Supabase.instance.client;
  await supabase.from('account_employee').delete().eq('id', employeeId);
}); 
