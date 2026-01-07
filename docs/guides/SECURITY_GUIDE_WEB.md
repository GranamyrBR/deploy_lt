# 🔒 Guia de Segurança - Flutter Web com API Keys

## ⚠️ PROBLEMA: Chaves de API Expostas no Client-Side

No Flutter Web, qualquer código JavaScript (incluindo `window.ENV`) é **visível no navegador**. Isso significa que chaves de API como a da OpenAI ficam expostas se colocadas diretamente no `index.html`.

---

## 🛡️ SOLUÇÕES POR AMBIENTE

### 🔓 **DESENVOLVIMENTO (Localhost)**

**Arquivo usado:** `web/index.dev.html`

```javascript
window.ENV = {
  OPENAI_API_KEY: "sk-proj-...", // Chave real para desenvolvimento
  OPENAI_ORGANIZATION: "Leco Tour"
};
```

**Segurança:**
- ✅ OK para localhost
- ✅ Não vai para produção
- ✅ Chaves não commitadas no Git (usar .gitignore)

---

### 🔒 **PRODUÇÃO (VPS/Servidor)**

**Opção 1: Backend Proxy (RECOMENDADO)**

Crie um endpoint no backend que faz a chamada à OpenAI:

```dart
// Frontend chama:
POST /api/ai/chat
Body: { message: "..." }

// Backend (Node.js/Python/etc) faz:
- Recebe request do Flutter
- Usa OPENAI_API_KEY do ambiente do servidor
- Faz request à OpenAI
- Retorna resposta ao Flutter
```

**Vantagens:**
- ✅ Chave NUNCA exposta no client
- ✅ Controle de rate limiting
- ✅ Logging e auditoria
- ✅ Custos controlados

---

**Opção 2: Injeção Dinâmica no Build**

No servidor VPS, criar um script que gera `index.html` com as chaves:

```bash
# deploy.sh
sed "s/{{ OPENAI_API_KEY }}/$OPENAI_API_KEY/g" web/index.html.template > web/index.html
```

**Desvantagens:**
- ⚠️ Chave ainda fica visível no código fonte do navegador
- ⚠️ Qualquer usuário pode copiar e usar

---

**Opção 3: Variáveis de Ambiente do Servidor**

Usar servidor web (nginx/Apache) para injetar variáveis:

```nginx
location / {
  sub_filter '{{ OPENAI_API_KEY }}' '$OPENAI_API_KEY';
  sub_filter_once off;
}
```

**Desvantagens:**
- ⚠️ Mesma exposição da Opção 2

---

## 🎯 RECOMENDAÇÃO FINAL

### **Para Produção: USE BACKEND PROXY**

1. **Criar API no backend** (Node.js, Python, PHP, etc)
2. **Endpoints seguros:**
   ```
   POST /api/ai/chat
   POST /api/ai/analyze
   ```
3. **Backend gerencia:**
   - Autenticação do usuário
   - Rate limiting (ex: 10 mensagens/minuto por usuário)
   - Logging de uso
   - Custos da OpenAI

4. **Flutter apenas envia mensagens:**
   ```dart
   // Sem OPENAI_API_KEY no frontend!
   final response = await http.post(
     Uri.parse('https://seu-vps.com/api/ai/chat'),
     headers: {'Authorization': 'Bearer $userToken'},
     body: {'message': userMessage},
   );
   ```

---

## 📋 CHECKLIST PRÉ-DEPLOY

### Desenvolvimento:
- [x] `web/index.dev.html` com chaves reais (não commitar)
- [x] `.gitignore` inclui `web/index.dev.html`
- [x] Usar `flutter run -d chrome` com `index.dev.html`

### Produção:
- [ ] Backend proxy implementado
- [ ] Chaves de API REMOVIDAS do `index.html`
- [ ] `window.ENV` vazio ou com placeholders
- [ ] Rate limiting configurado
- [ ] Logs de uso implementados
- [ ] Testes de segurança realizados

---

## 🚀 IMPLEMENTAÇÃO RÁPIDA (Backend Proxy)

### Node.js Express:

```javascript
// server.js
const express = require('express');
const OpenAI = require('openai');

const app = express();
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY, // Variável de ambiente do servidor
});

app.post('/api/ai/chat', async (req, res) => {
  const { message, userId } = req.body;
  
  // Validação e rate limiting aqui
  
  const completion = await openai.chat.completions.create({
    model: 'gpt-4-turbo-preview',
    messages: [{ role: 'user', content: message }],
  });
  
  res.json({ response: completion.choices[0].message.content });
});

app.listen(3000);
```

### Flutter:

```dart
// lib/services/ai_assistant_service.dart
Future<String> sendMessage(String message) async {
  final response = await http.post(
    Uri.parse('https://seu-vps.com:3000/api/ai/chat'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'message': message, 'userId': currentUserId}),
  );
  
  final data = jsonDecode(response.body);
  return data['response'];
}
```

---

## ⚠️ NUNCA FAÇA ISSO EM PRODUÇÃO:

```javascript
// ❌ NUNCA:
window.ENV = {
  OPENAI_API_KEY: "sk-proj-chave-real-aqui" // EXPOSTO NO NAVEGADOR!
};
```

```dart
// ❌ NUNCA:
const String apiKey = 'sk-proj-chave-real'; // HARDCODED NO CÓDIGO!
```

---

## 📚 Referências

- [OpenAI Best Practices](https://platform.openai.com/docs/guides/safety-best-practices)
- [Flutter Web Security](https://docs.flutter.dev/deployment/web)
- [OWASP API Security](https://owasp.org/www-project-api-security/)

---

**Resumo:** Para desenvolvimento use `index.dev.html` localmente. Para produção, SEMPRE use backend proxy! 🔒
