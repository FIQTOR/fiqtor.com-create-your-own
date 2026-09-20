# Rencana Perbaikan Struktur Folder & Nama File

> Tujuan: struktur **mudah dicari**, **konsisten**, dan **clean code / clean structure**.
> Repo ini berisi dua git repo terpisah: `backend/` (Express) dan `frontend/` (React + Vite).
> Semua path di dokumen ini **relatif** ke folder masing-masing.

---

## ✅ STATUS: SUDAH DIEKSEKUSI

Perbaikan telah diterapkan pada `backend/` dan `frontend/`. Ringkasan hasil:

**Backend (`backend/`)** — semua kode sekarang di bawah `src/`:
```
index.js
src/
├── config/          cors.js, crypto.js, identity.js, social.js
├── controllers/     ai.controller.js, contact.controller.js,
│                    github.controller.js, wakatime.controller.js
├── middleware/      error-handler.js, logger.js, rate-limiter.js
├── services/        contact.service.js, crypto.service.js, github.service.js,
│                    social.service.js, wakatime.service.js
└── routes/          index.js (agregator), ai.routes.js, contact.routes.js,
                     public.routes.js, stats.routes.js
```
- Handler inline di `routes.js` diekstrak ke controller (`contact`, `github`, `wakatime`).
- `public/index.js` → `src/routes/public.routes.js` (nama folder tidak lagi menyesatkan).
- Suffix `Config` redundan dihapus; `module.exports` distandarkan; endpoint `/health` ditambah.
- **Terverifikasi:** `node --check` semua file lolos; server boot & semua endpoint diuji via `curl` (health, crypto, social/stats, v1/public/stats, contact validation) → OK.

**Frontend (`frontend/`)**:
- `modules/` distandarkan: `elements`/`section` → `components/`/`sections/`, file PascalCase.
- Typo `recapthcha.tsx` → `Recaptcha.tsx` diperbaiki.
- `modules/certificate/` → `modules/certification/`; `modules/project/` → `modules/projects/` (selaras dengan route).
- File config mati dihapus: `AppConfig.ts`, `Instagram.ts`, `Tiktok.ts`.
- Aset mati dihapus: `src/assets/react.svg`, `src/assets/vite.svg`, `public/favicon copy.ico`.
- Semua import `@/…` dan relatif diperbarui; **verifikasi**: semua target import `@/…` ada.

> Catatan: `config/` tetap PascalCase (sudah konsisten internal). Rename kebab-case untuk config tidak dilakukan agar churn minim — lihat §3.5 untuk opsi lanjutan.

---

## 1. Prinsip yang Dipakai

1. **Satu pola penamaan per jenis file** — jangan campur `PascalCase`, `camelCase`, dan `kebab-case` untuk hal yang sama.
2. **Nama folder = nama domain / fitur**, bukan nama teknis (`elements`, `components` di dalam module membingungkan).
3. **Nama file = apa isinya**, bukan tipe generik (`index.js`/`index.tsx` hanya di folder yang benar-benar jadi entry point).
4. **Co-location** — kode yang berubah bersama diletakkan berdekatan (1 fitur = 1 folder).
5. **Import path konsisten** — selalu pakai alias `@/...` di frontend, path relatif bersih di backend.

### Konvensi penamaan yang disepakati

| Konteks | Konvensi | Contoh |
| --- | --- | --- |
| Folder | `kebab-case` | `certificates-grid` → folder `certificates` |
| Komponen React (`.tsx`) | `PascalCase` | `CertificateCard.tsx` |
| Utilitas/hook/helper TS | `kebab-case` | `use-scroll-top.ts` |
| Data/config TS | `PascalCase` (objek) / `kebab-case` (file) | `menu.ts`, `Identity.ts` (pilih satu) |
| File JS backend | `PascalCase` untuk class/service, `camelCase` untuk helper | `ContactHandler.js` |
| Route/endpoint | `kebab-case` | `/api/v1/github/contributions` |

