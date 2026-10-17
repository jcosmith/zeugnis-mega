import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeugnis_mega/main.dart';
import 'package:zeugnis_mega/services/storage.dart';

void main() {
  testWidgets('Neues Zeugnis anlegen und Fächer sehen', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final state = AppState(prefs);

    await tester.pumpWidget(ZeugnisApp(state: state));
    expect(find.text('Noch keine Zeugnisse'), findsOneWidget);

    await tester.tap(find.text('Neues Zeugnis'));
    await tester.pumpAndSettle();

    expect(find.text('Mathematik'), findsOneWidget);
    expect(find.text('Sprache und Kommunikation (Deutsch)'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Vorname'), 'Mia');
    await tester.tap(find.text('Mathematik'));
    await tester.pumpAndSettle();
    expect(find.text('Zahlen und Operationen'), findsOneWidget);
    await tester.tap(find.text('Zahlverständnis'));
    await tester.pumpAndSettle();

    expect(state.zeugnisse.single.vorname, 'Mia');
    final mathe = state.zeugnisse.single.faecher.firstWhere(
      (f) => f.fachId == 'mathematik',
    );
    expect(mathe.hatStichworte, isTrue);
    await tester.pump(const Duration(seconds: 1));
  });
}
