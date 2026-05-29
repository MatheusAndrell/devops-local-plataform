require('dotenv').config();

const express = require('express');
const { register, collectDefaultMetrics } = require('prom-client');
const { httpMetrics } = require('./middleware/httpMetrics');
const { healthRoute } = require('./routes/health');
const { runMigrations } = require('./db/postgres');
const { redis } = require('./db/redis');

const app = express();
const PORT = process.env.PORT || 3000;
const APP_VERSION = process.env.APP_VERSION || '2.0.0';

collectDefaultMetrics({ prefix: 'api_' });

app.use(express.json());
app.use(httpMetrics);

app.get('/', (req, res) => {
  res.json({
    service: 'devops-api',
    status: 'online',
    version: APP_VERSION,
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
  });
});

app.get('/health', healthRoute);

app.get('/livez', (req, res) => {
  res.status(200).json({ status: 'alive' });
});

app.get('/readyz', (req, res) => {
  res.status(200).json({ status: 'ready' });
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

app.get('/cache-test', async (req, res) => {
  const key = 'cache:test';
  const cached = await redis.get(key);
  if (cached) {
    return res.json({ source: 'cache', data: JSON.parse(cached) });
  }
  const data = { message: 'api response', ts: Date.now() };
  await redis.setex(key, 30, JSON.stringify(data));
  res.json({ source: 'origin', data });
});

async function bootstrap() {
  try {
    await runMigrations();
    console.log('Database migrations applied');
  } catch (err) {
    console.warn('Database not available at startup:', err.message);
  }

  try {
    await redis.connect();
    console.log('Redis connected');
  } catch (err) {
    console.warn('Redis not available at startup:', err.message);
  }

  const server = app.listen(PORT, () => {
    console.log(`devops-api v${APP_VERSION} running on port ${PORT}`);
  });

  return server;
}

const server = bootstrap();

module.exports = { app, server };