> **Rekomendasi utama:** pilih **satu** gaya untuk file frontend non-komponen. Saat ini `config/` memakai `PascalCase` (`Identity.ts`, `Metadata.ts`) sedangkan `data/` memakai `camelCase` (`menu.ts`). Tetapkan:
> - Komponen `.tsx` → **PascalCase**
> - Sisanya `.ts` → **kebab-case**

---

## 2. BACKEND (`backend/`)

### 2.1 Struktur saat ini

```
backend/
├── index.js
├── routes.js
├── public/
│   └── index.js            # router publik (/v1/public/stats)
├── config/
│   ├── corsConfig.js
│   ├── cryptoConfig.js
│   ├── identityConfig.js
│   └── socialConfig.js
├── controllers/
│   └── AIController.js
├── middleware/
│   ├── errorHandler.js
│   ├── logger.js
│   └── rateLimiter.js
├── services/
│   ├── ContactHandler.js
│   ├── Crypto.js
│   ├── Github.js
│   ├── UpdateStats.js
│   └── Wakatime.js
├── .env / .env.example
├── package.json
├── README.md
└── vercel.json
```

### 2.2 Masalah yang ditemukan

| No | Masalah | Dampak |
| --- | --- | --- |
| B1 | `public/index.js` adalah **router**, tapi diletakkan di folder `public/` (nama yang biasanya berarti aset statis). Membingungkan saat mencari. | Sulit dicari |
| B2 | Inkonsistensi suffix config: `corsConfig.js`, `cryptoConfig.js`, `identityConfig.js`, `socialConfig.js` — suffix `Config` **redundan** karena sudah ada di dalam folder `config/`. | Nama panjang, tidak clean |
| B3 | Pencampuran gaya nama file: `ContactHandler.js`, `AIController.js`, `Crypto.js`, `Github.js`, `Wakatime.js`, `UpdateStats.js` — tidak konsisten (`UpdateStats` vs `Crypto`). | Sulit diprediksi |
| B4 | `routes.js` di root bercampur dengan entry `index.js`. Tidak ada folder `routes/` yang jelas. | Struktur kurang rapi |
| B5 | Logika handler contact form ditulis langsung di `routes.js` (inline async), bukan di controller. | Melanggar pemisahan layer |
| B6 | `public/` hanya berisi 1 file, dan didaftarkan sebagai router publik non-`/api`. Nama folder menyesatkan. | Sulit dicari |
| B7 | Tidak ada `src/` — kode langsung di root. Untuk repo kecil ini masih OK, tapi tidak konsisten dengan frontend. | Opsional |

### 2.3 Struktur target (rekomendasi)

```
backend/
├── index.js                      # entry: setup app + middleware + listen
├── src/
│   ├── routes/
│   │   ├── index.js              # agregator: daftarkan semua router
│   │   ├── ai.routes.js
│   │   ├── contact.routes.js
│   │   ├── stats.routes.js       # github + wakatime + crypto + social
│   │   └── public.routes.js      # mantan public/index.js
│   ├── controllers/
│   │   ├── ai.controller.js
│   │   ├── contact.controller.js
│   │   ├── github.controller.js
│   │   ├── wakatime.controller.js
│   │   ├── crypto.controller.js
│   │   └── social.controller.js
│   ├── services/
│   │   ├── contact.service.js
│   │   ├── github.service.js
│   │   ├── wakatime.service.js
│   │   ├── crypto.service.js
│   │   └── social.service.js
│   ├── middleware/
│   │   ├── error-handler.js
│   │   ├── logger.js
│   │   └── rate-limiter.js
│   └── config/
│       ├── cors.js
│       ├── crypto.js
│       ├── identity.js
│       └── social.js
├── .env / .env.example
├── package.json
├── README.md
└── vercel.json
```

> **Alternatif lebih ringan** (tanpa `src/`): cukup rename folder `public/` → `routes/`, pindah `routes.js` ke `routes/index.js`, dan normalisasi nama file. Pilih salah satu, jangan setengah-setengah.

### 2.4 Pemetaan rename (dari → ke)

