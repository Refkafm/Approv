-- Tes database Family Points App (pgTAP). Jalankan dengan: supabase test db
--
-- Satu skenario keluarga utuh: Ibu Rina (owner), Ayah (admin), HP Raka (anak, login anonim),
-- dan satu orang luar. Setiap aksi dijalankan sebagai role `authenticated` lewat tests.as_user(),
-- sehingga RLS dan hak akses ikut teruji. Semua perubahan di-rollback di akhir.

begin;
create extension if not exists pgtap with schema extensions;
select plan(107);

-- =====================================================================
-- Helper
-- =====================================================================

create schema tests;
create table tests.users (who text primary key, id uuid not null, anon boolean not null);
create table tests.ids (k text primary key, v text);

create function tests.id(p_k text) returns uuid
language sql as $$ select v::uuid from tests.ids where k = p_k $$;

create function tests.save(p_k text, p_v text) returns text
language sql as $$
  insert into tests.ids values (p_k, p_v) on conflict (k) do update set v = excluded.v returning v
$$;

-- Jalankan p_sql sebagai user tertentu. Mengembalikan kolom pertama baris pertama (sebagai teks),
-- '' bila tidak ada hasil, atau 'ERROR: <pesan>' bila gagal.
create function tests.as_user(p_who text, p_sql text) returns text
language plpgsql as $$
declare
  v_uid    uuid;
  v_anon   boolean;
  v_result text;
begin
  select id, anon into v_uid, v_anon from tests.users where who = p_who;
  perform set_config('request.jwt.claim.sub', v_uid::text, true);
  perform set_config('request.jwt.claims',
                     json_build_object('sub', v_uid, 'role', 'authenticated', 'is_anonymous', v_anon)::text, true);
  begin
    set local role authenticated;
    execute p_sql into v_result;
    reset role;
  exception when others then
    reset role;
    return 'ERROR: ' || sqlerrm;
  end;
  return coalesce(v_result, '');
end;
$$;

-- Sama seperti as_user, tapi sebagai superuser (untuk menguji trigger)
create function tests.try(p_sql text) returns text
language plpgsql as $$
begin
  execute p_sql;
  return '';
exception when others then
  return 'ERROR: ' || sqlerrm;
end;
$$;

create function tests.bal(p_k text, p_bucket text default 'available') returns int
language sql as $$
  select coalesce(sum(amount), 0)::int from public.point_transactions
   where member_id = tests.id(p_k) and bucket = p_bucket
$$;

create function tests.task(p_title text) returns uuid
language sql as $$ select id from public.tasks where title = p_title $$;

create function tests.reward(p_title text) returns uuid
language sql as $$ select id from public.rewards where title = p_title $$;

-- Path foto bukti milik Raka
create function tests.photo(p_file text) returns text
language sql as $$ select tests.id('fam') || '/' || tests.id('raka') || '/' || p_file $$;

create function tests.photos(variadic p_files text[]) returns text
language sql as $$
  select json_agg(json_build_object('path', tests.photo(f)))::text from unnest(p_files) f
$$;

insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'),
  ('00000000-0000-0000-0000-00000000000b'),
  ('00000000-0000-0000-0000-00000000000c'),
  ('00000000-0000-0000-0000-00000000000d');
insert into tests.users values
  ('rina',    '00000000-0000-0000-0000-00000000000a', false),
  ('ayah',    '00000000-0000-0000-0000-00000000000b', false),
  ('hp_raka', '00000000-0000-0000-0000-00000000000c', true),
  ('luar',    '00000000-0000-0000-0000-00000000000d', false);

-- =====================================================================
-- 1. Setup keluarga (Flow 1)
-- =====================================================================

select tests.save('fam', tests.as_user('rina', $$ select create_family('Keluarga Rina', 'Ibu Rina') $$));
select ok(tests.id('fam') is not null, 'owner membuat keluarga');

select is(tests.as_user('rina', format($$ select apply_economy_template(%L, '10-13') $$, tests.id('fam'))),
          '', 'template ekonomi diterapkan');
select is((select count(*)::int from tasks), 6, 'template mengisi 6 tugas');
select is((select count(*)::int from rewards), 4, 'template mengisi 4 hadiah');
select is((select points from tasks where title = 'Rapikan kasur'), 20, 'poin sesuai template 10-13');

select tests.save('raka', tests.as_user('rina', format(
  $$ insert into members (family_id, role, name) values (%L, 'member', 'Raka') returning id $$, tests.id('fam'))));
