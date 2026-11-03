# design.md — Family Points App

Panduan visual untuk Family Points App. Gaya: **playful soft-brutalism** — latar krem bergaris grid, outline hitam tebal, hard shadow tanpa blur, blok warna cerah yang solid, tipografi display super tebal, dan ilustrasi karakter bergaris tebal dengan doodle kecil.

Rasa yang dituju: hangat, percaya diri, sedikit nakal — seperti buku tempel (sticker book) yang rapi. Bukan lucu kekanak-kanakan, bukan juga korporat.

> Catatan: dokumen ini mengadopsi *gaya*, bukan aset. Semua ilustrasi, maskot, nama, dan ikon harus dibuat orisinal untuk app ini.

---

## 1. Prinsip desain

1. **Garis tegas, bayangan keras.** Elemen interaktif punya outline hitam 2px dan shadow offset tanpa blur. Tidak ada soft shadow, glassmorphism, atau gradien.
2. **Warna sebagai blok, bukan aksen.** Kartu utama diisi penuh satu warna cerah. Satu layar maksimal 3 warna blok.
3. **Angka adalah pahlawan.** Saldo poin, progress, dan persentase ditulis besar dengan font display.
4. **Kertas, bukan layar.** Latar krem dengan grid tipis memberi kesan buku catatan/tabungan.
5. **Sedikit miring itu hidup.** Foto bukti, kartu hadiah, dan stiker boleh diputar −5° s/d +5° supaya terasa ditempel tangan. Saat foto dibuka layar penuh, foto selalu tegak.
6. **Doodle sebagai bumbu.** Bintang, asterisk, spiral, dan sparkle kecil di sekitar ilustrasi — maksimal 3 per layar.

---

## 2. Warna

### Token dasar

```css
:root {
  /* Netral */
  --paper:        #FBF7EE;  /* latar utama, krem */
  --paper-grid:   #EFE7D6;  /* garis grid latar */
  --surface:      #FFFFFF;  /* kartu putih, pill, input */
  --ink:          #161616;  /* teks utama, outline, shadow */
  --ink-muted:    #6B6760;  /* teks sekunder */
  --ink-faint:    #A9A39A;  /* placeholder, disabled */
  --line-soft:    #D9D3C7;  /* outline elemen non-aktif */

  /* Blok warna (kartu besar) */
  --tangerine:    #E9693F;  /* aksi utama, tugas */
  --sunflower:    #F4C845;  /* goal, progress, CTA utama */
  --grape:        #6A4E9E;  /* komunitas/keluarga, riwayat */
  --cobalt:       #3E6CE0;  /* aksen doodle, info */
  --bubblegum:    #F08BB2;  /* badge diskon, perayaan */
  --matcha:       #9DB33F;  /* sukses, streak */

  /* Pastel (lingkaran ikon kategori) */
  --pastel-lilac:  #DCD5FF;
  --pastel-butter: #FBEFB4;
  --pastel-lime:   #E4F5B8;
  --pastel-sky:    #D8E7FF;
  --pastel-peach:  #FFDCCB;

  /* Varian gelap — untuk TEKS & stempel berwarna (lolos AA ≥ 4.5:1 di putih & krem) */
  --tangerine-deep: #B4421C;  /* 5.6:1 di putih */
  --matcha-deep:    #5C6E1C;  /* 5.7:1 di putih */
  --cobalt-deep:    #2F55B8;  /* 6.8:1 di putih */

  /* Status — isian (fill) */
  --approved:     #9DB33F;
  --pending:      #F4C845;
  --rejected:     #E9693F;
  --retake:       #3E6CE0;
  --fulfilled:    #6A4E9E;
  --cancelled:    #6B6760;

  /* Status — teks/garis di atas paper atau surface */
  --approved-text: #5C6E1C;
  --pending-text:  #161616;  /* stempel MENUNGGU: teks ink di atas isian sunflower */
  --rejected-text: #B4421C;
  --retake-text:   #2F55B8;
  --fulfilled-text:#6A4E9E;
  --cancelled-text:#6B6760;
}
```