| Dari | Ke | Catatan |
| --- | --- | --- |
| `routes.js` | `src/routes/index.js` | jadi agregator router |
| `public/index.js` | `src/routes/public.routes.js` | **B1, B6** |
| `controllers/AIController.js` | `src/controllers/ai.controller.js` | **B3** |
| *(baru)* | `src/controllers/contact.controller.js` | ekstrak inline handler dari `routes.js` (**B5**) |
| `services/ContactHandler.js` | `src/services/contact.service.js` | **B3** |
| `services/Github.js` | `src/services/github.service.js` | **B3** |
| `services/Wakatime.js` | `src/services/wakatime.service.js` | **B3** |
| `services/Crypto.js` | `src/services/crypto.service.js` | **B3** |
| `services/UpdateStats.js` | `src/services/social.service.js` | **B3** |
| `config/corsConfig.js` | `src/config/cors.js` | **B2** |
| `config/cryptoConfig.js` | `src/config/crypto.js` | **B2** |
| `config/identityConfig.js` | `src/config/identity.js` | **B2** |
| `config/socialConfig.js` | `src/config/social.js` | **B2** |
| `middleware/errorHandler.js` | `src/middleware/error-handler.js` | konsistensi |
| `middleware/rateLimiter.js` | `src/middleware/rate-limiter.js` | konsistensi |
| `middleware/logger.js` | `src/middleware/logger.js` | sudah ok |
| `index.js` | `index.js` (tetap) | entry point |

### 2.5 Perbaikan clean code (backend)

1. **Ekstrak handler inline** di `routes.js` (contact form, wrapper github/wakatime) ke controller masing-masing agar `routes/*.js` hanya berisi deklarasi rute.
2. **Standarkan ekspor** service/controller: gunakan `module.exports = { ... }` konsisten (saat ini `Crypto.js` & `Wakatime.js` pakai `exports.xxx`, sisanya `module.exports`).
3. **Satu sumber config**: `config/identity.js` sudah bagus (kode, bukan env). Pastikan `AIController` tidak lagi bergantung pada env `AI_*` yang disebut di `AGENTS.md` — selaraskan dokumentasi.
4. **Hapus dependency tak terpakai** di `package.json`: `bcrypt`, `bcryptjs`, `googleapis`, `fs`, `mathjs`, `languagedetect`, `string-similarity`, `tinyld`, `body-parser` — verifikasi dulu apakah masih dipakai, lalu hapus yang tidak.
5. **Health-check endpoint** `/health` untuk memudahkan monitoring/verifikasi deploy.

---

## 3. FRONTEND (`frontend/`)

### 3.1 Struktur saat ini

```
frontend/src/
├── App.tsx
├── main.tsx
├── index.css / App.css
├── assets/
├── components/                   # shared UI (mixed folder & flat)
│   ├── AIHelper.tsx, Navbar.tsx, Footer.tsx, ...
│   ├── certificate/CertificateCard.tsx
│   └── github/ContributionsGithub.tsx
├── config/
│   ├── AppConfig.ts, Github.ts, Head.ts, Identity.ts,
│   ├── Instagram.ts, Metadata.ts, Tiktok.ts, Wakatime.ts
├── context/
│   ├── ContainerProvider.tsx
│   ├── ThemeProviderContext.tsx
│   └── WelcomeProvider.tsx
├── data/
│   ├── career.ts, certificate.ts, icons.tsx, menu.ts,
│   ├── projects.ts, services.ts, skills.ts, social.ts
├── layouts/MainLayout.tsx
├── modules/                      # per halaman
│   ├── career/elements/career-view.tsx
│   ├── certificate/components/certificates-grid.tsx
│   ├── contact/elements/contact-form.tsx, recapthcha.tsx, response-message.tsx
│   ├── home/
│   │   ├── index.tsx
│   │   ├── components/*.tsx
│   │   └── section/*.tsx
│   ├── linktree/elements/linktree-box.tsx
│   └── project/elements/projects-grid.tsx
└── pages/                        # file-based routing (vite-plugin-pages)
    ├── index.tsx, career.tsx, certification.tsx,
    ├── linktree.tsx, projects.tsx, talk.tsx, [...all].tsx
```

### 3.2 Masalah yang ditemukan