select ok(tests.id('raka') is not null, 'owner menambah anak');

select tests.save('code_raka', tests.as_user('rina', format(
  $$ select create_invite(%L, 'member', %L) $$, tests.id('fam'), tests.id('raka'))));
select matches((select v from tests.ids where k = 'code_raka'), '^[A-HJ-NP-Z2-9]{6}$', 'kode undangan anak 6 karakter');

select tests.save('code_ayah', tests.as_user('rina', format($$ select create_invite(%L, 'admin') $$, tests.id('fam'))));
select matches((select v from tests.ids where k = 'code_ayah'), '^[A-HJ-NP-Z2-9]{6}$', 'kode undangan admin 6 karakter');

-- =====================================================================
-- 2. Anak & admin bergabung (Flow 2), isolasi antar keluarga
-- =====================================================================

select matches(tests.as_user('hp_raka', $$ select create_family('x', 'y') $$),
               'account_required', 'akun anonim tidak bisa membuat keluarga');
select is(tests.as_user('hp_raka', format($$ select join_family(%L) $$, (select v from tests.ids where k = 'code_raka'))),
          tests.id('raka')::text, 'anak bergabung lewat kode');
select matches(tests.as_user('hp_raka', format($$ select join_family(%L) $$, (select v from tests.ids where k = 'code_raka'))),
               'invalid_invite', 'kode undangan hanya sekali pakai');
select is(tests.as_user('hp_raka', $$ select count(*) from tasks $$), '6', 'anak melihat tugas keluarganya');
select matches(tests.as_user('hp_raka', $$ select pin_hash from members limit 1 $$),
               'permission denied', 'pin_hash tidak bisa dibaca');
select matches(tests.as_user('hp_raka', $$ select count(*) from invites $$),
               '^0$', 'anak tidak melihat kode undangan');

select tests.save('ayah', tests.as_user('ayah', format(
  $$ select join_family(%L, 'Ayah') $$, (select v from tests.ids where k = 'code_ayah'))));
select is((select role from members where id = tests.id('ayah')), 'admin', 'ayah bergabung sebagai admin');

select is(tests.as_user('luar', $$ select count(*) from tasks $$), '0', 'orang luar tidak melihat tugas');
select is(tests.as_user('luar', $$ select count(*) from members $$), '0', 'orang luar tidak melihat anggota');
select is(tests.as_user('luar', $$ select count(*) from member_balances $$), '0', 'orang luar tidak melihat saldo');

-- =====================================================================
-- 3. Lapor tugas & persetujuan (Flow 3)
-- =====================================================================

select tests.save('kasur', tests.as_user('hp_raka', format(
  $$ select submit_task(%L, %L) $$, tests.task('Rapikan kasur'), tests.id('raka'))));
select is(tests.bal('raka'), 20, 'tugas verifikasi otomatis langsung memberi poin');
select matches(tests.as_user('hp_raka', format($$ select submit_task(%L, %L) $$, tests.task('Rapikan kasur'), tests.id('raka'))),
               'task_limit_reached', 'batas harian tugas');

select tests.save('cuci', tests.as_user('hp_raka', format(
  $$ select submit_task(%L, %L, 'sudah bersih') $$, tests.task('Bantu cuci piring'), tests.id('raka'))));
select is(tests.bal('raka'), 20, 'tugas persetujuan belum memberi poin');

select matches(tests.as_user('hp_raka', format(
  $$ insert into point_transactions (family_id, member_id, amount, type) values (%L, %L, 999, 'bonus') returning id $$,
  tests.id('fam'), tests.id('raka'))), 'permission denied', 'anak tidak bisa menambah poin langsung');
select matches(tests.as_user('hp_raka', format(
  $$ update task_submissions set status = 'approved' where id = %L returning id $$, tests.id('cuci'))),
  'permission denied', 'anak tidak bisa mengubah status laporan');
select matches(tests.as_user('hp_raka', format($$ select review_submission(%L, 'approve') $$, tests.id('cuci'))),
               'not_authorized', 'anak tidak bisa menyetujui laporan');

select is(tests.as_user('rina', format($$ select review_submission(%L, 'approve', 'Mantap', 10) $$, tests.id('cuci'))),
          '', 'owner menyetujui dengan bonus');
select is(tests.bal('raka'), 80, 'poin tugas + bonus masuk');
select matches(tests.as_user('ayah', format($$ select review_submission(%L, 'approve') $$, tests.id('cuci'))),
               'already_reviewed', 'persetujuan kedua ditolak');

