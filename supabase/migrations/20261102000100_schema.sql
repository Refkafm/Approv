-- Family Points App — skema awal Fase 1
-- Sumber: PRD-Family-Points-App-Fase-1.md (bagian "Model data")
--
-- Catatan terhadap PRD:
-- * Tabel `users` di PRD = `auth.users` milik Supabase (provider, email, phone sudah ada di sana).
-- * `families.owner_id` diganti oleh `members.role = 'owner'` (unik per keluarga), supaya tidak ada FK melingkar.
-- * `members.user_id` diganti tabel `member_logins` (banyak-ke-banyak), karena satu HP bisa dipakai beberapa anak
--   (PRD edge case "HP dipakai bersama") dan satu anak bisa masuk ulang dari HP baru.
-- * `families.plan` punya nilai 'beta' (tanpa batas) untuk Fase 1; batas paket gratis baru berlaku saat plan = 'free'.
-- * Tabel badges / member_badges (P2) belum dibuat.

create extension if not exists pgcrypto with schema extensions;

-- =====================================================================
-- Keluarga & anggota
-- =====================================================================

create table public.families (
  id                     uuid primary key default gen_random_uuid(),
  name                   text not null check (length(trim(name)) between 1 and 60),
  timezone               text not null default 'Asia/Jakarta'
                           check ((now() at time zone timezone) is not null),
  locale                 text not null default 'id' check (locale in ('id', 'en')),
  plan                   text not null default 'beta' check (plan in ('beta', 'free', 'premium')),
  quiet_start            time not null default '21:00',
  quiet_end              time not null default '06:00',
  allow_negative_penalty boolean not null default false,
  streak_bonus_pct       int not null default 10 check (streak_bonus_pct between 0 and 100),
  created_at             timestamptz not null default now()
);

create table public.members (
  id          uuid primary key default gen_random_uuid(),
  family_id   uuid not null references public.families (id) on delete cascade,
  role        text not null check (role in ('owner', 'admin', 'member')),
  -- Owner/admin dengan can_earn = true = opsi "ikut mengumpulkan poin" (pasangan dewasa)
  can_earn    boolean not null default true,
  name        text not null check (length(trim(name)) between 1 and 40),
  avatar      text,
  birth_date  date,
  pin_hash    text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  constraint members_member_can_earn check (role <> 'member' or can_earn)
);
create unique index members_one_owner on public.members (family_id) where role = 'owner';
create index members_family_idx on public.members (family_id);

create table public.member_logins (
  member_id  uuid not null references public.members (id) on delete cascade,
  user_id    uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (member_id, user_id)
);
create index member_logins_user_idx on public.member_logins (user_id);

create table public.invites (
  id          uuid primary key default gen_random_uuid(),
  family_id   uuid not null references public.families (id) on delete cascade,
  -- 6 karakter tanpa huruf/angka yang mirip (I, O, 0, 1)
  code        text not null unique check (code ~ '^[A-HJ-NP-Z2-9]{6}$'),
  role        text not null check (role in ('admin', 'member')),
  -- Undangan anak menunjuk baris members yang sudah dibuat orang tua (M-01)
  member_id   uuid references public.members (id) on delete cascade,
  created_by  uuid references public.members (id) on delete set null,
  expires_at  timestamptz not null default now() + interval '24 hours',
  used_by     uuid references auth.users (id) on delete set null,
  used_at     timestamptz,
  created_at  timestamptz not null default now(),
  constraint invites_member_target check ((role = 'member') = (member_id is not null))
);

-- =====================================================================
-- Tugas & laporan
-- =====================================================================

create table public.tasks (
  id             uuid primary key default gen_random_uuid(),
  family_id      uuid not null references public.families (id) on delete cascade,
  title          text not null check (length(trim(title)) between 1 and 60),
  icon           text,
  description    text check (length(description) <= 500),
  points         int not null check (points between 1 and 100000),
  frequency      text not null check (frequency in ('once', 'daily', 'days_of_week', 'weekly', 'repeat')),
  days_of_week   smallint[] check (days_of_week <@ array[1, 2, 3, 4, 5, 6, 7]::smallint[]),  -- ISO: 1 = Senin
  max_per_day    int not null default 1 check (max_per_day between 1 and 20),
  verification   text not null default 'approve' check (verification in ('auto', 'approve', 'photo')),
  min_photos     int not null default 0 check (min_photos between 0 and 3),
  before_after   boolean not null default false,
  allow_gallery  boolean not null default false,
  due_time       time,
  reminder_time  time,
  is_archived    boolean not null default false,
  created_by     uuid references public.members (id) on delete set null,
  created_at     timestamptz not null default now(),
  constraint tasks_days_required check (frequency <> 'days_of_week' or cardinality(days_of_week) > 0),
  constraint tasks_photo_min check (verification <> 'photo' or min_photos >= 1),
  constraint tasks_photo_options check (
    verification = 'photo' or (min_photos = 0 and not before_after and not allow_gallery)
  )
);
create index tasks_family_idx on public.tasks (family_id) where not is_archived;