| No | Masalah | Dampak |
| --- | --- | --- |
| F1 | **Nama folder tidak konsisten di dalam `modules/`**: `elements/` vs `components/` vs `section/`. Fungsinya tumpang tindih. | Sulit dicari |
| F2 | Nama file komponen di `modules/` memakai **kebab-case** (`career-view.tsx`, `certificates-grid.tsx`, `linktree-box.tsx`), sedangkan `components/` global memakai **PascalCase** (`CertificateCard.tsx`). | Tidak konsisten |
| F3 | **Typo: `recapthcha.tsx`** (harusnya `recaptcha`). | Sulit dicari, bug magnet |
| F4 | `components/` bercampur: sebagian flat (`Navbar.tsx`), sebagian nested per-domain (`certificate/`, `github/`). | Pola tidak jelas |
| F5 | `config/` mencampur gaya PascalCase (`Identity.ts`) dengan file yang terasa "data" (`Github.ts`, `Instagram.ts`, `Tiktok.ts` hanya berisi angka statis). | Sulit dibedakan config vs data |
| F6 | `data/icons.tsx` berekstensi `.tsx` di folder `data/` (bukan komponen halaman) — oke secara teknis tapi tidak konsisten. | Minor |
| F7 | Modul `certificate` dan `certification`: nama folder `modules/certificate/` tapi halaman `pages/certification.tsx`. Dua istilah untuk hal yang sama. | Sulit dicari |
| F8 | Modul `project` vs `pages/projects.tsx` (singular vs plural). | Tidak konsisten |
| F9 | Folder `assets/` masih berisi `react.svg` & `vite.svg` (sisa template). | Dead asset |
| F10 | `public/favicon copy.ico` (file duplikat dengan spasi). | Sampah |
| F11 | `components/HelmetContainer.tsx` — nama jelas; tapi pastikan semua halaman memakainya (aturan di `AGENTS.md`). | Konsistensi |
| F12 | Tidak ada barrel file (`index.ts`) per domain, sehingga import panjang: `@/modules/career/elements/career-view`. | Import tidak clean |

### 3.3 Struktur target (rekomendasi)

Standarkan **`modules/<domain>/`** dengan sub-folder yang konsisten: `sections/` (blok halaman) + `components/` (potongan UI domain) + `index.tsx` (entry).

```
frontend/src/
├── App.tsx
├── main.tsx
├── index.css / App.css
├── assets/                       # hanya aset yang di-import JS
├── components/                   # SHARED UI lintas-halaman (PascalCase file)
│   ├── AiHelper.tsx
│   ├── Navbar.tsx
│   ├── Footer.tsx
│   ├── Loading.tsx
│   ├── PageTransition.tsx
│   ├── HelmetContainer.tsx
│   ├── certificate/CertificateCard.tsx
│   └── github/ContributionsGithub.tsx
├── config/                       # semua file kebab-case (.ts)
│   ├── app.ts
│   ├── identity.ts
│   ├── head.ts
│   ├── metadata.ts
│   └── integrations/            # Github/Instagram/Tiktok/Wakatime digabung
│       ├── github.ts
│       ├── instagram.ts
│       ├── tiktok.ts
│       └── wakatime.ts
├── context/                      # semua PascalCase (.tsx, komponen provider)
│   ├── ContainerProvider.tsx
│   ├── ThemeProvider.tsx        # rename dari ThemeProviderContext
│   └── WelcomeProvider.tsx
├── data/                         # data statis murni (.ts)
│   ├── career.ts
│   ├── certificates.ts          # rename certificate.ts (plural, sesuai isi)
│   ├── menu.ts
│   ├── projects.ts
│   ├── services.ts
│   ├── skills.ts
│   ├── social.ts
│   └── icons.tsx
├── layouts/MainLayout.tsx
├── modules/                      # 1 folder = 1 halaman
│   ├── career/
│   │   ├── index.tsx
│   │   └── components/CareerView.tsx
│   ├── certification/           # rename dari certificate/ (samakan dgn route)
│   │   ├── index.tsx
│   │   └── components/CertificatesGrid.tsx
│   ├── contact/
│   │   ├── index.tsx            # (jika perlu)
│   │   └── components/
│   │       ├── ContactForm.tsx
│   │       ├── Recaptcha.tsx    # fix typo recapthcha
│   │       └── ResponseMessage.tsx
│   ├── home/
│   │   ├── index.tsx
│   │   ├── components/
│   │   │   ├── CertificateItem.tsx
│   │   │   ├── CryptoPrice.tsx
│   │   │   ├── ProjectItem.tsx
│   │   │   ├── Service.tsx
│   │   │   └── SkillIcon.tsx
│   │   └── sections/            # rename dari section/ (plural)
│   │       ├── About.tsx
│   │       ├── Certification.tsx
│   │       ├── Header.tsx
│   │       ├── RecentProjects.tsx
│   │       ├── Services.tsx
│   │       ├── Skills.tsx
│   │       └── SubHeader.tsx
│   ├── linktree/
│   │   ├── index.tsx
│   │   └── components/LinktreeBox.tsx
│   └── projects/                # rename dari project/ (plural = route)
│       ├── index.tsx
│       └── components/ProjectsGrid.tsx
└── pages/                        # tetap: file-based routing
    ├── index.tsx
    ├── career.tsx
    ├── certification.tsx
    ├── linktree.tsx
    ├── projects.tsx
    ├── talk.tsx
    └── [...all].tsx
```