-- =====================================================================
-- 4. Bukti foto (PF-01–PF-05)
-- =====================================================================

select matches(tests.as_user('hp_raka', format($$ select submit_task(%L, %L) $$, tests.task('PR selesai tanpa disuruh'), tests.id('raka'))),
               'photos_required', 'foto wajib untuk tugas berfoto');
select is(tests.as_user('hp_raka', format(
  $$ insert into storage.objects (bucket_id, name) values ('proofs', %L) returning name $$, tests.photo('p1.jpg'))),
  tests.photo('p1.jpg'), 'anak mengunggah foto ke foldernya');
select matches(tests.as_user('hp_raka', format(
  $$ insert into storage.objects (bucket_id, name) values ('proofs', %L) returning name $$,
  tests.id('fam') || '/' || tests.id('ayah') || '/x.jpg')),
  'row-level security', 'anak tidak bisa mengunggah ke folder anggota lain');
select matches(tests.as_user('hp_raka', format($$ select submit_task(%L, %L, null, %L::jsonb) $$,
                 tests.task('PR selesai tanpa disuruh'), tests.id('raka'), tests.photos('belum.jpg'))),
               'photo_not_uploaded', 'foto harus sudah terunggah');
select matches(tests.as_user('hp_raka', format($$ select submit_task(%L, %L, null, %L::jsonb) $$,
                 tests.task('PR selesai tanpa disuruh'), tests.id('raka'),
                 json_build_array(json_build_object('path', tests.photo('p1.jpg'), 'source', 'gallery')))),
               'invalid_photo', 'foto dari galeri ditolak secara default');

select tests.save('pr', tests.as_user('hp_raka', format($$ select submit_task(%L, %L, null, %L::jsonb) $$,
                    tests.task('PR selesai tanpa disuruh'), tests.id('raka'), tests.photos('p1.jpg'))));
select is((select status from task_submissions where id = tests.id('pr')), 'pending', 'laporan berfoto menunggu');

select is(tests.as_user('rina', format($$ select review_submission(%L, 'retake', 'Fotonya buram') $$, tests.id('pr'))),
          '', 'owner meminta foto ulang');
select is(tests.as_user('hp_raka', format($$ select status from task_submissions where id = %L $$, tests.id('pr'))),
          'needs_retake', 'anak melihat status perlu foto ulang');

select tests.as_user('hp_raka', format(
  $$ insert into storage.objects (bucket_id, name) values ('proofs', %L) returning name $$, tests.photo('p2.jpg')));
select is(tests.as_user('hp_raka', format($$ select resubmit_photos(%L, %L::jsonb) $$, tests.id('pr'), tests.photos('p2.jpg'))),
          '', 'anak mengirim foto ulang tanpa laporan baru');
select is((select count(*)::int from submission_photos where submission_id = tests.id('pr') and deleted_at is null),
          1, 'foto lama ditandai hapus');

select is(tests.as_user('ayah', $$ select count(*) from storage.objects where bucket_id = 'proofs' $$),
          '2', 'admin keluarga bisa membuka foto bukti');
select is(tests.as_user('luar', $$ select count(*) from storage.objects where bucket_id = 'proofs' $$),
          '0', 'orang luar tidak bisa membuka foto bukti');

select is(tests.as_user('rina', format($$ select review_submission(%L, 'approve') $$, tests.id('pr'))), '', 'foto ulang disetujui');
select is(tests.bal('raka'), 160, 'poin PR masuk');

-- Notifikasi (minggu 4): cuci & PR dilaporkan, PR diminta foto ulang lalu dikirim ulang
select is((select count(*)::int from notifications
            where member_id = (select id from members where name = 'Ibu Rina') and kind = 'submission_pending'),
          3, 'admin diberi tahu setiap laporan baru & foto ulang');
select is((select count(*)::int from notifications where member_id = tests.id('ayah') and kind = 'submission_pending'),
          3, 'semua admin diberi tahu');
select is((select title || ' ' || body from notifications
            where member_id = tests.id('raka') and kind = 'submission_approved' order by id limit 1),
          '+50 poin! Bantu cuci piring disetujui.', 'teks notifikasi disetujui sesuai PRD');
select is(tests.as_user('hp_raka', $$ select count(*) from notifications $$), '3',
          'anak hanya melihat notifikasinya sendiri (2 disetujui + 1 foto ulang)');