**Status tidak pernah ditunjukkan dengan warna saja.** Selalu sertakan label teks atau stempel. Ini penting karena `--tangerine` juga dipakai sebagai warna kartu tugas, bukan hanya untuk status ditolak.

### Aturan penggunaan

| Elemen | Warna |
| --- | --- |
| Latar semua layar | `--paper` + grid `--paper-grid` |
| Kartu tugas / aksi utama | `--tangerine`, teks `--ink` |
| Kartu goal & progress | `--sunflower`, teks `--ink` |
| Kartu keluarga / riwayat | `--grape`, teks `--surface` |
| Kartu persetujuan menunggu | `--sunflower`, teks `--ink` (sama dengan warna status menunggu) |
| CTA utama (mis. "Tukar sekarang") | Pill `--sunflower`, teks `--ink`, outline `--ink` 2px, hard shadow |
| CTA sekunder | Pill `--surface`, outline `--ink` 2px, hard shadow |
| Lingkaran ikon kategori | Pastel, outline `--ink` 2px, hard shadow |

**Kontras (target WCAG AA, sesuai PRD):**

| Pasangan | Rasio | Boleh untuk |
| --- | --- | --- |
| `--ink` di `--sunflower` / `--tangerine` / `--matcha` / `--bubblegum` | 11.4 / 5.7 / 7.7 / 7.8 | Semua ukuran teks |
| `--surface` di `--grape` | 6.6 | Semua ukuran teks |
| `--ink-muted` di `--paper` / `--surface` | 5.3 | Semua ukuran teks |
| `--surface` di `--tangerine` | 3.2 | **Jangan dipakai.** Cukup untuk teks besar, tapi kartu tangerine juga berisi teks kecil, jadi semua teksnya pakai `--ink` |
| `--surface` di `--bubblegum` / `--matcha` | 2.3 / 2.2 | **Jangan dipakai** |
| `--tangerine` / `--matcha` / `--cobalt` sebagai warna teks | 3.0 / 2.2 / 4.4 | **Jangan dipakai.** Pakai varian `-deep` |
| `--ink-faint` di `--surface` | 2.5 | Hanya untuk placeholder & elemen disabled, bukan teks berisi informasi |

Teks tidak boleh diberi opacity untuk menurunkan kontras. Untuk teks sekunder, pakai `--ink-muted` (di latar terang) atau `--surface` penuh (di `--grape`).

### Latar grid

```css
.screen {
  background-color: var(--paper);
  background-image:
    linear-gradient(var(--paper-grid) 1px, transparent 1px),
    linear-gradient(90deg, var(--paper-grid) 1px, transparent 1px);
  background-size: 24px 24px;
}
```

Grid hanya di latar layar, tidak di dalam kartu berwarna.

---

## 3. Tipografi

| Peran | Font | Bobot | Catatan |
| --- | --- | --- | --- |
| Display (judul, angka besar) | **Gabarito** (alternatif: Bricolage Grotesque, Lexend) | 800–900 | Tebal, padat, sedikit membulat |
| UI & body | **Plus Jakarta Sans** | 400 / 500 / 600 / 700 | Font buatan Indonesia, cocok untuk teks Bahasa Indonesia |
| Angka poin | Gabarito | 900 | `font-variant-numeric: tabular-nums` |

### Skala

| Token | Ukuran / line-height | Font | Contoh |
| --- | --- | --- | --- |
| `display-xl` | 40 / 44 | Display 900 | Judul onboarding |
| `display-lg` | 32 / 36 | Display 900 | "Halo, Raka!" |
| `number-hero` | 48 / 48 | Display 900 | Saldo `3.250` |
| `title-lg` | 24 / 30 | Jakarta 700 | Judul kartu warna |
| `title-md` | 18 / 24 | Jakarta 700 | Judul paket, nama tugas |
| `body` | 15 / 22 | Jakarta 500 | Deskripsi |
| `body-sm` | 13 / 18 | Jakarta 500 | Waktu, meta |
| `label` | 13 / 16 | Jakarta 600 | Label ikon kategori, chip |