### 3.4 Pemetaan rename (dari → ke)

| Dari | Ke | Alasan |
| --- | --- | --- |
| `modules/career/elements/career-view.tsx` | `modules/career/components/CareerView.tsx` | **F1, F2** |
| `modules/certificate/…` | `modules/certification/components/CertificatesGrid.tsx` | **F1, F2, F7** |
| `modules/contact/elements/contact-form.tsx` | `modules/contact/components/ContactForm.tsx` | **F1, F2** |
| `modules/contact/elements/recapthcha.tsx` | `modules/contact/components/Recaptcha.tsx` | **F2, F3** |
| `modules/contact/elements/response-message.tsx` | `modules/contact/components/ResponseMessage.tsx` | **F1, F2** |
| `modules/home/components/certificate-component.tsx` | `modules/home/components/CertificateItem.tsx` | **F2** |
| `modules/home/components/cryptocurrency-price.tsx` | `modules/home/components/CryptoPrice.tsx` | **F2** |
| `modules/home/components/project-component.tsx` | `modules/home/components/ProjectItem.tsx` | **F2** |
| `modules/home/components/service.tsx` | `modules/home/components/Service.tsx` | **F2** |
| `modules/home/components/skill-icon.tsx` | `modules/home/components/SkillIcon.tsx` | **F2** |
| `modules/home/section/*.tsx` | `modules/home/sections/*.tsx` + PascalCase | **F1, F2** |
| `modules/linktree/elements/linktree-box.tsx` | `modules/linktree/components/LinktreeBox.tsx` | **F1, F2** |
| `modules/project/…` | `modules/projects/components/ProjectsGrid.tsx` | **F2, F8** |
| `config/AppConfig.ts` | `config/app.ts` | **F5** |
| `config/Github.ts` dll. | `config/integrations/github.ts` | **F5** |
| `context/ThemeProviderContext.tsx` | `context/ThemeProvider.tsx` | naming bersih |
| `data/certificate.ts` | `data/certificates.ts` | plural konsisten |
| `public/favicon copy.ico` | *(hapus)* | **F10** |
| `src/assets/react.svg`, `vite.svg` | *(hapus jika tak dipakai)* | **F9** |

> **Catatan penting:** setiap rename **wajib** diikuti update import (frontend pakai alias `@/…`). Untuk komponen yang diimpor dari `modules/home/index.tsx` dan `pages/*.tsx`, jangan lupa perbarui path.

### 3.5 Perbaikan clean code (frontend)

