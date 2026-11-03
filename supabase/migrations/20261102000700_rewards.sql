-- Family Points App — minggu 7: hadiah & goal
--
-- * rewards.icon: ikon hadiah (kunci ikon di app), dipilih di form hadiah.
-- * Realtime: penukaran, goal, dan perubahan hadiah langsung terlihat di HP lain.
-- * Notifikasi penukaran & perubahan harga goal (PRD bagian "Notifikasi").

alter table public.rewards add column icon text;
grant insert (icon), update (icon) on public.rewards to authenticated;

alter publication supabase_realtime add table public.redemptions, public.goals, public.rewards;

alter table public.notifications drop constraint notifications_kind_check;
alter table public.notifications add constraint notifications_kind_check check (kind in (
  'submission_pending', 'submission_approved', 'submission_rejected', 'submission_retake',
  'redemption_requested', 'redemption_approved', 'redemption_rejected', 'redemption_fulfilled',
  'goal_price_changed'));

create function public._notify_redemption() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_reward   text;
  v_duration int;
  v_child    text;
begin
  select title, duration_minutes into v_reward, v_duration from rewards where id = new.reward_id;
  select name into v_child from members where id = new.member_id;

  if tg_op = 'INSERT' and new.status = 'requested' then
    insert into notifications (family_id, member_id, kind, title, body, ref_id)
    select new.family_id, m.id, 'redemption_requested', 'Permintaan hadiah',
           format('%s ingin menukar %s (%s poin).', v_child, v_reward, new.cost_snapshot), new.id
      from members m
     where m.family_id = new.family_id and m.role in ('owner', 'admin') and m.is_active and m.id <> new.member_id;

  elsif tg_op = 'UPDATE' and new.status is distinct from old.status then
    if new.status = 'approved' then
      insert into notifications (family_id, member_id, kind, title, body, ref_id)
      values (new.family_id, new.member_id, 'redemption_approved', 'Hore!',
              format('%s disetujui.', v_reward), new.id);
    elsif new.status = 'rejected' then
      insert into notifications (family_id, member_id, kind, title, body, ref_id)
      values (new.family_id, new.member_id, 'redemption_rejected', 'Belum disetujui',
              format('%s ditolak: %s. Poinmu sudah kembali.', v_reward, coalesce(new.reject_reason, '-')), new.id);
    elsif new.status = 'fulfilled' and v_duration is null then
      -- Sesi screen time yang habis ditutup otomatis oleh cron; tidak perlu notifikasi
      insert into notifications (family_id, member_id, kind, title, body, ref_id)
      values (new.family_id, new.member_id, 'redemption_fulfilled', 'Selamat!',
              format('%s sudah diberikan.', v_reward), new.id);
    end if;
  end if;
  return null;
end;
$$;

create trigger redemptions_notify
  after insert or update of status on public.redemptions
  for each row execute function public._notify_redemption();

-- Anak yang sedang menabung untuk hadiah ini diberi tahu kenaikan harganya (aturan bisnis 6)
create function public._notify_goal_price() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.pending_cost is not null and new.pending_cost is distinct from old.pending_cost then
    insert into notifications (family_id, member_id, kind, title, body, ref_id)
    select new.family_id, g.member_id, 'goal_price_changed', 'Harga goal berubah',
           format('Harga %s jadi %s poin mulai %s.', new.title, new.pending_cost,
                  to_char(new.cost_effective_at at time zone f.timezone, 'DD/MM')),
           new.id
      from goals g
      join families f on f.id = new.family_id
     where g.reward_id = new.id and g.is_active;
  end if;
  return null;
end;
$$;

create trigger rewards_notify_price
  after update of pending_cost on public.rewards
  for each row execute function public._notify_goal_price();

revoke execute on function public._notify_redemption(), public._notify_goal_price() from public, anon, authenticated;
