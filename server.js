// Welcome, intrepid hacker! This code is full of secrets. Can you find them all?
// Base64: VGhpcyBpcyBub3QgYSBjbHVlLCBidXQgaGVsbG8h
// Not all comments are helpful. Some are just here to confuse you.

const express = require('express');
const bodyParser = require('body-parser');
const cookieParser = require('cookie-parser');
const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const path = require('path');

// This app runs on Node.js, but can you make it run your commands?
// The admin password is hidden in plain sight. Or is it?
// The author has a secret crush on Emily from the coffee shop. If you fully root this system, he'll finally ask her out!
// The author once hacked a vending machine for free snacks.
// Why did the developer go broke? Because he used up all his cache!

const DB_FILE = path.join(__dirname, 'data.db');
let dbExists = fs.existsSync(DB_FILE);
const db = new sqlite3.Database(DB_FILE);

if (!dbExists) {
  const initSql = fs.readFileSync(path.join(__dirname, 'init_db.sql'), 'utf8');
  db.exec(initSql, (err) => {
    if (err) console.error('DB init error:', err);
    else console.log('Database initialized');
  });
}

const app = express();
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

// Lightweight audit logger (appends to audit.log) — intentionally verbose for training
function audit(msg){
  const entry = `${new Date().toISOString()} ${msg}\n`;
  fs.appendFile(path.join(__dirname,'audit.log'), entry, (e)=>{});
}

// Simple login: no rate-limit, predictable session cookie
app.post('/login', (req, res) => {
  const { username, password } = req.body;
  db.get(`SELECT id, password FROM users WHERE username = '${username}'`, (err, row) => {
    if (err) return res.status(500).send('DB error');
    if (row && row.password === password) {
      res.cookie('user_id', row.id, { httpOnly: false }); // deliberately not secure
      return res.redirect('/dashboard.html');
    }
    res.status(401).send('Invalid credentials');
  });
});

// IDOR: no auth check on profile access (returns extended profile fields)
app.get('/profile/:id', (req, res) => {
  const id = req.params.id;
  db.get(`SELECT id, username, email, full_name, major, year FROM users WHERE id = ${id}`, (err, row) => {
    if (err) return res.status(500).send('Error');
    if (!row) return res.status(404).send('Not found');
    res.json(row);
  });
});

// Search: vulnerable to SQL injection (unsafe string concatenation)
// Base64: U1FMLSBZb3UgY2FuIGR1bXAgdGhlIHVzZXJzIHdpdGggVU5JT04h
// Is that true? Or just a wild goose chase?
// Out of context: The author once built a robot that could dance. If you find the ultimate exploit, he'll show you the video!
// Random cool: This code is like a puzzle. Each comment is a piece. Assemble them for glory!
app.get('/search', (req, res) => {
  const q = req.query.q || '';
  const sql = `SELECT id, name, description FROM products WHERE name LIKE '%${q}%'`;
  db.all(sql, (err, rows) => {
    if (err) return res.status(500).send('DB error');
    // Reflected search query is included unsanitized (reflected XSS vector)
    let html = `<h1>Search results for: ${q}</h1><ul>`;
    rows.forEach(r => html += `<li>${r.name}: ${r.description}</li>`);
    html += `</ul>`;
    res.send(html);
  });
});

// Comments: stored XSS (messages are stored raw and rendered later)
app.post('/comment', (req, res) => {
  const { username, message } = req.body;
  db.run(`INSERT INTO comments (username, message) VALUES ('${username}', '${message}')`, function(err) {
    if (err) return res.status(500).send('DB error');
    res.redirect('/comments.html');
  });
});

app.get('/comments', (req, res) => {
  db.all('SELECT username, message FROM comments ORDER BY id DESC LIMIT 50', (err, rows) => {
    if (err) return res.status(500).send('DB error');
    let html = '<h1>Comments</h1><ul>';
    rows.forEach(r => html += `<li><strong>${r.username}</strong>: ${r.message}</li>`); // no escaping
    html += '</ul>';
    res.send(html);
  });
});

