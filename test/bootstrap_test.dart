import 'package:chang_app/bootstrap.dart';
import 'package:chang_app/features/home/presentation/pages/home_page.dart';
import 'package:chang_app/data/remote/supabase_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('Khởi tạo Supabase trước khi mở Chặng App', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.runAsync(() => Future<void>.sync(bootstrap));
    await tester.pumpAndSettle();

    final supabase = Supabase.instance;
    addTearDown(supabase.dispose);
    expect(supabase.isInitialized, isTrue);
    expect(supabase.client.auth.currentSession, isNull);
    expect(find.byType(HomePage), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomePage)),
    );
    expect(container.read(supabaseClientProvider), same(supabase.client));
    expect(tester.takeException(), isNull);
  });
}