Aturan:
- Judul display rata kiri, maksimal 3 baris, boleh diberi satu doodle di ujung baris (mis. asterisk biru).
- Tidak memakai huruf kapital semua (ALL CAPS) kecuali pada stempel "DISETUJUI".
- Letter-spacing display: `-0.01em`.

---

## 4. Bentuk, garis, dan bayangan

```css
:root {
  --stroke:        2px solid var(--ink);
  --stroke-soft:   1.5px solid var(--line-soft);

  --shadow-hard-sm: 2px 3px 0 var(--ink);
  --shadow-hard-md: 3px 4px 0 var(--ink);
  --shadow-hard-lg: 4px 6px 0 var(--ink);

  --radius-pill:  999px;
  --radius-card:  28px;   /* kartu warna besar */
  --radius-photo: 24px;   /* kartu foto / ilustrasi */
  --radius-row:   999px;  /* baris list di dalam kartu */
  --radius-chip:  14px;
  --radius-select: 40px;  /* kartu pilihan */

  --tilt-max:     5deg;   /* rotasi acak −5° s/d +5° */
}
```

| Elemen | Outline | Shadow | Radius |
| --- | --- | --- | --- |
| Kartu warna besar | Tidak ada | Tidak ada | 28 |
| Pill tombol (primary, sekunder, destructive) | 2px ink | hard-sm | pill |
| Lingkaran ikon | 2px ink | hard-md | lingkaran |
| Baris list di dalam kartu | 2px ink | Tidak ada | pill |
| Kartu pilihan (terpilih) | 2px ink | hard-lg | `--radius-select` (40) |
| Kartu pilihan (tidak dipilih) | 1.5px `--line-soft` | Tidak ada | `--radius-select` (40) |
| Kartu foto / ilustrasi | 2px ink | hard-md | 24, diputar −5° s/d +5° |

Kartu warna besar tidak bisa ditekan sebagai satu kesatuan, sehingga tidak perlu outline dan shadow. Aksinya lewat icon button atau baris list di dalamnya.

**Larangan:** `box-shadow` dengan blur, gradien, transparansi kaca, border berwarna selain ink/line-soft.

---

## 5. Spasi dan layout

- Grid dasar **8px**. Padding layar horizontal **20px**.
- Jarak antar kartu besar **16px**. Padding dalam kartu besar **20px**.
- Kartu warna memanjang penuh (full-width) dan ditumpuk vertikal.
- Baris shortcut ikon kategori bisa di-scroll horizontal; lingkaran **72px**, label di bawah.
- Area tap minimum **48×48px** (mode anak **56×56px**).
- **Ukuran teks dinamis.** Semua tinggi komponen di dokumen ini (tombol 56, list row 64, dan lainnya) adalah tinggi *minimum*. Saat pengguna memperbesar teks di pengaturan HP, komponen ikut memanjang dan teks boleh turun ke baris kedua, tidak terpotong. Angka `number-hero` boleh mengecil sampai 36px agar muat.

---

## 6. Ilustrasi dan doodle

**Gaya karakter**
- Outline hitam tebal (setara 3–4px pada ukuran tampil), bentuk sederhana, flat tanpa gradasi.
- Wajah: mata garis/titik, pipi blush pink `--bubblegum` 40%, ekspresi senang yang jelas.
- Baju diisi satu warna blok (`--sunflower`, `--tangerine`, dsb.).
- Karakter ditaruh di dalam **kartu foto putih miring** dengan outline dan hard shadow.
- Representasikan keluarga Indonesia yang beragam (warna kulit, hijab, rambut, usia).

**Doodle pendukung**
- Asterisk `--cobalt`, bintang `--sunflower` bergaris ink, spiral `--matcha`, sparkle 4 sudut, petir kecil.
- Maksimal 3 doodle per layar, ditempatkan di sudut ilustrasi atau ujung judul.

