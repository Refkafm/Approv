// Family Points App — pengirim push OneSignal.
//
// Dipanggil pg_cron tiap menit (migrasi 20261102000800_push.sql). Mengambil antrean lewat
// claim_push_batch(), mengirim ke OneSignal dengan external_id = auth user id (app memanggil
// OneSignal.login(userId) setelah masuk), lalu mengembalikan yang gagal lewat release_push().
//
// Secrets (supabase secrets set ...): ONESIGNAL_APP_ID, ONESIGNAL_REST_API_KEY.
// SUPABASE_URL dan SUPABASE_SERVICE_ROLE_KEY sudah disediakan Supabase.

import { createClient } from "npm:@supabase/supabase-js@2";

type PushRow = {
  id: number;
  external_ids: string[];
  title: string;
  body: string;
  route: string;
  send_after: string | null;
};

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const appId = Deno.env.get("ONESIGNAL_APP_ID")!;
const restKey = Deno.env.get("ONESIGNAL_REST_API_KEY")!;

async function send(row: PushRow): Promise<boolean> {
  const payload: Record<string, unknown> = {
    app_id: appId,
    target_channel: "push",
    include_aliases: { external_id: row.external_ids },
    headings: { en: row.title, id: row.title },
    contents: { en: row.body, id: row.body },
    data: { route: row.route },
  };
  // Jam tidur anak: OneSignal menahan dan mengirim di akhir jam tidur
  if (row.send_after) payload.send_after = row.send_after;

  const res = await fetch("https://api.onesignal.com/notifications?c=push", {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Key ${restKey}` },
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    console.error(`push ${row.id} gagal: ${res.status} ${await res.text()}`);
    return false;
  }
  return true;
}

Deno.serve(async (req) => {
  // Hanya cron (membawa service role key) yang boleh memicu pengiriman
  if (req.headers.get("Authorization") !== `Bearer ${serviceKey}`) {
    return new Response("forbidden", { status: 403 });
  }

  const db = createClient(supabaseUrl, serviceKey, { auth: { persistSession: false } });
  const { data, error } = await db.rpc("claim_push_batch", { p_limit: 100 });
  if (error) return new Response(error.message, { status: 500 });

  const rows = (data ?? []) as PushRow[];
  const failed: number[] = [];
  let sent = 0;
  for (const row of rows) {
    // Penerima belum login di HP mana pun: tidak ada yang bisa dikirimi, anggap selesai
    if (row.external_ids.length === 0) continue;
    if (await send(row)) sent++;
    else failed.push(row.id);
  }

  if (failed.length > 0) {
    const { error: releaseError } = await db.rpc("release_push", { p_ids: failed });
    if (releaseError) console.error(`release_push gagal: ${releaseError.message}`);
  }

  return Response.json({ claimed: rows.length, sent, failed: failed.length });
});
