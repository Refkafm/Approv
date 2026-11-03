# Family Points — Supabase

- `migrations/` — skema, RLS, RPC, cron, realtime, notifikasi, push.
- `tests/family_points.test.sql` — pgTAP (`supabase test db`).
- `functions/send-push/` — Edge Function pengirim push OneSignal.

## Deploy

```sh
supabase link --project-ref <ref>
supabase db push
supabase functions deploy send-push --no-verify-jwt   # fungsi memeriksa sendiri header service role
supabase secrets set ONESIGNAL_APP_ID=... ONESIGNAL_REST_API_KEY=...
```

Job cron `send-push` (migrasi `20261102000800_push.sql`) memanggil fungsi itu setiap menit lewat `pg_net`.
URL proyek dan kuncinya dibaca dari Vault, jadi isi sekali di SQL editor:

```sql
select vault.create_secret('https://<ref>.supabase.co', 'project_url');
select vault.create_secret('<service role key>', 'service_role_key');
```

## Cara kerja push

1. Trigger mengisi `notifications` (teks sesuai PRD bagian "Notifikasi").
2. `send-push` memanggil `claim_push_batch()`, yang mengambil yang belum terkirim (maks 1 hari, maks 5 percobaan)
   dan langsung menandai `sent_at`. Pemanggilan ganda aman karena memakai `SKIP LOCKED`.
3. Tiap baris dikirim ke OneSignal dengan `include_aliases.external_id` = semua login milik penerima.
4. **Jam tidur keluarga** hanya berlaku untuk anak. Push untuk anak di jam tidur diberi `send_after` = akhir jam
   tidur, sedangkan orang tua selalu menerima langsung.
5. Yang gagal dikembalikan ke antrean lewat `release_push()`.

## Belum ada (butuh Edge Function terpisah)

- Penghapusan file foto dari storage (`photos_to_purge`) dan file yatim dari upload yang laporannya gagal.
- Pengingat tugas/streak dan ringkasan mingguan (R-01, P1).
