-- Family Points App — realtime untuk tugas & anggota
--
-- Tugas baru/diubah/diarsipkan dan anggota baru dari HP orang tua langsung terlihat di HP lain
-- (anak & admin kedua). RLS select (is_family_member) tetap berlaku untuk realtime.

alter publication supabase_realtime add table public.tasks, public.members;
