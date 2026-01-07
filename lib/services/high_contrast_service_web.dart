import 'dart:html' as html;

class HighContrastService {
  static void apply(bool enabled) {
    try {
      final body = html.document.body;
      if (body == null) return;
      if (enabled) {
        body.classes.add('high-contrast');
      } else {
        body.classes.remove('high-contrast');
      }
      html.window.localStorage['high_contrast_enabled'] = enabled ? 'true' : 'false';
    } catch (_) {}
  }
}

