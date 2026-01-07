import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart'; // Added for FlutterError and PlatformDispatcher
import 'package:intl/date_symbol_data_local.dart'; // Para formatação de datas em PT-BR

import 'config/supabase_config.dart';
import 'providers/theme_provider.dart';
import 'providers/localization_provider.dart';
import 'providers/auth_provider.dart';
import 'services/localization_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/global_search_screen.dart';
import 'design/app_theme.dart';
import 'utils/timezone_utils.dart';
import 'screens/seller_dashboard_screen.dart';
import 'screens/seller_kanban_screen.dart';
import 'screens/customer_profile_screen.dart';
import 'screens/contacts_multi_view_screen.dart';
import 'screens/contacts_grid_table_screen.dart';
import 'screens/quotations_screen_premium.dart';
import 'models/user_roles.dart';

bool _hydratedAuth = false;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar timezone data
  TimezoneUtils.initialize();
  
  // Inicializar formatação de datas em português
  await initializeDateFormatting('pt_BR', null);
  
  // Configurar tratamento de erros global
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Erro Flutter capturado: ${details.exception}');
    print('Stack trace: ${details.stack}');
    // Não deixar o app sair, apenas logar o erro
  };
  
  // Configurar tratamento de erros assíncronos
  PlatformDispatcher.instance.onError = (error, stack) {
    print('Erro assíncrono capturado: $error');
    print('Stack trace: $stack');
    // Não deixar o app sair, apenas logar o erro
    return true;
  };
  
  // Load environment variables (ignore errors if .env doesn't exist)
  try {
    if (!kIsWeb) {
      await dotenv.load(fileName: ".env");
      print('✅ .env file loaded successfully');
    } else {
      print('ℹ️ Web build: pulando carregamento de .env (usando fallback)');
    }
  } catch (e) {
    print('⚠️ .env file not found, using default values: $e');
  }
  
  // Inicializar Supabase antes de qualquer provider/UI
  try {
    await SupabaseConfig.initialize();
    print('✅ Supabase inicializado');
  } catch (e, st) {
    print('Erro ao inicializar Supabase: $e');
    print('Stack: $st');
    // Fallback direto em desenvolvimento
    try {
      await Supabase.initialize(
        url: 'https://sup.axioscode.com',
        anonKey: 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTc1MjU5MDI4MCwiZXhwIjo0OTA4MjYzODgwLCJyb2xlIjoiYW5vbiJ9.nnCYUuqOTv_ZFZXy6u7-gDQc_VMCc9veZDrQ0rDWJhA',
      );
      print('✅ Supabase inicializado (fallback)');
    } catch (e2, st2) {
      print('Erro no fallback Supabase: $e2');
      print('Stack fallback: $st2');
    }
  }

  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: LocalizationService.supportedLocales,
      path: 'translations',
      fallbackLocale: const Locale('pt', 'BR'),
      child: const ProviderScope(child: LecotourApp()),
    ),
  );
}

class LecotourApp extends ConsumerWidget {
  const LecotourApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);
    final currentLanguage = ref.watch(currentLanguageProvider);
    final supaUser = Supabase.instance.client.auth.currentUser;
    if (supaUser != null && !_hydratedAuth) {
      Future.microtask(() async {
        final svc = ref.read(authServiceProvider);
        final profile = await svc.getUserById(supaUser.id);
        if (profile != null) {
          await ref.read(authProvider.notifier).setCurrentUser(profile);
          _hydratedAuth = true;
        }
      });
    }
    
    return MaterialApp(
      title: 'app.title'.tr(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(themeProvider),
      home: authState.isAuthenticated ? const DashboardScreen() : const LoginScreen(),
      routes: {
        '/global-search': (context) => const GlobalSearchScreen(),
        '/seller-dashboard': (context) => const SellerDashboardScreen(),
        '/seller-kanban': (context) => const SellerKanbanScreen(),
        '/quotations': (context) => const QuotationsScreenPremium(),
        '/customer-profile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            final id = args['customerId'] as int;
            final name = (args['customerName'] ?? '') as String;
            return CustomerProfileScreen(customerId: id, customerName: name);
          }
          return const Scaffold(body: Center(child: Text('Parâmetros inválidos para /customer-profile')));
        },
        '/contacts-multi': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            final contacts = (args['contacts'] as List).cast<Map<String, dynamic>>();
            final onOpenProfileModal = args['onOpenProfileModal'] as void Function(Map<String, dynamic>);
            final onOpenProfilePage = args['onOpenProfilePage'] as void Function(Map<String, dynamic>);
            final onOpenWhatsApp = args['onOpenWhatsApp'] as void Function(Map<String, dynamic>);
            final onCreateSale = args['onCreateSale'] as void Function(Map<String, dynamic>);
            return ContactsMultiViewScreen(
              contacts: contacts,
              onOpenProfileModal: onOpenProfileModal,
              onOpenProfilePage: onOpenProfilePage,
              onOpenWhatsApp: onOpenWhatsApp,
              onCreateSale: onCreateSale,
            );
          }
          return const Scaffold(body: Center(child: Text('Parâmetros inválidos para /contacts-multi')));
        },
        '/contacts-grid': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            final contacts = (args['contacts'] as List).cast<Map<String, dynamic>>();
            final onOpenProfileModal = args['onOpenProfileModal'] as void Function(Map<String, dynamic>);
            final onOpenProfilePage = args['onOpenProfilePage'] as void Function(Map<String, dynamic>);
            final onOpenWhatsApp = args['onOpenWhatsApp'] as void Function(Map<String, dynamic>);
            final onCreateSale = args['onCreateSale'] as void Function(Map<String, dynamic>);
            return ContactsGridTableScreen(
              contacts: contacts,
              onOpenProfileModal: onOpenProfileModal,
              onOpenProfilePage: onOpenProfilePage,
              onOpenWhatsApp: onOpenWhatsApp,
              onCreateSale: onCreateSale,
            );
          }
          return const Scaffold(body: Center(child: Text('Parâmetros inválidos para /contacts-grid')));
        },
      },
    );
  }
}
