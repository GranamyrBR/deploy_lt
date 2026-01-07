Relatório de Acessibilidade

- Contraste revisado em cabeçalhos, avatares, chips, textos e fundos do modal de cotação.
- Modo de alto contraste com toggle no cabeçalho do modal.
- Persistência da preferência em localStorage via SharedPreferences (Flutter Web usa localStorage).
- CSS high-contrast aplicado ao body em web com classe `high-contrast` e reatividade via evento `storage`.
- Testes de contraste adicionados em `test/accessibility/contrast_test.dart` com validações de limiar WCAG.

