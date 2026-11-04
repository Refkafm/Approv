/// Konfigurasi build. Isi lewat:
///   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=...
/// Tanpa nilai ini, app berjalan dalam mode demo (FakeRepository, data di memori).
abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  /// Push notification: --dart-define=ONESIGNAL_APP_ID=... (hanya dipakai bersama Supabase).
  static const oneSignalAppId = String.fromEnvironment('ONESIGNAL_APP_ID');

  static bool get hasOneSignal => hasSupabase && oneSignalAppId.isNotEmpty;

  /// Analitik PostHog: --dart-define=POSTHOG_API_KEY=phc_... (opsional POSTHOG_HOST).
  static const postHogApiKey = String.fromEnvironment('POSTHOG_API_KEY');
  static const postHogHost = String.fromEnvironment('POSTHOG_HOST', defaultValue: 'https://eu.i.posthog.com');

  static bool get hasPostHog => hasSupabase && postHogApiKey.isNotEmpty;

  /// Login Google native di iOS (Google Cloud > Clients). Bukan rahasia: memang tertanam di app.
  /// iOS client: juga sebagai URL scheme terbalik di ios/Runner/Info.plist.
  /// Keduanya terdaftar di Supabase > Auth > Providers > Google > Client IDs.
  static const googleIosClientId = '622357705333-skuaa3r5aqt6tnohqhhnh0246j58e01q.apps.googleusercontent.com';
  static const googleWebClientId = '622357705333-ofmugj8chv1bg0id7m8v032jertjvgcl.apps.googleusercontent.com';

  /// Deep link setelah login Google/Apple. Daftarkan juga di Supabase Auth > URL Configuration,
  /// android/app/src/main/AndroidManifest.xml, dan ios/Runner/Info.plist.
  static const authRedirectUrl = 'com.familypoints.app://login-callback';
}
