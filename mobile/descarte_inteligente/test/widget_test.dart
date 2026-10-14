import 'package:flutter_test/flutter_test.dart';

import 'package:descarte_inteligente/main.dart';

void main() {
  testWidgets('aplicativo inicia e exibe a tela inicial', (WidgetTester tester) async {
    await tester.pumpWidget(const DescarteInteligenteApp());

    expect(find.text('Olá!'), findsOneWidget);
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Identificar'), findsOneWidget);
  });
}