select is(tests.as_user('luar', $$ select count(*) from notifications $$), '0', 'orang luar tidak melihat notifikasi');
select tests.as_user('hp_raka', format($$ select mark_notifications_read(%L) $$, tests.id('raka')));
select is(tests.as_user('hp_raka', $$ select count(*) from notifications where read_at is null $$),
          '0', 'anak menandai notifikasi sudah dibaca');

-- =====================================================================
-- 5. Tukar hadiah instan (Flow 4)
-- =====================================================================

select tests.save('red1', tests.as_user('hp_raka', format(
  $$ select redeem_reward(%L, %L) $$, tests.reward('30 menit main game'), tests.id('raka'))));
select is(tests.bal('raka'), 60, 'poin ditahan saat menukar');
select is(tests.as_user('hp_raka', format($$ select on_hold from member_balances where member_id = %L $$, tests.id('raka'))),
          '100', 'poin yang sedang ditukar terlihat');

select matches(tests.as_user('rina', format($$ select review_redemption(%L, 'reject') $$, tests.id('red1'))),
               'reason_required', 'menolak penukaran wajib alasan');
select is(tests.as_user('rina', format($$ select review_redemption(%L, 'reject', 'Besok saja') $$, tests.id('red1'))),
          '', 'owner menolak penukaran');
select is(tests.bal('raka'), 160, 'poin kembali saat penukaran ditolak');

select tests.save('red2', tests.as_user('hp_raka', format(
  $$ select redeem_reward(%L, %L) $$, tests.reward('30 menit main game'), tests.id('raka'))));
select tests.save('red3', tests.as_user('hp_raka', format(
  $$ select redeem_reward(%L, %L) $$, tests.reward('Pilih menu makan malam'), tests.id('raka'))));
select is(tests.as_user('hp_raka', format($$ select cancel_redemption(%L) $$, tests.id('red3'))), '', 'anak membatalkan penukaran');
select is(tests.bal('raka'), 60, 'poin kembali saat dibatalkan');

select is(tests.as_user('rina', format($$ select review_redemption(%L, 'approve') $$, tests.id('red2'))), '', 'owner menyetujui screen time');
select is((select session_ends_at - session_started_at from redemptions where id = tests.id('red2')),
          interval '30 minutes', 'sesi screen time 30 menit dimulai');

-- =====================================================================
-- 6. Goal (Flow 5)
-- =====================================================================

select tests.as_user('hp_raka', format($$ select set_goal(%L, %L) $$, tests.id('raka'), tests.reward('Makan di restoran favorit')));
select is(tests.as_user('hp_raka', format($$ select save_to_goal(%L, 50) $$, tests.id('raka'))), '', 'anak menabung untuk goal');
select is(tests.bal('raka'), 10, 'tabungan goal keluar dari saldo tersedia');
select is(tests.bal('raka', 'goal'), 50, 'tabungan goal tercatat di ledger');
select matches(tests.as_user('hp_raka', format($$ select redeem_reward(%L, %L) $$, tests.reward('Makan di restoran favorit'), tests.id('raka'))),
               'insufficient_points', 'goal belum bisa ditukar bila poin kurang');

select is(tests.as_user('rina', format($$ select adjust_points(%L, 5000, 'Hadiah ulang tahun') $$, tests.id('raka'))),
          '', 'owner memberi bonus');
select matches(tests.as_user('rina', format($$ select adjust_points(%L, -999999, 'Tes') $$, tests.id('raka'))),
               'insufficient_points', 'penalti tidak boleh melebihi saldo');
select matches(tests.as_user('rina', format($$ select adjust_points(%L, 10, '') $$, tests.id('raka'))),
               'reason_required', 'bonus/penalti wajib alasan');

select tests.save('red4', tests.as_user('hp_raka', format(
  $$ select redeem_reward(%L, %L) $$, tests.reward('Makan di restoran favorit'), tests.id('raka'))));
select is(tests.bal('raka'), 60, 'tabungan goal dipakai dulu, kekurangannya dari saldo');
select is(tests.bal('raka', 'goal'), 0, 'tabungan goal terpakai');
select is(tests.as_user('rina', format($$ select review_redemption(%L, 'fulfill') $$, tests.id('red4'))), '', 'owner menandai sudah diberikan');
select ok((select achieved_at is not null from goals where reward_id = tests.reward('Makan di restoran favorit')), 'goal tercapai');

-- =====================================================================
-- 7. Aturan harga 7 hari (aturan bisnis 6)
-- =====================================================================

select tests.save('sepatu', tests.as_user('rina', format(
  $$ insert into rewards (family_id, title, cost, type) values (%L, 'Sepatu baru', 8000, 'goal') returning id $$, tests.id('fam'))));
