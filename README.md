# Microweber CMS ≤ 2.0.20 — Unauthenticated RCE in 3 GET Requests

![CVSS 9.8 CRITICAL](https://img.shields.io/badge/CVSS_v3.1-9.8_CRITICAL-red)
![Auth: NONE](https://img.shields.io/badge/auth-NONE-critical)
![Requests: 3 GET](https://img.shields.io/badge/requests-3%C3%97GET-informational)
![Python 3.6+](https://img.shields.io/badge/PoC-Python_3.6%2B_zero--deps-blue)
![License: MIT](https://img.shields.io/badge/license-MIT-green)

> **[EMBARGOED — placeholder header, replace on release day]**
> Three individually low-severity bugs chained into a fully **unauthenticated, self-sufficient remote code execution**: exactly **3 HTTP GET requests**, no account, no CSRF token, no prior upload, no knowledge of the target beyond its URL. Works against a **default, fresh install** of Microweber CMS (latest release at time of reporting).
>
> **Status:** coordinated disclosure in progress — this repository goes public together with the vendor patch (or at expiry of the 90-day window). Watch the repo to get notified.

## Impact

| | |
|---|---|
| Affected versions | Microweber CMS **≤ 2.0.20** (default install; SQLite confirmed, MySQL path exists) |
| Fixed version | **[FILL ON RELEASE]** |
| CVE | **[FILL ON RELEASE]** |
| CVSS v3.1 | **9.8 CRITICAL** — `AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H` |
| CWE | CWE-306 (missing auth), CWE-22 (path traversal), CWE-290 (bypassable check) |
| Attacker requirements | network access to the HTTP port — **nothing else** |

## The chain in 30 seconds

```
[REQUEST 1]            [REQUEST 2]                  [REQUEST 3]
GET /api/.../          GET /api/thumbnail_img       GET /module/?module=X&c=id
OptionManager/save  →  ?src=storage/database    →   PHP include of the
                       .sqlite&ext=svg&cache_       planted .php module
   ↓                   path_relative=modules/X.php       ↓
raw "<?php ... ?>"     whole SQLite DB (shell        OS command
bytes written into    inside) copied verbatim to    execution, output
the options table     userfiles/modules/X.php       in the response
```

1. **CWE-306** — `OptionManager::save()` lost its `is_admin()` check (commented out upstream, "moved to middleware" — but that middleware never fires on the legacy class-dispatch route) **and** its XSS filter. Anyone can store raw PHP bytes in the `options` table → on the stock SQLite install the payload lands verbatim inside `storage/database.sqlite`.
2. **CWE-22** — `MediaManager::thumbnail_img()` runs `extract($params)` and trusts `cache_path_relative` (no `..` filtering, `normalize_path(..., resolve=false)`). The `ext=svg` branch passes binary through untouched → the **entire SQLite database** gets copied to any web-reachable path, e.g. `userfiles/modules/X.php`.
3. **CWE-290** — the only guard on the module loader, `SameSiteRefererMiddleware`, is `Str::startsWith($referer, site_url())` on a header the client fully controls. Forge the `Referer`, done.

## Reproduce (authorized lab only)

```bash
# 1. vulnerable lab
docker compose -f lab/docker-compose.yml up --build   # http://localhost:8888

# 2. full chain + verdict (exit 0 = vulnerable)
python exploit/microweber_unauth_rce.py -t http://127.0.0.1:8888 -c whoami

# safe self-test: plant → verify → cleanup, PASS/FAIL per step
python exploit/microweber_unauth_rce.py -t http://127.0.0.1:8888 --test
```

See [`exploit/README.md`](exploit/README.md) for all modes (`--setup-only`, `--exec-only`, `--cleanup`, `--json` for CI) and [`advisory.md`](advisory.md) for the full analysis.

## Detection (before you can patch)

Look for these in access logs — each is a smoking gun:

```
GET /api/MicroweberPackages/Option/OptionManager/save?option_key=…&option_value=%3C%3Fphp
GET /api/thumbnail_img?…&ext=svg&cache_path_relative=modules%2F….php
GET /module/?module=<random-looking-name>&c=
```

Also inspect `userfiles/modules/` for `.php` files whose content starts with `SQLite format 3`, and audit the `options` table for PHP tags in `option_value`.

## Mitigation (interim, until the vendor patch)

```nginx
# 1. kill PHP execution inside userfiles (breaks step 2→3)
location ~* ^/userfiles/.*\.php$ { deny all; }
```

```apache
# .htaccess inside userfiles/
php_flag engine off
```

Plus: restrict `/api/MicroweberPackages/Option/OptionManager/*` and `/api/thumbnail_img` at the WAF, and VACUUM the SQLite database (planted payloads survive in free pages even after the option row is deleted — rotate all secrets on any suspected compromise).

Root-cause fixes recommended to the vendor are in [`advisory.md`](advisory.md#remediation).

## Timeline

| Date | Event |
|---|---|
| 2025-08-14 | Microweber v2.0.20 released (latest at time of research) |
| 2026-Q4 | Chain discovered during whitebox source review; verified on lab (fresh install, no admin) |
| **[FILL]** | Reported to vendor (GitHub private vulnerability reporting + email) — 90-day clock starts |
| **[FILL]** | Vendor acknowledgment / CVE requested |
| **[FILL]** | Public release: patch published or 90-day window expired |

## Credits

Found by **[0xki29](https://0xki29.github.io/blog)** — security research, responsible disclosure. Full write-up: **[[blog post]](https://0xki29.github.io/blog/microweber-unauth-rce)**.

## Legal / responsible use

Provided for defensive verification and vendor patch validation on systems **you own or are authorized in writing to test**. The chain was reported to the vendor before publication; this repo publishes under a coordinated-disclosure / 90-day policy.
