-- Family Points App — database functions (RPC)
--
-- Semua operasi yang mengubah poin atau status berjalan di sini, dalam satu transaksi database.
-- Konvensi error: pesan exception = kode mesin (mis. 'insufficient_points'), diterjemahkan di aplikasi.
-- Untuk 'already_reviewed', DETAIL berisi nama admin yang sudah memproses dan HINT berisi status saat ini.
--
-- Fungsi berawalan "_" adalah helper internal dan tidak bisa dipanggil dari aplikasi.

-- =====================================================================
-- Helper internal
-- =====================================================================

create function public._family_today(p_family_id uuid) returns date
language sql stable security definer set search_path = public as $$
  select (now() at time zone timezone)::date from families where id = p_family_id;
$$;

create function public._balance(p_member_id uuid, p_bucket text) returns int
language sql stable security definer set search_path = public as $$
  select coalesce(sum(amount), 0)::int
    from point_transactions
   where member_id = p_member_id and bucket = p_bucket;
$$;

-- Anggota yang sedang dipakai di HP ini (anak, atau orang dewasa yang ikut mengumpulkan poin)
create function public._require_linked_member(p_member_id uuid) returns public.members
language plpgsql stable security definer set search_path = public as $$
declare
  v members;
begin
  select m.* into v
    from members m
    join member_logins ml on ml.member_id = m.id
   where m.id = p_member_id and ml.user_id = auth.uid() and m.is_active;
  if not found then
    raise exception 'not_authorized';
  end if;
  return v;
end;
$$;

-- Baris admin milik pemanggil di keluarga tersebut
create function public._require_admin(p_family_id uuid) returns public.members
language plpgsql stable security definer set search_path = public as $$
declare
  v members;
begin
  select m.* into v
    from members m
    join member_logins ml on ml.member_id = m.id
   where m.family_id = p_family_id
     and ml.user_id = auth.uid()
     and m.is_active
     and m.role in ('owner', 'admin')
   order by (m.role = 'owner') desc
   limit 1;
  if not found then
    raise exception 'not_authorized';
  end if;
  return v;
end;
$$;

create function public._add_points(
  p_family_id uuid, p_member_id uuid, p_bucket text, p_amount int,
  p_type text, p_ref_id uuid, p_reason text, p_created_by uuid
) returns void
language sql security definer set search_path = public as $$
  insert into point_transactions (family_id, member_id, bucket, amount, type, ref_id, reason, created_by)
  values (p_family_id, p_member_id, p_bucket, p_amount, p_type, p_ref_id, p_reason, p_created_by);
$$;