**Avatar & stiker emosi**
- Lingkaran berwarna dengan wajah sederhana (bisa pakai aksesori: kacamata hitam, mahkota) untuk avatar anak dan badge.
- Stiker punya outline putih tipis + garis putus-putus di tepi, seperti stiker yang ditempel.

**Ikon UI**
- Garis 2px, sudut membulat, gaya outline (mis. Phosphor Bold, atau set custom). Tidak memakai emoji sebagai ikon.

---

## 7. Komponen

### 7.1 Tombol

| Varian | Tampilan | Dipakai untuk |
| --- | --- | --- |
| Primary | Pill `--sunflower`, outline 2px ink, hard-sm, teks ink Jakarta 700 17px, tinggi min. 56 | Satu aksi utama per layar ("Tukar sekarang", "Kirim laporan") |
| Secondary | Pill putih, outline 2px ink, hard-sm, tinggi min. 52 | "Masuk", "Lihat semua" |
| Icon button | Lingkaran putih 40px (area tap tetap 48/56), outline 2px ink | Tambah (+), panah (↗), pengaturan |
| Destructive | Pill putih, outline 2px ink, hard-sm, teks `--tangerine-deep` + ikon silang | "Tolak" |

Pressed state (semua varian): shadow hilang, elemen bergeser `translate(2px, 3px)`, seperti ditekan ke kertas.

### 7.2 Lingkaran kategori (shortcut)

Lingkaran 72px pastel + ikon ink 24px + label `label` di bawah. Contoh: Tugas, Hadiah, Goal, Riwayat.

### 7.3 Kartu warna (feature card)

Struktur: judul `title-lg` + deskripsi `body` + aksi icon button di kanan atas + konten (list row, angka, chart). Warna teks mengikuti tabel kontras di bagian 2, tanpa opacity.

| Kartu | Warna | Teks | Isi |
| --- | --- | --- | --- |
| Tugas hari ini | `--tangerine` | `--ink` | 2–3 list row tugas + tombol (+) |
| Goal saya | `--sunflower` | `--ink` | Avatar hadiah, angka `number-hero`, progress dot grid |
| Persetujuan menunggu (orang tua) | `--sunflower` | `--ink` | Angka besar jumlah laporan + penukaran menunggu |
| Keluarga | `--grape` | `--surface` | Ringkasan anggota, tombol ↗ |

### 7.4 List row (di dalam kartu)

Pill putih, outline 2px, tinggi 64. Kiri: avatar/ikon bulat 44px. Tengah: judul `title-md` + subjudul `body-sm` terpotong satu baris. Kanan: waktu atau chevron `>`.

### 7.5 Progress dot grid (goal)

Visualisasi khas pengganti progress bar:
- Selalu **20 lingkaran**, masing-masing mewakili 5% dari harga goal, apa pun harganya. Pembulatan ke bawah, jadi lingkaran terakhir baru terisi saat poin benar-benar cukup.
- Grid lingkaran 18px, jarak 6px, membentuk "tangga" naik ke kanan.
- Di kartu `--sunflower`: lingkaran terisi `--ink` solid = poin terkumpul; lingkaran outline `--ink` 2px = sisa.
- Di sebelahnya angka besar, mis. **64%** atau **3.200 / 5.000**, plus estimasi hari (PRD G-02), mis. "±6 hari lagi".
- Untuk pembaca layar, umumkan sebagai teks: "Goal Makan di Solaria, 3.200 dari 5.000 poin, 64 persen".

### 7.6 Dropdown pill

Pill putih, outline 2px, teks `label` + chevron. Mis. "Minggu ini ⌄".

### 7.7 Kartu pilihan (selectable card)

Dipakai untuk memilih hadiah, template usia, atau paket langganan.
- Terpilih: outline ink 2px + hard-lg, teks ink, plus ikon centang (agar tidak bergantung pada outline saja).
- Tidak terpilih: outline `--line-soft`, teks `--ink-muted`.
- Badge kanan: pill `--bubblegum` teks `--ink` (mis. "Hemat 20%" atau "Cukup!").

