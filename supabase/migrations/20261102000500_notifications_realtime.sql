-- Family Points App — minggu 4: realtime laporan + kotak keluar notifikasi
--
-- * Realtime: perubahan task_submissions dikirim ke app (antrean persetujuan & status di HP anak).
--   Realtime Supabase tetap menghormati RLS, jadi tiap HP hanya menerima data keluarganya.
-- * notifications: satu baris per penerima, diisi trigger dengan teks dari PRD bagian "Notifikasi".
--   Pengiriman push (FCM/APNs/OneSignal) dilakukan Edge Function yang membaca baris sent_at IS NULL,
--   menghormati jam tidur keluarga (families.quiet_start/quiet_end), lalu mengisi sent_at.

alter publication supabase_realtime add table public.task_submissions;

create table public.notifications (
  id          bigint generated always as identity primary key,
  family_id   uuid not null references public.families (id) on delete cascade,
  member_id   uuid not null references public.members (id) on delete cascade,  -- penerima
  kind        text not null check (kind in (
                'submission_pending', 'submission_approved', 'submission_rejected', 'submission_retake')),
  title       text not null,
  body        text not null,
  ref_id      uuid,          -- task_submissions.id
  created_at  timestamptz not null default now(),
  read_at     timestamptz,
  sent_at     timestamptz    -- diisi pengirim push
);
create index notifications_member_idx on public.notifications (member_id, created_at desc);
create index notifications_unsent_idx on public.notifications (created_at) where sent_at is null;

alter table public.notifications enable row level security;
revoke all on public.notifications from anon;
revoke insert, update, delete, truncate on public.notifications from authenticated;
grant select on public.notifications to authenticated;

-- Hanya penerima yang bisa membaca notifikasinya
create policy notifications_select on public.notifications for select to authenticated
  using (exists (select 1 from public.member_logins ml
                  where ml.member_id = notifications.member_id and ml.user_id = (select auth.uid())));

create function public.mark_notifications_read(p_member_id uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  perform _require_linked_member(p_member_id);
  update notifications set read_at = now() where member_id = p_member_id and read_at is null;
end;
$$;

-- Teks notifikasi mengikuti contoh di PRD
create function public._notify_submission() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_task  text;
  v_child text;
begin
  select title into v_task from tasks where id = new.task_id;
  select name into v_child from members where id = new.member_id;

  if new.status = 'pending' and (tg_op = 'INSERT' or old.status is distinct from 'pending') then
    -- Laporan baru, atau foto ulang sudah dikirim: semua admin lain diberi tahu
    insert into notifications (family_id, member_id, kind, title, body, ref_id)
    select new.family_id, m.id, 'submission_pending',
           case when tg_op = 'INSERT' then 'Laporan baru' else 'Foto ulang dikirim' end,
           format('%s menyelesaikan "%s". Tinjau sekarang.', v_child, v_task),
           new.id
      from members m
     where m.family_id = new.family_id and m.role in ('owner', 'admin') and m.is_active and m.id <> new.member_id;

  elsif tg_op = 'UPDATE' and new.status is distinct from old.status then
    if new.status = 'approved' then
      insert into notifications (family_id, member_id, kind, title, body, ref_id)
      values (new.family_id, new.member_id, 'submission_approved',
              format('+%s poin!', new.points_snapshot), format('%s disetujui.', v_task), new.id);
    elsif new.status = 'rejected' then
      insert into notifications (family_id, member_id, kind, title, body, ref_id)
      values (new.family_id, new.member_id, 'submission_rejected',
              'Belum disetujui', format('%s ditolak: %s. Coba lagi ya.', v_task, new.reject_reason), new.id);
    elsif new.status = 'needs_retake' then
      insert into notifications (family_id, member_id, kind, title, body, ref_id)
      values (new.family_id, new.member_id, 'submission_retake',
              'Foto ulang', format('%s: %s, ambil ulang ya.', v_task, coalesce(new.reject_reason, 'fotonya kurang jelas')),
              new.id);
    end if;
  end if;
  return null;
end;
$$;

create trigger task_submissions_notify
  after insert or update of status on public.task_submissions
  for each row execute function public._notify_submission();

revoke execute on function public._notify_submission(), public.mark_notifications_read(uuid)
  from public, anon, authenticated;
grant execute on function public.mark_notifications_read(uuid) to authenticated;