select matches(tests.as_user('rina', format($$ update rewards set cost = 1 where id = %L returning id $$, tests.id('sepatu'))),
               'permission denied', 'harga tidak bisa diubah langsung');
select tests.as_user('hp_raka', format($$ select set_goal(%L, %L) $$, tests.id('raka'), tests.id('sepatu')));

select is(tests.as_user('rina', format($$ select update_reward_price(%L, 9000) $$, tests.id('sepatu'))),
          'scheduled', 'kenaikan harga goal dijadwalkan 7 hari');
select is((select cost from rewards where id = tests.id('sepatu')), 8000, 'harga lama masih berlaku');
select is(tests.as_user('rina', format($$ select update_reward_price(%L, 7000) $$, tests.id('sepatu'))),
          'applied', 'penurunan harga langsung berlaku');
select is((select pending_cost from rewards where id = tests.id('sepatu')), null::int, 'kenaikan tertunda dibatalkan');

select tests.as_user('rina', format($$ select update_reward_price(%L, 9500) $$, tests.id('sepatu')));
update rewards set cost_effective_at = now() - interval '1 second' where id = tests.id('sepatu');
select public.apply_pending_prices();
select is((select cost from rewards where id = tests.id('sepatu')), 9500, 'job menerapkan harga setelah 7 hari');

-- Notifikasi penukaran & harga goal (minggu 7)
select is((select count(*)::int from notifications
            where member_id = (select id from members where name = 'Ibu Rina') and kind = 'redemption_requested'),
          4, 'admin diberi tahu setiap permintaan hadiah');
select is((select body from notifications where member_id = tests.id('raka') and kind = 'redemption_rejected'),
          '30 menit main game ditolak: Besok saja. Poinmu sudah kembali.', 'anak diberi tahu alasan penolakan hadiah');
select is((select count(*)::int from notifications where member_id = tests.id('raka') and kind = 'redemption_approved'),
          1, 'anak diberi tahu hadiah disetujui');
select is((select body from notifications where member_id = tests.id('raka') and kind = 'redemption_fulfilled'),
          'Makan di restoran favorit sudah diberikan.', 'anak diberi tahu hadiah goal sudah diberikan');
select is((select count(*)::int from notifications where member_id = tests.id('raka') and kind = 'goal_price_changed'),
          2, 'anak diberi tahu setiap kenaikan harga goal');

-- =====================================================================
-- 8. Pembatalan tugas otomatis -> utang poin (aturan bisnis 3)
-- =====================================================================

select tests.as_user('rina', format($$ select adjust_points(%L, -50, 'Tes') $$, tests.id('raka')));
select is(tests.bal('raka'), 10, 'saldo sebelum pembatalan');
select is(tests.as_user('rina', format($$ select reverse_auto_task(%L, 'Kasur belum rapi') $$, tests.id('kasur'))),
          '', 'owner membatalkan tugas otomatis');
select is(tests.bal('raka'), -10, 'pembatalan boleh menghasilkan utang poin');

-- =====================================================================
-- 9. Pasangan dewasa: tidak bisa menyetujui laporan sendiri
-- =====================================================================

select is(tests.as_user('ayah', format($$ update members set can_earn = true where id = %L returning can_earn $$, tests.id('ayah'))),
          'true', 'admin mengaktifkan "ikut mengumpulkan poin"');
select tests.save('ayahlapor', tests.as_user('ayah', format(
  $$ select submit_task(%L, %L) $$, tests.task('Baca buku 30 menit'), tests.id('ayah'))));
select matches(tests.as_user('ayah', format($$ select review_submission(%L, 'approve') $$, tests.id('ayahlapor'))),
               'cannot_review_own', 'tidak bisa menyetujui laporan sendiri');
select tests.as_user('rina', format($$ select review_submission(%L, 'approve') $$, tests.id('ayahlapor')));
select is(tests.bal('ayah'), 60, 'admin lain menyetujui laporan ayah');

-- =====================================================================
-- 10. Streak (aturan bisnis 8)
-- =====================================================================

select is((select current_count from streaks where member_id = tests.id('raka')), 1, 'streak hari ini');

insert into task_submissions (task_id, member_id, family_id, status, points_snapshot, for_date)
values (tests.task('Bantu cuci piring'), tests.id('raka'), tests.id('fam'), 'approved', 50,
        (now() at time zone 'Asia/Jakarta')::date - 2),
       (tests.task('Bantu cuci piring'), tests.id('raka'), tests.id('fam'), 'pending', 50,
        (now() at time zone 'Asia/Jakarta')::date - 1);