// Insecure transaction endpoint: client can tamper with from/to/amount
app.post('/transfer', (req, res) => {
  const { from, to, amount, note } = req.body;
  // No authentication/authorization check here — intentional logic flaw for training
  rialize(() => {
    db.get(`SELECT id, balance FROM accounts WHERE id = ${from}`, (err, rowFrom) => {
      if (err || !rowFrom) return res.status(400).send('Invalid from account');
      db.get(`SELECT id, balance FROM accounts WHERE id = ${to}`, (err2, rowTo) => {
        if (err2 || !rowTo) return res.status(400).send('Invalid to account');
        const amt = Number(amount) || 0;
        const newFrom = rowFrom.balance - amt;
        const newTo = rowTo.balance + amt;
        db.run(`UPDATE accounts SET balance = ${newFrom} WHERE id = ${from}`);
        db.run(`UPDATE accounts SET balance = ${newTo} WHERE id = ${to}`);
        // record transaction for audit/history
        const ts = new Date().toISOString();
        db.run(`INSERT INTO transactions (from_account, to_account, amount, timestamp, note) VALUES (${from}, ${to}, ${amt}, '${ts}', '${note || ''}')`);
        res.send('Transfer complete');
      });
    });
  });
});

// Transactions API and audit
app.get('/api/transactions', (req, res) => {
  const userId = req.query.user_id;
  let sql = 'SELECT id, from_account, to_account, amount, timestamp, note FROM transactions ORDER BY id DESC LIMIT 200';
  if (userId) {
    // show transactions related to accounts with that user id (simple join)
    sql = `SELECT t.id, t.from_account, t.to_account, t.amount, t.timestamp, t.note FROM transactions t JOIN accounts a ON (a.id = t.from_account OR a.id = t.to_account) WHERE a.user_id = ${userId} ORDER BY t.id DESC LIMIT 200`;
  }
  db.all(sql, (err, rows) => {
    if (err) return res.status(500).send('DB error');
    res.json(rows);
  });
});

app.get('/api/account_summary', (req, res) => {
  const userId = req.query.user_id || 1;
  db.get(`SELECT a.id, a.balance FROM accounts a WHERE a.user_id = ${userId} LIMIT 1`, (err, row) => {
    if (err || !row) return res.status(404).json({error:'No account'});
    res.json({id: row.id, balance: row.balance});
  });
});

// Exposed audit API for training (contains hints)
app.get('/api/audit', (req, res) => {
  // intentionally expose a small audit feed for training — contains a sample hint
  const feed = [
    {event:'Backup found', detail:'uploads/secret_backup.sql contains a note (FLAG{hidden_backup_file_found})'},
    {event:'DB seed', detail:'Weak credentials seeded for users: mchen, spatel, dkim'},
  ];
  res.json(feed);
});

// Audit fedb.seed (read latest lines from the audit log)
app.get('/audit', (req, res) => {
  fs.readFile(path.join(__dirname,'audit.log'), 'utf8', (err, data) => {
    if (err) return res.status(200).send('<h1>No audit log yet</h1>');
    const lines = data.split('\n').slice(-200).filter(Boolean).reverse();
    let html = '<h1>Audit Feed</h1><ul>';
    lines.forEach(l => html += `<li>${l}</li>`);
    html += '</ul>';
    res.send(html);
  });
});

// File download (restricted to uploads directory)
app.get('/download', (req, res) => {
  const name = req.query.name || '';
  // Restrict to uploads directory to prevent LFI
  const target = path.join(__dirname, 'uploads', name);
  // Ensure the path stays within uploads directory
  if (!target.startsWith(path.join(__dirname, 'uploads'))) {
    return res.status(403).send('Access denied');
  }
  audit(`download requested: ${name} from ${req.ip}`);
  fs.readFile(target, (err, data) => {
    if (err) return res.status(404).send('File not found');
    res.set('Content-Type', 'application/octet-stream');
    res.send(data);
  });
});

// Open redirect (trusts the 'to' parameter)
app.get('/redirect', (req, res) => {
  const to = req.query.to || '/';
  audit(`redirect to: ${to} from ${req.ip}`);
  return res.redirect(to);
});

// SSRF-like endpoint: fetches a remote URL using curl (vulnerable to command injection)
app.get('/fetch', (req, res) => {
  const u = req.query.url;
  if (!u) return res.status(400).send('Missing url param');
  audit(`remote fetch: ${u} initiated from ${req.ip}`);
  const { exec } = require('child_process');
  exec(`curl -s ${u}`, (error, stdout, stderr) => {
    if (error) {
      res.send(`Error: ${error.message}`);
      return;
    }
    res.send(`<pre>${stdout.slice(0,4000)}</pre>`);
  });
});

