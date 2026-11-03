# Family Points — app Flutter

Spesifikasi: `../PRD-Family-Points-App-Fase-1.md`, jadwal: `../Rencana-Implementasi-Fase-1.md`, gaya visual: `../design.md`.
Backend: `../supabase` (lihat README di sana).

## Menjalankan

```sh
flutter pub get
flutter run                     # mode demo: data di memori (FakeRepository), tanpa server
```

Dengan server sungguhan, isi lewat `--dart-define` (semua opsional kecuali dua yang pertama):

| Nilai | Untuk |
| --- | --- |
| `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` | Data sungguhan. Tanpa ini app berjalan dalam mode demo. |
| `ONESIGNAL_APP_ID` | Push notification. Tanpa ini app tetap jalan, hanya tanpa push. |
| `POSTHOG_API_KEY`, `POSTHOG_HOST` | Event analitik (default host `https://eu.i.posthog.com`). |

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_... \
  --dart-define=ONESIGNAL_APP_ID=... \
  --dart-define=POSTHOG_API_KEY=phc_...
```

## Pemeriksaan (sama dengan CI)

```sh
dart format --line-length 120 --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Struktur

- `lib/data/` — model & antarmuka repository per domain. `fake/` meniru RPC Supabase (dipakai mode demo & tes),
  `supabase/` implementasi produksi. `report_queue.dart` = antrean laporan offline.
- `lib/core/` — tema, widget dasar, foto, `push.dart` (OneSignal), `analytics.dart` (PostHog).
- `lib/features/` — layar per modul PRD. `shell/session.dart` memegang login, profil aktif, push, analitik,
  dan antrean offline.

## Push notification (OneSignal)

Server mengirim push lewat OneSignal dengan **external_id = auth user id**. App memanggil `OneSignal.login(userId)`
setelah user punya keluarga dan `OneSignal.logout()` saat keluar. Izin notifikasi ditanyakan saat itu juga, bukan
saat app pertama dibuka. Notifikasi yang diketuk membuka rutenya (`data.route`, mis. `/parent/approvals`).

Langkah sekali saja:

1. Buat app di OneSignal, sambungkan **FCM** (file service account Firebase) dan **APNs** (key .p8 dari Apple).
2. **iOS** (Xcode, target Runner → Signing & Capabilities):
   - tambah capability **Push Notifications**;
   - tambah **Background Modes**, lalu centang *Remote notifications*.
3. **Android:** tidak perlu langkah tambahan. Izin `POST_NOTIFICATIONS` (Android 13+) sudah ikut dari plugin.
4. Isi secrets Edge Function & Vault, lihat `../supabase/README.md`.

## Analitik

Hanya 7 event metrik sukses (lihat `AnalyticsEvent`). Event dikirim tanpa autocapture dan tanpa profil orang
(`$process_person_profile: false`). Identitasnya hanya auth user id acak, tanpa nama atau isi laporan, sesuai
prinsip data anak minimal.
