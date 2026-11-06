import 'package:flutter_test/flutter_test.dart';

import 'package:walletgek/main.dart';

void main() {
  testWidgets('La app muestra la pantalla de login', (WidgetTester tester) async {
    await tester.pumpWidget(const WalletgekApp(loggedIn: false));

    expect(find.text('walletgek'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
