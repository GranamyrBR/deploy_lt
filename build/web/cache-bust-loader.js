// ============================================
// Cache Busting Loader - Estratégia Lukas Nevosad
// Garante que usuários sempre recebam a versão mais recente
// ============================================

(function() {
  'use strict';

  // Verificar nova versão disponível
  async function checkForUpdate() {
    try {
      const response = await fetch('/version.txt?t=' + Date.now(), {
        cache: 'no-store'
      });
      
      if (!response.ok) return;
      
      const latestVersion = (await response.text()).trim();
      const currentVersion = document.querySelector('meta[name="app-version"]')?.content;
      
      if (currentVersion && latestVersion && currentVersion !== latestVersion) {
        console.log('🔄 Nova versão disponível:', latestVersion);
        
        // Notificar usuário (opcional)
        if (window.confirm('Uma nova versão está disponível. Deseja atualizar agora?')) {
          await forceUpdate();
        } else {
          // Atualizar em background
          scheduleUpdate();
        }
      }
    } catch (error) {
      console.warn('Erro ao verificar atualização:', error);
    }
  }

  // Forçar atualização imediata
  async function forceUpdate() {
    try {
      // 1. Limpar cache do service worker
      if ('serviceWorker' in navigator) {
        const registrations = await navigator.serviceWorker.getRegistrations();
        await Promise.all(registrations.map(reg => reg.unregister()));
      }
      
      // 2. Limpar cache do navegador
      if ('caches' in window) {
        const cacheNames = await caches.keys();
        await Promise.all(cacheNames.map(name => caches.delete(name)));
      }
      
      // 3. Recarregar página (bypass cache)
      window.location.reload(true);
    } catch (error) {
      console.error('Erro ao forçar atualização:', error);
      window.location.reload();
    }
  }

  // Agendar atualização para próximo reload
  function scheduleUpdate() {
    sessionStorage.setItem('pendingUpdate', 'true');
  }

  // Executar atualização pendente
  function executePendingUpdate() {
    if (sessionStorage.getItem('pendingUpdate') === 'true') {
      sessionStorage.removeItem('pendingUpdate');
      forceUpdate();
    }
  }

  // Inicializar
  function init() {
    // Verificar se há update pendente
    executePendingUpdate();
    
    // Verificar atualizações periodicamente (a cada 5 minutos)
    setInterval(checkForUpdate, 5 * 60 * 1000);
    
    // Verificar na primeira carga
    setTimeout(checkForUpdate, 5000);
    
    // Verificar quando a página fica visível novamente
    document.addEventListener('visibilitychange', () => {
      if (!document.hidden) {
        checkForUpdate();
      }
    });

    // Expor funções globalmente para debug
    window.appUpdate = {
      check: checkForUpdate,
      force: forceUpdate,
      version: document.querySelector('meta[name="app-version"]')?.content
    };

    console.log('✅ Cache busting loader inicializado');
    console.log('📌 Versão atual:', window.appUpdate.version);
  }

  // Aguardar DOM estar pronto
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
