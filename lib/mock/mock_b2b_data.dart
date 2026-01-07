// Mock data for Hub B2B (account-centric CRM)
// Cada entidade tem exemplos para visualização e testes

import '../models/account.dart';
// Importe outros models conforme necessário

final List<Account> mockAccounts = [
  Account(
    id: 1,
    name: 'MOCKADO1',
    contactName: 'Contato Principal 1',
    domain: 'mockado1.com',
    phone: '+55 11 99999-0001',
    email: 'contato1@mockado1.com',
    logoUrl: null,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    chaveId: null,
    isActive: true,
    accountType: 'Agência',
    agencyId: null,
    positionId: null,
    isPrimaryContact: true,
    whatsapp: '+55 11 98888-0001',
    extension: '101',
  ),
  Account(
    id: 2,
    name: 'MOCKADO2',
    contactName: 'Contato Principal 2',
    domain: 'mockado2.com',
    phone: '+55 21 99999-0002',
    email: 'contato2@mockado2.com',
    logoUrl: null,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    chaveId: null,
    isActive: true,
    accountType: 'Empresa',
    agencyId: null,
    positionId: null,
    isPrimaryContact: true,
    whatsapp: '+55 21 98888-0002',
    extension: '102',
  ),
];

// Exemplo de mock para account_contact
final List<Map<String, dynamic>> mockAccountContacts = [
  {
    'id': 1,
    'account_id': 1,
    'name': 'Contato MOCKADO1',
    'position': 'CEO',
    'department': 'Diretoria',
    'email': 'ceo@mockado1.com',
    'phone': '+55 11 90000-0001',
    'whatsapp': '+55 11 98888-0001',
    'extension': '201',
    'notes': 'Contato principal da agência MOCKADO1',
    'is_primary_contact': true,
    'is_decision_maker': true,
    'hierarchy_level': 1,
    'preferred_contact_method': 'email',
    'is_active': true,
    'created_at': DateTime.now(),
    'updated_at': DateTime.now(),
  },
  {
    'id': 2,
    'account_id': 2,
    'name': 'Contato MOCKADO2',
    'position': 'Financeiro',
    'department': 'Financeiro',
    'email': 'financeiro@mockado2.com',
    'phone': '+55 21 90000-0002',
    'whatsapp': '+55 21 98888-0002',
    'extension': '202',
    'notes': 'Contato financeiro da empresa MOCKADO2',
    'is_primary_contact': false,
    'is_decision_maker': false,
    'hierarchy_level': 3,
    'preferred_contact_method': 'whatsapp',
    'is_active': true,
    'created_at': DateTime.now(),
    'updated_at': DateTime.now(),
  },
];

// Repita o padrão acima para as demais tabelas CRM (account_interaction_log, account_client_ranking, etc)
// Use nomes como 'MOCKADO1', 'MOCKADO2' para fácil identificação
