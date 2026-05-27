const { checkHealth: pgHealth } = require('../db/postgres');
const { checkHealth: redisHealth } = require('../db/redis');
const os = require('os');

async function healthRoute(req, res) {
  const start = Date.now();

  const [pgStatus, redisStatus] = await Promise.allSettled([
    pgHealth(),
    redisHealth(),
  ]);

  const checks = {
    postgres: pgStatus.status === 'fulfilled' ? pgStatus.value : { status: 'unhealthy', error: pgStatus.reason?.message },
    redis: redisStatus.status === 'fulfilled' ? redisStatus.value : { status: 'unhealthy', error: redisStatus.reason?.message },
  };

  const allHealthy = Object.values(checks).every((c) => c.status === 'healthy');
  const mem = process.memoryUsage();
  const totalMem = os.totalmem();
  const freeMem = os.freemem();

  const payload = {
    status: allHealthy ? 'healthy' : 'degraded',
    version: process.env.APP_VERSION || '2.0.0',
    environment: process.env.NODE_ENV || 'development',
    uptime: Math.floor(process.uptime()),
    responseTime: `${Date.now() - start}ms`,
    checks,
    system: {
      memory: {
        heap: { used: mem.heapUsed, total: mem.heapTotal },
        rss: mem.rss,
        system: { total: totalMem, free: freeMem, usedPercent: (((totalMem - freeMem) / totalMem) * 100).toFixed(1) },
      },
      cpu: os.loadavg(),
      platform: os.platform(),
    },
    timestamp: new Date().toISOString(),
  };

  res.status(allHealthy ? 200 : 503).json(payload);
}

module.exports = { healthRoute };
