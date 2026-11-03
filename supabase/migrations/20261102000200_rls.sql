-- Family Points App — hak akses & Row Level Security
--
-- Prinsip (Rencana Implementasi, "Arsitektur ringkas"):
-- * Setiap query dibatasi ke keluarga sendiri.
-- * Aplikasi boleh CRUD langsung hanya untuk data konfigurasi (tugas, hadiah, anggota, pengaturan keluarga).
-- * Semua yang mengubah poin atau status (laporan, penukaran, goal, undangan) hanya lewat RPC di
--   20261102000300_functions.sql. Tabel-tabel itu read-only bagi klien.
-- * Anak masuk lewat anonymous sign-in Supabase, jadi berperan `authenticated`, sama seperti orang tua.

-- =====================================================================
-- Helper untuk policy (security definer supaya tidak rekursif terhadap RLS members)
-- =====================================================================

create function public.is_family_member(p_family_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1
      from member_logins ml
      join members m on m.id = ml.member_id
     where ml.user_id = auth.uid()
       and m.family_id = p_family_id
       and m.is_active
  );
$$;

create function public.is_family_admin(p_family_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1
      from member_logins ml
      join members m on m.id = ml.member_id
     where ml.user_id = auth.uid()
       and m.family_id = p_family_id
       and m.is_active
       and m.role in ('owner', 'admin')
  );
$$;

-- =====================================================================
-- Grant dasar: anon tidak boleh apa-apa, authenticated hanya baca (lalu dibuka per kolom)
-- =====================================================================

revoke all on all tables in schema public from anon;
revoke insert, update, delete, truncate on all tables in schema public from authenticated;
grant select on all tables in schema public to authenticated;

-- pin_hash tidak boleh terbaca klien
revoke select on public.members from authenticated;
grant select (id, family_id, role, can_earn, name, avatar, birth_date, is_active, created_at)
  on public.members to authenticated;

-- Data konfigurasi yang boleh diubah admin secara langsung
grant update (name, timezone, locale, quiet_start, quiet_end, allow_negative_penalty, streak_bonus_pct)
  on public.families to authenticated;

grant insert (family_id, role, name, avatar, birth_date)
  on public.members to authenticated;
grant update (name, avatar, birth_date, is_active, can_earn)
  on public.members to authenticated;

grant insert (family_id, title, icon, description, points, frequency, days_of_week, max_per_day,
              verification, min_photos, before_after, allow_gallery, due_time, reminder_time, created_by)
  on public.tasks to authenticated;
grant update (title, icon, description, points, frequency, days_of_week, max_per_day,
              verification, min_photos, before_after, allow_gallery, due_time, reminder_time, is_archived)
  on public.tasks to authenticated;

grant insert, delete on public.task_assignments to authenticated;

-- Harga (cost) hanya boleh diubah lewat RPC update_reward_price (aturan harga 7 hari)
grant insert (family_id, title, image_url, cost, type, duration_minutes, max_per_day, stock,
              needs_approval, created_by)
  on public.rewards to authenticated;
grant update (title, image_url, duration_minutes, max_per_day, stock, needs_approval, is_archived)
  on public.rewards to authenticated;

-- =====================================================================
-- RLS
-- =====================================================================

alter table public.families           enable row level security;
alter table public.members            enable row level security;
alter table public.member_logins      enable row level security;
alter table public.invites            enable row level security;
alter table public.tasks              enable row level security;
alter table public.task_assignments   enable row level security;
alter table public.task_submissions   enable row level security;
alter table public.submission_photos  enable row level security;
alter table public.rewards            enable row level security;
alter table public.redemptions        enable row level security;
alter table public.goals              enable row level security;
alter table public.point_transactions enable row level security;
alter table public.streaks            enable row level security;
alter table public.devices            enable row level security;

-- families
create policy families_select on public.families for select to authenticated
  using (public.is_family_member(id));
create policy families_update on public.families for update to authenticated
  using (public.is_family_admin(id))
  with check (public.is_family_admin(id));

-- members
create policy members_select on public.members for select to authenticated
  using (public.is_family_member(family_id));
create policy members_insert on public.members for insert to authenticated
  with check (role = 'member' and public.is_family_admin(family_id));
create policy members_update on public.members for update to authenticated
  using (public.is_family_admin(family_id))
  with check (public.is_family_admin(family_id) and (role <> 'owner' or is_active));

