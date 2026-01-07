import 'agency_model.dart';
import 'contact.dart';

class SampleData {
  static final List<Agency> agencies = [
    Agency(
      id: 'agency_1',
      name: 'Viagens Brasil Tour',
      cnpj: '12.345.678/0001-90',
      email: 'contato@brasilviagens.com.br',
      phone: '+55 11 1234-5678',
      address: 'Rua Augusta, 1000',
      city: 'São Paulo',
      state: 'SP',
      cep: '01305-100',
      contactPerson: 'Maria Silva',
      commissionRate: 15.0,
      paymentTerms: '30 dias após embarque',
      createdAt: DateTime.now(),
    ),
    Agency(
      id: 'agency_2',
      name: 'Tour América',
      cnpj: '98.765.432/0001-10',
      email: 'america@touramerica.com.br',
      phone: '+55 21 9876-5432',
      address: 'Av. Atlântica, 2000',
      city: 'Rio de Janeiro',
      state: 'RJ',
      cep: '22010-001',
      contactPerson: 'João Santos',
      commissionRate: 12.0,
      paymentTerms: '15 dias após embarque',
      createdAt: DateTime.now(),
    ),
    Agency(
      id: 'agency_3',
      name: 'Global Travel',
      cnpj: '11.222.333/0001-44',
      email: 'global@globaltravel.com.br',
      phone: '+55 31 3333-4444',
      address: 'Rua da Bahia, 1500',
      city: 'Belo Horizonte',
      state: 'MG',
      cep: '30160-010',
      contactPerson: 'Ana Costa',
      commissionRate: 18.0,
      paymentTerms: '45 dias após embarque',
      createdAt: DateTime.now(),
    ),
    Agency(
      id: 'agency_4',
      name: 'Nova York Express',
      cnpj: '55.666.777/0001-88',
      email: 'ny@novayorkexpress.com.br',
      phone: '+55 11 5555-6666',
      address: 'Av. Paulista, 1000',
      city: 'São Paulo',
      state: 'SP',
      cep: '01310-100',
      contactPerson: 'Carlos Oliveira',
      commissionRate: 20.0,
      paymentTerms: '30 dias após embarque',
      createdAt: DateTime.now(),
    ),
  ];

