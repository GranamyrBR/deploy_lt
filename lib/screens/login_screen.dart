import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/auth_provider.dart';
import '../design/design_tokens.dart';
import '../utils/responsive_utils.dart';
import '../widgets/base_components.dart';
import '../widgets/language_selector.dart';
import '../screens/dashboard_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      final authState = ref.read(authProvider);
      if (authState.isAuthenticated) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authState.errorMessage ?? 'errors.unknown_error'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isMobile = ResponsiveUtils.isMobile(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              DesignTokens.primaryBlue.withValues(alpha: 0.08),
              DesignTokens.secondaryBlue.withValues(alpha: 0.04),
              DesignTokens.neutral50,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Seletor de idioma no canto superior direito
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const LanguageSelector(),
              ),
            ),
            
            // Conteúdo principal
            Center(
              child: SingleChildScrollView(
                padding: ResponsiveUtils.getScreenPadding(context),
                child: ResponsiveContainer(
                  maxWidth: isMobile ? 400 : 500,
                  child: ModernCard(
                    elevation: 16,
                    borderRadius: DesignTokens.radius24,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(DesignTokens.radius24),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            DesignTokens.neutral50,
                          ],
                        ),
                      ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo da empresa
                          Container(
                            width: ResponsiveUtils.isMobile(context) ? 80 : 100,
                            height: ResponsiveUtils.isMobile(context) ? 80 : 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(DesignTokens.radius16),
                              boxShadow: DesignTokens.shadowLg,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(DesignTokens.radius16),
                              child: Image.asset(
                                'web/icons/lecotour.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    padding: const EdgeInsets.all(DesignTokens.spacing16),
                                    decoration: BoxDecoration(
                                      color: DesignTokens.primaryBlue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(DesignTokens.radius16),
                                    ),
                                    child: Icon(
                                      Icons.flight_takeoff,
                                      size: ResponsiveUtils.isMobile(context) ? 48 : 56,
                                      color: DesignTokens.primaryBlue,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: DesignTokens.spacing24),
                          
                          Text(
                            'LecoTour',
                            style: GoogleFonts.inter(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                mobile: 28,
                                tablet: 32,
                                desktop: 36,
                              ),
                              fontWeight: FontWeight.w700,
                              color: DesignTokens.primaryBlue,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: DesignTokens.spacing8),
                          
                          Text(
                            'Dashboard Profissional',
                            style: GoogleFonts.inter(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                mobile: 16,
                                tablet: 18,
                                desktop: 20,
                              ),
                              fontWeight: FontWeight.w500,
                              color: DesignTokens.neutral600,
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: DesignTokens.spacing40),

                          // Email Field
                          ModernTextField(
                            label: 'auth.email'.tr(),
                            hint: 'auth.email'.tr(),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'auth.email_required'.tr();
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'auth.email_invalid'.tr();
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: DesignTokens.spacing20),

                          // Password Field
                          ModernTextField(
                            label: 'auth.password'.tr(),
                            hint: 'auth.password'.tr(),
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            prefixIcon: Icon(
                              Icons.lock_outlined,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'auth.password_required'.tr();
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: DesignTokens.spacing32),

                          // Login Button
                          ModernButton(
                            text: 'auth.sign_in'.tr(),
                            onPressed: _handleLogin,
                            variant: ButtonVariant.primary,
                            size: ButtonSize.large,
                            icon: Icons.login,
                            isLoading: _isLoading ||
                            authState.isLoading,
                            isFullWidth: true,
                          ),
                          
                          const SizedBox(height: DesignTokens.spacing16),
                          
                          // Botão para modo desenvolvimento
                          if (kDebugMode)
                            TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sistema em modo desenvolvimento - Acesso direto ao dashboard'),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              },
                              child: const Text(
                                'Modo Desenvolvimento',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          const SizedBox(height: DesignTokens.spacing32),

                          // Help Text
                          Text(
                            'Faça login para acessar o dashboard',
                            style: GoogleFonts.inter(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                mobile: 13,
                                tablet: 14,
                                desktop: 15,
                              ),
                              fontWeight: FontWeight.w400,
                              color: DesignTokens.neutral500,
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
