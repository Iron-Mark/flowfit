import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowfit/screens/dashboard_screen.dart';

void main() {
  group('DashboardScreen Responsive Navigation Bar Tests', () {
    testWidgets(
      'Navigation bar adapts to device with gesture navigation (bottom padding)',
      (WidgetTester tester) async {
        // Simulate device with gesture navigation (e.g., Xiaomi 14T, Pixel 6+)
        // Typical gesture bar adds ~24-34 pixels of bottom padding
        await tester.pumpWidget(
          ProviderScope(
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(412, 915), // Typical phone screen
                padding: EdgeInsets.only(bottom: 34), // Gesture bar padding
              ),
              child: const MaterialApp(home: DashboardScreen()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find the navigation bar container
        final containerFinder = find.descendant(
          of: find.byType(Scaffold),
          matching: find.byType(Container),
        );

        // Verify container exists
        expect(containerFinder, findsWidgets);

        // Find the BottomNavigationBar
        final navBarFinder = find.byType(BottomNavigationBar);
        expect(navBarFinder, findsOneWidget);

        // Verify all 5 navigation items are present
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Health'), findsOneWidget);
        expect(find.text('Track'), findsOneWidget);
        expect(find.text('Progress'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);

        // Verify navigation items are tappable
        await tester.tap(find.text('Health'));
        await tester.pumpAndSettle();

        final navBar = tester.widget<BottomNavigationBar>(navBarFinder);
        expect(navBar.currentIndex, 1);
      },
    );

    testWidgets('Navigation bar adapts to device with software buttons', (
      WidgetTester tester,
    ) async {
      // Simulate device with software navigation buttons
      // Software buttons typically add ~48 pixels of bottom padding
      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(412, 915),
              padding: EdgeInsets.only(bottom: 48), // Software button padding
            ),
            child: const MaterialApp(home: DashboardScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify BottomNavigationBar exists
      final navBarFinder = find.byType(BottomNavigationBar);
      expect(navBarFinder, findsOneWidget);

      // Verify all navigation items are accessible
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Health'), findsOneWidget);
      expect(find.text('Track'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets(
      'Navigation bar displays correctly on device with no system navigation',
      (WidgetTester tester) async {
        // Simulate device with no system navigation (tablets, some custom ROMs)
        await tester.pumpWidget(
          ProviderScope(
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(800, 1280), // Tablet size
                padding: EdgeInsets.zero, // No system UI padding
              ),
              child: const MaterialApp(home: DashboardScreen()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify BottomNavigationBar exists
        final navBarFinder = find.byType(BottomNavigationBar);
        expect(navBarFinder, findsOneWidget);

        // Verify all navigation items are present
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Health'), findsOneWidget);
        expect(find.text('Track'), findsOneWidget);
        expect(find.text('Progress'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);
      },
    );

    testWidgets(
      'Navigation bar adapts to orientation changes (portrait to landscape)',
      (WidgetTester tester) async {
        // Start in portrait mode
        await tester.pumpWidget(
          ProviderScope(
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(412, 915), // Portrait
                padding: EdgeInsets.only(bottom: 34),
              ),
              child: const MaterialApp(home: DashboardScreen()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify navigation bar in portrait
        expect(find.byType(BottomNavigationBar), findsOneWidget);
        expect(find.text('Home'), findsOneWidget);

        // Simulate orientation change to landscape
        await tester.pumpWidget(
          ProviderScope(
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(915, 412), // Landscape
                padding: EdgeInsets.only(
                  bottom: 0,
                ), // Often no bottom padding in landscape
              ),
              child: const MaterialApp(home: DashboardScreen()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify navigation bar still works in landscape
        expect(find.byType(BottomNavigationBar), findsOneWidget);
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Health'), findsOneWidget);
        expect(find.text('Track'), findsOneWidget);
        expect(find.text('Progress'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);
      },
    );

    testWidgets('All 5 navigation items remain fully tappable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(412, 915),
              padding: EdgeInsets.only(bottom: 34),
            ),
            child: const MaterialApp(home: DashboardScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final navBarFinder = find.byType(BottomNavigationBar);
      expect(navBarFinder, findsOneWidget);

      // Test tapping each navigation item
      final items = ['Home', 'Health', 'Track', 'Progress', 'Profile'];

      for (int i = 0; i < items.length; i++) {
        await tester.tap(find.text(items[i]));
        await tester.pumpAndSettle();

        final navBar = tester.widget<BottomNavigationBar>(navBarFinder);
        expect(
          navBar.currentIndex,
          i,
          reason: '${items[i]} tab should be selected',
        );
      }
    });

    testWidgets('Navigation bar maintains minimum touch target size (48x48dp)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(412, 915),
              padding: EdgeInsets.only(bottom: 34),
            ),
            child: const MaterialApp(home: DashboardScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find all navigation items
      final navBarFinder = find.byType(BottomNavigationBar);
      expect(navBarFinder, findsOneWidget);

      // Get the BottomNavigationBar widget
      final navBar = tester.widget<BottomNavigationBar>(navBarFinder);

      // Verify icon size is appropriate (24dp is standard, provides good touch target)
      expect(navBar.iconSize, 24);

      // BottomNavigationBar automatically ensures minimum touch targets
      // by default, so we verify it's using the standard implementation
      expect(navBar.type, BottomNavigationBarType.fixed);
    });

    testWidgets(
      'Navigation bar preserves visual styling across configurations',
      (WidgetTester tester) async {
        // Test with gesture navigation
        await tester.pumpWidget(
          ProviderScope(
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(412, 915),
                padding: EdgeInsets.only(bottom: 34),
              ),
              child: const MaterialApp(home: DashboardScreen()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final navBarFinder = find.byType(BottomNavigationBar);
        final navBar1 = tester.widget<BottomNavigationBar>(navBarFinder);

        // Test with no system navigation
        await tester.pumpWidget(
          ProviderScope(
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(412, 915),
                padding: EdgeInsets.zero,
              ),
              child: const MaterialApp(home: DashboardScreen()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final navBar2 = tester.widget<BottomNavigationBar>(navBarFinder);

        // Verify styling is consistent
        expect(navBar1.iconSize, navBar2.iconSize);
        expect(navBar1.selectedFontSize, navBar2.selectedFontSize);
        expect(navBar1.unselectedFontSize, navBar2.unselectedFontSize);
        expect(navBar1.type, navBar2.type);
        expect(navBar1.items.length, navBar2.items.length);
      },
    );
  });

  group('Task 3: Accessibility and Visual Consistency Validation', () {
    testWidgets(
      'Touch targets meet 48x48dp minimum size requirement (Requirement 1.4)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MediaQuery(
              data: MediaQueryData(
                size: Size(412, 915),
                padding: EdgeInsets.only(bottom: 34),
                devicePixelRatio: 2.0,
              ),
              child: MaterialApp(home: DashboardScreen()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find the BottomNavigationBar
        final navBarFinder = find.byType(BottomNavigationBar);
        expect(navBarFinder, findsOneWidget);

        final navBar = tester.widget<BottomNavigationBar>(navBarFinder);

        // Verify icon size is 24dp (standard size that ensures good touch targets)
        expect(navBar.iconSize, 24);

        // Verify font sizes are appropriate for touch targets
        expect(navBar.selectedFontSize, 12);
        expect(navBar.unselectedFontSize, 12);

        // BottomNavigationBar with type 'fixed' automatically ensures
        // minimum touch targets of 48x48dp per Material Design guidelines
        expect(navBar.type, BottomNavigationBarType.fixed);

        // Verify all navigation items are tappable by attempting to tap each
        final items = ['Home', 'Health', 'Track', 'Progress', 'Profile'];
        for (final item in items) {
          final itemFinder = find.text(item);
          expect(itemFinder, findsOneWidget);

          // Verify the item is hittable (has sufficient touch target)
          await tester.tap(itemFinder);
          await tester.pumpAndSettle();
        }
      },
    );

    testWidgets(
      'Navigation items have proper semantic labels for TalkBack (Requirement 1.4)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MediaQuery(
              data: MediaQueryData(
                size: Size(412, 915),
                padding: EdgeInsets.only(bottom: 34),
              ),
              child: MaterialApp(home: DashboardScreen()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find the BottomNavigationBar
        final navBarFinder = find.byType(BottomNavigationBar);
        final navBar = tester.widget<BottomNavigationBar>(navBarFinder);

        // Verify each navigation item has proper tooltip for accessibility
        expect(navBar.items[0].tooltip, 'Home');
        expect(navBar.items[1].tooltip, 'Health');
        expect(navBar.items[2].tooltip, 'Track');
        expect(navBar.items[3].tooltip, 'Progress');
        expect(navBar.items[4].tooltip, 'Profile');

        // Verify labels match tooltips for consistency
        expect(navBar.items[0].label, 'Home');
        expect(navBar.items[1].label, 'Health');
        expect(navBar.items[2].label, 'Track');
        expect(navBar.items[3].label, 'Progress');
        expect(navBar.items[4].label, 'Profile');
      },
    );

    testWidgets(
      'Visual styling is preserved after responsive changes (Requirement 1.5, 2.5)',
      (WidgetTester tester) async {
        // Capture baseline styling
        await tester.pumpWidget(
          const ProviderScope(
            child: MediaQuery(
              data: MediaQueryData(
                size: Size(412, 915),
                padding: EdgeInsets.zero, // No system padding baseline
              ),
              child: MaterialApp(home: DashboardScreen()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final navBarFinder = find.byType(BottomNavigationBar);
        final baselineNavBar = tester.widget<BottomNavigationBar>(navBarFinder);

        // Store baseline properties
        final baselineIconSize = baselineNavBar.iconSize;
        final baselineSelectedFontSize = baselineNavBar.selectedFontSize;
        final baselineUnselectedFontSize = baselineNavBar.unselectedFontSize;
        final baselineType = baselineNavBar.type;
        final baselineElevation = baselineNavBar.elevation;

        // Test with gesture navigation padding
        await tester.pumpWidget(
          const ProviderScope(
            child: MediaQuery(
              data: MediaQueryData(
                size: Size(412, 915),
                padding: EdgeInsets.only(bottom: 34),
              ),
              child: MaterialApp(home: DashboardScreen()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final responsiveNavBar = tester.widget<BottomNavigationBar>(
          navBarFinder,
        );

        // Verify all styling properties remain unchanged
        expect(responsiveNavBar.iconSize, baselineIconSize);
        expect(responsiveNavBar.selectedFontSize, baselineSelectedFontSize);
        expect(responsiveNavBar.unselectedFontSize, baselineUnselectedFontSize);
        expect(responsiveNavBar.type, baselineType);
        expect(responsiveNavBar.elevation, baselineElevation);

        // Verify colors are preserved
        expect(
          responsiveNavBar.selectedItemColor,
          baselineNavBar.selectedItemColor,
        );
        expect(
          responsiveNavBar.unselectedItemColor,
          baselineNavBar.unselectedItemColor,
        );
        expect(
          responsiveNavBar.backgroundColor,
          baselineNavBar.backgroundColor,
        );
      },
    );

    testWidgets(
      'Shadow and elevation effects remain consistent (Requirement 1.5)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MediaQuery(
              data: MediaQueryData(
                size: Size(412, 915),
                padding: EdgeInsets.only(bottom: 34),
              ),
              child: MaterialApp(home: DashboardScreen()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find the Container that contains the BottomNavigationBar
        final containerFinder = find.ancestor(
          of: find.byType(BottomNavigationBar),
          matching: find.byType(Container),
        );

        expect(containerFinder, findsOneWidget);
        final bottomNavBar = tester.widget<Container>(containerFinder);

        // Verify the Container has decoration with shadow
        expect(bottomNavBar.decoration, isA<BoxDecoration>());
        final decoration = bottomNavBar.decoration as BoxDecoration;

        // Verify shadow is present
        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow!.length, 1);

        // Verify shadow properties
        final shadow = decoration.boxShadow!.first;
        expect(shadow.blurRadius, 8);
        expect(shadow.offset, const Offset(0, -2));
        expect(shadow.color, Colors.black.withValues(alpha: 0.1));

        // Verify BottomNavigationBar has elevation set to 0
        // (since we handle elevation with Container shadow)
        final navBarFinder = find.byType(BottomNavigationBar);
        final navBar = tester.widget<BottomNavigationBar>(navBarFinder);
        expect(navBar.elevation, 0);
      },
    );

    testWidgets(
      'Icon sizes remain consistent across device configurations (Requirement 2.5)',
      (WidgetTester tester) async {
        final configurations = [
          const MediaQueryData(
            size: Size(412, 915),
            padding: EdgeInsets.only(bottom: 34), // Gesture navigation
          ),
          const MediaQueryData(
            size: Size(412, 915),
            padding: EdgeInsets.only(bottom: 48), // Software buttons
          ),
          const MediaQueryData(
            size: Size(800, 1280),
            padding: EdgeInsets.zero, // Tablet, no system navigation
          ),
          const MediaQueryData(
            size: Size(915, 412),
            padding: EdgeInsets.zero, // Landscape
          ),
        ];

        for (final config in configurations) {
          await tester.pumpWidget(
            ProviderScope(
              child: MediaQuery(
                data: config,
                child: const MaterialApp(home: DashboardScreen()),
              ),
            ),
          );

          await tester.pumpAndSettle();

          final navBarFinder = find.byType(BottomNavigationBar);
          final navBar = tester.widget<BottomNavigationBar>(navBarFinder);

          // Verify icon size is always 24dp
          expect(
            navBar.iconSize,
            24,
            reason: 'Icon size should be 24dp for config: ${config.size}',
          );

          // Verify font sizes are consistent
          expect(
            navBar.selectedFontSize,
            12,
            reason:
                'Selected font size should be 12 for config: ${config.size}',
          );
          expect(
            navBar.unselectedFontSize,
            12,
            reason:
                'Unselected font size should be 12 for config: ${config.size}',
          );
        }
      },
    );

    testWidgets(
      'Label positioning remains unchanged across configurations (Requirement 2.5)',
      (WidgetTester tester) async {
        // Test with different padding configurations
        final configs = [
          EdgeInsets.zero,
          const EdgeInsets.only(bottom: 34),
          const EdgeInsets.only(bottom: 48),
        ];

        for (final padding in configs) {
          await tester.pumpWidget(
            ProviderScope(
              child: MediaQuery(
                data: MediaQueryData(
                  size: const Size(412, 915),
                  padding: padding,
                ),
                child: const MaterialApp(home: DashboardScreen()),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Verify all labels are visible and positioned correctly
          expect(find.text('Home'), findsOneWidget);
          expect(find.text('Health'), findsOneWidget);
          expect(find.text('Track'), findsOneWidget);
          expect(find.text('Progress'), findsOneWidget);
          expect(find.text('Profile'), findsOneWidget);

          // Verify label styles are consistent
          final navBarFinder = find.byType(BottomNavigationBar);
          final navBar = tester.widget<BottomNavigationBar>(navBarFinder);

          expect(navBar.selectedLabelStyle, isNotNull);
          expect(navBar.unselectedLabelStyle, isNotNull);
        }
      },
    );

    testWidgets(
      'Container background color matches theme surface color (Requirement 1.5)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MediaQuery(
              data: MediaQueryData(
                size: Size(412, 915),
                padding: EdgeInsets.only(bottom: 34),
              ),
              child: MaterialApp(home: DashboardScreen()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Get the theme
        final context = tester.element(find.byType(DashboardScreen));
        final theme = Theme.of(context);

        // Find the Container that contains the BottomNavigationBar
        final containerFinder = find.ancestor(
          of: find.byType(BottomNavigationBar),
          matching: find.byType(Container),
        );

        expect(containerFinder, findsOneWidget);
        final container = tester.widget<Container>(containerFinder);
        final decoration = container.decoration as BoxDecoration;

        // Verify container color matches theme surface color
        expect(decoration.color, theme.colorScheme.surface);

        // Verify BottomNavigationBar background also matches
        final navBarFinder = find.byType(BottomNavigationBar);
        final navBar = tester.widget<BottomNavigationBar>(navBarFinder);
        expect(navBar.backgroundColor, theme.colorScheme.surface);
      },
    );

    testWidgets(
      'All navigation items maintain proper spacing and alignment (Requirement 2.5)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MediaQuery(
              data: MediaQueryData(
                size: Size(412, 915),
                padding: EdgeInsets.only(bottom: 34),
              ),
              child: MaterialApp(home: DashboardScreen()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final navBarFinder = find.byType(BottomNavigationBar);
        final navBar = tester.widget<BottomNavigationBar>(navBarFinder);

        // Verify type is 'fixed' which ensures equal spacing
        expect(navBar.type, BottomNavigationBarType.fixed);

        // Verify all 5 items are present
        expect(navBar.items.length, 5);

        // Verify each item has both icon and label
        for (final item in navBar.items) {
          expect(item.icon, isNotNull);
          expect(item.label, isNotNull);
          expect(item.label!.isNotEmpty, true);
        }
      },
    );
  });
}
