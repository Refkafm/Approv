-- Family Points App — teks dari server mengikuti bahasa keluarga (families.locale)
--
-- * create_family menerima p_locale: keluarga baru langsung memakai bahasa yang dipilih di app.
-- * apply_economy_template: judul tugas & hadiah contoh dalam bahasa keluarga.
-- * Notifikasi (laporan, penukaran, harga goal) dalam bahasa keluarga.
-- * Alasan bawaan di riwayat poin ('Kerja bagus!', 'Dibatalkan') diganti null; app menampilkan
--   teks penggantinya sesuai bahasa yang sedang dipakai.

drop function public.create_family(text, text, text);

create function public.create_family(
  p_family_name text, p_owner_name text, p_timezone text default 'Asia/Jakarta', p_locale text default 'id'
) returns uuid
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

  insert into families (name, timezone, locale)
  values (p_family_name, p_timezone, case when p_locale = 'en' then 'en' else 'id' end)
  returning id into v_family;

  insert into members (family_id, role, can_earn, name) values (v_family, 'owner', false, p_owner_name)
  returning id into v_member;

  insert into member_logins (member_id, user_id) values (v_member, auth.uid());
  return v_family;
end;
$$;

revoke execute on function public.create_family(text, text, text, text) from public, anon;
grant execute on function public.create_family(text, text, text, text) to authenticated;

-- Template ekonomi per usia; judul mengikuti families.locale (salinannya ada di app: EconomyTemplate)
create or replace function public.apply_economy_template(p_family_id uuid, p_age_band text, p_member_ids uuid[] default null)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_admin      members;
  v_en         boolean;
  v_factor     numeric;
  v_screen     int;
  v_goal_title text;
  v_goal_cost  int;