### 7.8 Kartu foto bukti (polaroid)

Kartu putih, outline 2px, hard-md, radius 24, diputar acak −5° s/d +5°. Foto di dalam, stempel waktu kecil di bawah (`body-sm`, ink-muted). Lebih dari satu foto ditumpuk saling tumpang tindih.

Saat ditekan, foto terbuka **layar penuh dan tegak** (tanpa rotasi, outline, atau shadow) dengan latar `--ink`. Foto bisa di-zoom dan digeser antar foto (PRD PF-04). Untuk mode sebelum & sesudah (PF-06), dua polaroid diberi label "Sebelum" dan "Sesudah".

### 7.9 Stempel status

Lingkaran/kotak bergaris ganda, diputar −12°, teks ALL CAPS Display 900. Garis dan teks memakai warna `-text` dari bagian 2, di atas `--paper` atau `--surface`.

| Stempel (ID) | Stempel (EN) | Warna garis & teks | Dipakai untuk |
| --- | --- | --- | --- |
| **MENUNGGU** | **PENDING** | Isian `--sunflower`, teks & garis `--ink` | Laporan & penukaran yang diajukan |
| **DISETUJUI** | **APPROVED** | `--matcha-deep` | Laporan & penukaran |
| **DITOLAK** | **REJECTED** | `--tangerine-deep` | Laporan & penukaran |
| **FOTO ULANG** | **RETAKE** | `--cobalt-deep` | Laporan berfoto |
| **DIBERIKAN** | **GIVEN** | `--grape` | Penukaran hadiah yang sudah diberikan |
| **DIBATALKAN** | **CANCELLED** | `--ink-muted` | Penukaran yang dibatalkan anak |
| **TERCAPAI!** | **REACHED!** | `--matcha-deep` | Goal tercapai |

Teks stempel versi Inggris lebih pendek, tapi ukuran stempel mengikuti teks terpanjang supaya tata letak tidak bergeser saat bahasa diganti.

Animasi: stempel muncul dari skala 1.4 ke 1.0 dengan sedikit hentakan (lihat Motion).

### 7.10 Saldo poin

Ikon mata uang custom (mis. "Bintang" — bintang kuning bergaris ink) + angka `number-hero`. Di mode anak 6–9 tahun, tambahkan visual stack bintang kecil.

Variasi tampilan saldo:

| Kondisi | Tampilan |
| --- | --- |
| Normal | Ikon bintang + angka `number-hero` `--ink` |
| Ada tabungan goal (G-03) | Di bawah angka: "+ 1.200 di tabungan goal" (`body-sm`, `--ink-muted`) |
| Ada poin ditahan untuk penukaran | Di bawah angka: "100 sedang ditukar" (`body-sm`, `--ink-muted`) |
| **Utang poin** (saldo negatif) | Angka diawali tanda minus, warna `--tangerine-deep`, label "Utang poin" + alasan singkat, lalu kalimat "Akan lunas otomatis dari poin berikutnya." Tidak memakai stempel atau ilustrasi sedih |

### 7.10b Indikator streak

Deretan 7 lingkaran hari (Sen–Min) berukuran 28px:

| Status hari | Tampilan |
| --- | --- |
| Berhasil | Isian `--matcha`, outline ink, ikon centang ink |
| **Tertunda** (masih ada laporan menunggu untuk tanggal itu) | Isian `--sunflower`, outline ink **putus-putus**, ikon jam pasir |
| Putus / kosong | Isian `--surface`, outline `--line-soft` |
| Hari ini (belum ada laporan) | Outline ink 2px, tanpa isian |

Di samping deretan: angka streak `title-lg` + "hari berturut-turut". Bila ada hari tertunda, tambahkan keterangan "Menunggu persetujuan, streak aman dulu."

### 7.11 Pagination & indikator

Titik 8px outline ink; titik aktif berupa pill 24×8 terisi ink.

### 7.12 Bottom navigation

