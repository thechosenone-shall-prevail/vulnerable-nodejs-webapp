# Westbridge University Portal (Deliberately Vulnerable) — Educational Use Only

This is a deliberately vulnerable, college-themed web application for authorized training events. The experience is meant to feel like a bustling university portal—with plenty of links, notices, and distractions—while containing intentionally insecure functionality for hands‑on practice.

## Campus Snapshot (What you’ll see)
- Hero banner promoting admissions, alumni weekend, and course registration—all clickable.
- Crowded navigation: Academics, Housing, Dining, Athletics, IT Help, Bursar, Library, Clubs, Events.
- Pop-up style “urgent” notices about parking, cafeteria hours, and forgotten IDs.
- Mixed content cards (courses, transactions, uploads, forgot password, audit feed) to pull attention in different directions.

## Quick Start
1. Install deps: `npm install`
2. Start server: `node server.js`
3. Browse: `http://localhost:3000`

## Intentional Vulnerabilities / Exercises
- Brute-forceable login (no rate-limiting, weak passwords)
- IDOR: `/profile/:id` returns user profile without authorization checks
- SQL Injection: `/search?q=` uses unsafe string concatenation in SQL
- Reflected XSS: search query is echoed without escaping
- Stored XSS: `/comment` stores unescaped input; `/comments` renders it directly
- Insecure transaction flow: `/transfer` trusts client-provided `from`/`to`/`amount`
- Exposed debug API: `/debug` returns environment details
- File listing: `/files` exposes `uploads/` (includes a sample backup/flag)

## Navigation Map (high-distraction links)
- `/` — landing page with rotating banners and multiple “Learn more” buttons
- `/transactions.html` — transfer form + transaction history (logic flaws)
- `/courses.html` — course gallery, materials, and image tiles
- `/upload.html` — upload form writing to `uploads/`
- `/download.html` — download endpoint demonstrating traversal risk
- `/forgot.html` — password reset flow using Host header (host header injection)
- `/audit.html` — exposed training audit feed
- `/comments` — renders stored comments (stored XSS playground)
- `/profile/:id` — profile viewer (IDOR)
- `/search?q=` — search UI (SQLi + reflected XSS)

## Suggested Student “Admissions” Personas (demo creds)
- Student: `student1 / password123`
- Bursar intern: `bursar / bursar123`
- Library aide: `library / library123`
*(Accounts are intentionally weak; rotate if running multiple cohorts.)*

## Lab Scenarios to Try
- Enumerate user profiles via IDOR and pivot to transaction tampering.
- Inject into `/search` to exfiltrate mock grades data.
- Drop a stored XSS payload in `/comment` and harvest cookies on `/comments`.
- Alter `from`/`to`/`amount` in `/transfer` to move campus “funds.”
- Explore `/files` for exposed backups and flags.
- Abuse Host header in `/forgot.html` to craft reset links.

## Operator Notes
- Safety: Do **NOT** deploy to public/untrusted networks. Use isolation (VPC, IP allowlists) and monitoring.
- Images: Course/gallery images are hot-linked from Unsplash/Picsum. To localize, drop CC0 photos into `public/photos/` and update templates.
- Logs/data: The app is intentionally noisy; reset the environment between runs if used in multiple workshops.
- Network: Keep everything on a private range; avoid exposing port 3000 externally.

## Campus “Help Desk” Hours
- Live TA window: 15 minutes before/after each lab block.
- Self-help: Check `/debug` (intentionally exposed) for environment hints.
- If something seems broken, assume it’s deliberate—verify before “fixing.”

## Known Quirks (by design)
- No CSRF protection on forms.
- Weak password policy and no lockouts.
- Direct object references on profiles and transactions.
- Banners and notices change copy often to keep users skimming instead of reading deeply.

Use this only for the intended educational lab. Do not deploy in production.