  static final List<Contact> contacts = [
    // Clientes
    Contact(
      id: 'contact_1',
      name: 'Roberto Silva',
      email: 'roberto.silva@email.com',
      phone: '+55 11 91234-5678',
      whatsapp: '+55 11 91234-5678',
      cpf: '123.456.789-00',
      city: 'São Paulo',
      state: 'SP',
      type: ContactType.client,
      createdAt: DateTime.now(),
    ),
    Contact(
      id: 'contact_2',
      name: 'Mariana Santos',
      email: 'mariana.santos@email.com',
      phone: '+55 21 98765-4321',
      whatsapp: '+55 21 98765-4321',
      cpf: '987.654.321-00',
      city: 'Rio de Janeiro',
      state: 'RJ',
      type: ContactType.client,
      createdAt: DateTime.now(),
    ),
    Contact(
      id: 'contact_3',
      name: 'Fernanda Costa',
      email: 'fernanda.costa@email.com',
      phone: '+55 31 92345-6789',
      whatsapp: '+55 31 92345-6789',
      cpf: '456.789.123-00',
      city: 'Belo Horizonte',
      state: 'MG',
      type: ContactType.client,
      createdAt: DateTime.now(),
    ),
    
    // Contatos de Agências
    Contact(
      id: 'contact_4',
      name: 'Maria Silva',
      email: 'maria.silva@brasilviagens.com.br',
      phone: '+55 11 1234-5678',
      whatsapp: '+55 11 91234-5678',
      city: 'São Paulo',
      state: 'SP',
      type: ContactType.agency,
      agencyId: 'agency_1',
      createdAt: DateTime.now(),
    ),
    Contact(
      id: 'contact_5',
      name: 'João Santos',
      email: 'joao.santos@touramerica.com.br',
      phone: '+55 21 9876-5432',
      whatsapp: '+55 21 98765-4321',
      city: 'Rio de Janeiro',
      state: 'RJ',
      type: ContactType.agency,
      agencyId: 'agency_2',
      createdAt: DateTime.now(),
    ),
    
    // Guias
    Contact(
      id: 'contact_6',
      name: 'Antonio Rodríguez',
      email: 'antonio.rodriguez@guiasny.com',
      phone: '+1 646 123-4567',
      whatsapp: '+1 646 123-4567',
      city: 'Nova York',
      state: 'NY',
      country: 'USA',
      type: ContactType.guide,
      notes: 'Guia profissional falante de espanhol e português',
      createdAt: DateTime.now(),
    ),
    Contact(
      id: 'contact_7',
      name: 'Carlos Mendoza',
      email: 'carlos.mendoza@guiasny.com',
      phone: '+1 917 987-6543',
      whatsapp: '+1 917 987-6543',
      city: 'Nova York',
      state: 'NY',
      country: 'USA',
      type: ContactType.guide,
      notes: 'Guia especializado em tours históricos e culturais',
      createdAt: DateTime.now(),
    ),
    
    // Motoristas
    Contact(
      id: 'contact_8',
      name: 'John Smith',
      email: 'john.smith@driversny.com',
      phone: '+1 718 555-1234',
      whatsapp: '+1 718 555-1234',
      city: 'Nova York',
      state: 'NY',
      country: 'USA',
      type: ContactType.driver,
      notes: 'Motorista profissional com van executiva',
      createdAt: DateTime.now(),
    ),
    Contact(
      id: 'contact_9',
      name: 'Michael Johnson',
      email: 'michael.johnson@driversny.com',
      phone: '+1 917 444-5678',
      whatsapp: '+1 917 444-5678',
      city: 'Nova York',
      state: 'NY',
      country: 'USA',
      type: ContactType.driver,
      notes: 'Motorista bilíngue inglês/português',
      createdAt: DateTime.now(),
    ),
    
    // Fornecedores
    Contact(
      id: 'contact_10',
      name: 'Central Park Tours',
      email: 'reservas@centralparktours.com',
      phone: '+1 212 123-4567',
      city: 'Nova York',
      state: 'NY',
      country: 'USA',
      type: ContactType.supplier,
      notes: 'Fornecedor de tours de bicicleta e caminhada no Central Park',
      createdAt: DateTime.now(),
    ),
  ];

  static List<Agency> getAgencies() => List.from(agencies);
  static List<Contact> getContacts() => List.from(contacts);
  
  static List<Contact> getContactsByType(ContactType type) {
    return contacts.where((contact) => contact.type == type).toList();
  }
  
  static List<Contact> getContactsByAgency(String agencyId) {
    return contacts.where((contact) => contact.agencyId == agencyId).toList();
  }
  
  static Agency? getAgencyById(String id) {
    try {
      return agencies.firstWhere((agency) => agency.id == id);
    } catch (e) {
      return null;
    }
  }
  
  static Contact? getContactById(String id) {
    try {
      return contacts.firstWhere((contact) => contact.id == id);
    } catch (e) {
      return null;
    }
  }
  
  static List<Agency> searchAgencies(String query) {
    query = query.toLowerCase();
    return agencies.where((agency) => 
      agency.name.toLowerCase().contains(query) ||
      (agency.contactPerson != null && agency.contactPerson!.toLowerCase().contains(query)) ||
      (agency.city != null && agency.city!.toLowerCase().contains(query))
    ).toList();
  }
  
  static List<Contact> searchContacts(String query) {
    query = query.toLowerCase();
    return contacts.where((contact) => 
      contact.name.toLowerCase().contains(query) ||
      (contact.email != null && contact.email!.toLowerCase().contains(query)) ||
      (contact.city != null && contact.city!.toLowerCase().contains(query))
    ).toList();
  }
}