select public._recompute_streak(tests.id('raka'));
select is((select current_count from streaks where member_id = tests.id('raka')), 2, 'hari tertunda tidak memutus streak');
select ok((select has_pending from streaks where member_id = tests.id('raka')), 'hari tertunda ditandai');

-- =====================================================================
-- 11. Job terjadwal
-- =====================================================================

select is((select count(*)::int from cron.job where jobname in (
            'apply-pending-prices', 'finish-screen-sessions', 'flag-stale-submissions',
            'refresh-streaks', 'expire-old-photos', 'cleanup-invites')), 6, '6 job terjadwal terdaftar');
select lives_ok($$ select public.expire_old_photos(), public.flag_stale_submissions(),
                          public.finish_screen_sessions(), public.refresh_streaks(), public.cleanup_invites() $$,
                'semua job terjadwal berjalan');

-- =====================================================================
-- 12. Batas paket gratis
-- =====================================================================

update families set plan = 'free' where id = tests.id('fam');
select matches(tests.as_user('rina', format(
  $$ insert into members (family_id, role, name) values (%L, 'member', 'Kiara') returning id $$, tests.id('fam'))),
  'plan_limit_children', 'paket gratis: maksimal 1 anak');
update families set plan = 'beta' where id = tests.id('fam');

-- =====================================================================
-- 12b. Push OneSignal (antrean notifikasi)
-- =====================================================================

select matches(tests.as_user('rina', $$ select count(*) from claim_push_batch() $$),
               'permission denied', 'app tidak bisa mengambil antrean push');
create table tests.claimed as select * from public.claim_push_batch(1000);
select ok((select count(*) from tests.claimed) > 0, 'notifikasi yang belum terkirim diambil');
select is((select count(*)::int from notifications where sent_at is null), 0, 'yang diambil langsung ditandai terkirim');
select ok((select bool_and(c.external_ids @> array[(select id::text from tests.users where who = 'hp_raka')])
             from tests.claimed c join notifications n on n.id = c.id where n.member_id = tests.id('raka')),
          'push ke anak ditujukan ke login HP-nya (external_id)');
select is((select string_agg(distinct c.route, ',') from tests.claimed c join notifications n on n.id = c.id
            where n.kind in ('submission_pending', 'redemption_requested')),
          '/parent/approvals', 'push laporan baru membuka antrean persetujuan');
select release_push(array(select id from tests.claimed));
select is((select count(*)::int from notifications where sent_at is null), (select count(*)::int from tests.claimed),
          'pengiriman gagal kembali ke antrean');
select is(_quiet_until(tests.id('fam'), '2026-11-05 22:00+07'), '2026-11-06 06:00+07'::timestamptz,
          'jam tidur malam: push anak ditunda sampai 06:00 besok');
select is(_quiet_until(tests.id('fam'), '2026-11-05 05:00+07'), '2026-11-05 06:00+07'::timestamptz,
          'jam tidur dini hari: ditunda sampai 06:00 hari itu');
select ok(_quiet_until(tests.id('fam'), '2026-11-05 12:00+07') is null, 'di luar jam tidur: langsung dikirim');
select is((select count(*)::int from cron.job where jobname = 'send-push'), 1, 'job send-push terdaftar');

select is((select count(*)::int from pg_publication_tables
            where pubname = 'supabase_realtime' and tablename in ('tasks', 'members')), 2,
          'tugas & anggota ikut realtime');

-- =====================================================================
-- 13. Ledger, kepemilikan, hapus keluarga
-- =====================================================================

select matches(tests.try('update public.point_transactions set amount = 1'),
               'ledger_is_append_only', 'ledger tidak bisa diubah');
select matches(tests.as_user('ayah', format($$ select delete_family(%L) $$, tests.id('fam'))),
               'owner_only', 'hanya owner yang bisa menghapus keluarga');
select is(tests.as_user('rina', format($$ select transfer_ownership(%L) $$, tests.id('ayah'))), '', 'owner mengalihkan kepemilikan');
select is((select role from members where id = tests.id('ayah')), 'owner', 'ayah menjadi owner');
select is(tests.as_user('ayah', format($$ select delete_family(%L) $$, tests.id('fam'))), '', 'owner baru menghapus keluarga');
select is((select count(*)::int from point_transactions where family_id = tests.id('fam')), 0, 'seluruh data keluarga ikut terhapus');

select * from finish();
rollback;