Latar `--surface`, garis atas 2px ink. Tab aktif: ikon di dalam pill `--sunflower` dengan outline ink.

---

## 8. Pemetaan ke layar

| Layar | Susunan |
| --- | --- |
| Onboarding | Logo kiri atas → judul `display-xl` + doodle → 2 kartu ilustrasi miring bertumpuk → pagination → tombol secondary "Masuk" → deskripsi kecil `ink-muted` |
| Beranda anak | "Halo, Raka!" + ikon pengaturan → saldo hero → lingkaran kategori → kartu Goal (sunflower, dot grid) → kartu Tugas hari ini (tangerine) |
| Beranda orang tua | Sapaan → kartu ringkasan per anak (pill list row) → kartu Persetujuan menunggu (sunflower, angka besar) → kartu Keluarga (grape) |
| Lapor tugas | Judul tugas → area kamera → kartu polaroid hasil foto → catatan → tombol primary "Kirim laporan" (non-aktif sampai jumlah foto minimal terpenuhi, dengan keterangan "Butuh 1 foto lagi") |
| Detail persetujuan | Polaroid foto bukti besar (tekan untuk layar penuh) → info tugas → tiga tombol: Setujui (primary), Minta foto ulang (secondary), Tolak (destructive) → stempel muncul setelah aksi |
| Toko hadiah | Ilustrasi kecil di atas → judul display tengah → kartu pilihan hadiah → tombol primary "Tukar sekarang" menempel di bawah |
| Goal tercapai | Ilustrasi perayaan + doodle → angka besar → stempel "TERCAPAI!" → confetti bentuk doodle |

---

## 9. Mode orang tua vs mode anak

| Aspek | Orang tua | Anak |
| --- | --- | --- |
| Kepadatan | Lebih banyak list row, angka ringkas | Lebih sedikit elemen, lebih besar |
| Ilustrasi | Hanya di empty state & onboarding | Di beranda, perayaan, toko hadiah |
| Doodle | Maks 1 per layar | Maks 3 per layar |
| Area tap | 48px | 56px |
| Microcopy | Lugas: "3 laporan menunggu" | Hangat: "Tinggal 2 tugas lagi, semangat!" |

Keduanya memakai token, komponen, dan font yang sama.

---

## 10. Motion

| Interaksi | Animasi | Durasi / easing |
| --- | --- | --- |
| Tombol ditekan | Translate (2px, 3px), shadow → 0 | 80ms, ease-out |
| Kartu muncul | Fade + naik 12px, berurutan 40ms | 220ms, ease-out |
| Stempel status | Scale 1.4 → 0.95 → 1.0, rotasi −12° | 320ms, spring (damping tinggi) |
| Poin bertambah | Angka count-up + bintang kecil melompat | 600ms |
| Dot grid progress | Lingkaran terisi satu per satu | 30ms per dot |
| Goal tercapai | Confetti doodle (bintang, spiral, asterisk) | 1.2s |

Hormati pengaturan "reduce motion": ganti semua dengan fade 150ms.

---

## 11. Microcopy

- Bahasa Indonesia sehari-hari, kalimat pendek, sapaan "kamu".
- Contoh: "Kamarnya udah rapi? Fotoin dong 📸" → **tanpa emoji**: "Kamarnya udah rapi? Fotoin dong."
- Penolakan selalu disertai alasan dan ajakan mencoba lagi: "Belum pas nih — lantainya masih kotor. Coba lagi ya."
- Hindari: "Welcome back 👋", "Unlock your potential", kalimat motivasi generik.

---

## 12. Do & Don't

**Do**
- Outline ink 2px + hard shadow pada semua elemen yang bisa ditekan (termasuk tombol primary).
- Status selalu disertai teks atau stempel, tidak hanya warna.
- Satu warna blok per kartu, maksimal 3 warna blok per layar.
- Angka penting dalam font display besar.
- Ilustrasi orisinal dengan karakter keluarga Indonesia.