-- member_logins: user melihat login miliknya; admin melihat siapa saja yang sudah terhubung
create policy member_logins_select on public.member_logins for select to authenticated
  using (
    user_id = (select auth.uid())
    or exists (select 1 from public.members m
                where m.id = member_id and public.is_family_admin(m.family_id))
  );

-- invites: hanya admin (kode undangan bersifat rahasia)
create policy invites_select on public.invites for select to authenticated
  using (public.is_family_admin(family_id));

-- tasks
create policy tasks_select on public.tasks for select to authenticated
  using (public.is_family_member(family_id));
create policy tasks_insert on public.tasks for insert to authenticated
  with check (public.is_family_admin(family_id));
create policy tasks_update on public.tasks for update to authenticated
  using (public.is_family_admin(family_id))
  with check (public.is_family_admin(family_id));

-- task_assignments: tugas dan anggota harus satu keluarga
create policy task_assignments_select on public.task_assignments for select to authenticated
  using (exists (select 1 from public.tasks t
                  where t.id = task_id and public.is_family_member(t.family_id)));
create policy task_assignments_insert on public.task_assignments for insert to authenticated
  with check (exists (select 1 from public.tasks t
                        join public.members m on m.family_id = t.family_id
                       where t.id = task_id and m.id = member_id
                         and public.is_family_admin(t.family_id)));
create policy task_assignments_delete on public.task_assignments for delete to authenticated
  using (exists (select 1 from public.tasks t
                  where t.id = task_id and public.is_family_admin(t.family_id)));

-- rewards
create policy rewards_select on public.rewards for select to authenticated
  using (public.is_family_member(family_id));
create policy rewards_insert on public.rewards for insert to authenticated
  with check (public.is_family_admin(family_id));
create policy rewards_update on public.rewards for update to authenticated
  using (public.is_family_admin(family_id))
  with check (public.is_family_admin(family_id));

-- Tabel yang hanya ditulis lewat RPC: cukup policy SELECT
create policy task_submissions_select on public.task_submissions for select to authenticated
  using (public.is_family_member(family_id));

create policy submission_photos_select on public.submission_photos for select to authenticated
  using (exists (select 1 from public.task_submissions s
                  where s.id = submission_id and public.is_family_member(s.family_id)));

create policy redemptions_select on public.redemptions for select to authenticated
  using (public.is_family_member(family_id));

create policy goals_select on public.goals for select to authenticated
  using (public.is_family_member(family_id));

create policy point_transactions_select on public.point_transactions for select to authenticated
  using (public.is_family_member(family_id));

create policy streaks_select on public.streaks for select to authenticated
  using (exists (select 1 from public.members m
                  where m.id = member_id and public.is_family_member(m.family_id)));

-- devices: ditulis lewat RPC register_device
create policy devices_select on public.devices for select to authenticated
  using (user_id = (select auth.uid()));

-- =====================================================================
-- Storage: foto bukti di bucket privat "proofs"
-- Path wajib: {family_id}/{member_id}/{nama file}.jpg
-- =====================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('proofs', 'proofs', false, 1048576, array['image/jpeg', 'image/webp'])
on conflict (id) do nothing;

-- Catatan: di dalam subquery, tulis `objects.name`. Tanpa prefiks, `name` akan terbaca sebagai
-- members.name / families.name dan policy diam-diam selalu gagal.

-- Upload hanya ke folder anggota yang login di HP ini
create policy proofs_insert on storage.objects for insert to authenticated
  with check (
    bucket_id = 'proofs'
    and exists (
      select 1
        from public.member_logins ml
        join public.members m on m.id = ml.member_id
       where ml.user_id = (select auth.uid())
         and m.is_active
         and m.family_id::text = (storage.foldername(objects.name))[1]
         and m.id::text = (storage.foldername(objects.name))[2]
    )
  );

-- Baca (termasuk membuat signed URL) oleh semua anggota keluarga
create policy proofs_select on storage.objects for select to authenticated
  using (
    bucket_id = 'proofs'
    and exists (
      select 1 from public.families f
       where f.id::text = (storage.foldername(objects.name))[1]
         and public.is_family_member(f.id)
    )
  );

-- Admin boleh menghapus foto tidak pantas (PRD edge case)
create policy proofs_delete on storage.objects for delete to authenticated
  using (
    bucket_id = 'proofs'
    and exists (
      select 1 from public.families f
       where f.id::text = (storage.foldername(objects.name))[1]
         and public.is_family_admin(f.id)
    )
  );