begin
  v_admin := _require_admin(p_family_id);
  select locale = 'en' into v_en from families where id = p_family_id;

  case p_age_band
    when '6-9' then
      v_factor := 0.5;  v_screen := 50;  v_goal_cost := 2000;
      v_goal_title := case when v_en then 'New toy' else 'Mainan baru' end;
    when '10-13' then
      v_factor := 1;    v_screen := 100; v_goal_cost := 5000;
      v_goal_title := case when v_en then 'Dinner at a favorite restaurant' else 'Makan di restoran favorit' end;
    when '14-17' then
      v_factor := 1.35; v_screen := 150; v_goal_cost := 10000;
      v_goal_title := case when v_en then 'Game top-up' else 'Top-up game' end;
    else
      raise exception 'invalid_age_band';
  end case;

  with base (title, title_en, icon, points, frequency, max_per_day, verification, min_photos, allow_gallery) as (
    values
      ('Rapikan kasur',            'Make the bed',                      'bed',    20,  'daily',  1, 'auto',    0, false),
      ('Bantu cuci piring',        'Help wash the dishes',              'dish',   50,  'daily',  1, 'approve', 0, false),
      ('Baca buku 30 menit',       'Read a book for 30 minutes',        'book',   60,  'repeat', 2, 'approve', 0, false),
      ('PR selesai tanpa disuruh', 'Homework done without being asked', 'pencil', 80,  'daily',  1, 'photo',   1, false),
      ('Bersihkan kamar',          'Clean the bedroom',                 'broom',  150, 'weekly', 1, 'photo',   1, false),
      ('Nilai ujian ≥ 85',         'Test score ≥ 85',                   'trophy', 300, 'once',   1, 'photo',   1, true)
  ), inserted as (
    insert into tasks (family_id, title, icon, points, frequency, max_per_day, verification,
                       min_photos, allow_gallery, created_by)
    select p_family_id, case when v_en then title_en else title end, icon,
           greatest(5, round(points * v_factor / 5) * 5)::int,
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
    (p_family_id, case when v_en then '30 minutes of gaming' else '30 menit main game' end,
     v_screen, 'instant', 30, 2, v_admin.id),
    (p_family_id, case when v_en then '30 minutes of TikTok / YouTube' else '30 menit TikTok / YouTube' end,
     v_screen, 'instant', 30, 2, v_admin.id),
    (p_family_id, case when v_en then 'Pick what''s for dinner' else 'Pilih menu makan malam' end,
     greatest(5, round(v_screen * 0.5 / 5) * 5)::int, 'instant', null, 1, v_admin.id),
    (p_family_id, v_goal_title, v_goal_cost, 'goal', null, null, v_admin.id);
end;
$$;

create or replace function public._notify_submission() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_task  text;
  v_child text;
  v_en    boolean;
begin
  select title into v_task from tasks where id = new.task_id;
  select name into v_child from members where id = new.member_id;
  select locale = 'en' into v_en from families where id = new.family_id;

  if new.status = 'pending' and (tg_op = 'INSERT' or old.status is distinct from 'pending') then
    -- Laporan baru, atau foto ulang sudah dikirim: semua admin lain diberi tahu
    insert into notifications (family_id, member_id, kind, title, body, ref_id)
    select new.family_id, m.id, 'submission_pending',
           case when tg_op = 'INSERT'
                then case when v_en then 'New report' else 'Laporan baru' end
                else case when v_en then 'Retake sent' else 'Foto ulang dikirim' end end,
           format(case when v_en then '%s finished "%s". Review it now.'
                       else '%s menyelesaikan "%s". Tinjau sekarang.' end, v_child, v_task),
           new.id
      from members m
     where m.family_id = new.family_id and m.role in ('owner', 'admin') and m.is_active and m.id <> new.member_id;

  elsif tg_op = 'UPDATE' and new.status is distinct from old.status then
    if new.status = 'approved' then
      insert into notifications (family_id, member_id, kind, title, body, ref_id)
      values (new.family_id, new.member_id, 'submission_approved',
              format(case when v_en then '+%s points!' else '+%s poin!' end, new.points_snapshot),
              format(case when v_en then '%s approved.' else '%s disetujui.' end, v_task), new.id);
    elsif new.status = 'rejected' then
      insert into notifications (family_id, member_id, kind, title, body, ref_id)
      values (new.family_id, new.member_id, 'submission_rejected',
              case when v_en then 'Not approved yet' else 'Belum disetujui' end,
              format(case when v_en then '%s was declined: %s. Give it another try.'
                          else '%s ditolak: %s. Coba lagi ya.' end, v_task, new.reject_reason), new.id);
    elsif new.status = 'needs_retake' then
      insert into notifications (family_id, member_id, kind, title, body, ref_id)
      values (new.family_id, new.member_id, 'submission_retake',
              case when v_en then 'Retake photo' else 'Foto ulang' end,
              format(case when v_en then '%s: %s, please retake it.' else '%s: %s, ambil ulang ya.' end, v_task,
                     coalesce(new.reject_reason,
                              case when v_en then 'the photo is not clear enough' else 'fotonya kurang jelas' end)),
              new.id);
    end if;
  end if;
  return null;
end;
$$;

create or replace function public._notify_redemption() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_reward   text;
  v_duration int;
  v_child    text;
  v_en       boolean;
begin
  select title, duration_minutes into v_reward, v_duration from rewards where id = new.reward_id;
  select name into v_child from members where id = new.member_id;
  select locale = 'en' into v_en from families where id = new.family_id;

  if tg_op = 'INSERT' and new.status = 'requested' then
    insert into notifications (family_id, member_id, kind, title, body, ref_id)
    select new.family_id, m.id, 'redemption_requested',
           case when v_en then 'Reward request' else 'Permintaan hadiah' end,
           format(case when v_en then '%s wants to redeem %s (%s points).'
                       else '%s ingin menukar %s (%s poin).' end, v_child, v_reward, new.cost_snapshot), new.id
      from members m
     where m.family_id = new.family_id and m.role in ('owner', 'admin') and m.is_active and m.id <> new.member_id;

  elsif tg_op = 'UPDATE' and new.status is distinct from old.status then
    if new.status = 'approved' then
      insert into notifications (family_id, member_id, kind, title, body, ref_id)
      values (new.family_id, new.member_id, 'redemption_approved',
              case when v_en then 'Hooray!' else 'Hore!' end,
              format(case when v_en then '%s approved.' else '%s disetujui.' end, v_reward), new.id);
    elsif new.status = 'rejected' then
      insert into notifications (family_id, member_id, kind, title, body, ref_id)
      values (new.family_id, new.member_id, 'redemption_rejected',
              case when v_en then 'Not approved yet' else 'Belum disetujui' end,
              format(case when v_en then '%s was declined: %s. Your points are back.'
                          else '%s ditolak: %s. Poinmu sudah kembali.' end,
                     v_reward, coalesce(new.reject_reason, '-')), new.id);
    elsif new.status = 'fulfilled' and v_duration is null then
      -- Sesi screen time yang habis ditutup otomatis oleh cron; tidak perlu notifikasi
      insert into notifications (family_id, member_id, kind, title, body, ref_id)
      values (new.family_id, new.member_id, 'redemption_fulfilled',
              case when v_en then 'Congrats!' else 'Selamat!' end,
              format(case when v_en then '%s has been given.' else '%s sudah diberikan.' end, v_reward), new.id);
    end if;
  end if;
  return null;
end;
$$;

create or replace function public._notify_goal_price() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.pending_cost is not null and new.pending_cost is distinct from old.pending_cost then
    insert into notifications (family_id, member_id, kind, title, body, ref_id)
    select new.family_id, g.member_id, 'goal_price_changed',
           case when f.locale = 'en' then 'Goal price changed' else 'Harga goal berubah' end,
           case when f.locale = 'en'
                then format('%s now costs %s points from %s.', new.title, new.pending_cost,
                            to_char(new.cost_effective_at at time zone f.timezone, 'FMMon FMDD'))
                else format('Harga %s jadi %s poin mulai %s.', new.title, new.pending_cost,
                            to_char(new.cost_effective_at at time zone f.timezone, 'DD/MM')) end,
           new.id
      from goals g
      join families f on f.id = new.family_id
     where g.reward_id = new.id and g.is_active;
  end if;
  return null;
end;
$$;

-- Bonus tanpa alasan: null (app menampilkan "kerja bagus" / "great work")
create or replace function public.review_submission(
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
                          'bonus', v_sub.id, nullif(trim(p_reason), ''), v_admin.id);
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

-- Penukaran dibatalkan anak: alasan null (app menampilkan "Poin kembali" / "Points refunded")
create or replace function public.cancel_redemption(p_redemption_id uuid) returns void
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
  perform _release_redemption(v_red, null, null);
end;
$$;

revoke execute on function public._notify_submission(), public._notify_redemption(), public._notify_goal_price()
  from public, anon, authenticated;
