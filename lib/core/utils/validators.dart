abstract final class Validators {
  static String? requiredName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresá tu nombre.';
    if (text.length < 2) return 'El nombre debe tener al menos 2 caracteres.';
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresá tu correo.';
    final pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!pattern.hasMatch(text)) return 'Ingresá un correo válido.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Ingresá tu contraseña.';
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    return null;
  }

  static String? passwordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirmá tu contraseña.';
    if (value != password) return 'Las contraseñas no coinciden.';
    return null;
  }
}
