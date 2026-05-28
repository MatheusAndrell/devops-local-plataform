require('dotenv').config();

const express = require('express');
const { Pool } = require('pg');
const { register, collectDefaultMetrics } = require('prom-client');

const app = express();
const PORT = process.env.PORT || 3002;

collectDefaultMetrics({ prefix: 'user_' });
app.use(express.json());

const pool = new Pool({
  host: process.env.POSTGRES_HOST || 'localhost',
  port: parseInt(process.env.POSTGRES_PORT || '5432'),
  database: process.env.POSTGRES_DB || 'devops_platform',
  user: process.env.POSTGRES_USER || 'devops',
  password: process.env.POSTGRES_PASSWORD || 'devops123',
});

async function init() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(100) UNIQUE NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        role VARCHAR(50) DEFAULT 'user',
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    `);
  } catch (err) {
    console.warn('DB init failed:', err.message);
  }
}

app.get('/', (req, res) => {
  res.json({ service: 'user-service', status: 'online', version: '1.0.0' });
});

app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'healthy', db: 'connected', timestamp: new Date().toISOString() });
  } catch {
    res.status(503).json({ status: 'degraded', db: 'disconnected' });
  }
});

app.get('/users', async (req, res) => {
  const result = await pool.query('SELECT id, username, email, role, created_at FROM users ORDER BY id');
  res.json({ users: result.rows, total: result.rowCount });
});

app.post('/users', async (req, res) => {
  const { username, email, role = 'user' } = req.body;
  if (!username || !email) return res.status(400).json({ error: 'username and email are required' });
  const result = await pool.query(
    'INSERT INTO users (username, email, role) VALUES ($1, $2, $3) RETURNING *',
    [username, email, role]
  );
  res.status(201).json(result.rows[0]);
});

app.get('/users/:id', async (req, res) => {
  const result = await pool.query('SELECT id, username, email, role, created_at FROM users WHERE id = $1', [req.params.id]);
  if (!result.rowCount) return res.status(404).json({ error: 'User not found' });
  res.json(result.rows[0]);
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

const server = app.listen(PORT, async () => {
  await init();
  console.log(`user-service running on port ${PORT}`);
});

module.exports = { app, server };
