-- Family Points App — job terjadwal (pg_cron)
-- Sumber: Rencana-Implementasi-Fase-1.md, bagian "Job terjadwal"
--
-- Belum termasuk (butuh Edge Function + pg_net, dibuat bersama modul notifikasi di minggu 8):
-- * Penghapusan file foto dari storage (baca view photos_to_purge, hapus lewat Storage API)
-- * Pengingat tugas/streak dan ringkasan mingguan (push notification)
-- * Bonus streak (X-01, P1)

create extension if not exists pg_cron;

-- Kenaikan harga hadiah goal yang sudah lewat 7 hari
create function public.apply_pending_prices() returns void
language sql security definer set search_path = public as $$
  update rewards
     set cost = pending_cost, pending_cost = null, cost_effective_at = null
   where cost_effective_at <= now();
$$;

-- Foto > 30 hari yang bukan "kenangan" ditandai untuk dihapus
create function public.expire_old_photos() returns void
language sql security definer set search_path = public as $$
  update submission_photos
     set deleted_at = now()
   where deleted_at is null and not is_kept and created_at < now() - interval '30 days';
$$;

-- Laporan menunggu > 72 jam diberi penanda (tidak disetujui otomatis)
create function public.flag_stale_submissions() returns void
language sql security definer set search_path = public as $$
  update task_submissions
     set is_flagged = true
   where status = 'pending' and not is_flagged and created_at < now() - interval '72 hours';
$$;

-- Sesi screen time yang sudah habis otomatis ditandai "diberikan"
create function public.finish_screen_sessions() returns void
language sql security definer set search_path = public as $$
  update redemptions
     set status = 'fulfilled', fulfilled_at = session_ends_at
   where status = 'approved' and session_ends_at <= now();
$$;

-- Streak bisa putus hanya karena hari berganti, tanpa ada persetujuan baru
create function public.refresh_streaks() returns void
language plpgsql security definer set search_path = public as $$
declare
  v_member uuid;
begin
  for v_member in
    select member_id from streaks where current_count > 0 or has_pending
  loop
    perform _recompute_streak(v_member);
  end loop;
end;
$$;

create function public.cleanup_invites() returns void
language sql security definer set search_path = public as $$
  delete from invites where expires_at < now() - interval '7 days';
$$;

-- Untuk Edge Function penghapus file (service role): foto yang ditandai hapus tapi filenya masih ada
create view public.photos_to_purge as
select p.id, p.storage_path
  from public.submission_photos p
  join storage.objects o on o.bucket_id = 'proofs' and o.name = p.storage_path
 where p.deleted_at is not null;

revoke all on public.photos_to_purge from anon, authenticated;
revoke execute on function
  public.apply_pending_prices(),
  public.expire_old_photos(),
  public.flag_stale_submissions(),
  public.finish_screen_sessions(),
  public.refresh_streaks(),
  public.cleanup_invites()
from public, anon, authenticated;

select cron.schedule('apply-pending-prices',   '0 * * * *',    'select public.apply_pending_prices()');
select cron.schedule('finish-screen-sessions', '* * * * *',    'select public.finish_screen_sessions()');
select cron.schedule('flag-stale-submissions', '15 * * * *',   'select public.flag_stale_submissions()');
-- Tiap jam, supaya pergantian hari di WIB, WITA, dan WIT semuanya tertangkap
select cron.schedule('refresh-streaks',        '5 * * * *',    'select public.refresh_streaks()');
select cron.schedule('expire-old-photos',      '30 19 * * *',  'select public.expire_old_photos()');   -- 02:30 WIB
select cron.schedule('cleanup-invites',        '45 19 * * *',  'select public.cleanup_invites()');     -- 02:45 WIB