1. **Barrel export (opsional tapi disarankan)** tiap modul: `modules/home/index.ts` re-export komponen kunci agar import ringkas.
2. **Pisahkan config vs data** tegas: `config/` = konfigurasi & metadata, `data/` = konten statis. Hindari file `config/Instagram.ts` yang isinya sekadar angka → pindah ke `data/social.ts` (sudah ada) atau `config/integrations/`.
3. **Type ketat**: ganti banyak `any` (mis. `Navbar.tsx` pakai `menu: any`) dengan tipe dari `data/menu.ts` — perbaiki definisi tipe `Menu`.
4. **Nomor pesan duplikat**: `pages/certification.tsx` vs `modules/certificate` — satukan jadi satu istilah `certification`.
5. **Nama variabel/komponen** konsisten: `RecentProjects`, `ServicesSection` → `RecentProjectsSection` / `ServicesSection` (pilih pola `*Section` untuk bagian halaman).
6. **Hapus dead asset** (`react.svg`, `vite.svg`, `favicon copy.ico`).
7. **`vite-env.d.ts`**: sinkronkan `ImportMetaEnv` dengan `.env.example`.

---

## 4. Checklist Eksekusi (urutan aman)

**Backend**
- [ ] Buat folder `src/` (jika memakai opsi lengkap) dan pindahkan `config/`, `controllers/`, `middleware/`, `services/`, `routes/`.
- [ ] Rename file sesuai tabel §2.4 (lakukan dengan `git mv` agar history terjaga).
- [ ] Ekstrak handler inline `contact` & wrapper `github/wakatime` dari `routes.js` ke controller.
- [ ] Pindahkan `public/index.js` → `routes/public.routes.js`.
- [ ] Update semua `require()` mengikuti path baru.
- [ ] Selaraskan `module.exports` (semua pakai objek yang sama polanya).
- [ ] Audit & hapus dependency tak terpakai di `package.json`.
- [ ] Tambah endpoint `/health`.
- [ ] Jalankan `npm run dev` dan uji semua endpoint.

**Frontend**
- [ ] Rename file/folder sesuai tabel §3.4 (pakai `git mv`).
- [ ] Standarkan sub-folder module: `sections/` + `components/` + `index.tsx`.
- [ ] Fix typo `recapthcha` → `recaptcha`.
- [ ] Update semua import `@/…`.
- [ ] Hapus dead asset (`react.svg`, `vite.svg`, `favicon copy.ico`).
- [ ] Perbaiki tipe `any` → tipe konkret.
- [ ] Selaraskan `ImportMetaEnv` di `vite-env.d.ts`.
- [ ] Jalankan `npm run dev` dan cek tiap route: `/`, `/career`, `/certification`, `/linktree`, `/projects`, `/talk`.

---

## 5. Verifikasi Akhir

- [ ] Tidak ada import yang menunjuk path lama (`grep` untuk nama lama).
- [ ] Tidak ada dua istilah untuk hal yang sama (certificate vs certification, project vs projects).
- [ ] Tidak ada file `* copy.*`, `*.svg` template, atau file kosong.
- [ ] Semua komponen halaman render `<HelmetContainer page="..." />` (aturan `AGENTS.md`).
- [ ] Struktur folder bisa ditebak: `modules/<fitur>/` untuk halaman, `components/` untuk shared, `data/` untuk konten, `config/` untuk konfigurasi.

---

## 6. Ringkasan Prioritas

| Prioritas | Item | Alasan |
| --- | --- | --- |
| 🔴 Tinggi | Fix typo `recapthcha` (**F3**) | Bug magnet, mudah dicari |
| 🔴 Tinggi | Samakan istilah `certificate` ↔ `certification` (**F7**) | Sulit dicari |
| 🔴 Tinggi | Rename `public/` → `routes/` di backend (**B1, B6**) | Nama menyesatkan |
| 🟠 Sedang | Standarkan `modules/`: `elements`/`section` → `components`/`sections` (**F1**) | Konsistensi |
| 🟠 Sedang | Samakan kasus nama file (**B3, F2**) | Prediktabilitas |
| 🟠 Sedang | Hapus suffix `Config` redundan di backend (**B2**) | Clean code |
| 🟢 Rendah | Hapus dead asset & dependency tak terpakai (**F9, F10, B4**) | Kebersihan |
| 🟢 Rendah | Barrel export & tipe ketat (**F12, §3.5**) | DX |
```
