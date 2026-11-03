-- Family Points App — minggu 6: dompet
--
-- Bonus, penalti, dan pembatalan tugas otomatis langsung terlihat di HP anak (realtime).
-- Realtime tetap menghormati RLS point_transactions_select, jadi hanya keluarga sendiri yang menerima.

alter publication supabase_realtime add table public.point_transactions;