-- Kosong untuk satu tugas = tugas untuk semua anggota yang bisa mengumpulkan poin
create table public.task_assignments (
  task_id   uuid not null references public.tasks (id) on delete cascade,
  member_id uuid not null references public.members (id) on delete cascade,
  primary key (task_id, member_id)
);

create table public.task_submissions (
  id               uuid primary key default gen_random_uuid(),
  task_id          uuid not null references public.tasks (id) on delete cascade,
  member_id        uuid not null references public.members (id) on delete cascade,
  family_id        uuid not null references public.families (id) on delete cascade,
  status           text not null default 'pending'
                     check (status in ('pending', 'approved', 'rejected', 'needs_retake')),
  note             text check (length(note) <= 500),
  points_snapshot  int not null,          -- mengunci nilai poin saat dilaporkan
  for_date         date not null,         -- tanggal lapor di zona waktu keluarga (dasar batas harian & streak)
  is_auto          boolean not null default false,
  reviewed_by      uuid references public.members (id) on delete set null,
  reviewed_at      timestamptz,
  reject_reason    text,                  -- juga dipakai untuk alasan "minta foto ulang" & pembatalan
  is_flagged       boolean not null default false,  -- menunggu > 72 jam
  reversed_at      timestamptz,           -- tugas otomatis yang dibatalkan admin (aturan bisnis 3)
  created_at       timestamptz not null default now()
);
create index task_submissions_member_date_idx on public.task_submissions (member_id, for_date);
create index task_submissions_task_member_idx on public.task_submissions (task_id, member_id, for_date);
create index task_submissions_pending_idx on public.task_submissions (family_id, created_at)
  where status = 'pending';

create table public.submission_photos (
  id             uuid primary key default gen_random_uuid(),
  submission_id  uuid not null references public.task_submissions (id) on delete cascade,
  kind           text not null default 'single' check (kind in ('single', 'before', 'after')),
  storage_path   text not null unique,    -- {family_id}/{member_id}/{nama file} di bucket "proofs"
  taken_at       timestamptz not null,
  source         text not null default 'camera' check (source in ('camera', 'gallery')),
  is_kept        boolean not null default false,  -- "kenangan" (PF-10)
  deleted_at     timestamptz,             -- diisi saat kedaluwarsa/diganti; file dihapus oleh Edge Function
  created_at     timestamptz not null default now()
);
create index submission_photos_submission_idx on public.submission_photos (submission_id);

-- =====================================================================
-- Hadiah, penukaran, goal
-- =====================================================================

create table public.rewards (
  id                 uuid primary key default gen_random_uuid(),
  family_id          uuid not null references public.families (id) on delete cascade,
  title              text not null check (length(trim(title)) between 1 and 60),
  image_url          text,
  cost               int not null check (cost between 1 and 10000000),
  type               text not null check (type in ('instant', 'goal')),
  duration_minutes   int check (duration_minutes between 1 and 1440),  -- hadiah screen time
  max_per_day        int check (max_per_day >= 1),                     -- null = tanpa batas
  stock              int check (stock >= 0),                           -- null = tanpa batas
  needs_approval     boolean not null default true,
  is_archived        boolean not null default false,
  pending_cost       int check (pending_cost between 1 and 10000000),  -- kenaikan harga yang menunggu 7 hari
  cost_effective_at  timestamptz,
  created_by         uuid references public.members (id) on delete set null,
  created_at         timestamptz not null default now(),
  constraint rewards_pending_pair check ((pending_cost is null) = (cost_effective_at is null))
);
create index rewards_family_idx on public.rewards (family_id) where not is_archived;

create table public.redemptions (
  id                  uuid primary key default gen_random_uuid(),
  reward_id           uuid not null references public.rewards (id) on delete cascade,
  member_id           uuid not null references public.members (id) on delete cascade,
  family_id           uuid not null references public.families (id) on delete cascade,
  cost_snapshot       int not null,
  status              text not null default 'requested'
                        check (status in ('requested', 'approved', 'fulfilled', 'rejected', 'cancelled')),
  for_date            date not null,
  session_started_at  timestamptz,
  session_ends_at     timestamptz,
  reviewed_by         uuid references public.members (id) on delete set null,
  reviewed_at         timestamptz,
  reject_reason       text,
  fulfilled_at        timestamptz,
  created_at          timestamptz not null default now()
);
create index redemptions_member_idx on public.redemptions (member_id, for_date);
create index redemptions_open_idx on public.redemptions (family_id) where status in ('requested', 'approved');