**Don't**
- Soft shadow, gradien, glassmorphism, blur.
- Emoji sebagai ikon atau dekorasi.
- Teks putih di atas `--sunflower`, `--tangerine`, `--matcha`, atau `--bubblegum`.
- Warna blok terang (`--tangerine`, `--matcha`, `--cobalt`) sebagai warna teks. Pakai varian `-deep`.
- Opacity pada teks.
- Lebih dari 3 doodle per layar.
- Memakai ulang nama, logo, atau ilustrasi dari app/referensi lain.

---

## 13. Token ringkas (untuk Flutter / React Native)

```json
{
  "color": {
    "paper": "#FBF7EE", "paperGrid": "#EFE7D6", "surface": "#FFFFFF",
    "ink": "#161616", "inkMuted": "#6B6760", "inkFaint": "#A9A39A", "lineSoft": "#D9D3C7",
    "tangerine": "#E9693F", "sunflower": "#F4C845", "grape": "#6A4E9E",
    "cobalt": "#3E6CE0", "bubblegum": "#F08BB2", "matcha": "#9DB33F",
    "pastelLilac": "#DCD5FF", "pastelButter": "#FBEFB4", "pastelLime": "#E4F5B8",
    "pastelSky": "#D8E7FF", "pastelPeach": "#FFDCCB",
    "tangerineDeep": "#B4421C", "matchaDeep": "#5C6E1C", "cobaltDeep": "#2F55B8"
  },
  "status": {
    "pending":   { "fill": "#F4C845", "text": "#161616" },
    "approved":  { "fill": "#9DB33F", "text": "#5C6E1C" },
    "rejected":  { "fill": "#E9693F", "text": "#B4421C" },
    "retake":    { "fill": "#3E6CE0", "text": "#2F55B8" },
    "fulfilled": { "fill": "#6A4E9E", "text": "#6A4E9E" },
    "cancelled": { "fill": "#6B6760", "text": "#6B6760" }
  },
  "font": { "display": "Gabarito", "body": "Plus Jakarta Sans" },
  "type": {
    "displayXl":  { "size": 40, "line": 44, "font": "display", "weight": 900 },
    "displayLg":  { "size": 32, "line": 36, "font": "display", "weight": 900 },
    "numberHero": { "size": 48, "line": 48, "font": "display", "weight": 900, "tabular": true },
    "titleLg":    { "size": 24, "line": 30, "font": "body", "weight": 700 },
    "titleMd":    { "size": 18, "line": 24, "font": "body", "weight": 700 },
    "body":       { "size": 15, "line": 22, "font": "body", "weight": 500 },
    "bodySm":     { "size": 13, "line": 18, "font": "body", "weight": 500 },
    "label":      { "size": 13, "line": 16, "font": "body", "weight": 600 }
  },
  "radius": { "pill": 999, "card": 28, "photo": 24, "chip": 14, "select": 40 },
  "tiltMaxDeg": 5,
  "stroke": { "width": 2, "softWidth": 1.5 },
  "shadow": {
    "sm": { "x": 2, "y": 3, "blur": 0, "color": "#161616" },
    "md": { "x": 3, "y": 4, "blur": 0, "color": "#161616" },
    "lg": { "x": 4, "y": 6, "blur": 0, "color": "#161616" }
  },
  "space": { "base": 8, "screenX": 20, "cardGap": 16, "cardPadding": 20 },
  "tapTarget": { "parent": 48, "child": 56 },
  "motion": {
    "press":    { "ms": 80,  "easing": "easeOut", "dx": 2, "dy": 3 },
    "cardIn":   { "ms": 220, "easing": "easeOut", "stagger": 40, "rise": 12 },
    "stamp":    { "ms": 320, "easing": "spring", "scale": [1.4, 0.95, 1.0], "rotateDeg": -12 },
    "countUp":  { "ms": 600 },
    "dotFill":  { "msPerDot": 30 },
    "confetti": { "ms": 1200 },
    "reduced":  { "ms": 150, "type": "fade" }
  }
}
```
