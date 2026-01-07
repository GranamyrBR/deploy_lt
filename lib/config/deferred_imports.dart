// ============================================
// Deferred Loading Configuration
// Baseado na estratégia do Lukas Nevosad
// ============================================

// Carregar bibliotecas pesadas sob demanda
// Nota: Apenas bibliotecas que já estão no pubspec.yaml

// Charts - Syncfusion (já no pubspec.yaml)
import 'package:syncfusion_flutter_charts/charts.dart' deferred as charts;
import 'package:syncfusion_flutter_gauges/gauges.dart' deferred as gauges;

// PDF (já no pubspec.yaml)
import 'package:pdf/pdf.dart' deferred as pdf;
import 'package:pdf/widgets.dart' deferred as pdf_widgets;

// ============================================
// Loader Functions
// ============================================

/// Carrega biblioteca de charts
Future<void> loadCharts() async {
  try {
    await charts.loadLibrary();
    print('✅ Charts library loaded');
  } catch (e) {
    print('⚠️ Charts already loaded or error: $e');
  }
}

/// Carrega biblioteca de gauges
Future<void> loadGauges() async {
  try {
    await gauges.loadLibrary();
    print('✅ Gauges library loaded');
  } catch (e) {
    print('⚠️ Gauges already loaded or error: $e');
  }
}

/// Carrega biblioteca de PDF
Future<void> loadPdf() async {
  try {
    await pdf.loadLibrary();
    await pdf_widgets.loadLibrary();
    print('✅ PDF libraries loaded');
  } catch (e) {
    print('⚠️ PDF already loaded or error: $e');
  }
}

/// Carrega todas as bibliotecas pesadas em background
Future<void> preloadAllLibraries() async {
  print('🔄 Preloading heavy libraries in background...');
  
  // Carregar em paralelo
  await Future.wait([
    loadCharts(),
    loadGauges(),
    loadPdf(),
  ]);
  
  print('✅ All heavy libraries preloaded');
}

/// Inicializa o sistema de deferred loading
/// Chame isso na inicialização do app (após login ou splash)
Future<void> initDeferredLoading() async {
  // Aguarda 3 segundos após o app carregar
  // para não competir com a renderização inicial
  Future.delayed(const Duration(seconds: 3), () {
    preloadAllLibraries().catchError((error) {
      print('⚠️ Error preloading libraries: $error');
    });
  });
}
