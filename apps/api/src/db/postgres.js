const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.POSTGRES_HOST || 'localhost',
  port: parseInt(process.env.POSTGRES_PORT || '5432'),
  database: process.env.POSTGRES_DB || 'devops_platform',
  user: process.env.POSTGRES_USER || 'devops',
  password: process.env.POSTGRES_PASSWORD || 'devops123',
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

async function checkHealth() {
  const client = await pool.connect();
  try {
    await client.query('SELECT 1');
    return { status: 'healthy' };
  } finally {
    client.release();
  }
}

async function runMigrations() {
  const client = await pool.connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS health_checks (
        id SERIAL PRIMARY KEY,
        checked_at TIMESTAMPTZ DEFAULT NOW(),
        status VARCHAR(20) NOT NULL
      )
    `);
  } finally {
    client.release();
  }
}

module.exports = { pool, checkHealth, runMigrations };