-- Streak dihitung per for_date (aturan bisnis 8):
--   hari "berhasil" = ada laporan disetujui (dan tidak dibatalkan) untuk tanggal itu
--   hari "tertunda" = belum berhasil, tapi masih ada laporan menunggu / perlu foto ulang -> tidak memutus
--   hari lainnya    = memutus streak (kecuali hari ini, yang belum selesai)
create function public._recompute_streak(p_member_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_today       date;
  v_day         date;
  v_state       text;
  v_count       int := 0;
  v_last        date;
  v_has_pending boolean := false;
begin
  select _family_today(family_id) into v_today from members where id = p_member_id;
  v_day := v_today;

  while v_day > v_today - 400 loop
    select case
             when bool_or(status = 'approved' and reversed_at is null) then 'ok'
             when bool_or(status in ('pending', 'needs_retake')) then 'pending'
             else 'none'
           end
      into v_state
      from task_submissions
     where member_id = p_member_id and for_date = v_day;

    if v_state = 'ok' then
      v_count := v_count + 1;
      v_last := coalesce(v_last, v_day);
    elsif v_state = 'pending' then
      v_has_pending := true;
    elsif v_day <> v_today then
      exit;
    end if;
    v_day := v_day - 1;
  end loop;

  insert into streaks (member_id, current_count, best_count, last_date, has_pending, updated_at)
  values (p_member_id, v_count, v_count, v_last, v_has_pending, now())
  on conflict (member_id) do update
     set current_count = excluded.current_count,
         best_count    = greatest(streaks.best_count, excluded.current_count),
         last_date     = excluded.last_date,
         has_pending   = excluded.has_pending,
         updated_at    = now();
end;
$$;

-- Validasi & simpan foto bukti (PF-01, PF-02, PF-06, PF-07)
-- p_photos: [{"path": "...", "kind": "single|before|after", "source": "camera|gallery", "taken_at": "..."}]
create function public._insert_photos(
  p_task public.tasks, p_member public.members, p_submission_id uuid, p_photos jsonb
) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_prefix text := p_member.family_id::text || '/' || p_member.id::text || '/';
  v_total  int;
  v_before int;
  v_after  int;
begin
  p_photos := coalesce(p_photos, '[]'::jsonb);
  if jsonb_typeof(p_photos) <> 'array' then
    raise exception 'invalid_photo';
  end if;

  if p_task.verification <> 'photo' then
    if jsonb_array_length(p_photos) > 0 then
      raise exception 'photos_not_allowed';
    end if;
    return;
  end if;

  select count(*),
         count(*) filter (where e ->> 'kind' = 'before'),
         count(*) filter (where e ->> 'kind' = 'after')
    into v_total, v_before, v_after
    from jsonb_array_elements(p_photos) e;

  if v_total > 6 then
    raise exception 'too_many_photos';
  end if;
  if p_task.before_after then
    if v_before < 1 or v_after < 1 then
      raise exception 'photos_required';
    end if;
  elsif v_total < p_task.min_photos then
    raise exception 'photos_required';
  end if;

  if exists (
    select 1 from jsonb_array_elements(p_photos) e
     where left(coalesce(e ->> 'path', ''), length(v_prefix)) <> v_prefix
        or coalesce(e ->> 'kind', 'single') not in ('single', 'before', 'after')
        or coalesce(e ->> 'source', 'camera') not in ('camera', 'gallery')
        or (coalesce(e ->> 'source', 'camera') = 'gallery' and not p_task.allow_gallery)
  ) then
    raise exception 'invalid_photo';
  end if;

  -- File harus sudah benar-benar terunggah ke bucket privat
  if exists (
    select 1 from jsonb_array_elements(p_photos) e
     where not exists (select 1 from storage.objects o
                        where o.bucket_id = 'proofs' and o.name = e ->> 'path')
  ) then
    raise exception 'photo_not_uploaded';
  end if;

  insert into submission_photos (submission_id, kind, storage_path, taken_at, source)
  select p_submission_id,
         coalesce(e ->> 'kind', 'single'),
         e ->> 'path',
         least(now(), coalesce((e ->> 'taken_at')::timestamptz, now())),
         coalesce(e ->> 'source', 'camera')
    from jsonb_array_elements(p_photos) e;
end;
$$;

-- Kembalikan poin yang ditahan sebuah penukaran dan kembalikan stok.
-- Poin dari kantong goal kembali ke goal bila goal itu masih aktif; kalau tidak, ke saldo tersedia.
create function public._release_redemption(p_redemption public.redemptions, p_reason text, p_by uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_goal_active boolean;
begin
  select exists (select 1 from goals
                  where member_id = p_redemption.member_id and reward_id = p_redemption.reward_id and is_active)
    into v_goal_active;

  insert into point_transactions (family_id, member_id, bucket, amount, type, ref_id, reason, created_by)
  select family_id, member_id,
         case when bucket = 'goal' and not v_goal_active then 'available' else bucket end,
         -amount, 'redeem_release', ref_id, p_reason, p_by
    from point_transactions
   where ref_id = p_redemption.id and type = 'redeem_hold';

  update rewards set stock = stock + 1
   where id = p_redemption.reward_id and stock is not null;
end;
$$;

-- Pindahkan seluruh tabungan goal kembali ke saldo tersedia
create function public._unsave_all(p_family_id uuid, p_member_id uuid, p_goal_id uuid, p_reason text, p_by uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_saved int := _balance(p_member_id, 'goal');
begin
  if v_saved > 0 then
    perform _add_points(p_family_id, p_member_id, 'goal', -v_saved, 'goal_unsave', p_goal_id, p_reason, p_by);
    perform _add_points(p_family_id, p_member_id, 'available', v_saved, 'goal_unsave', p_goal_id, p_reason, p_by);
  end if;
end;
$$;

-- Tutup goal yang tercapai; sisa tabungan goal kembali ke saldo tersedia
create function public._close_goal(p_member_id uuid, p_reward_id uuid, p_by uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_goal goals;
begin
  update goals set is_active = false, achieved_at = now()
   where member_id = p_member_id and reward_id = p_reward_id and is_active
  returning * into v_goal;
  if found then
    perform _unsave_all(v_goal.family_id, p_member_id, v_goal.id, 'Sisa tabungan goal', p_by);
  end if;
end;
$$;

-- =====================================================================
-- Akun, keluarga, anggota (A-01–A-05, M-01–M-03)
-- =====================================================================

create function public.create_family(p_family_name text, p_owner_name text, p_timezone text default 'Asia/Jakarta')
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_family uuid;
  v_member uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;
  if coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) then
    raise exception 'account_required';
  end if;

  insert into families (name, timezone) values (p_family_name, p_timezone)
  returning id into v_family;

  insert into members (family_id, role, can_earn, name) values (v_family, 'owner', false, p_owner_name)
  returning id into v_member;

  insert into member_logins (member_id, user_id) values (v_member, auth.uid());
  return v_family;
end;
$$;

-- Template ekonomi per usia (PRD "Template ekonomi bawaan"). Nilai dasar = template 10–13 tahun.
-- p_member_ids: anak yang ditugaskan; kosong = tugas untuk semua.
create function public.apply_economy_template(p_family_id uuid, p_age_band text, p_member_ids uuid[] default null)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_admin      members;
  v_factor     numeric;
  v_screen     int;
  v_goal_title text;
  v_goal_cost  int;
begin
  v_admin := _require_admin(p_family_id);

  case p_age_band
    when '6-9' then
      v_factor := 0.5;  v_screen := 50;  v_goal_title := 'Mainan baru';               v_goal_cost := 2000;
    when '10-13' then
      v_factor := 1;    v_screen := 100; v_goal_title := 'Makan di restoran favorit'; v_goal_cost := 5000;
    when '14-17' then
      v_factor := 1.35; v_screen := 150; v_goal_title := 'Top-up game';               v_goal_cost := 10000;
    else
      raise exception 'invalid_age_band';
  end case;

  with base (title, icon, points, frequency, max_per_day, verification, min_photos, allow_gallery) as (
    values
      ('Rapikan kasur',            'bed',    20,  'daily',  1, 'auto',    0, false),
      ('Bantu cuci piring',        'dish',   50,  'daily',  1, 'approve', 0, false),
      ('Baca buku 30 menit',       'book',   60,  'repeat', 2, 'approve', 0, false),
      ('PR selesai tanpa disuruh', 'pencil', 80,  'daily',  1, 'photo',   1, false),
      ('Bersihkan kamar',          'broom',  150, 'weekly', 1, 'photo',   1, false),
      ('Nilai ujian ≥ 85',         'trophy', 300, 'once',   1, 'photo',   1, true)
  ), inserted as (
    insert into tasks (family_id, title, icon, points, frequency, max_per_day, verification,
                       min_photos, allow_gallery, created_by)
    select p_family_id, title, icon, greatest(5, round(points * v_factor / 5) * 5)::int,
           frequency, max_per_day, verification, min_photos, allow_gallery, v_admin.id
      from base
    returning id
  )
  insert into task_assignments (task_id, member_id)
  select i.id, m.id
    from inserted i
    cross join unnest(coalesce(p_member_ids, '{}'::uuid[])) as a (member_id)
    join members m on m.id = a.member_id and m.family_id = p_family_id;

  insert into rewards (family_id, title, cost, type, duration_minutes, max_per_day, created_by)
  values
    (p_family_id, '30 menit main game',        v_screen,                                  'instant', 30,   2,    v_admin.id),
    (p_family_id, '30 menit TikTok / YouTube', v_screen,                                  'instant', 30,   2,    v_admin.id),
    (p_family_id, 'Pilih menu makan malam',    greatest(5, round(v_screen * 0.5 / 5) * 5)::int, 'instant', null, 1, v_admin.id),
    (p_family_id, v_goal_title,                v_goal_cost,                               'goal',    null, null, v_admin.id);
end;
$$;

-- Kode undangan 6 karakter, berlaku 24 jam, sekali pakai (A-04, M-02)
create function public.create_invite(p_family_id uuid, p_role text, p_member_id uuid default null)
returns text
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_admin    members;
  v_alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';  -- 32 karakter
  v_bytes    bytea;
  v_code     text;
begin
  v_admin := _require_admin(p_family_id);

  if p_role = 'member' then
    if not exists (select 1 from members
                    where id = p_member_id and family_id = p_family_id and role = 'member' and is_active) then
      raise exception 'member_not_found';
    end if;
    -- Hanya satu kode aktif per anak
    update invites set expires_at = now()
     where member_id = p_member_id and used_at is null and expires_at > now();
  elsif p_role = 'admin' then
    if v_admin.role <> 'owner' then
      raise exception 'owner_only';
    end if;
    p_member_id := null;
  else
    raise exception 'invalid_role';
  end if;

  loop
    v_bytes := gen_random_bytes(6);
    v_code := '';
    for i in 0..5 loop
      v_code := v_code || substr(v_alphabet, (get_byte(v_bytes, i) % 32) + 1, 1);
    end loop;
    begin
      insert into invites (family_id, code, role, member_id, created_by)
      values (p_family_id, v_code, p_role, p_member_id, v_admin.id);
      return v_code;
    exception when unique_violation then
      null;  -- kode bentrok, coba lagi
    end;
  end loop;
end;
$$;

-- Anak: sign in anonim dulu, lalu panggil ini. Admin: wajib akun penuh.
create function public.join_family(p_code text, p_name text default null)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_invite invites;
  v_member uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select * into v_invite from invites where code = upper(trim(p_code)) for update;
  if not found or v_invite.used_at is not null or v_invite.expires_at <= now() then
    raise exception 'invalid_invite';
  end if;

  if v_invite.role = 'member' then
    v_member := v_invite.member_id;
    -- Anak pindah HP / reinstall: sesi lama dicabut
    delete from member_logins where member_id = v_member;
  else
    if coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) then
      raise exception 'account_required';
    end if;
    if exists (select 1 from member_logins ml join members m on m.id = ml.member_id
                where ml.user_id = auth.uid() and m.family_id = v_invite.family_id
                  and m.role in ('owner', 'admin')) then
      raise exception 'already_admin';
    end if;
    insert into members (family_id, role, can_earn, name)
    values (v_invite.family_id, 'admin', false, coalesce(nullif(trim(p_name), ''), 'Admin'))
    returning id into v_member;
  end if;

  insert into member_logins (member_id, user_id) values (v_member, auth.uid())
  on conflict do nothing;
  update invites set used_by = auth.uid(), used_at = now() where id = v_invite.id;
  return v_member;
end;
$$;

-- PIN 4 digit untuk HP bersama (A-05). Hanya disimpan sebagai hash bcrypt.
create function public.set_member_pin(p_member_id uuid, p_pin text) returns void
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_family uuid;
begin
  if p_pin !~ '^[0-9]{4}$' then
    raise exception 'invalid_pin';
  end if;
  select family_id into v_family from members where id = p_member_id;
  if not found
     or (not exists (select 1 from member_logins where member_id = p_member_id and user_id = auth.uid())
         and not is_family_admin(v_family)) then
    raise exception 'not_authorized';
  end if;
  update members set pin_hash = crypt(p_pin, gen_salt('bf')) where id = p_member_id;
end;
$$;

create function public.verify_member_pin(p_member_id uuid, p_pin text) returns boolean
language plpgsql security definer set search_path = public, extensions as $$
declare
  v members;
begin
  v := _require_linked_member(p_member_id);
  return v.pin_hash is null or v.pin_hash = crypt(p_pin, v.pin_hash);
end;
$$;

-- Owner keluar: wajib mengalihkan kepemilikan ke admin lain (PRD edge case)
create function public.transfer_ownership(p_new_owner_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_target members;
  v_owner  members;
begin
  select * into v_target from members where id = p_new_owner_id for update;
  if not found then
    raise exception 'member_not_found';
  end if;
  v_owner := _require_admin(v_target.family_id);
  if v_owner.role <> 'owner' then
    raise exception 'owner_only';
  end if;
  if v_target.role <> 'admin' or not v_target.is_active
     or not exists (select 1 from member_logins where member_id = v_target.id) then
    raise exception 'invalid_target';
  end if;
  update members set role = 'admin' where id = v_owner.id;
  update members set role = 'owner' where id = v_target.id;
end;
$$;

-- Hapus keluarga beserta seluruh datanya. File foto di storage dibersihkan oleh Edge Function
-- (folder {family_id}/ yang tidak lagi punya baris families).
create function public.delete_family(p_family_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_owner members;
begin
  v_owner := _require_admin(p_family_id);
  if v_owner.role <> 'owner' then
    raise exception 'owner_only';
  end if;
  delete from families where id = p_family_id;
end;
$$;

create function public.register_device(p_push_token text, p_platform text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;
  insert into devices (user_id, push_token, platform, updated_at)
  values (auth.uid(), p_push_token, p_platform, now())
  on conflict (push_token) do update
     set user_id = excluded.user_id, platform = excluded.platform, updated_at = now();
end;
$$;

-- =====================================================================
-- Laporan & persetujuan (L-01–L-06, PF-01–PF-07)
-- =====================================================================

-- p_reported_at: waktu lapor dari HP untuk laporan yang diantre saat offline (maks 24 jam ke belakang)
create function public.submit_task(
  p_task_id uuid, p_member_id uuid, p_note text default null,
  p_photos jsonb default '[]'::jsonb, p_reported_at timestamptz default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_member   members;
  v_task     tasks;
  v_tz       text;
  v_for_date date;
  v_week     date;
  v_count    int;
  v_sub      uuid;
begin
  v_member := _require_linked_member(p_member_id);
  if not v_member.can_earn then
    raise exception 'member_cannot_earn';
  end if;

  -- Kunci baris anggota supaya cek batas harian tidak bisa diakali dengan laporan bersamaan
  perform 1 from members where id = p_member_id for update;

  select * into v_task from tasks where id = p_task_id and family_id = v_member.family_id;
  if not found or v_task.is_archived then
    raise exception 'task_not_available';
  end if;
  if exists (select 1 from task_assignments where task_id = p_task_id)
     and not exists (select 1 from task_assignments where task_id = p_task_id and member_id = p_member_id) then
    raise exception 'task_not_assigned';
  end if;

  select timezone into v_tz from families where id = v_member.family_id;
  v_for_date := (least(now(), greatest(coalesce(p_reported_at, now()), now() - interval '24 hours'))
                 at time zone v_tz)::date;

  -- Laporan yang ditolak atau dibatalkan tidak menghabiskan jatah
  if v_task.frequency = 'once' then
    select count(*) into v_count from task_submissions
     where task_id = p_task_id and member_id = p_member_id
       and status <> 'rejected' and reversed_at is null;
    if v_count > 0 then
      raise exception 'task_limit_reached';
    end if;
  elsif v_task.frequency = 'weekly' then
    v_week := date_trunc('week', v_for_date)::date;
    select count(*) into v_count from task_submissions
     where task_id = p_task_id and member_id = p_member_id
       and for_date >= v_week and for_date < v_week + 7
       and status <> 'rejected' and reversed_at is null;
    if v_count > 0 then
      raise exception 'task_limit_reached';
    end if;
  else
    if v_task.frequency = 'days_of_week'
       and not (extract(isodow from v_for_date)::smallint = any (v_task.days_of_week)) then
      raise exception 'task_not_today';
    end if;
    select count(*) into v_count from task_submissions
     where task_id = p_task_id and member_id = p_member_id and for_date = v_for_date
       and status <> 'rejected' and reversed_at is null;
    if v_count >= v_task.max_per_day then
      raise exception 'task_limit_reached';
    end if;
  end if;

  insert into task_submissions (task_id, member_id, family_id, status, note, points_snapshot,
                                for_date, is_auto, reviewed_at)
  values (p_task_id, p_member_id, v_member.family_id,
          case when v_task.verification = 'auto' then 'approved' else 'pending' end,
          nullif(trim(p_note), ''), v_task.points, v_for_date,
          v_task.verification = 'auto',
          case when v_task.verification = 'auto' then now() end)
  returning id into v_sub;

  perform _insert_photos(v_task, v_member, v_sub, p_photos);

  if v_task.verification = 'auto' then
    perform _add_points(v_member.family_id, p_member_id, 'available', v_task.points, 'task', v_sub, v_task.title, null);
  end if;

  perform _recompute_streak(p_member_id);
  return v_sub;
end;
$$;

-- p_action: 'approve' (opsional p_bonus), 'reject' (p_reason wajib), 'retake' (minta foto ulang)
create function public.review_submission(
  p_submission_id uuid, p_action text, p_reason text default null, p_bonus int default 0
) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_sub      task_submissions;
  v_admin    members;
  v_task     tasks;
  v_reviewer text;
begin
  select * into v_sub from task_submissions where id = p_submission_id for update;
  if not found then
    raise exception 'not_found';
  end if;
  v_admin := _require_admin(v_sub.family_id);
  if v_admin.id = v_sub.member_id then
    raise exception 'cannot_review_own';
  end if;

  -- Dua admin bersamaan: yang kedua mendapat pesan "sudah diproses oleh X"
  if v_sub.status <> 'pending' then
    select name into v_reviewer from members where id = v_sub.reviewed_by;
    raise exception 'already_reviewed' using detail = coalesce(v_reviewer, ''), hint = v_sub.status;
  end if;

  select * into v_task from tasks where id = v_sub.task_id;

  if p_action = 'approve' then
    if coalesce(p_bonus, 0) not between 0 and 100000 then
      raise exception 'invalid_bonus';
    end if;
    update task_submissions
       set status = 'approved', reviewed_by = v_admin.id, reviewed_at = now(), is_flagged = false
     where id = v_sub.id;
    perform _add_points(v_sub.family_id, v_sub.member_id, 'available', v_sub.points_snapshot,
                        'task', v_sub.id, v_task.title, v_admin.id);
    if coalesce(p_bonus, 0) > 0 then
      perform _add_points(v_sub.family_id, v_sub.member_id, 'available', p_bonus,
                          'bonus', v_sub.id, coalesce(nullif(trim(p_reason), ''), 'Kerja bagus!'), v_admin.id);
    end if;

  elsif p_action = 'reject' then
    if nullif(trim(p_reason), '') is null then
      raise exception 'reason_required';
    end if;
    update task_submissions
       set status = 'rejected', reviewed_by = v_admin.id, reviewed_at = now(),
           reject_reason = trim(p_reason), is_flagged = false
     where id = v_sub.id;

  elsif p_action = 'retake' then
    if v_task.verification <> 'photo' then
      raise exception 'retake_requires_photo';
    end if;
    update task_submissions
       set status = 'needs_retake', reviewed_by = v_admin.id, reviewed_at = now(),
           reject_reason = nullif(trim(p_reason), '')
     where id = v_sub.id;

  else
    raise exception 'invalid_action';
  end if;

  perform _recompute_streak(v_sub.member_id);
end;
$$;

-- Kirim foto ulang tanpa membuat laporan baru (PRD: "Perlu foto ulang" tidak memutus streak)
create function public.resubmit_photos(p_submission_id uuid, p_photos jsonb) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_sub    task_submissions;
  v_member members;
  v_task   tasks;
begin
  select * into v_sub from task_submissions where id = p_submission_id for update;
  if not found then
    raise exception 'not_found';
  end if;
  v_member := _require_linked_member(v_sub.member_id);
  if v_sub.status <> 'needs_retake' then
    raise exception 'not_awaiting_retake';
  end if;

  select * into v_task from tasks where id = v_sub.task_id;
  update submission_photos set deleted_at = now()
   where submission_id = v_sub.id and deleted_at is null;
  perform _insert_photos(v_task, v_member, v_sub.id, p_photos);

  update task_submissions
     set status = 'pending', reviewed_by = null, reviewed_at = null
   where id = v_sub.id;
end;
$$;

-- Batalkan tugas verifikasi otomatis dalam 24 jam (aturan bisnis 3). Saldo boleh menjadi negatif.
create function public.reverse_auto_task(p_submission_id uuid, p_reason text) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_sub   task_submissions;
  v_admin members;
begin
  select * into v_sub from task_submissions where id = p_submission_id for update;
  if not found then
    raise exception 'not_found';
  end if;
  v_admin := _require_admin(v_sub.family_id);
  if v_admin.id = v_sub.member_id then
    raise exception 'cannot_review_own';
  end if;
  if not v_sub.is_auto or v_sub.status <> 'approved' or v_sub.reversed_at is not null then
    raise exception 'not_reversible';
  end if;
  if v_sub.created_at < now() - interval '24 hours' then
    raise exception 'reversal_window_passed';
  end if;
  if nullif(trim(p_reason), '') is null then
    raise exception 'reason_required';
  end if;

  update task_submissions
     set reversed_at = now(), reviewed_by = v_admin.id, reject_reason = trim(p_reason)
   where id = v_sub.id;
  perform _add_points(v_sub.family_id, v_sub.member_id, 'available', -v_sub.points_snapshot,
                      'reversal', v_sub.id, trim(p_reason), v_admin.id);
  perform _recompute_streak(v_sub.member_id);
end;
$$;

-- =====================================================================
-- Dompet (P-01–P-03)
-- =====================================================================

-- p_amount > 0 = bonus, < 0 = penalti. Alasan wajib dan terlihat oleh anak.
create function public.adjust_points(p_member_id uuid, p_amount int, p_reason text) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_target members;
  v_admin  members;
  v_allow  boolean;
begin
  select * into v_target from members where id = p_member_id for update;
  if not found then
    raise exception 'member_not_found';
  end if;
  v_admin := _require_admin(v_target.family_id);
  if v_admin.id = p_member_id then
    raise exception 'cannot_review_own';
  end if;
  if not v_target.can_earn then
    raise exception 'member_cannot_earn';
  end if;
  if coalesce(p_amount, 0) = 0 or abs(p_amount) > 1000000 then
    raise exception 'invalid_amount';
  end if;
  if nullif(trim(p_reason), '') is null then
    raise exception 'reason_required';
  end if;

  if p_amount < 0 then
    select allow_negative_penalty into v_allow from families where id = v_target.family_id;
    if not v_allow and _balance(p_member_id, 'available') + p_amount < 0 then
      raise exception 'insufficient_points';
    end if;
  end if;

  perform _add_points(v_target.family_id, p_member_id, 'available', p_amount,
                      case when p_amount > 0 then 'bonus' else 'penalty' end,
                      null, trim(p_reason), v_admin.id);
end;
$$;

-- =====================================================================
-- Hadiah & penukaran (H-01–H-07)
-- =====================================================================

create function public.redeem_reward(p_reward_id uuid, p_member_id uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_member     members;
  v_reward     rewards;
  v_today      date;
  v_count      int;
  v_from_goal  int := 0;
  v_from_avail int;
  v_approved   boolean;
  v_red        uuid;
begin
  v_member := _require_linked_member(p_member_id);
  if not v_member.can_earn then
    raise exception 'member_cannot_earn';
  end if;
  perform 1 from members where id = p_member_id for update;

  select * into v_reward from rewards
   where id = p_reward_id and family_id = v_member.family_id
   for update;
  if not found or v_reward.is_archived then
    raise exception 'reward_not_available';
  end if;
  if v_reward.stock is not null and v_reward.stock <= 0 then
    raise exception 'out_of_stock';
  end if;

  v_today := _family_today(v_member.family_id);
  if v_reward.max_per_day is not null then
    select count(*) into v_count from redemptions
     where reward_id = p_reward_id and member_id = p_member_id and for_date = v_today
       and status not in ('rejected', 'cancelled');
    if v_count >= v_reward.max_per_day then
      raise exception 'reward_limit_reached';
    end if;
  end if;

  -- Hadiah goal: pakai tabungan goal dulu, kekurangannya dari saldo tersedia
  if v_reward.type = 'goal'
     and exists (select 1 from goals where member_id = p_member_id and reward_id = p_reward_id and is_active) then
    v_from_goal := least(greatest(_balance(p_member_id, 'goal'), 0), v_reward.cost);
  end if;
  v_from_avail := v_reward.cost - v_from_goal;
  if v_from_avail > 0 and _balance(p_member_id, 'available') < v_from_avail then
    raise exception 'insufficient_points';
  end if;

  v_approved := not v_reward.needs_approval;
  insert into redemptions (reward_id, member_id, family_id, cost_snapshot, status, for_date,
                           reviewed_at, session_started_at, session_ends_at)
  values (p_reward_id, p_member_id, v_member.family_id, v_reward.cost,
          case when v_approved then 'approved' else 'requested' end,
          v_today,
          case when v_approved then now() end,
          case when v_approved and v_reward.duration_minutes is not null then now() end,
          case when v_approved and v_reward.duration_minutes is not null
               then now() + make_interval(mins => v_reward.duration_minutes) end)
  returning id into v_red;

  if v_from_goal > 0 then
    perform _add_points(v_member.family_id, p_member_id, 'goal', -v_from_goal, 'redeem_hold', v_red, v_reward.title, null);
  end if;
  if v_from_avail > 0 then
    perform _add_points(v_member.family_id, p_member_id, 'available', -v_from_avail, 'redeem_hold', v_red, v_reward.title, null);
  end if;

  if v_reward.stock is not null then
    update rewards set stock = stock - 1 where id = p_reward_id;
  end if;
  return v_red;
end;
$$;

-- p_action: 'approve' (sesi screen time mulai), 'reject' (alasan wajib, poin kembali), 'fulfill' ("sudah diberikan")
create function public.review_redemption(p_redemption_id uuid, p_action text, p_reason text default null)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_red      redemptions;
  v_reward   rewards;
  v_admin    members;
  v_reviewer text;
begin
  select * into v_red from redemptions where id = p_redemption_id for update;
  if not found then
    raise exception 'not_found';
  end if;
  v_admin := _require_admin(v_red.family_id);
  if v_admin.id = v_red.member_id then
    raise exception 'cannot_review_own';
  end if;
  select * into v_reward from rewards where id = v_red.reward_id;

  if v_red.status not in ('requested', 'approved')
     or (p_action = 'approve' and v_red.status <> 'requested') then
    select name into v_reviewer from members where id = v_red.reviewed_by;
    raise exception 'already_reviewed' using detail = coalesce(v_reviewer, ''), hint = v_red.status;
  end if;

  if p_action = 'approve' then
    update redemptions
       set status = 'approved', reviewed_by = v_admin.id, reviewed_at = now(),
           session_started_at = case when v_reward.duration_minutes is not null then now() end,
           session_ends_at    = case when v_reward.duration_minutes is not null
                                     then now() + make_interval(mins => v_reward.duration_minutes) end
     where id = v_red.id;

  elsif p_action = 'reject' then
    if nullif(trim(p_reason), '') is null then
      raise exception 'reason_required';
    end if;
    update redemptions
       set status = 'rejected', reviewed_by = v_admin.id, reviewed_at = now(), reject_reason = trim(p_reason)
     where id = v_red.id;
    perform _release_redemption(v_red, trim(p_reason), v_admin.id);

  elsif p_action = 'fulfill' then
    update redemptions
       set status = 'fulfilled', fulfilled_at = now(),
           reviewed_by = v_admin.id, reviewed_at = coalesce(reviewed_at, now())
     where id = v_red.id;
    if v_reward.type = 'goal' then
      perform _close_goal(v_red.member_id, v_red.reward_id, v_admin.id);
    end if;

  else
    raise exception 'invalid_action';
  end if;
end;
$$;

-- Anak membatalkan penukaran yang belum diproses; poin kembali penuh
create function public.cancel_redemption(p_redemption_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_red redemptions;
begin
  select * into v_red from redemptions where id = p_redemption_id for update;
  if not found then
    raise exception 'not_found';
  end if;
  perform _require_linked_member(v_red.member_id);
  if v_red.status <> 'requested' then
    raise exception 'not_cancellable';
  end if;
  update redemptions set status = 'cancelled' where id = v_red.id;
  perform _release_redemption(v_red, 'Dibatalkan', null);
end;
$$;

-- =====================================================================
-- Goal (G-01–G-03)
-- =====================================================================

create function public.set_goal(p_member_id uuid, p_reward_id uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_member  members;
  v_current goals;
  v_id      uuid;
begin
  v_member := _require_linked_member(p_member_id);
  if not v_member.can_earn then
    raise exception 'member_cannot_earn';
  end if;
  perform 1 from members where id = p_member_id for update;

  if not exists (select 1 from rewards
                  where id = p_reward_id and family_id = v_member.family_id
                    and type = 'goal' and not is_archived) then
    raise exception 'reward_not_available';
  end if;

  select * into v_current from goals where member_id = p_member_id and is_active;
  if found then
    if v_current.reward_id = p_reward_id then
      return v_current.id;
    end if;
    update goals set is_active = false where id = v_current.id;
    perform _unsave_all(v_member.family_id, p_member_id, v_current.id, 'Ganti goal', null);
  end if;

  insert into goals (member_id, reward_id, family_id) values (p_member_id, p_reward_id, v_member.family_id)
  returning id into v_id;
  return v_id;
end;
$$;

-- p_amount > 0 = sisihkan ke tabungan goal, < 0 = tarik kembali ke saldo tersedia
create function public.save_to_goal(p_member_id uuid, p_amount int) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_member members;
  v_goal   goals;
begin
  v_member := _require_linked_member(p_member_id);
  perform 1 from members where id = p_member_id for update;

  select * into v_goal from goals where member_id = p_member_id and is_active;
  if not found then
    raise exception 'no_active_goal';
  end if;
  if coalesce(p_amount, 0) = 0 then
    raise exception 'invalid_amount';
  end if;

  if p_amount > 0 then
    if _balance(p_member_id, 'available') < p_amount then
      raise exception 'insufficient_points';
    end if;
    perform _add_points(v_member.family_id, p_member_id, 'available', -p_amount, 'goal_save', v_goal.id, null, null);
    perform _add_points(v_member.family_id, p_member_id, 'goal', p_amount, 'goal_save', v_goal.id, null, null);
  else
    if _balance(p_member_id, 'goal') < -p_amount then
      raise exception 'insufficient_points';
    end if;
    perform _add_points(v_member.family_id, p_member_id, 'goal', p_amount, 'goal_unsave', v_goal.id, null, null);
    perform _add_points(v_member.family_id, p_member_id, 'available', -p_amount, 'goal_unsave', v_goal.id, null, null);
  end if;
end;
$$;

-- Kenaikan harga hadiah yang sedang dijadikan goal berlaku 7 hari lagi; penurunan langsung (aturan bisnis 6).
-- Mengembalikan 'applied' atau 'scheduled'.
create function public.update_reward_price(p_reward_id uuid, p_new_cost int) returns text
language plpgsql security definer set search_path = public as $$
declare
  v_reward rewards;
begin
  select * into v_reward from rewards where id = p_reward_id for update;
  if not found then
    raise exception 'not_found';
  end if;
  perform _require_admin(v_reward.family_id);
  if coalesce(p_new_cost, 0) not between 1 and 10000000 then
    raise exception 'invalid_cost';
  end if;

  if p_new_cost > v_reward.cost
     and exists (select 1 from goals where reward_id = p_reward_id and is_active) then
    update rewards
       set pending_cost = p_new_cost, cost_effective_at = now() + interval '7 days'
     where id = p_reward_id;
    return 'scheduled';
  end if;

  update rewards
     set cost = p_new_cost, pending_cost = null, cost_effective_at = null
   where id = p_reward_id;
  return 'applied';
end;
$$;

-- =====================================================================
-- Hak eksekusi: hanya RPC publik yang bisa dipanggil aplikasi
-- =====================================================================

revoke execute on all functions in schema public from public, anon, authenticated;

grant execute on function
  public.is_family_member(uuid),
  public.is_family_admin(uuid),
  public.create_family(text, text, text),
  public.apply_economy_template(uuid, text, uuid[]),
  public.create_invite(uuid, text, uuid),
  public.join_family(text, text),
  public.set_member_pin(uuid, text),
  public.verify_member_pin(uuid, text),
  public.transfer_ownership(uuid),
  public.delete_family(uuid),
  public.register_device(text, text),
  public.submit_task(uuid, uuid, text, jsonb, timestamptz),
  public.review_submission(uuid, text, text, int),
  public.resubmit_photos(uuid, jsonb),
  public.reverse_auto_task(uuid, text),
  public.adjust_points(uuid, int, text),
  public.redeem_reward(uuid, uuid),
  public.review_redemption(uuid, text, text),
  public.cancel_redemption(uuid),
  public.set_goal(uuid, uuid),
  public.save_to_goal(uuid, int),
  public.update_reward_price(uuid, int)
to authenticated;
