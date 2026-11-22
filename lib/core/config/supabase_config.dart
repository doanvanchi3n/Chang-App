/// Cấu hình public của ứng dụng; không đặt khóa quản trị vào đây.
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qoyyqjkbmeauqmivbynd.supabase.co',
  );

  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_E-o4MY-fXu8r8toFO2nKrg_LojlwmOS',
  );
}
