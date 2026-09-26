# AGENTS.md

Personal portfolio (`fiqtor.com`). Root repo tracks two submodules:

- `frontend/`: React SPA (Vercel)
- `backend/`: Express API (Vercel)

Scope git commands per repo: `git -C frontend ...` or `git -C backend ...`.
Publishing a change therefore has two steps — commit/push inside the submodule,
then bump the pointer in the root. Use `scripts/push-submodules.sh -m "..."` to
do both at once (see script header for flags).

Full-stack docs live in `README.md` (root), `backend/README.md`, `frontend/README.md`.

---

## ⛔ EXECUTION & TOKEN SAFETY (STRICT)

1. **No Auto Build/Lint:** NEVER run `npm run build`, `npx tsc`, or `eslint` unless explicitly instructed.
2. **Strict Exclusions:** NEVER read/scan `node_modules`, `dist`, `build`, `.git`, `.next`, `coverage`, lock files (`*.lock`, `*-lock.yaml`), `.env*`, `.log`, or binary/media assets.
3. **Headroom & Targeted Tooling:**
   - Active context max 2-3 files. Drop unneeded files.
   - Use `grep` / `glob` for searching; do NOT read whole directories.
   - Use `offset`/`limit` in `read` tool for files > 100 lines.
   - Prefer surgical `edit` tool calls over overwriting whole files (`write`).
   - Batch independent tool calls in a single response.
4. **Code Quality & Zero Noise:**
   - Strict TS typings. No `any` unless required.
   - Zero residual code: strip unused imports, dead vars, commented code, temporary `console.log`.
   - Mimic existing code conventions and folder patterns.

---

## ⚡ FRONTEND (`frontend/`)

- **Tech:** React SPA, Vite, TypeScript (strict), Tailwind v4 (`@tailwindcss/vite`), `next-themes`.
- **Routing:** File-based via `vite-plugin-pages` (`src/pages/*.tsx`).
  - `src/pages/` are thin wrappers importing modules from `src/modules/<page>/`.
  - Shared UI: `src/components/`. Static data: `src/data/`.
  - Every page MUST render `<HelmetContainer page="..." />` (see `src/config/Metadata.ts`).
- **AI helper:** `src/components/AIHelper.tsx` is a thin orchestrator; logic lives in `src/components/ai/` (hooks `useAIChat`, `useSpeechDictation`, `useFileAttachment` + components `AIMessageList`, `AIComposer`, shared `types.ts`).
- **Contexts:** `ContainerContext` / `WelcomeContext` live in `src/context/*-context.ts` (separate from their providers for Fast Refresh). Import the context from the `*-context` file, the provider component from `*Provider`. `fullPathName` is derived from `useLocation()` inside `ContainerProvider` (single source of truth) — do NOT store route state manually.
- **Layout tokens:** use the `.page-x` and `.page-base` utility classes (defined in `src/index.css`) for page padding + base text instead of ad-hoc `px-7 md:px-24` etc.
- **Modals/dialogs:** use `useFocusTrap(active, onClose)` (`src/hooks/useFocusTrap.ts`) for focus trapping, Escape-to-close and focus restore. Icon-only buttons MUST have `aria-label`; live regions use `role="status"` + `aria-live`.
- **Tests:** Vitest (`npm test`), config in `vitest.config.ts`, setup in `src/test/setup.ts`; test files sit next to source as `*.test.ts(x)`.
- **Aliases:** `@/*` maps to `src/*` (always use `@/...` imports).
- **API Base:** `${import.meta.env.VITE_API_BASE_URL}/v1/...` (Base URL ends in `/api`).
- **Config is env-driven:** all branding/identity/SEO values come from `src/config/Identity.ts` and `src/config/Head.ts` (which read `VITE_*`). Do NOT hardcode personal data or brand strings in components.
- **`<head>` + `sitemap.xml` + `robots.txt`** are generated at build time by `htmlHeadPlugin` (`vite.config.ts`) from `src/config/Head.ts`. Do NOT edit `index.html` directly and do NOT add static `sitemap.xml`/`robots.txt` to `public/`.
- **New env key?** Add it to `frontend/.env.example` AND to the `ImportMetaEnv` interface in `src/vite-env.d.ts`.

---

## ⚡ BACKEND (`backend/`)

- **Tech:** CommonJS (Express 4). `index.js` (bootstrap/`listen`) → `src/app.js` (`createApp()` builds the app, exported for tests) → `src/routes/index.js` → `src/controllers/` + `src/services/`.
- **AI:** Google Gemini (`@google/genai`, `GEMINI_API_KEY`) in `src/controllers/ai.controller.js`; client is lazy + injectable via `setAiClient()` (test seam); identity from `src/config/identity.js`.
- **Integrations:** WhatsApp/Meta Cloud API + Email (SMTP) in `src/services/contact.service.js` (exposes `createMessagingService(deps)` for injectable transports); GitHub (`src/services/github.service.js`); WakaTime (`src/services/wakatime.service.js`, with timeout/retry/cache).
- **Public Stats:** `/v1/public/stats` (mounted outside `/api`).
- **Rate limiting:** `src/middleware/rate-limiter.js` exports `apiLimiter` (global), `statsLimiter`, `contactLimiter`, `aiLimiter` + `aiDailyLimiter` (daily AI quota).
- **Tests:** Vitest + supertest (`npm test`), config `vitest.config.mjs`, tests in `tests/*.test.js`.
- **Env Sync:** Always sync new env keys to `.env.example`. All secrets come from env — never hardcode.

---

## 🔒 SECURITY

- NEVER read, edit, parse, or output any `.env` file or its values in outputs, diffs, or commits.
- If you need the env structure, refer ONLY to `.env.example`.
- NEVER commit or print service-account JSON keys, API tokens, or personal data.
- `VITE_*` values are PUBLIC (browser bundle) — never place real secrets behind `VITE_`.
- Keep secrets server-side (backend env only). Rotate anything ever committed.

---

## 🤖 OUTPUT FORMAT

- CAVEMAN MODE active: no intros, no conversational fluff, no code explanations unless requested.
- Direct, working code + ultra-concise responses (< 3 lines when non-code).

Do not output <thinking></thinking> tags or any internal reasoning chain in the final response. Output only the final answer directly.
