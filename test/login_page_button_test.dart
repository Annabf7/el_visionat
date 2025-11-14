import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RegisterStep3 button text is "Iniciar sessió"', () {
    final content = File(
      'lib/features/auth/pages/login_page.dart',
    ).readAsStringSync();
    expect(
      content.contains("Iniciar sessió"),
      isTrue,
      reason:
          'Expected the login_page.dart to contain the updated button label',
    );
  });

  test('RegisterStep3 button uses theme colorScheme.onPrimary', () {
    final content = File(
      'lib/features/auth/pages/login_page.dart',
    ).readAsStringSync();
    expect(
      content.contains('colorScheme.onPrimary'),
      isTrue,
      reason:
          'Expected the login_page.dart to use colorScheme.onPrimary for the button text',
    );
  });
}