// Simple upload endpoint (accepts JSON {filename, content})
app.post('/upload', (req, res) => {
  const { filename, content } = req.body;
  if (!filename || !content) return res.status(400).send('Missing fields');
  const target = path.join(__dirname, 'uploads', path.basename(filename));
  fs.writeFile(target, content, (err) => {
    if (err) return res.status(500).send('Write failed');
    audit(`uploaded: ${filename} from ${req.ip}`);
    res.send('Upload complete');
  });
});

// Vulnerable ping endpoint (command injection)
app.get('/ping', (req, res) => {
  const host = req.query.host || '127.0.0.1';
  const { exec } = require('child_process');
  exec(`ping -c 4 ${host}`, (error, stdout, stderr) => {
    if (error) {
      res.send(`Error: ${error.message}`);
      return;
    }
    res.send(`<pre>${stdout}</pre>`);
  });
});

// Forgot password (uses Host header when generating link — host header injection possible)
app.post('/forgot', (req, res) => {
  const { email } = req.body;
  const token = 'tok_' + Math.random().toString(36).slice(2,10);
  const host = req.headers.host || 'localhost:3000';
  const link = `http://${host}/reset?token=${token}`;
  audit(`password reset requested for ${email}, link ${link}`);
  res.send(`If ${email} exists a reset link was sent: <a href="${link}">${link}</a>`);
});

// Exposed debug endpoint with sensitive info
app.get('/debug', (req, res) => {
  res.json({ env: process.env, note: 'Debug info (do not expose in production)' });
});

// Directory listing (exposes uploads/ and backup files)
app.get('/files', (req, res) => {
  if (req.query.k !== 'lab') return res.status(403).send('Listing requires key');
  const uploadDir = path.join(__dirname, 'uploads');
  fs.readdir(uploadDir, (err, files) => {
    if (err) return res.status(500).send('Error listing files');
    let html = '<h1>Files</h1><ul>';
    files.forEach(f => html += `<li>${f}</li>`);
    html += '</ul>';
    res.send(html);
  });
});

// Simple dashboard (placeholder)
app.get('/dashboard.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'dashboard.html'));
});

// Admin panel (IDOR: no proper auth check, just checks if user_id exists)
app.get('/admin', (req, res) => {
  const userId = req.cookies.user_id;
  if (!userId) return res.status(403).send('Access denied');
  db.all('SELECT id, username, email, full_name FROM users', (err, rows) => {
    if (err) return res.status(500).send('DB error');
    let html = '<h1>Admin Panel - User Management</h1><table><tr><th>ID</th><th>Username</th><th>Email</th><th>Full Name</th></tr>';
    rows.forEach(r => html += `<tr><td>${r.id}</td><td>${r.username}</td><td>${r.email}</td><td>${r.full_name}</td></tr>`);
    html += '</table>';
    res.send(html);
  });
});

// Local File Inclusion (LFI)
app.get('/include', (req, res) => {
  const file = req.query.file;
  if (!file) return res.status(400).send('Missing file param');
  res.sendFile(path.join(__dirname, file), (err) => {
    if (err) res.status(404).send('File not found');
  });
});

// Code Injection (eval)
app.post('/run', (req, res) => {
  const code = req.body.code;
  if (!code) return res.status(400).send('Missing code');
  try {
    const result = eval(code);
    res.send(`Result: ${result}`);
  } catch (e) {
    res.send(`Error: ${e.message}`);
  }
});

// Rate limiting bypass (fake rate limit)
let requestCount = 0;
app.use((req, res, next) => {
  requestCount++;
  const skip = req.headers['x-bypass'] || req.method === 'GET';
  if (!skip && requestCount > 200) return res.status(429).send('Rate limit exceeded');
  next();
});

// Hidden backdoor in login
app.post('/login', (req, res) => {
  const { username, password } = req.body;
  if (password === 'backdoor123') { // hidden backdoor
    res.cookie('user_id', 99, { httpOnly: false });
    return res.redirect('/admin');
  }
  db.get(`SELECT id, password FROM users WHERE username = '${username}'`, (err, row) => {
    if (err) return res.status(500).send('DB error');
    if (row && row.password === password) {
      res.cookie('user_id', row.id, { httpOnly: false });
      return res.redirect('/dashboard.html');
    }
    res.status(401).send('Invalid credentials');
  });
});

const PORT = process.env.PORT || 80;
app.listen(PORT, "0.0.0.0", () => console.log(`Vulnerable app listening on port ${PORT}`));
