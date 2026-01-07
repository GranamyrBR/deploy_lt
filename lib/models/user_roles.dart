// User role definitions for the application
// This file defines the roles and permissions for different user types

import '../models/user.dart';

// Role constants
class UserRoles {
  // Main roles
  static const String ADMIN = 'admin';
  static const String MANAGER = 'manager';
  static const String SELLER = 'seller';
  static const String VIEWER = 'viewer';
  
  // Permission constants
  static const String VIEW_ALL_SALES = 'view_all_sales';
  static const String VIEW_OWN_SALES = 'view_own_sales';
  static const String CREATE_SALE = 'create_sale';
  static const String EDIT_SALE = 'edit_sale';
  static const String DELETE_SALE = 'delete_sale';
  static const String VIEW_COST_CENTER = 'view_cost_center';
  static const String MANAGE_COST_CENTER = 'manage_cost_center';
  static const String MANAGE_USERS = 'manage_users';
  
  // Default permissions for each role
  static Map<String, List<String>> rolePermissions = {
    ADMIN: [
      VIEW_ALL_SALES,
      CREATE_SALE,
      EDIT_SALE,
      DELETE_SALE,
      VIEW_COST_CENTER,
      MANAGE_COST_CENTER,
      MANAGE_USERS,
    ],
    MANAGER: [
      VIEW_ALL_SALES,
      CREATE_SALE,
      EDIT_SALE,
      DELETE_SALE,
      MANAGE_USERS,
    ],
    SELLER: [
      VIEW_OWN_SALES,
      CREATE_SALE,
      EDIT_SALE,
    ],
    VIEWER: [
      VIEW_OWN_SALES,
    ],
  };
  
  // Helper method to get permissions for a role
  static List<String> getPermissionsForRole(String role) {
    return rolePermissions[role] ?? [];
  }
  
  // Helper method to check if a role has a specific permission
  static bool roleHasPermission(String role, String permission) {
    return rolePermissions[role]?.contains(permission) ?? false;
  }
}

// Extension on User class to add role-based methods
extension UserRoleExtension on User {
  // Check if user has a specific role
  bool hasRole(String role) {
    return permissions.contains(role);
  }
  
  // Check if user is a manager
  bool get isManager => hasRole(UserRoles.MANAGER) || isAdmin;
  
  // Check if user is a seller
  bool get isSeller => hasRole(UserRoles.SELLER);
  
  // Check if user can view all sales
  bool get canViewAllSales => hasPermission(UserRoles.VIEW_ALL_SALES);
  
  // Check if user can view cost center
  bool get canViewCostCenter => hasPermission(UserRoles.VIEW_COST_CENTER);
  
  // Check if user can manage cost center
  bool get canManageCostCenter => hasPermission(UserRoles.MANAGE_COST_CENTER);
}
