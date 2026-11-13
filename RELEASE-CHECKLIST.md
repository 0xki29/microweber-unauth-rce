# RELEASE DAY — checklist + trending playbook

> Điều kiện mở khoá: **(a)** vendor đã release patch, hoặc **(b)** đủ 90 ngày từ ngày báo cáo mà vendor im lặng. Chưa đạt → không publish, dù bất kỳ lý do nào.

## A. Trước khi publish (30 phút)

1. Verify patch: dựng lab bản mới, chạy `python exploit/microweber_unauth_rce.py -t http://127.0.0.1:8888 --test` → phải exit **1**. Chụp lại output làm bằng chứng "patch verified".
2. Điền mọi chỗ `[FILL …]` trong `README.md`, `advisory.md` (CVE, fixed version, dates, blog URL).
3. Kiểm tra 6 ảnh `img_POC/` — **xóa/che tên máy, đường dẫn cá nhân, email** nếu lộ (search `VIETLONG`, `hoangnv`, `vietlongvnn`).
4. Quay 1 đoạn ~20s banner exploit chạy thật (terminal truecolor của mày rất "shareable") → `demo.gif` đặt cạnh README. Repo có GIF có tỷ lệ click cao hơn hẳn.
5. Rename repo nếu đã có CVE: `CVE-2026-XXXX` (GitHub tự redirect tên cũ).

## B. Publish repo (10 phút)

```bash
cd <this-repo-folder>
git init && git add -A && git commit -m "Microweber <= 2.0.20 unauth RCE (CVSS 9.8) - coordinated disclosure release"
# nếu chưa có repo trên GitHub: tạo private repo r đẩy lên
git remote add origin https://github.com/0xki29/<repo-name>.git
git branch -M main && git push -u origin main
```

- **Topics** (quan trọng cho discovery): `cve` `security` `rce` `microweber` `exploit` `poc` `penetration-testing` `php` `cms`
- **Pin** repo vào profile. Mở **Issues** (nếu ai đó hỏi kỹ thuật, trả lời nhanh = lên trending có trọng số).

## C. Publish bài blog (1 LỆNH)

> **Đã dựng sẵn launcher ngoài repo (không thể lộ lên GitHub):**
>
> ```
> C:\Users\VIETLONGVNN\Documents\XUAT-BAN-MICROWEBER.cmd     (double-click hoặc gõ tên trong cmd)
> ```
>
> Tương đương: `powershell tools\release-microweber.ps1 -Force -PublishRepo`
>
> **Script tự làm hết:** move ảnh + rewrite path → stamp ngày release → sinh + optipng OG image → ghi `_posts\<ngày>-microweber-unauth-rce.md` → commit + push blog → push repo research + API flip private→public.
>
> **Guard không thể skip:** còn bất kỳ `[FILL]` nào (CVE, link repo, timeline) → script list ra từng dòng và DỪNG — tránh publish bài đứt đủ. Chỉ việc điền 5 chỗ `[FILL]` trong draft trước khi chạy (đã test với bản tiếng Việt: guard list đúng 5 dòng 10/203/204/205/211).
>
> `-Force` chỉ bypass MỘT thứ: check "vendor đã patch chưa". Quyết định thời điểm (patch hoặc đủ 90 ngày) là của mày lúc bấm chạy.

## D. Phát tán (thứ tự + giờ vàng)

1. **Giờ:** Thứ 3–5, ~14:00–16:00 UTC (sáng Mỹ, chiều EU) — giờ GA của security Twitter
2. **X/Twitter thread** (5–7 tweet): bug đơn lẻ vô hại → ghép chain → GIF RCE → CVSS 9.8 + timeline đạo đức → link repo + blog. Thread có GIF ở tweet 3-4 giữ retention.
3. **r/netsec** (reddit.com/r/netsec Submit): title chuẩn của mày
   `Microweber CMS <= 2.0.20 - unauthenticated RCE by chaining 3 "low" bugs (CVSS 9.8) [0-day responsibly disclosed, patch released]`
   - link về **bài blog** (không phải thẳng repo — r/netsec dislike self-promo repo trần)
   - comment đầu tiên: link repo + PoC usage
4. **Newsletter submit** (miễn phí, chuẩn beloved của ngành):
   - tl;dr Sec — https://tldrsec.com/articles/submit/
   - PortSwigger Daily Swig —https://portswigger.net/daily-swig (email tips@)
   - Unsupervised Learning (Daniel Miessler) — submit form
   - This Week in OSINT không hợp — bỏ
5. **Hacker News**: submit link blog, title giữ nguyên tên bài. Nếu lên front page → hàng chục nghìn views.
6. **LinkedIn** + các group VN: Whitehat.vn, RE Vietnam, Facebook group security VN (nội dung VN ngắn + link EN)

## E. Sau 48h

- Trả lời mọi issue/comment (tốc độ phản hồi của author ảnh hưởng trending)
- Thêm section "Q&A / FAQ" vào README từ câu hỏi thực tế
- Nếu vendor credited mày trong advisory của họ → thêm link 2 chiều
- Ghi kết quả (stars, CVE ID, vendor credit) vào `upgrade.md` blog làm case study
