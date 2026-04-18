import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vettri/main.dart';
import 'package:vettri/screens/revenue_summary_screen.dart';

void main() {
  group('Revenue Summary Screen - Save Summary Button Tests', () {
    testWidgets('Should show error when all expense fields are empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const RevenueSummaryScreen());
      await tester.pumpAndSettle();

      // Find and tap the Save Summary button
      final saveButton = find.byType(ElevatedButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Check for validation error message
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SnackBar &&
                  widget.content is Text &&
                  (widget.content as Text).data?.contains(
                    'at least one expense',
                  ) ??
              false,
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'Should show error when invalid (non-numeric) value is entered',
      (WidgetTester tester) async {
        await tester.pumpWidget(const RevenueSummaryScreen());
        await tester.pumpAndSettle();

        // Enter invalid text in first field
        final trainerField = find.byType(TextFormField).first;
        await tester.tap(trainerField);
        await tester.enterText(trainerField, 'invalid');
        await tester.pumpAndSettle();

        // Find and tap the Save Summary button
        final saveButton = find.byType(ElevatedButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Check for validation error message
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is SnackBar &&
                    widget.content is Text &&
                    (widget.content as Text).data?.contains('valid number') ??
                false,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('Should show error when negative value is entered', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const RevenueSummaryScreen());
      await tester.pumpAndSettle();

      // Enter negative value
      final trainerField = find.byType(TextFormField).first;
      await tester.tap(trainerField);
      await tester.enterText(trainerField, '-100');
      await tester.pumpAndSettle();

      // Find and tap the Save Summary button
      final saveButton = find.byType(ElevatedButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Check for validation error message
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SnackBar &&
                  widget.content is Text &&
                  (widget.content as Text).data?.contains(
                    'cannot be negative',
                  ) ??
              false,
        ),
        findsOneWidget,
      );
    });

    testWidgets('Should allow saving with valid numeric values', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const RevenueSummaryScreen());
      await tester.pumpAndSettle();

      // Enter valid values
      final fields = find.byType(TextFormField);
      await tester.tap(fields.at(0));
      await tester.enterText(fields.at(0), '1000');
      await tester.pumpAndSettle();

      // Find and tap the Save Summary button
      final saveButton = find.byType(ElevatedButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // The app should attempt to save (validation should pass)
      // Look for loading indicator or success message
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });
}
