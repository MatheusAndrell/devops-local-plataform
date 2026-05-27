require('dotenv').config();

const express = require('express');
const jwt = require('jsonwebtoken');
const { register, collectDefaultMetrics } = require('prom-client');

const app = express();
const PORT = process.env.PORT || 3001;
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-in-production';

collectDefaultMetrics({ prefix: 'auth_' });
app.use(express.json());

const USERS = [
  { id: 1, username: 'admin', password: 'admin123', role: 'admin' },
  { id: 2, username: 'user', password: 'user123', role: 'user' },
];

app.get('/', (req, res) => {
  res.json({ service: 'auth-service', status: 'online', version: '1.0.0' });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', uptime: process.uptime(), timestamp: new Date().toISOString() });
});

app.post('/auth/login', (req, res) => {
  const { username, password } = req.body;
  const user = USERS.find((u) => u.username === username && u.password === password);
  if (!user) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }
  const token = jwt.sign({ sub: user.id, username: user.username, role: user.role }, JWT_SECRET, { expiresIn: '1h' });
  res.json({ token, expiresIn: 3600 });
});

app.post('/auth/verify', (req, res) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing token' });
  }
  try {
    const payload = jwt.verify(authHeader.split(' ')[1], JWT_SECRET);
    res.json({ valid: true, payload });
  } catch {
    res.status(401).json({ valid: false, error: 'Invalid or expired token' });
  }
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

const server = app.listen(PORT, () => {
  console.log(`auth-service running on port ${PORT}`);
});

module.exports = { app, server };
