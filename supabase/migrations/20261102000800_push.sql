-- Family Points App — minggu 8: pengiriman push lewat OneSignal
--
-- Alur: pg_cron (tiap menit) -> pg_net memanggil Edge Function send-push -> fungsi itu memanggil
-- claim_push_batch() dengan service role, mengirim tiap baris ke OneSignal REST API
-- (external_id = auth user id, diset app lewat OneSignal.login), lalu release_push() untuk yang gagal.
--
-- * Jam tidur (families.quiet_start/quiet_end) hanya berlaku untuk anak: push tetap dibuat, tetapi
--   dijadwalkan OneSignal (send_after) ke akhir jam tidur. Orang tua selalu menerima langsung.
-- * Notifikasi yang lebih tua dari 1 hari atau sudah gagal 5 kali tidak dikirim lagi.
--
-- Rahasia yang harus diisi di Vault sebelum job berjalan (lihat supabase/README.md):
--   project_url, service_role_key

create extension if not exists pg_net;

alter table public.notifications add column push_attempts int not null default 0;

-- Rute app yang dibuka saat notifikasi diketuk
create function public._push_route(p_kind text) returns text
language sql immutable as $$
  select case
    when p_kind in ('submission_pending', 'redemption_requested') then '/parent/approvals'
    when p_kind like 'submission_%' then '/child/tasks'
    else '/child/rewards'
  end
$$;

-- Akhir jam tidur keluarga bila p_at jatuh di dalamnya; null bila di luar jam tidur
create function public._quiet_until(p_family uuid, p_at timestamptz default now()) returns timestamptz
language sql stable set search_path = public as $$
  select case
    when (f.quiet_start < f.quiet_end and l.t >= f.quiet_start and l.t < f.quiet_end)
      or (f.quiet_start > f.quiet_end and (l.t >= f.quiet_start or l.t < f.quiet_end))
    then ((l.d + case when l.t < f.quiet_end then 0 else 1 end) + f.quiet_end) at time zone f.timezone
  end
  from families f,
       lateral (select (p_at at time zone f.timezone)::time as t, (p_at at time zone f.timezone)::date as d) l
  where f.id = p_family
$$;

-- Mengambil notifikasi yang belum dikirim dan langsung menandainya terkirim (aman bila dua pemanggil
-- berjalan bersamaan: SKIP LOCKED). external_ids kosong = penerima belum login di HP mana pun.
create function public.claim_push_batch(p_limit int default 100)
returns table (id bigint, external_ids text[], title text, body text, route text, send_after timestamptz)
language sql security definer set search_path = public as $$
  with picked as (
    select n.id
      from notifications n
     where n.sent_at is null and n.push_attempts < 5 and n.created_at > now() - interval '1 day'
     order by n.created_at
     limit p_limit
       for update skip locked
  ), claimed as (
    update notifications n
       set sent_at = now(), push_attempts = n.push_attempts + 1
      from picked
     where n.id = picked.id
    returning n.id, n.family_id, n.member_id, n.kind, n.title, n.body
  )
  select c.id,
         array(select ml.user_id::text from member_logins ml where ml.member_id = c.member_id order by ml.created_at),
         c.title,
         c.body,
         _push_route(c.kind),
         case when m.role = 'member' then _quiet_until(c.family_id) end
    from claimed c
    join members m on m.id = c.member_id
   order by c.id
$$;

-- Pengiriman gagal: kembalikan ke antrean untuk dicoba lagi di menit berikutnya
create function public.release_push(p_ids bigint[]) returns void
language sql security definer set search_path = public as $$
  update notifications set sent_at = null where id = any (p_ids)
$$;

revoke execute on function
  public._push_route(text),
  public._quiet_until(uuid, timestamptz),
  public.claim_push_batch(int),
  public.release_push(bigint[])
from public, anon, authenticated;
grant execute on function public.claim_push_batch(int), public.release_push(bigint[]) to service_role;

select cron.schedule('send-push', '* * * * *', $$
  select net.http_post(
    url     := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url')
               || '/functions/v1/send-push',
    headers := jsonb_build_object(
                 'Content-Type', 'application/json',
                 'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets
                                                 where name = 'service_role_key')),
    body    := '{}'::jsonb
  )
$$);
