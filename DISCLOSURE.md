# DISCLOSURE — gửi vendor NGAY HÔM NAY (10 phút)

> Mục tiêu: có timestamp chính thức + xin CVE. 90 ngày tính từ ngày vendor nhận báo cáo.
> Ngày bắt đầu: điền ngày mày thực sự gửi (không dùng ngày soạn thảo).

## 1. GitHub Private Vulnerability Reporting (chính, có timestamp + xin CVE)

1. Vào `https://github.com/microweber/microweber` → tab **Security** → **Report a vulnerability**
   (nếu không thấy: `https://github.com/microweber/microweber/security/advisories/new`)
2. Dán nội dung `advisory.md` (đính kèm `exploit/microweber_unauth_rce.py` + 1-2 ảnh trong `img_POC/`)
3. Mẫu title: `Unauthenticated RCE (CVSS 9.8) — chain of 3 bugs in ≤ 2.0.20`
4. Trong báo cáo, **xin CVE rõ ràng**: "Please assign a CVE ID via GitHub's CNA for this advisory."
5. Lưu lại link advisory + ngày gửi vào bảng Timeline ở `README.md` + `advisory.md`

## 2. Email song song (vendor nhỏ có thể không xem GitHub)

- Gửi tới: `security@microweber.com` (đồng thời `peter@microweber.com` — maintainer chính peter-mw, nếu không chắc thì chỉ gửi security@)
- Subject: `[SECURITY] Unauthenticated RCE (CVSS 9.8) in Microweber ≤ 2.0.20 — coordinated disclosure, 90-day policy`
- Body: dùng template dưới, đính kèm `Microweber_RCE_Advisory.docx` + link GitHub advisory private

```
Hello Microweber team,

I reported a critical security issue via GitHub Private Vulnerability
Reporting on microweber/microweber (link: <FILL>) and am notifying you
in parallel by email.

Short version: three bugs in <= 2.0.20 chain into a fully
unauthenticated RCE with 3 HTTP GET requests on a default install
(CVSS 3.1 9.8). A zero-dependency PoC and a detailed advisory with
remediation for each bug are attached / in the private report.

I follow a 90-day coordinated disclosure policy — public release on
patch availability or day 90, whichever comes first. Happy to assist
with reproduction (a self-testing PoC mode is included) and to
coordinate the release announcement.

Best regards,
0xki29
https://0xki29.github.io/blog
```

## 3. Theo dõi

- Ghi ngày gửi vào `README.md` + `advisory.md` (trường [FILL: report date])
- Nếu 7 ngày không phản hồi: gửi follow-up 1 lần/tuần, ghi lại (timestamp bằng chứng thiện chí)
- Khi vendor xác nhận + release patch: điền tiếp các trường [FILL], làm theo `RELEASE-CHECKLIST.md`
- Khi có CVE: **rename repo** thành `CVE-2026-XXXX` (GitHub tự redirect), thêm CVE vào badges
