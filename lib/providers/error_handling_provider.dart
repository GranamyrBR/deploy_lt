import 'package:flutter_riverpod/flutter_riverpod.dart';

// Wrapper para providers que trata erros automaticamente
class ErrorHandlingProvider<T> extends AutoDisposeAsyncNotifier<T> {
  @override
  Future<T> build() async {
    try {
      return await _buildInternal();
    } catch (error, stackTrace) {
      print('Erro capturado pelo ErrorHandlingProvider: $error');
      print('Stack trace: $stackTrace');
      
      // Retornar um valor padrão ou re-throw dependendo do tipo
      if (T == List) {
        return [] as T;
      } else if (T == Map) {
        return {} as T;
      } else if (T == String) {
        return '' as T;
      } else if (T == int) {
        return 0 as T;
      } else if (T == double) {
        return 0.0 as T;
      } else if (T == bool) {
        return false as T;
      }
      
      // Para outros tipos, re-throw o erro
      throw error;
    }
  }
  
  Future<T> _buildInternal() async {
    throw UnimplementedError('Subclasses devem implementar _buildInternal');
  }
}

// Mixin para providers que precisam de tratamento de erro
mixin ErrorHandlingMixin<T> on AutoDisposeAsyncNotifier<T> {
  @override
  Future<T> build() async {
    try {
      return await buildInternal();
    } catch (error, stackTrace) {
      print('Erro capturado pelo ErrorHandlingMixin: $error');
      print('Stack trace: $stackTrace');
      
      // Retornar valor padrão baseado no tipo
      return _getDefaultValue();
    }
  }
  
  Future<T> buildInternal();
  
  T _getDefaultValue() {
    if (T == List) {
      return [] as T;
    } else if (T == Map) {
      return {} as T;
    } else if (T == String) {
      return '' as T;
    } else if (T == int) {
      return 0 as T;
    } else if (T == double) {
      return 0.0 as T;
    } else if (T == bool) {
      return false as T;
    }
    
    throw UnimplementedError('Tipo $T não suportado para valor padrão');
  }
}

// Provider wrapper que trata erros
class SafeAsyncProvider<T> extends AutoDisposeAsyncNotifier<T> {
  final Future<T> Function() _builder;
  final T _defaultValue;
  
  SafeAsyncProvider(this._builder, this._defaultValue);
  
  @override
  Future<T> build() async {
    try {
      return await _builder();
    } catch (error, stackTrace) {
      print('Erro capturado pelo SafeAsyncProvider: $error');
      print('Stack trace: $stackTrace');
      return _defaultValue;
    }
  }
}

// Função helper para criar providers seguros
FutureProvider<T> safeProvider<T>(
  Future<T> Function() builder,
  T defaultValue,
) {
  return FutureProvider<T>((ref) async {
    try {
      return await builder();
    } catch (error, stackTrace) {
      print('Erro capturado pelo safeProvider: $error');
      print('Stack trace: $stackTrace');
      return defaultValue;
    }
  });
}

// Provider wrapper específico para listas
class SafeListProvider<T> extends AutoDisposeAsyncNotifier<List<T>> {
  final Future<List<T>> Function() _builder;
  
  SafeListProvider(this._builder);
  
  @override
  Future<List<T>> build() async {
    try {
      return await _builder();
    } catch (error, stackTrace) {
      print('Erro capturado pelo SafeListProvider: $error');
      print('Stack trace: $stackTrace');
      return [];
    }
  }
}

// Função helper para criar providers de lista seguros
FutureProvider<List<T>> safeListProvider<T>(
  Future<List<T>> Function() builder,
) {
  return FutureProvider<List<T>>((ref) async {
    try {
      return await builder();
    } catch (error, stackTrace) {
      print('Erro capturado pelo safeListProvider: $error');
      print('Stack trace: $stackTrace');
      return [];
    }
  });
} 
