#!/usr/bin/env node
const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const HOST = '127.0.0.1';
const PORT = 3000;
const WEB_ROOT = path.resolve(__dirname, 'web');
const TOKEN = process.env.MEGA_DASHBOARD_TOKEN || crypto.randomBytes(32).toString('hex');

function sendJson(res, status, data) {
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store' });
  res.end(JSON.stringify(data));
}

function isAuthorized(req) {
  const auth = req.headers.authorization || '';
  const match = auth.match(/^Bearer\s+(.+)$/i);
  const candidate = match ? match[1].trim() : '';
  if (!candidate) return false;
  try {
    return crypto.timingSafeEqual(Buffer.from(candidate), Buffer.from(TOKEN));
  } catch (error) {
    return false;
  }
}

function safeFileRead(filePath) {
  if (!filePath.startsWith(WEB_ROOT)) return null;
  try {
    return fs.readFileSync(filePath);
  } catch (error) {
    return null;
  }
}

function getContentType(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  const map = {
    '.html': 'text/html; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.js': 'application/javascript; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.svg': 'image/svg+xml',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.ico': 'image/x-icon'
  };
  return map[ext] || 'application/octet-stream';
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${HOST}:${PORT}`);

  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'SAMEORIGIN');
  res.setHeader('Referrer-Policy', 'no-referrer');
  res.setHeader('Content-Security-Policy', "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; object-src 'none'; base-uri 'self'; frame-ancestors 'none'; form-action 'self';");

  if (url.pathname === '/api/health') {
    if (!isAuthorized(req)) {
      res.writeHead(401, { 'WWW-Authenticate': 'Bearer realm="mega-code-4"' });
      return sendJson(res, 401, { error: 'Unauthorized', message: 'Token Bearer inválido ou ausente.' });
    }

    return sendJson(res, 200, {
      status: 'ok',
      service: 'MEGA-CODE-4',
      host: HOST,
      model: 'Fable 5',
      mcp: {
        hexstrike: 'ON',
        cyberstrike: 'ON'
      },
      timestamp: new Date().toISOString()
    });
  }

  if (url.pathname === '/api/token') {
    return sendJson(res, 200, { token: TOKEN });
  }

  if (!isAuthorized(req)) {
    res.writeHead(401, { 'WWW-Authenticate': 'Bearer realm="mega-code-4"' });
    return sendJson(res, 401, { error: 'Unauthorized', message: 'Token Bearer inválido ou ausente.' });
  }

  const requestedPath = url.pathname === '/' ? '/index.html' : url.pathname;
  const filePath = path.join(WEB_ROOT, requestedPath);
  if (!filePath.startsWith(WEB_ROOT)) {
    res.writeHead(403);
    return res.end('Forbidden');
  }

  const data = safeFileRead(filePath);
  if (!data) {
    res.writeHead(404);
    return res.end('Not Found');
  }

  res.writeHead(200, { 'Content-Type': getContentType(filePath) });
  res.end(data);
});

server.listen(PORT, HOST, () => {
  console.log(`[MEGA-CODE-4] Dashboard seguro em http://${HOST}:${PORT}`);
  console.log(`[MEGA-CODE-4] Bearer Token: ${TOKEN}`);
});

process.on('SIGINT', () => server.close(() => process.exit(0)));
process.on('SIGTERM', () => server.close(() => process.exit(0)));