create table public.goals (
  id           uuid primary key default gen_random_uuid(),
  member_id    uuid not null references public.members (id) on delete cascade,
  reward_id    uuid not null references public.rewards (id) on delete cascade,
  family_id    uuid not null references public.families (id) on delete cascade,
  is_active    boolean not null default true,
  achieved_at  timestamptz,
  created_at   timestamptz not null default now()
);
create unique index goals_one_active on public.goals (member_id) where is_active;
create index goals_reward_idx on public.goals (reward_id) where is_active;

-- =====================================================================
-- Ledger poin (sumber kebenaran saldo)
-- =====================================================================

create table public.point_transactions (
  id          bigint generated always as identity primary key,
  family_id   uuid not null references public.families (id) on delete cascade,
  member_id   uuid not null references public.members (id) on delete cascade,
  bucket      text not null default 'available' check (bucket in ('available', 'goal')),
  amount      int not null check (amount <> 0),
  type        text not null check (type in (
                'task', 'bonus', 'penalty', 'streak', 'redeem_hold', 'redeem_release',
                'reversal', 'goal_save', 'goal_unsave')),
  ref_id      uuid,          -- task_submissions.id / redemptions.id / goals.id
  reason      text,
  created_by  uuid references public.members (id) on delete set null,  -- null = sistem
  created_at  timestamptz not null default now()
);
create index point_transactions_balance_idx on public.point_transactions (member_id, bucket);
create index point_transactions_ref_idx on public.point_transactions (ref_id);

-- Transaksi tidak pernah diubah; koreksi selalu lewat transaksi pembalik.
-- DELETE dicegah lewat hak akses (tidak ada grant/policy), supaya hapus keluarga (cascade) tetap bisa.
create function public.forbid_ledger_update() returns trigger
language plpgsql as $$
begin
  raise exception 'ledger_is_append_only';
end;
$$;

create trigger point_transactions_no_update
  before update on public.point_transactions
  for each row execute function public.forbid_ledger_update();

create table public.streaks (
  member_id      uuid primary key references public.members (id) on delete cascade,
  current_count  int not null default 0,
  best_count     int not null default 0,
  last_date      date,                 -- hari "berhasil" terakhir
  has_pending    boolean not null default false,  -- ada hari "tertunda" di dalam streak
  updated_at     timestamptz not null default now()
);

create table public.devices (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  push_token  text not null unique,
  platform    text not null check (platform in ('ios', 'android')),
  updated_at  timestamptz not null default now()
);

-- =====================================================================
-- Saldo (dihitung dari ledger)
-- =====================================================================

create view public.member_balances with (security_invoker = true) as
select
  m.id        as member_id,
  m.family_id,
  coalesce(sum(t.amount) filter (where t.bucket = 'available'), 0)::int as available,
  coalesce(sum(t.amount) filter (where t.bucket = 'goal'), 0)::int      as goal_saved,
  (select coalesce(sum(r.cost_snapshot), 0)::int
     from public.redemptions r
    where r.member_id = m.id and r.status = 'requested')               as on_hold
from public.members m
left join public.point_transactions t on t.member_id = m.id
group by m.id, m.family_id;

-- =====================================================================
-- Batas paket gratis (hanya berlaku bila families.plan = 'free')
-- =====================================================================

create function public.enforce_plan_limits() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_plan  text;
  v_count int;
begin
  select plan into v_plan from families where id = new.family_id;
  if v_plan is distinct from 'free' then
    return new;
  end if;

  if tg_table_name = 'members' and new.is_active then
    if new.role = 'member' then
      select count(*) into v_count from members
       where family_id = new.family_id and role = 'member' and is_active and id <> new.id;
      if v_count >= 1 then raise exception 'plan_limit_children'; end if;
    else
      select count(*) into v_count from members
       where family_id = new.family_id and role in ('owner', 'admin') and is_active and id <> new.id;
      if v_count >= 2 then raise exception 'plan_limit_admins'; end if;
    end if;
  elsif tg_table_name = 'tasks' and not new.is_archived then
    select count(*) into v_count from tasks
     where family_id = new.family_id and not is_archived and id <> new.id;
    if v_count >= 10 then raise exception 'plan_limit_tasks'; end if;
  elsif tg_table_name = 'rewards' and not new.is_archived then
    select count(*) into v_count from rewards
     where family_id = new.family_id and not is_archived and id <> new.id;
    if v_count >= 5 then raise exception 'plan_limit_rewards'; end if;
  end if;
  return new;
end;
$$;

create trigger members_plan_limits
  before insert or update of is_active, role on public.members
  for each row execute function public.enforce_plan_limits();

create trigger tasks_plan_limits
  before insert or update of is_archived on public.tasks
  for each row execute function public.enforce_plan_limits();

create trigger rewards_plan_limits
  before insert or update of is_archived on public.rewards
  for each row execute function public.enforce_plan_limits();
