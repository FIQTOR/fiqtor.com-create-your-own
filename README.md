<div align="center">

# 🚀 Personal Portfolio Website

**A modern, full-stack personal portfolio template** — built with React 19 + Vite (frontend) and Node.js + Express (backend).

AI chatbot · Contact form (WhatsApp + Email) · GitHub & WakaTime stats · Certifications · Projects · Career timeline · Multi-language resume

</div>

<img src="/img/thumbnail.png" alt="thumbnail.png">

---

## 📑 Table of Contents

- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Configuration](#-configuration)
  - [Backend Environment Variables](#backend-environment-variables-backendenv)
  - [Frontend Environment Variables](#frontend-environment-variables-frontendenv)
  - [Customizing Your Portfolio Content](#customizing-your-portfolio-content)
- [Running the Project](#-running-the-project)
- [Available Scripts](#-available-scripts)
- [API Endpoints](#-api-endpoints)
- [Deployment](#-deployment)
- [Security Notes](#-security-notes)
- [Troubleshooting](#-troubleshooting)
- [License](#-license)

---

## ✨ Features

- 🤖 **AI Assistant** — Context-aware chatbot (Google Gemini / Groq) that answers questions about you.
- 📬 **Contact Form** — Sends notifications via WhatsApp Business API with automatic Email (SMTP) fallback.
- 📊 **Live Stats** — GitHub contribution graph and WakaTime coding activity.
- 🎨 **Modern UI** — Tailwind CSS v4, Framer Motion animations, dark/light theme, 3D & Lottie effects.
- 🗂️ **Portfolio Sections** — Projects, career timeline, certifications, skills, services.
- 💰 **Crypto Widget** — Static BTC/ETH/SOL prices served by the backend (no third-party API key to leak).
- 🔍 **SEO Ready** — Structured data (JSON-LD), OpenGraph, Twitter cards, sitemap, robots.
- 🌐 **Fully Configurable** — Personal/brand data lives in `frontend/src/config/Identity.ts` (code) and a few `VITE_*` env vars (no editing components needed).
- 📱 **Responsive** — Mobile-first design with a classic linktree page.

---

## 🛠 Tech Stack

| Layer      | Technology                                                                                     |
| ---------- | ---------------------------------------------------------------------------------------------- |
| **Frontend** | React 19, TypeScript, Vite, Tailwind CSS v4, Framer Motion, React Router, react-helmet-async |
| **Backend**  | Node.js 20, Express, Axios, Nodemailer, Helmet, express-rate-limit                            |
| **AI**       | `@google/genai` (Gemini), `groq-sdk` (Groq)                                                     |
| **Services** | WhatsApp Cloud API, Gmail SMTP, GitHub GraphQL, WakaTime, reCAPTCHA |
| **Deploy**   | Vercel (frontend + backend)                                                                     |

---

## 📂 Project Structure

```
personal-website/
├── backend/
│   ├── config/              # CORS + static identity/crypto/social data
│   ├── controllers/         # AI, Application, Product controllers
│   ├── middleware/          # rate limiter, logger, error handler
│   ├── services/            # Contact (WA+Email), GitHub, WakaTime, Crypto, Stats
│   ├── public/              # public routes
│   ├── index.js             # 🚀 server entry point
│   ├── routes.js            # all API routes
│   ├── .env.example         # backend env template
│   └── vercel.json
│
└── frontend/
    ├── public/              # static assets (images, pdf, favicon)
    │   ├── img/             # project/company images
    │   └── pdf/             # resume files
    │   # sitemap.xml + robots.txt are GENERATED at build time (not stored here)
    ├── src/
    │   ├── components/      # shared UI components (Navbar, Footer, AIHelper…)
    │   ├── config/          # ⚙️ Identity.ts (code-based branding), Metadata, Head, integrations
    │   ├── context/         # React contexts (theme, container, welcome)
    │   ├── data/            # 📝 YOUR CONTENT: projects, career, certificates…
    │   ├── layouts/         # layout wrappers
    │   ├── modules/         # feature modules (home, contact, linktree…)
    │   ├── pages/           # route pages (file-based routing)
    │   ├── App.tsx          # app shell
    │   └── main.tsx         # entry point
    ├── index.html           # minimal shell (head injected at build from src/config/Head.ts)
    ├── vite.config.ts       # includes htmlHeadPlugin (head + sitemap + robots)
    └── .env.example         # frontend env template
```

> 💡 **Key idea:** Personal/brand data → **env vars** (`.env`). Portfolio content (projects, certificates, career) → **`src/data/*.ts`**. The `<head>` metadata is generated at build time from **`src/config/Head.ts`**.

---

## ✅ Prerequisites

Make sure you have installed:

- [Node.js](https://nodejs.org/) **v20.x or higher** (required by backend `engines`)
- [npm](https://www.npmjs.com/) (comes with Node) — or `pnpm` / `yarn`
- [Git](https://git-scm.com/)

---

## 📦 Installation

### 1. Clone the repository

```bash
git clone https://github.com/<your-username>/personal-website.git
cd personal-website
```

### 2. Install backend dependencies

```bash
cd backend
npm install
```

### 3. Install frontend dependencies

```bash
cd ../frontend
npm install
```

### 4. Create environment files

Copy the example files and fill in your own values (see [Configuration](#-configuration)):

```bash
# Backend
cd ../backend
cp .env.example .env

# Frontend
cd ../frontend
cp .env.example .env
```

---

## ⚙️ Configuration

All configuration is done through environment variables. **Never commit your real `.env` files** — they are already excluded in `.gitignore`.

- **Backend** → `backend/.env`
- **Frontend** → `frontend/.env`

> ⚠️ Any variable starting with `VITE_` is embedded into the **public browser bundle**. Never put true secrets (API secrets, private tokens) in a `VITE_` variable. Branding/identity is code-based in `frontend/src/config/Identity.ts`; backend identity/social in `backend/config/identityConfig.js`.

### Backend Environment Variables (`backend/.env`)

| Variable                | Required | Description                                                                 |
| ----------------------- | :------: | --------------------------------------------------------------------------- |
| `NODE_ENV`              |    ✅    | `development` or `production`                                               |
| `APP_PORT`              |    ✅    | Server port (default `4000`)                                                |
| `FRONTEND_HOST`         |    ✅    | Allowed CORS origin(s), e.g. `http://localhost:5173`                        |
| **AI**                  |          |                                                                             |
| `GEMINI_API_KEY`        |    ✅    | Google Gemini key — https://aistudio.google.com/app/apikey                  |
| `GROQ_API_KEY`          |    ⬜    | Groq key (optional) — https://console.groq.com/keys                        |
| **Identity / Social**   |    —     | **Not env** → code in `backend/config/identityConfig.js` (brand, owner, company, social URLs) |
| **Email / SMTP**        |          |                                                                             |
| `EMAIL_HOST`            |    ✅    | SMTP host, e.g. `smtp.googlemail.com`                                       |
| `EMAIL_PORT`            |    ✅    | SMTP port, e.g. `465`                                                       |
| `EMAIL_USERNAME`        |    ✅    | SMTP username (your Gmail)                                                  |
| `EMAIL_PASSWORD`        |    ✅    | Gmail **App Password** — https://myaccount.google.com/apppasswords          |
| `EMAIL_RECIPIENT`       |    ✅    | Email that receives contact form submissions                                 |
| `EMAIL_BUSINESS`        |    ⬜    | Optional public business email                                              |
| **WhatsApp / Meta**     |    ⬜    | `APP_ID`, `APP_SECRET`, `RECIPIENT_WAID`, `VERSION`, `PHONE_NUMBER_ID`, `ACCESS_TOKEN` |
| **GitHub**              |    ⬜    | `GITHUB_USERNAME`, `GITHUB_TOKEN` — https://github.com/settings/tokens      |
| **WakaTime**            |    ⬜    | `WAKATIME_APP_SECRET` — https://wakatime.com/settings/api                   |
| `WAKATIME_TIMEOUT_MS`   |    ⬜    | Request timeout in ms (default `8000`)                                      |
| `WAKATIME_MAX_RETRIES`  |    ⬜    | Retries on transient errors (default `2`)                                   |
| `WAKATIME_CACHE_TTL_MS` |    ⬜    | Cache TTL in ms (default `300000` = 5 min)                                  |
| **Google Sheets**       |    ⬜    | `GOOGLE_CLIENT_EMAIL`, `GOOGLE_PRIVATE_KEY`, `GOOGLE_SHEET_ID`, `SHEET_SECRET_KEY` |
| **Security**            |    ✅    | `APP_KEY_HASH` (bcrypt hash)                                                |

> 💡 **AI identity & social URLs are code-based** — `backend/config/identityConfig.js` (not secrets, so kept out of `.env`).

> 💡 **Crypto & social stats are static** — no env vars, no third-party API. Edit `backend/config/cryptoConfig.js` and `backend/config/socialConfig.js` and restart the server.

### Frontend Environment Variables (`frontend/.env`)

Only a few values remain in env — identity/branding moved into code (`frontend/src/config/Identity.ts`).

| Variable                  | Required | Description                                                       |
| ------------------------- | :------: | ----------------------------------------------------------------- |
| `VITE_DOMAIN`             |    ⬜    | Optional site-origin override (defaults to `SITE_ORIGIN` in `src/config/Identity.ts`) |
| `VITE_API_BASE_URL`       |    ✅    | Backend API URL, e.g. `http://localhost:4000/api`                 |
| `VITE_RECAPTCHA_SITE_KEY` |    ⬜    | reCAPTCHA **site** key — https://www.google.com/recaptcha/admin   |
| `VITE_ENABLE_AI`          |    ⬜    | `TRUE` / `FALSE` to toggle AI features                            |

> 📌 **Branding, owner identity, contact, social URLs, resume paths, company brand, site origin and GA ID** are code in [`frontend/src/config/Identity.ts`](frontend/src/config/Identity.ts). Integration usernames live in `src/config/{Github,Wakatime,Instagram,Tiktok}.ts`. **No `VITE_*` API keys exist.**

### Customizing Your Portfolio Content

Beyond env vars, edit these files in `frontend/src/data/` to replace the sample content with your own:

| File               | What it controls                                             |
| ------------------ | ----------------------------------------------------------- |
| `projects.ts`      | Project portfolio (title, image, description, links, tags)  |
| `career.ts`        | Work experience timeline                                    |
| `certificate.ts`   | Certificates, awards & credentials                          |
| `skills.ts`        | Skill icons & stack                                         |
| `services.ts`      | Services offered                                            |
| `menu.ts`          | Navigation menu items                                       |
| `social.ts`        | Social links (wired to `Identity.ts`)                       |
| `icons.tsx`        | Custom SVG icon components                                  |

> 📄 **`index.html` `<head>` metadata** (title, meta, OpenGraph, Twitter, JSON-LD, Google Analytics) is **generated at build time** from [`src/config/Head.ts`](frontend/src/config/Head.ts) via the `htmlHeadPlugin` in [`vite.config.ts`](frontend/vite.config.ts). You don't edit `index.html` directly — change the values in `Head.ts` (they read from the same `VITE_*` env vars), and the correct tags are injected automatically for both dev and production builds. This guarantees crawlers that don't run JavaScript still see accurate metadata.

> 🗺️ **`sitemap.xml` and `robots.txt` are also generated at build time** from `VITE_DOMAIN` (see `renderSitemap` / `renderRobots` in `Head.ts`) — no static files to maintain, no hardcoded domain in the repo. They are emitted to `dist/` on build and served automatically by the dev server.

> 🔑 **Google / Bing site-verification files** (e.g. `google*.html`, `BingSiteAuth.xml`) are intentionally **not** included — add your own verification file to `frontend/public/` after cloning if you need search-console verification.

Also replace the assets in `frontend/public/`:
- `img/projects/*` — project thumbnails
- `img/career/*` — company logos
- `img/certificate/*` — certificate images
- `pdf/*` — your resume files (update the paths in `frontend/src/config/Identity.ts` → `RESUME` to match your file names)
- `icon.webp`, `favicon.ico` — your logo/favicon

> `sitemap.xml` and `robots.txt` are **generated automatically** — do not add them to `public/`.

---

## ▶️ Running the Project

You need **two terminals** — one for backend, one for frontend.

**Terminal 1 — Backend:**
```bash
cd backend
npm run dev          # nodemon, auto-reload
# or
npm start            # production mode
```
Backend runs at **http://localhost:4000**

**Terminal 2 — Frontend:**
```bash
cd frontend
npm run dev
```
Frontend runs at **http://localhost:5173**

Open http://localhost:5173 in your browser. 🎉

---

## 📜 Available Scripts

### Frontend (`frontend/`)

| Command             | Description                                |
| ------------------- | ------------------------------------------ |
| `npm run dev`       | Start dev server with HMR                  |
| `npm run build`     | Type-check + build for production          |
| `npm run preview`   | Preview the production build locally       |
| `npm run lint`      | Run ESLint                                 |

### Backend (`backend/`)

| Command         | Description                          |
| --------------- | ------------------------------------ |
| `npm run dev`   | Start with nodemon (auto-reload)     |
| `npm start`     | Start the server                     |

---

## 🔌 API Endpoints

All endpoints are served under `/api` (backend base URL).

| Method   | Endpoint                              | Description                          |
| -------- | ------------------------------------- | ------------------------------------ |
| `POST`   | `/api/v1/ai/generate`                 | AI chat completion                   |
| `POST`   | `/api/v1/contact/send`                | Contact form (WhatsApp → Email)      |
| `GET`    | `/api/v1/github/contributions`        | GitHub contribution stats            |
| `GET`    | `/api/v1/wakatime`                    | WakaTime coding stats                |
| `GET`    | `/api/v1/crypto`                      | Static BTC/ETH/SOL prices            |
| `GET`    | `/api/v1/social/stats`                | Static TikTok/Instagram stats        |
| `GET`    | `/v1/public/stats`                    | Public social stats (same static data) |
| `GET`    | `/api/v1/products`                    | List products                        |
| `GET`    | `/api/v1/product/:row`                | Get a product                        |
| `POST`   | `/api/v1/product`                     | Create a product                     |
| `POST`   | `/api/v1/product/:row/update`         | Update a product                     |
| `POST`   | `/api/v1/product/:row/delete`         | Delete a product                     |
| `POST`   | `/api/v1/s/product`                   | Search products                      |
| `POST`   | `/api/v1/createentry`                 | Create application entry             |
| `GET`    | `/api/v1/readentries`                 | Read application entries             |
| `PUT`    | `/api/v1/updateentry`                 | Update application entry             |
| `DELETE` | `/api/v1/deleteentry`                 | Delete application entry             |

---

## 🚢 Deployment

Both apps are configured for **Vercel** (`vercel.json` included in each folder).

### Backend
1. Import the `backend/` folder as a Vercel project.
2. Add all backend env vars in **Settings → Environment Variables**.
3. Set `FRONTEND_HOST` to your production frontend URL (for CORS).
4. Deploy.

### Frontend
1. Import the `frontend/` folder as a Vercel project.
2. Add all `VITE_*` env vars in **Settings → Environment Variables**.
3. Set `VITE_DOMAIN` to your production domain and `VITE_API_BASE_URL` to your deployed backend URL.
4. Deploy.

> The frontend `vercel.json` rewrites all routes to `/index.html` (SPA routing), while keeping `sitemap.xml` and `robots.txt` intact.

---

## 🔒 Security Notes

- ❌ **Never commit `.env`** — real env files are ignored via `.gitignore`. Only `.env.example` is committed.
- 🔑 **Rotate secrets** if they were ever committed to git. Purge history with [`git filter-repo`](https://github.com/newren/git-filter-repo) or [BFG](https://rtyley.github.io/bfg-repo-cleaner/) and force-push.
- 🧾 Any `VITE_*` value is **public** (shipped to the browser). Keep secrets server-side only.
- 🔐 **No third-party API keys ship to the client.** Crypto prices and social stats are served by the backend as static data; integration usernames live in `src/config/*.ts`. If you ever switch to a live provider, proxy it through the backend — never expose the key via `VITE_*`.
- 🚫 **No secrets, tokens, personal data, or verification files are committed to this repo** — everything sensitive lives in `.env` (gitignored). The only `.env` tracked is `.env.example` (placeholders).
- 🛡️ The backend uses Helmet, HPP, rate limiting, and CORS — keep these enabled in production.
- 🔐 Generate `APP_KEY_HASH` securely, e.g.:
  ```bash
  node -e "console.log(require('bcrypt').hashSync(require('crypto').randomBytes(24).toString('hex'), 10))"
  ```

---

## 🧰 Troubleshooting

| Problem                              | Fix                                                                                     |
| ------------------------------------ | --------------------------------------------------------------------------------------- |
| `Cannot find module './controllers/...'` | Ensure all controller files exist in `backend/controllers/`.                          |
| CORS error in browser                | Set `FRONTEND_HOST` in `backend/.env` to your frontend origin.                          |
| AI not responding                    | Verify `GEMINI_API_KEY` (backend) and `VITE_API_BASE_URL` (frontend).                   |
| Contact form fails                   | Check `EMAIL_*` / WhatsApp vars; the backend falls back to email if WhatsApp fails.     |
| `.env` values not applying           | Restart the dev server (env vars are read on startup).                                  |
| GitHub/WakaTime stats empty          | Set the relevant tokens/usernames in `backend/.env`.                                    |
| WakaTime times out (ETIMEDOUT)       | Network/IPv6 issue — the service already retries + caches. Tune via `WAKATIME_TIMEOUT_MS`, `WAKATIME_MAX_RETRIES`, `WAKATIME_CACHE_TTL_MS` in `backend/.env`. |
| Sitemap/robots show wrong domain     | Set `VITE_DOMAIN` in `frontend/.env` and rebuild — they are generated from it.           |

---

## 📄 License

ISC — free to use as a template. Attribution appreciated but not required.

---

<div align="center">

**Built with ❤️ — happy coding!**

</div>
