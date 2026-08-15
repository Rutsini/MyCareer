import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('rechaza un email inválido', () {
      expect(Validators.email('correo-invalido'), isNotNull);
    });

    test('rechaza una contraseña menor a seis caracteres', () {
      expect(Validators.password('12345'), isNotNull);
    });

    test('rechaza una confirmación diferente', () {
      expect(Validators.passwordConfirmation('abcdefg', '123456'), isNotNull);
    });
  });
}
