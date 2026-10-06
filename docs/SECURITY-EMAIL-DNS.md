# Email & DNS Security (SPF, DKIM, DMARC, MTA-STS, HSTS)

This document covers the DNS + email-authentication setup for the `fiqtor.com`
portfolio, which uses **Gmail / Google Workspace SMTP** to send contact-form
notifications and a **Cloudflare**-managed DNS zone.

> ✅ Goal: make the contact form's outgoing mail land in inboxes (not spam),
> prove the domain is authenticating its mail, and lock down transport + web
> security. None of these records contain secrets — they are all public DNS.

---

## 1. SPF — authorise senders

SPF (TXT on the apex) lists which servers may send mail for the domain. With
Google Workspace + the contact form sending via Gmail SMTP, a single Google
include is enough.

| Type | Name | Value | TTL |
| ---- | ---- | ----- | --- |
| TXT  | `@`  | `v=spf1 include:_spf.google.com ~all` | Auto |

- Use `~all` (soft-fail) while testing; tighten to `-all` (hard-fail) once you've
  confirmed **every** legitimate sender is listed.
- **One SPF record only.** Multiple `v=spf1` records break SPF. If another
  service (e.g. a newsletter tool) sends mail, merge its `include:` into this
  single record.

---

## 2. DKIM — sign outgoing mail

Google Workspace signs mail with a DKIM key you generate in the Admin console
(**Apps → Google Workspace → Gmail → Authenticate email**).

1. Generate a 2048-bit key for your domain; Google shows a TXT name + value.
2. Add the record it gives you (name is typically `google._domainkey`):

| Type | Name | Value | TTL |
| ---- | ---- | ----- | --- |
| TXT  | `google._domainkey` | `v=DKIM1; k=rsa; p=<public-key-from-google>` | Auto |

3. Back in the Admin console, click **Start authentication**.

> ⚠️ Keep the **selector** (`google`) consistent between the DNS record and the
> `s=` tag your mail uses. Rotate the key periodically.

---

## 3. DMARC — policy + reporting

DMARC tells receivers what to do when SPF/DKIM fail, and where to send reports.

| Type | Name | Value | TTL |
| ---- | ---- | ----- | --- |
| TXT  | `_dmarc` | `v=DMARC1; p=none; rua=mailto:dmarc@fiqtor.com; ruf=mailto:dmarc@fiqtor.com; fo=1; adkim=s; aspf=s` | Auto |

Rollout, in order:

1. **`p=none`** — monitor only. Watch `rua` aggregate reports (use a free
   analyser like `dmarcian` or Google Postmaster Tools) for 2–4 weeks.
2. **`p=quarantine`** — start routing failing mail to spam.
3. **`p=reject`** — reject outright. This is the target end-state.

- `adkim=s` / `aspf=s` demand **strict** alignment (header From matches the
  DKIM/SPF domain exactly) — correct when both send from `fiqtor.com`.
- If you relay through a subdomain, relax to `r` (relaxed) instead.

---

## 4. MTA-STS — enforce TLS for inbound SMTP

MTA-STS lets receiving MTAs require TLS when delivering to your domain.

1. Serve a policy file at `https://mta-sts.fiqtor.com/.well-known/mta-sts.txt`:

   ```txt
   version: STSv1
   mode: enforce
   mx: smtp.google.com
   max_age: 604800
   ```

   Start with `mode: testing` until reports look clean, then switch to `enforce`.

2. Publish the policy pointer:

   | Type | Name | Value | TTL |
   | ---- | ---- | ----- | --- |
   | TXT  | `_mta-sts` | `v=STSv1; id=20260101T000000;` | Auto |

   Bump `id` whenever you change the policy file so receivers re-fetch it.

3. The `mta-sts` subdomain must be reachable over **valid HTTPS** (a Cloudflare
   proxied record + edge certificate works).

---

## 5. TLS-RPT — reports for MTA-STS

| Type | Name | Value | TTL |
| ---- | ---- | ----- | --- |
| TXT  | `_smtp._tls` | `v=TLSRPTv1; rua=mailto:tlsrpt@fiqtor.com` | Auto |

---

## 6. HSTS — enforce HTTPS for the web app

HSTS is already sent by the backend via `helmet` (`strictTransportSecurity` in
`backend/src/app.js`: 2 years, `includeSubDomains`, `preload`). To make browsers
honour it from the first visit, also add the preload record and submit the
domain to the preload list.

| Type | Name | Value | TTL |
| ---- | ---- | ----- | --- |
| HTTPS (or TXT alias) | `@` | `max-age=63072000; includeSubDomains; preload` | Auto |

> ⚠️ Only `preload` if **every** current and future subdomain is HTTPS-only —
> removal from the preload list is slow. Until then, keep the `includeSubDomains`
> flag but drop `preload`.

---

## 7. Subdomain hygiene

- Add explicit `A`/`AAAA`/`CNAME` records for every subdomain you actually use
  (`www`, `mta-sts`, `api`). Delete stale ones.
- Avoid a wildcard `*` record — it widens your attack surface and can silently
  receive mail/HTTP you didn't intend.
- For the Vercel-hosted apps, point `api` (backend) and the apex/`www`
  (frontend) at Vercel's recommended targets via Cloudflare **DNS-only** (grey
  cloud) unless you need Cloudflare's proxy features.

---

## 8. Verification checklist

- [ ] Single SPF record present; `~all` → `-all` once senders are confirmed.
- [ ] DKIM selector published and "authentication started" in Google Admin.
- [ ] DMARC published; aggregate reports arriving; progressed to `p=reject`.
- [ ] MTA-STS policy served over HTTPS; `id` bumped on every change.
- [ ] TLS-RPT reporting address live.
- [ ] HSTS header confirmed (see below) and preload submitted (if applicable).
- [ ] No wildcard record; stale subdomains removed.

Quick checks:

```bash
# SPF / DKIM / DMARC / MTA-STS / TLS-RPT
dig +short TXT _dmarc.fiqtor.com
dig +short TXT fiqtor.com | grep spf
dig +short TXT google._domainkey.fiqtor.com
dig +short TXT _mta-sts.fiqtor.com
dig +short TXT _smtp._tls.fiqtor.com

# HSTS header from the deployed backend
curl -s -D - -o /dev/null https://api.fiqtor.com/health | grep -i strict-transport-security
```

---

## References

- Google Workspace DKIM: https://support.google.com/a/answer/174124
- DMARC: https://dmarc.org/overview/
- MTA-STS (RFC 8461): https://datatracker.ietf.org/doc/html/rfc8461
- TLS-RPT (RFC 8460): https://datatracker.ietf.org/doc/html/rfc8460
- HSTS preload: https://hstspreload.org/
